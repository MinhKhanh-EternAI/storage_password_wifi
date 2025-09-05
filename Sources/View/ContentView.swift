import SwiftUI
import UniformTypeIdentifiers
import NetworkExtension

struct ContentView: View {
    @EnvironmentObject private var store: WiFiStore
    @EnvironmentObject private var theme: AppTheme

    @StateObject private var wifiInfo = CurrentWiFi()   // 👈 NEW

    @State private var showAdd = false
    @State private var editItem: WiFiNetwork?
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportTempURL: URL?
    @State private var exportDoc: FileDocumentURL?
    @State private var search = ""

    // QR scan
    @State private var showQRScanner = false            // 👈 NEW
    @State private var connectMessage: String? = nil    // 👈 NEW

    private var filtered: [WiFiNetwork] {
        let s = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !s.isEmpty else { return store.items }
        return store.items.filter { $0.ssid.lowercased().contains(s) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Mạng hiện tại
                Section("Mạng hiện tại") {
                    HStack {
                        Text("SSID")
                        Spacer()
                        Text(wifiInfo.currentSSID ?? "Không đọc được")
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        wifiInfo.requestAndFetch()
                    } label: {
                        Label("Làm mới", systemImage: "arrow.clockwise")
                    }
                }

                // Hành động nhanh
                Section("Hành động") {
                    Button {
                        showQRScanner = true
                    } label: {
                        Label("Quét QR Wi-Fi", systemImage: "qrcode.viewfinder")
                    }
                    .accessibilityLabel("Quét QR Wi-Fi")
                }

                // Danh sách
                if filtered.isEmpty {
                    EmptyState()
                } else {
                    Section {
                        ForEach(filtered) { item in
                            NavigationLink {
                                WiFiDetailHost(
                                    item: item,
                                    onUpdate: { store.update($0) },
                                    onDelete: { store.delete(item.id) },
                                    onEdit: { editItem = item }
                                )
                            } label: { WiFiRow(item: item) }
                            .contextMenu {
                                Button("Kết nối", systemImage: "wifi") {
                                    connect(item)
                                }
                                Button("Sửa", systemImage: "pencil") { editItem = item }
                                Button("Xoá", systemImage: "trash", role: .destructive) {
                                    store.delete(item.id)
                                }
                            }
                        }
                        .onDelete(perform: store.delete)
                    } header: { Text("Danh sách") }
                }
            }
            .navigationTitle("Wi-Fi Offline")
            .searchable(text: $search, prompt: "Tìm SSID…")
            .toolbar {
                LeadingAppearanceToolbar(appearance: Binding(
                    get: { theme.appearance },
                    set: { theme.appearance = $0 }
                ))
                TrailingActionToolbar(
                    importTapped: { showImporter = true },
                    exportTapped: doExport,
                    addTapped: { showAdd = true }
                )
            }
            .onAppear { wifiInfo.requestAndFetch() }   // 👈 tải SSID lúc mở

            // Add
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    WiFiFormView(
                        item: .init(ssid: "", password: ""),
                        onSubmit: { item in
                            store.add(item)
                            showAdd = false
                        }
                    )
                    .navigationTitle("Thêm Wi-Fi")
                    .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Đóng") { showAdd = false } } }
                }
            }
            // Edit
            .sheet(item: $editItem) { item in
                NavigationStack {
                    WiFiFormView(item: item, onSubmit: { updated in
                        store.update(updated)
                        editItem = nil
                    })
                    .navigationTitle("Sửa Wi-Fi")
                    .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Đóng") { editItem = nil } } }
                }
            }
            // Importer
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first {
                    do {
                        let data = try Data(contentsOf: url)
                        try store.importData(data, merge: true)
                    } catch { print("Import error:", error) }
                }
            }
            // Exporter
            .fileExporter(isPresented: $showExporter, document: exportDoc, contentType: .json, defaultFilename: "wifi.json") { _ in
                if let url = exportTempURL { try? FileManager.default.removeItem(at: url) }
                exportTempURL = nil
                exportDoc = nil
            }
            // QR Scanner
            .sheet(isPresented: $showQRScanner) {
                QRScannerView { text in
                    showQRScanner = false
                    if let parsed = WiFiQRParser.parse(text) {
                        // auto connect + save
                        connect(parsed, saveIfSuccess: true)
                    } else {
                        connectMessage = "QR không đúng chuẩn Wi-Fi."
                    }
                }
                .ignoresSafeArea()
            }
            // thông báo đơn giản
            .alert("Kết nối", isPresented: Binding(get: { connectMessage != nil }, set: { if !$0 { connectMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(connectMessage ?? "")
            }
        }
    }

    // MARK: - Actions

    private func doExport() {
        do {
            let data = try store.exportData()
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wifi-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: tmp, options: .atomic)
            exportTempURL = tmp
            exportDoc = FileDocumentURL(url: tmp)
            showExporter = true
        } catch {
            print("Export error:", error)
        }
    }

    /// Kết nối đến 1 mạng trong danh sách (không tự lưu).
    private func connect(_ item: WiFiNetwork) {
        connect(item, saveIfSuccess: false)
    }

    /// Kết nối và có thể tự lưu khi thành công (dùng cho quét QR).
    private func connect(_ item: WiFiNetwork, saveIfSuccess: Bool) {
        wifiInfo.connect(ssid: item.ssid, password: item.security == .open ? nil : item.password, security: item.security, joinOnce: false) { err in
            DispatchQueue.main.async {
                if let err = err as NSError? {
                    if err.domain == NEHotspotConfigurationError.domain,
                       err.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                        self.connectMessage = "Đã kết nối với \(item.ssid)."
                        if saveIfSuccess { self.store.add(item) }
                    } else {
                        self.connectMessage = "Kết nối thất bại: \(err.localizedDescription)"
                    }
                } else {
                    self.connectMessage = "Đã gửi yêu cầu kết nối \(item.ssid). Có thể hệ thống hiện prompt xác nhận."
                    if saveIfSuccess { self.store.add(item) }
                }
                self.wifiInfo.requestAndFetch()
            }
        }
    }
}

