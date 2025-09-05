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
    @State private var exportDoc: FileDocumentURL?      // tách document để compiler dễ type-check
    @State private var search = ""

    // Lọc danh sách theo từ khoá
    private var filtered: [WiFiNetwork] {
        let s = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !s.isEmpty else { return store.items }
        return store.items.filter { $0.ssid.lowercased().contains(s) }
    }

    var body: some View {
        NavigationStack {
            MainListView(
                items: filtered,
                onEdit: { editItem = $0 },
                onDeleteOffsets: { store.delete(at: $0) },
                onDeleteId: { store.delete($0) },
                onUpdate: { store.update($0) }
            )
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
            // Add
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    WiFiFormView(item: .init(ssid: "", password: ""))
                        .navigationTitle("Thêm Wi-Fi")
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) { Button("Đóng") { showAdd = false } }
                        }
                        .onSubmit { item in
                            store.add(item)
                            showAdd = false
                        }
                }
            }
            // Edit
            .sheet(item: $editItem) { item in
                NavigationStack {
                    WiFiFormView(item: item)
                        .navigationTitle("Sửa Wi-Fi")
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) { Button("Đóng") { editItem = nil } }
                        }
                        .onSubmit { updated in
                            store.update(updated)
                            editItem = nil
                        }
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
                        try store.importData(data, merge: true)
                    } catch { print("Import error:", error) }
                }
            }
            // Exporter (dùng exportDoc để giảm độ phức tạp biểu thức)
            .fileExporter(
                isPresented: $showExporter,
                document: exportDoc,
                contentType: .json,
                defaultFilename: "wifi.json"
            ) { result in
                if case .success = result { /* ok */ }
                if let url = exportTempURL { try? FileManager.default.removeItem(at: url) }
                exportTempURL = nil
                exportDoc = nil
            }
        }
    }

    // MARK: - Actions

    private func doExport() {
        do {
            let data = try store.exportData()
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("wifi-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: tmp, options: .atomic)
            exportTempURL = tmp
            exportDoc = FileDocumentURL(url: tmp)
            showExporter = true
        } catch {
            print("Export error:", error)
        }
    }
}

#pragma mark - Subviews (tách nhỏ để giảm tải type-check)

/// Danh sách chính (đã bóc tách khỏi ContentView)
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
                        } label: {
                            WiFiRow(item: item)
                        }
                        .contextMenu {
                            Button("Sửa", systemImage: "pencil") { onEdit(item) }
                            Button("Xoá", systemImage: "trash", role: .destructive) {
                                onDeleteId(item.id)
                            }
                        }
                    }
                    .onDelete(perform: onDeleteOffsets)
                } header: {
                    Text("Danh sách")
                }
            }
        }
    }
}

/// Hàng hiển thị 1 wifi
struct WiFiRow: View {
    let item: WiFiNetwork
    var body: some View {
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
}

/// Màn hình chi tiết bọc lại để làm đích của NavigationLink (nhẹ hơn cho type-check)
struct WiFiDetailHost: View {
    let item: WiFiNetwork
    let onUpdate: (WiFiNetwork) -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    var body: some View {
        WiFiDetailView(item: item, onUpdate: onUpdate, onDelete: onDelete, onEdit: onEdit)
    }
}

/// Empty state
struct EmptyState: View {
    var body: some View {
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
    }
}

#pragma mark - Toolbars (đóng gói thành ToolbarContent)

struct LeadingAppearanceToolbar: ToolbarContent {
    @Binding var appearance: AppTheme.Appearance
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Giao diện", selection: $appearance) {
                    ForEach(AppTheme.Appearance.allCases) { a in
                        Text(a.label).tag(a)
                    }
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
                .help("Nhập dữ liệu từ JSON")
            Button(action: exportTapped) { Image(systemName: "square.and.arrow.up") }
                .help("Xuất toàn bộ Wi-Fi ra JSON")
            Button(action: addTapped) { Image(systemName: "plus.circle.fill") }
                .accessibilityLabel("Thêm Wi-Fi")
        }
    }
}

#pragma mark - FileDocument wrapper

/// Gói URL tạm thành FileDocument để dùng với .fileExporter
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
