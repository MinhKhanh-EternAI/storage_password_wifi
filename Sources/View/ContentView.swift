import SwiftUI
import UniformTypeIdentifiers
import NetworkExtension

struct ContentView: View {
    @EnvironmentObject private var store: WiFiStore
    @EnvironmentObject private var theme: AppTheme
    @StateObject private var wifiInfo = CurrentWiFi()

    @State private var showAdd = false
    @State private var editItem: WiFiNetwork?
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportTempURL: URL?
    @State private var exportDoc: FileDocumentURL?
    @State private var showQRScanner = false
    @State private var search = ""
    @State private var connectMessage: String?

    private var filtered: [WiFiNetwork] {
        let s = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !s.isEmpty else { return store.items }
        return store.items.filter { $0.ssid.lowercased().contains(s) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Mạng hiện tại") {
                    HStack {
                        Text("SSID")
                        Spacer()
                        Text(wifiInfo.currentSSID ?? "Không đọc được")
                            .foregroundStyle(.secondary)
                    }
                    Button { wifiInfo.requestAndFetch() } label: {
                        Label("Làm mới", systemImage: "arrow.clockwise")
                    }
                }

                if filtered.isEmpty {
                    EmptyState()
                } else {
                    Section("Danh sách Wi-Fi đã lưu") {
                        ForEach(filtered) { item in
                            NavigationLink {
                                WiFiDetailHost(
                                    item: item,
                                    onUpdate: { store.update($0) },
                                    onDelete: { store.delete(item.id) },
                                    onEdit: { editItem = item }
                                )
                            } label: {
                                WiFiRow(item: item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.delete(item.id)
                                } label: {
                                    Label("Xoá", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button("Kết nối", systemImage: "wifi") { connect(item) }
                                Button("Sửa", systemImage: "pencil") { editItem = item }
                                Button("Xoá", systemImage: "trash", role: .destructive) {
                                    store.delete(item.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wi-fi")
            .searchable(text: $search, prompt: "Tìm Tên mạng…")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Giao diện", selection: $theme.appearance) {
                            ForEach(AppTheme.Appearance.allCases) { a in
                                HStack { Text(a.label); if a == theme.appearance { Spacer(); Image(systemName: "checkmark") } }
                                    .tag(a)
                            }
                        }
                    } label: { Image(systemName: "moon.circle") }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button { showQRScanner = true } label: {
                            Label("Quét QR Wi-Fi", systemImage: "qrcode.viewfinder")
                        }
                        Button { showImporter = true } label: {
                            Label("Nhập từ JSON", systemImage: "square.and.arrow.down")
                        }
                        Button { doExport() } label: {
                            Label("Xuất JSON", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }.accessibilityLabel("Thêm Wi-Fi")
                }
            }
            .onAppear { wifiInfo.requestAndFetch() }

            // Add
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    WiFiFormView(item: .init(ssid: "", password: "")) { item in
                        store.add(item)
                    }
                    .navigationTitle("Thêm Wi-Fi")
                }
            }
            // Edit
            .sheet(item: $editItem) { item in
                NavigationStack {
                    WiFiFormView(item: item) { updated in
                        store.update(updated)
                    }
                    .navigationTitle("Sửa Wi-Fi")
                }
            }
            // Import
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first {
                    do {
                        let data = try Data(contentsOf: url)
                        try store.importData(data, merge: true)
                    } catch { print("Import error:", error) }
                }
            }
            // Export
            .fileExporter(isPresented: $showExporter, document: exportDoc, contentType: .json, defaultFilename: "wifi.json") { _ in
                if let url = exportTempURL { try? FileManager.default.removeItem(at: url) }
                exportTempURL = nil
                exportDoc = nil
            }
            // QR
            .sheet(isPresented: $showQRScanner) {
                QRScannerView { text in
                    showQRScanner = false
                    if let parsed = WiFiQRParser.parse(text) {
                        connect(parsed, saveIfSuccess: true)
                    } else {
                        connectMessage = "QR không đúng chuẩn Wi-Fi."
                    }
                }
                .ignoresSafeArea()
            }
            .alert("Kết nối", isPresented: Binding(get: { connectMessage != nil }, set: { if !$0 { connectMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(connectMessage ?? "")
            }
        }
    }

    private func doExport() {
        do {
            let data = try store.exportData()
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wifi-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: tmp, options: .atomic)
            exportTempURL = tmp
            exportDoc = FileDocumentURL(url: tmp)
            showExporter = true
        } catch { print("Export error:", error) }
    }

    private func connect(_ item: WiFiNetwork) { connect(item, saveIfSuccess: false) }

    private func connect(_ item: WiFiNetwork, saveIfSuccess: Bool) {
        wifiInfo.connect(ssid: item.ssid,
                         password: item.security == .open ? nil : item.password,
                         security: item.security,
                         joinOnce: false) { err in
            DispatchQueue.main.async {
                if let nsErr = err as NSError? {
                    if nsErr.domain == NEHotspotConfigurationErrorDomain,
                       nsErr.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                        connectMessage = "Đã kết nối với \(item.ssid)."
                        if saveIfSuccess { store.add(item) }
                    } else {
                        connectMessage = "Kết nối thất bại: \(nsErr.localizedDescription)"
                    }
                } else {
                    connectMessage = "Đã gửi yêu cầu kết nối \(item.ssid). Có thể hệ thống hiện prompt xác nhận."
                    if saveIfSuccess { store.add(item) }
                }
                wifiInfo.requestAndFetch()
            }
        }
    }
}

struct WiFiRow: View {
    let item: WiFiNetwork
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi").font(.title3).foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.ssid).font(.headline)
                Text(item.security.rawValue).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "qrcode").foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyState: View {
    var body: some View {
        Section {
            VStack(spacing: 8) {
                Image(systemName: "wifi.slash").font(.system(size: 48, weight: .thin))
                Text("Chưa có Wi-Fi nào").font(.headline)
                Text("Nhấn **Thêm** để lưu mạng Wi-Fi mới.").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 40)
        }
    }
}

struct WiFiDetailHost: View {
    let item: WiFiNetwork
    let onUpdate: (WiFiNetwork) -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    var body: some View {
        WiFiDetailView(item: item, onUpdate: onUpdate, onDelete: onDelete, onEdit: onEdit)
    }
}

struct FileDocumentURL: FileDocument {
    static var readableContentTypes: [UTType] = [.json]
    static var writableContentTypes: [UTType] = [.json]
    var url: URL
    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws { self.url = .init(fileURLWithPath: "") }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url, options: .immediate)
    }
}
