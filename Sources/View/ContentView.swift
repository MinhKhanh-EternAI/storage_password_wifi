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
            listContent
                .listStyle(.insetGrouped)
                .listSectionSpacingCompat(4)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { topToolbar }
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .automatic),
                            prompt: "Search")
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

    // MARK: - Subviews

    @ViewBuilder
    private var listContent: some View {
        List {
            currentNetworkSection
            savedListSection
        }
    }

    private var currentNetworkSection: some View {
        Section {
            // CARD "Mạng hiện tại"
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    if let ssid = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !ssid.isEmpty {
                        Text(ssid).font(.headline)
                        Text("Đang kết nối")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    } else {
                        Text("Không khả dụng").font(.headline)
                        Text("Vui lòng kết nối mạng")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
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
                } label: {
                    Image(systemName: "plus").font(.title3)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 10)
            // .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            HStack(spacing: 8) {
                statusDot
                Text("MẠNG HIỆN TẠI")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    refreshSSID()
                } label: {
                    Label("Làm mới", systemImage: "arrow.clockwise").font(.footnote)
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var savedListSection: some View {
        if filteredItems.isEmpty {
            Section {
                emptyState
                    .listRowBackground(Color.clear)
            } header: {
                HStack(spacing: 8) {
                    savedStatusDot            // 🔸 dùng dot riêng cho "ĐÃ LƯU"
                    Text("ĐÃ LƯU")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        } else {
            // Mỗi chữ cái là Section top-level
            ForEach(Array(groupedKeys.enumerated()), id: \.element) { index, key in
                let items = filteredItemsByKey[key] ?? []
                Section {
                    ForEach(items) { network in
                        NavigationLink {
                            WiFiDetailView(item: network).environmentObject(store)
                        } label: { row(for: network) }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { confirmDelete = network.id } label: {
                                Label("Xóa", systemImage: "trash")
                            }.tint(.red)
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        if index == 0 {
                            HStack(spacing: 8) {
                                savedStatusDot    // 🔸 chấm trạng thái cho header đầu
                                Text("ĐÃ LƯU")
                                    .textCase(.uppercase)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(key).textCase(.uppercase)
                    }
                }
            }
        }
    }

    private var savedHeader: some View {
        HStack {
            Text("ĐÃ LƯU")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 4)
    }

    // Toolbar
    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
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

        // Giữa
        ToolbarItem(placement: .principal) {
            Text("Wi-Fi")
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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

    // MARK: - Helpers (logic & small views)

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

    // Chấm trạng thái cho "MẠNG HIỆN TẠI" (xanh/đỏ)
    private var statusDot: some View {
        Circle()
            .fill(isConnected ? Color.green : Color.red)
            .frame(width: 8, height: 8)
    }

    // 🔸 Chấm trạng thái riêng cho "ĐÃ LƯU"
    // Cam nếu KHÔNG có mạng lưu, Xanh nếu có.
    private var savedStatusDot: some View {
        Circle()
            .fill(hasSavedNetworks ? Color.green : Color.orange)
            .frame(width: 8, height: 8)
    }

    private var hasSavedNetworks: Bool { !store.items.isEmpty }
}

// MARK: - Small helpers used in ContentView

private struct SecureDots: View {
    let text: String
    var body: some View {
        if text.isEmpty {
            Text("Mở")
                .foregroundStyle(.secondary)
                .font(.footnote)
        } else {
            Text(String(repeating: "●", count: max(6, text.count)))
                .foregroundStyle(.secondary)
                .font(.footnote)
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

// MARK: - Compat

extension View {
    @ViewBuilder
    func listSectionSpacingCompat(_ spacing: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            self.listSectionSpacing(spacing)   // hoặc .compact
        } else {
            self
        }
    }
}
