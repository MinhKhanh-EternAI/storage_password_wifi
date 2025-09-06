import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: Env & State
    @EnvironmentObject var store: WiFiStore
    @EnvironmentObject var theme: ThemeManager

    @State private var showingAdd = false
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDoc = WiFiJSONDocument(networks: [])
    @State private var searchText = ""
    @State private var confirmDelete: UUID?

    private let currentWiFi = CurrentWiFi()

    // Layout constants
    private let cellLeading: CGFloat = 16          // lề trái mặc định của .insetGrouped
    private let statusDotSize: CGFloat = 6         // chấm trạng thái nhỏ

    // MARK: Body
    var body: some View {
        NavigationStack {
            listContent
                .listStyle(.insetGrouped)
                .listSectionSpacingCompat(6)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { topToolbar }
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .automatic),
                            prompt: "Search")
                .onAppear { refreshSSID() }
                .alert("Bạn có chắc chắn muốn xóa?", isPresented: Binding(get: {
                    confirmDelete != nil
                }, set: { v in if !v { confirmDelete = nil } })) {
                    Button("Hủy", role: .cancel) {}
                    Button("Chắc chắn", role: .destructive) {
                        if let id = confirmDelete { store.delete(id) }
                    }
                }
        }
        // Export
        .fileExporter(isPresented: $showingExporter,
                      document: exportDoc,
                      contentType: .json,
                      defaultFilename: "wifi_networks.json",
                      onCompletion: { _ in })
        // Import
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
    }

    // MARK: - List
    @ViewBuilder
    private var listContent: some View {
        List {
            currentNetworkSection
            savedListSection
        }
    }

    // MARK: - Current network
    private var currentNetworkSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if isConnected {
                        Text(store.currentSSID!.trimmingCharacters(in: .whitespacesAndNewlines))
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
                Button {
                    if isConnected {
                        pathToForm(with: WiFiNetwork(
                            ssid: store.currentSSID!.trimmingCharacters(in: .whitespacesAndNewlines),
                            password: nil))
                    } else {
                        pathToForm(with: newItem())
                    }
                } label: {
                    Image(systemName: "plus").font(.title3)
                }
                .buttonStyle(.borderless)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            // Cùng lề trái với list
            .listRowInsets(EdgeInsets(top: 0, leading: cellLeading, bottom: 0, trailing: cellLeading))
            .listRowSeparator(.hidden)
        } header: {
            HStack(spacing: 8) {
                Circle()
                    .fill(isConnected ? .green : .red)
                    .frame(width: statusDotSize, height: statusDotSize)
                Text("MẠNG HIỆN TẠI")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Button(action: refreshSSID) {
                    Label("Làm mới", systemImage: "arrow.clockwise")
                        .font(.footnote)
                }
                .buttonStyle(.borderless)
            }
            // Header cùng mép trái với cell & các letter A/B/…
            .padding(.leading, cellLeading)
            .padding(.top, 4)
        }
    }

    // MARK: - Saved list
    private var savedListSection: some View {
        if filteredItems.isEmpty {
            Section {
                emptyState
                    .listRowBackground(Color.clear)
            } header: {
                HStack(spacing: 8) {
                    savedStatusDot
                    Text("ĐÃ LƯU")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.leading, cellLeading)   // đồng bộ lề trái
                .padding(.top, 4)
            }
        } else {
            // Header "ĐÃ LƯU" (1 lần)
            Section { } header: {
                HStack(spacing: 8) {
                    savedStatusDot
                    Text("ĐÃ LƯU")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.leading, cellLeading)   // đồng bộ lề trái
                .padding(.top, 4)
            }

            // Các nhóm A, B, C…
            ForEach(groupedKeys, id: \.self) { key in
                Section {
                    ForEach(filteredItemsByKey[key] ?? []) { network in
                        NavigationLink {
                            WiFiDetailView(item: network)
                                .environmentObject(store)
                        } label: {
                            row(for: network)
                        }
                        // card cùng lề trái với current card
                        .listRowInsets(EdgeInsets(top: 0, leading: cellLeading, bottom: 0, trailing: cellLeading))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                confirmDelete = network.id
                            } label: { Label("Xóa", systemImage: "trash") }
                            .tint(.red)
                        }
                    }
                } header: {
                    Text(key)
                        .textCase(.uppercase)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, cellLeading) // đồng bộ lề trái
                        .padding(.top, 2)
                }
            }
        }
    }

    private var savedStatusDot: some View {
        Circle()
            .fill(hasSavedNetworks ? .green : .red) // có mạng đã lưu → xanh
            .frame(width: statusDotSize, height: statusDotSize)
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Giao diện", selection: $theme.mode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            } label: {
                Image(systemName: theme.mode == .dark ? "moon.fill"
                                 : theme.mode == .light ? "sun.max.fill"
                                 : "circle.lefthalf.filled")
            }
        }

        ToolbarItem(placement: .principal) {
            Text("Wi-Fi")
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }

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

    // MARK: - Helpers
    private func pathToForm(with item: WiFiNetwork) {
        showingAdd = true
        let view = WiFiFormView(mode: .create, item: item).environmentObject(store)
        let hosting = UIHostingController(rootView: NavigationStack { view })
        UIApplication.shared.windows.first?.rootViewController?.present(hosting, animated: true)
    }

    private var filteredItems: [WiFiNetwork] {
        let base = store.items
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return base }
        return base.filter { $0.ssid.localizedCaseInsensitiveContains(q) }
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
            DispatchQueue.main.async { store.currentSSID = ssid }
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

    private var isConnected: Bool {
        if let s = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !s.isEmpty { return true }
        return false
    }

    private var hasSavedNetworks: Bool { !store.items.isEmpty }
}

// MARK: - Small views
private struct SecureDots: View {
    let text: String
    var body: some View {
        if text.isEmpty {
            Text("Mở")
                .foregroundStyle(.secondary)
                .font(.footnote)
        } else {
            Text(String(repeating: "•", count: max(6, text.count)))
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
    }
}

// MARK: - Helpers
private extension String {
    var firstGroupKey: String {
        guard let first = trimmingCharacters(in: .whitespacesAndNewlines).first else { return "#" }
        let s = String(first).folding(options: .diacriticInsensitive, locale: .current)
        let u = s.uppercased()
        if u.range(of: "[A-Z0-9]", options: .regularExpression) != nil { return u }
        return "#"
    }
}

extension View {
    @ViewBuilder
    func listSectionSpacingCompat(_ spacing: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            self.listSectionSpacing(spacing) // 6pt gần giống .compact
        } else {
            self
        }
    }
}
