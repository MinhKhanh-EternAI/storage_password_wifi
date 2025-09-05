import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: WiFiStore
    @EnvironmentObject private var theme: AppTheme
    @State private var showAdd = false
    @State private var editItem: WiFiNetwork?
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportTempURL: URL?
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 48, weight: .thin))
                            Text("Chưa có Wi-Fi nào")
                                .font(.headline)
                            Text("Nhấn **Thêm** để lưu mạng Wi-Fi mới.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    Section {
                        ForEach(filtered) { item in
                            NavigationLink {
                                WiFiDetailView(item: item) { updated in
                                    store.update(updated)
                                } onDelete: {
                                    store.delete(item.id)
                                } onEdit: {
                                    editItem = item
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "wifi")
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.ssid).font(.headline)
                                        Text(item.security.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "qrcode")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .contextMenu {
                                Button("Sửa", systemImage: "pencil") { editItem = item }
                                Button("Xoá", systemImage: "trash", role: .destructive) {
                                    store.delete(item.id)
                                }
                            }
                        }
                        .onDelete(perform: store.delete)
                    } header: {
                        Text("Danh sách")
                    }
                }
            }
            .navigationTitle("Wi-Fi Offline")
            .searchable(text: $search, prompt: "Tìm SSID…")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Menu {
                        Picker("Giao diện", selection: Binding(
                            get: { theme.appearance },
                            set: { theme.appearance = $0 }
                        )) {
                            ForEach(AppTheme.Appearance.allCases) { a in
                                Text(a.label).tag(a)
                            }
                        }
                    } label: {
                        Image(systemName: "moon.circle")
                    }
                    .accessibilityLabel("Giao diện")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showImporter = true
                    } label: { Image(systemName: "square.and.arrow.down") }
                    .help("Nhập dữ liệu từ JSON")

                    Button {
                        do {
                            let data = try store.exportData()
                            let tmp = FileManager.default.temporaryDirectory
                                .appendingPathComponent("wifi-\(Int(Date().timeIntervalSince1970)).json")
                            try data.write(to: tmp, options: .atomic)
                            exportTempURL = tmp
                            showExporter = true
                        } catch { print("Export error", error) }
                    } label: { Image(systemName: "square.and.arrow.up") }
                    .help("Xuất toàn bộ Wi-Fi ra JSON")

                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Thêm Wi-Fi")
                }
            }
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    WiFiFormView(item: .init(ssid: "", password: ""))
                        .navigationTitle("Thêm Wi-Fi")
                        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Đóng") { showAdd = false } } }
                        .onSubmit { item in store.add(item); showAdd = false }
                }
            }
            .sheet(item: $editItem) { item in
                NavigationStack {
                    WiFiFormView(item: item)
                        .navigationTitle("Sửa Wi-Fi")
                        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Đóng") { editItem = nil } } }
                        .onSubmit { updated in store.update(updated); editItem = nil }
                }
            }
            // Importer
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    do {
                        let data = try Data(contentsOf: url)
                        try store.importData(data, merge: true) // merge
                    } catch { print("Import error:", error) }
                }
            }
            // Exporter
            .fileExporter(
                isPresented: $showExporter,
                document: exportTempURL.map { FileDocumentURL(url: $0) },
                contentType: .json,
                defaultFilename: "wifi.json"
            ) { result in
                if case .success = result { /* ok */ }
                if let url = exportTempURL { try? FileManager.default.removeItem(at: url) }
                exportTempURL = nil
            }
        }
    }

    private var filtered: [WiFiNetwork] {
        let s = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !s.isEmpty else { return store.items }
        return store.items.filter { $0.ssid.lowercased().contains(s) }
    }
}

/// Gói URL tạm thành FileDocument để dùng với .fileExporter
import UniformTypeIdentifiers
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
