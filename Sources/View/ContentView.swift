import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore
    @EnvironmentObject var theme: ThemeManager

    @State private var showingAdd = false
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDoc = WiFiJSONDocument(networks: [])
    @State private var searchText = ""
    @State private var confirmDelete: UUID?
    private let currentWiFi = CurrentWiFi()

    var body: some View {
        NavigationStack {
            List {
                // Current network card
                Section {
                    // --- NỘI DUNG THẺ "MẠNG HIỆN TẠI" ---
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if let ssid = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines),
                            !ssid.isEmpty {
                                Text(ssid)
                                    .font(.headline)
                                Text("Đang kết nối")
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                            } else {
                                Text("Không khả dụng")
                                    .font(.headline)
                                Text("Vui lòng kết nối mạng")
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                        // Giữ nút "+" trong card như cũ
                        Button {
                            if let ssid = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines),
                            !ssid.isEmpty {
                                pathToForm(with: WiFiNetwork(ssid: ssid, password: nil))
                            } else {
                                pathToForm(with: newItem())
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                }
                header: {
                    // --- HEADER TUỲ BIẾN: TIÊU ĐỀ + LÀM MỚI ---
                    HStack {
                        Text("MẠNG HIỆN TẠI")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)     // (tuỳ chọn) giữ kiểu chữ giống hệ thống
                        Spacer()
                        Button {
                            refreshSSID()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text("Làm mới")
                            }
                            .font(.footnote)
                        }
                        .buttonStyle(.borderless)     // giúp button trong header List bấm mượt
                    }
                    .padding(.top, 4)                  // canh nhẹ cho đẹp
                }

                // Saved list
                Section(header: Text("ĐÃ LƯU")) {
                    if filteredItems.isEmpty {
                        emptyState
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(groupedKeys, id: \.self) { key in
                            Section(key) {
                                ForEach(filteredItemsByKey[key] ?? []) { network in
                                    NavigationLink {
                                        WiFiDetailView(item: network)
                                            .environmentObject(store)
                                    } label: {
                                        row(for: network)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            confirmDelete = network.id
                                        } label: {
                                            Label("Xóa", systemImage: "trash")
                                        }
                                        .tint(.red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Trái
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Giao diện", selection: $theme.mode) {
                            ForEach(ThemeMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                    } label: {
                        Image(systemName: theme.mode == .dark ? "moon.fill" :
                                            theme.mode == .light ? "sun.max.fill" :
                                            "circle.lefthalf.filled")
                    }
                }

                // GIỮA (tiêu đề)
                ToolbarItem(placement: .principal) {
                    Text("Wi-Fi")
                        .font(.system(size: 22, weight: .bold)) // tăng size (20–24 là đẹp)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)                 // co lại chút nếu màn nhỏ
                }

                // Phải
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { pathToForm(with: newItem()) } label: {
                        Image(systemName: "plus")
                    }
                    Menu {
                        Button { prepareExport(); showingExporter = true } label: {
                            Label("Xuất dữ liệu", systemImage: "square.and.arrow.up")
                        }
                        Button { showingImporter = true } label: {
                            Label("Nhập dữ liệu", systemImage: "tray.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search")
            .onAppear { refreshSSID() }
            .alert("Bạn có chắc chắn muốn xóa?", isPresented: Binding(get: {
                confirmDelete != nil
            }, set: { v in
                if !v { confirmDelete = nil }
            })) {
                Button("Hủy", role: .cancel) {}
                Button("Chắc chắn", role: .destructive) {
                    if let id = confirmDelete { store.delete(id) }
                }
            }
        }
        // Export
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDoc,
            contentType: .json,
            defaultFilename: "wifi_networks.json",
            onCompletion: { _ in }
        )
        // Import
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
    }

    // MARK: - Helpers

    private func pathToForm(with item: WiFiNetwork) {
        showingAdd = true
        // Present inline (sheet with NavigationStack)
        // but to keep code simple, present immediately:
        let view = WiFiFormView(mode: .create, item: item).environmentObject(store)
        let hosting = UIHostingController(rootView: NavigationStack { view })
        UIApplication.shared.windows.first?.rootViewController?.present(hosting, animated: true)
    }

    private var filteredItems: [WiFiNetwork] {
        let base = store.items
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        return base.filter { $0.ssid.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredItemsByKey: [String: [WiFiNetwork]] {
        Dictionary(grouping: filteredItems, by: { $0.ssid.firstGroupKey })
            .mapValues { $0.sorted { $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending } }
    }

    private var groupedKeys: [String] {
        filteredItemsByKey.keys.sorted()
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
            Text("Chưa có mạng nào được lưu")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
    }

    private func row(for item: WiFiNetwork) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ssid)
                    .font(.headline)
                HStack(spacing: 8) {
                    SecureDots(text: item.password ?? "")
                    Text("•")
                    Text(item.security.rawValue)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            Spacer()
            Image(systemName: "qrcode")
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func newItem() -> WiFiNetwork {
        WiFiNetwork(ssid: "", password: nil)
    }

    private func refreshSSID() {
        currentWiFi.fetchSSID { ssid in
            store.currentSSID = ssid
        }
    }

    private func prepareExport() {
        exportDoc = WiFiJSONDocument(networks: store.items)
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            var map = Dictionary(uniqueKeysWithValues: store.items.map { ($0.id, $0) })
            for n in imported { map[n.id] = n }
            store.items = Array(map.values)
            store.sortInPlace()
        } catch {
            print("Import failed: \(error)")
        }
    }
}

// MARK: - Small helpers

private struct SecureDots: View {
    let text: String
    var body: some View {
        if text.isEmpty {
            Text("Mở")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        } else {
            Text(String(repeating: "•", count: max(6, text.count)))
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}

private extension String {
    var firstGroupKey: String {
        guard let first = trimmingCharacters(in: .whitespacesAndNewlines).first else { return "#" }
        let s = String(first).folding(options: .diacriticInsensitive, locale: .current)
        let u = s.uppercased()
        if u.range(of: "[A-Z0-9]", options: .regularExpression) != nil {
            return u
        }
        return "#"
    }
}
