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
                    // CARD "Mạng hiện tại"
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if let ssid = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines),
                            !ssid.isEmpty {
                                Text(ssid).font(.headline)
                                Text("Đang kết nối").foregroundStyle(.secondary).font(.footnote)
                            } else {
                                Text("Không khả dụng").font(.headline)
                                Text("Vui lòng kết nối mạng").foregroundStyle(.secondary).font(.footnote)
                            }
                        }
                        Spacer()
                        Button {
                            if let ssid = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines),
                            !ssid.isEmpty {
                                pathToForm(with: WiFiNetwork(ssid: ssid, password: nil))
                            } else {
                                pathToForm(with: newItem())
                            }
                        } label: { Image(systemName: "plus").font(.title3) }
                        .buttonStyle(.borderless)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    HStack {
                        Text("MẠNG HIỆN TẠI")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                        Button {
                            refreshSSID()
                        } label: {
                            Label("Làm mới", systemImage: "arrow.clockwise")
                                .font(.footnote)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.top, 4)
                }

                // Saved list
                if filteredItems.isEmpty {
                    Section {
                        emptyState
                            .listRowBackground(Color.clear)
                    } header: {
                        HStack {
                            Text("ĐÃ LƯU")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                } else {
                    // Header "ĐÃ LƯU" cùng style
                    Section { } header: {
                        HStack {
                            Text("ĐÃ LƯU")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }

                    // Mỗi chữ cái là 1 Section top-level (như ảnh mẫu)
                    ForEach(groupedKeys, id: \.self) { key in
                        Section(header: Text(key).textCase(.uppercase)) {
                            ForEach(filteredItemsByKey[key] ?? []) { network in
                                NavigationLink {
                                    WiFiDetailView(item: network).environmentObject(store)
                                } label: {
                                    row(for: network)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        confirmDelete = network.id
                                    } label: { Label("Xóa", systemImage: "trash") }
                                    .tint(.red)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(8)   // hoặc .listSectionSpacing(.compact)
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
                        .font(.system(size: 18, weight: .bold))
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
        let keys = Array(filteredItemsByKey.keys)
        return keys.sorted { a, b in
            if a == "#" { return false }
            if b == "#" { return true }
            return a.localizedStandardCompare(b) == .orderedAscending
        }
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
                }
            }
            Spacer()
            Image(systemName: "qrcode")
                .foregroundStyle(.secondary)
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