// MARK: - Các view con & toolbar & FileDocument giữ nguyên như bản trước

struct MainListView: View {
    let items: [WiFiNetwork]
    let onEdit: (WiFiNetwork) -> Void
    let onDeleteOffsets: (IndexSet) -> Void
    let onDeleteId: (UUID) -> Void
    let onUpdate: (WiFiNetwork) -> Void

    var body: some View {
        List {
            if items.isEmpty {
                EmptyState()
            } else {
                Section {
                    ForEach(items) { item in
                        NavigationLink {
                            WiFiDetailHost(
                                item: item,
                                onUpdate: onUpdate,
                                onDelete: { onDeleteId(item.id) },
                                onEdit: { onEdit(item) }
                            )
                        } label: { WiFiRow(item: item) }
                        .contextMenu {
                            Button("Sửa", systemImage: "pencil") { onEdit(item) }
                            Button("Xoá", systemImage: "trash", role: .destructive) {
                                onDeleteId(item.id)
                            }
                        }
                    }
                    .onDelete(perform: onDeleteOffsets)
                } header: { Text("Danh sách") }
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

struct WiFiDetailHost: View {
    let item: WiFiNetwork
    let onUpdate: (WiFiNetwork) -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    var body: some View {
        WiFiDetailView(item: item, onUpdate: onUpdate, onDelete: onDelete, onEdit: onEdit)
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

struct LeadingAppearanceToolbar: ToolbarContent {
    @Binding var appearance: AppTheme.Appearance
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Giao diện", selection: $appearance) {
                    ForEach(AppTheme.Appearance.allCases) { a in Text(a.label).tag(a) }
                }
            } label: { Image(systemName: "moon.circle") }
        }
    }
}

struct TrailingActionToolbar: ToolbarContent {
    let importTapped: () -> Void
    let exportTapped: () -> Void
    let addTapped: () -> Void
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: importTapped) { Image(systemName: "square.and.arrow.down") }
            Button(action: exportTapped) { Image(systemName: "square.and.arrow.up") }
            Button(action: addTapped) { Image(systemName: "plus.circle.fill") }
        }
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

struct WiFiDetailView: View {
    var item: WiFiNetwork
    var onUpdate: (WiFiNetwork) -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void

    @StateObject private var wifiInfo = CurrentWiFi()
    @State private var showShareSheet = false
    @State private var connectMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                QRCodeView(text: item.qrPayload, size: 240)
                    .padding(.top, 8)

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        row("SSID", item.ssid)
                        row("Mật khẩu", item.security == .open ? "(Không cần)" : item.password)
                        row("Bảo mật", item.security.rawValue)
                        if let note = item.note, !note.isEmpty { row("Ghi chú", note) }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        showShareSheet = true
                    } label: { Label("Chia sẻ QR", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.bordered)

                    Button {
                        connect(item)
                    } label: { Label("Kết nối mạng này", systemImage: "wifi") }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) { onDelete() } label: {
                        Label("Xoá", systemImage: "trash")
                    }

                    Button { onEdit() } label: { Label("Sửa", systemImage: "pencil") }
                }
            }
            .padding()
        }
        .navigationTitle(item.ssid)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [UIImage.qr(from: item.qrPayload, size: 800)])
        }
        .onAppear { wifiInfo.requestAndFetch() }
        .alert("Kết nối", isPresented: Binding(get: { connectMessage != nil }, set: { if !$0 { connectMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(connectMessage ?? "")
        }
    }

    @ViewBuilder private func row(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body)
            Divider()
        }
    }

    private func connect(_ item: WiFiNetwork) {
        wifiInfo.connect(ssid: item.ssid,
                         password: item.security == .open ? nil : item.password,
                         security: item.security,
                         joinOnce: false) { err in
            DispatchQueue.main.async {
                if let nsErr = err as NSError? {
                    if nsErr.domain == NEHotspotConfigurationErrorDomain,
                       nsErr.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                        connectMessage = "Đã kết nối với \(item.ssid)."
                    } else {
                        connectMessage = "Kết nối thất bại: \(nsErr.localizedDescription)"
                    }
                } else {
                    connectMessage = "Đã gửi yêu cầu kết nối \(item.ssid). Có thể hệ thống hiện prompt xác nhận."
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}