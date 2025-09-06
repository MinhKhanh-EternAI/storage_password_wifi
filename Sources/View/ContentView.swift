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
                    Button("Xóa", role: .destructive) {
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
        // Import (.json / .js / .txt) — dùng overload trả Result<[URL], Error>
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType.json, UTType.text, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
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
                VStack(alignment: .leading, spacing: 8) {
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
                    savedStatusDot
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
                                savedStatusDot
                                Text("ĐÃ LƯU")
                                    .textCase(.uppercase)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
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
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            root.present(hosting, animated: true)
        }
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

    // MARK: - Import (.json / .js / .txt)

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }

            do {
                let rawData = try Data(contentsOf: url)
                let ext = url.pathExtension.lowercased()

                // Nếu .js / .txt: lột JS wrapper để lấy JSON thuần
                let dataForDecode: Data
                if ["js", "txt"].contains(ext) {
                    guard let text = String(data: rawData, encoding: .utf8) else {
                        throw ImportError.invalidEncoding
                    }
                    let jsonString = extractJSON(from: text)
                    guard let jsonData = jsonString.data(using: .utf8) else {
                        throw ImportError.invalidEncoding
                    }
                    dataForDecode = jsonData
                } else {
                    dataForDecode = rawData
                }

                // Thử decode [WiFiNetwork] hoặc { "items": [...] }
                let decoder = JSONDecoder()
                var imported: [WiFiNetwork]?

                if let arr = try? decoder.decode([WiFiNetwork].self, from: dataForDecode) {
                    imported = arr
                } else {
                    struct Wrapper: Codable { let items: [WiFiNetwork] }
                    if let wrap = try? decoder.decode(Wrapper.self, from: dataForDecode) {
                        imported = wrap.items
                    }
                }

                guard let list = imported, !list.isEmpty else {
                    throw ImportError.empty
                }

                // Merge & sort
                merge(list)
                store.sortInPlace()

            } catch {
                print("Import failed:", error.localizedDescription)
            }

        case .failure(let err):
            print("Picker error:", err.localizedDescription)
        }
    }

    // Bóc JSON từ text có JS wrapper (const data = [...]; / export default [...])
    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first, first == "[" || first == "{" {
            return trimmed
        }
        if let s = trimmed.firstIndex(of: "["),
           let e = trimmed.lastIndex(of: "]"), s < e {
            return String(trimmed[s...e])
        }
        if let s = trimmed.firstIndex(of: "{"),
           let e = trimmed.lastIndex(of: "}"), s < e {
            return String(trimmed[s...e])
        }
        return trimmed // để lỗi decode báo ra
    }

    // Gộp: ưu tiên trùng id, nếu không có id trùng thì ghép theo ssid (normalize)
    private func merge(_ incoming: [WiFiNetwork]) {
        var indexByID: [UUID: Int] = [:]
        var indexBySSID: [String: Int] = [:]
        for (i, it) in store.items.enumerated() {
            indexByID[it.id] = i
            indexBySSID[norm(it.ssid)] = i
        }

        for nw in incoming {
            if let idx = indexByID[nw.id] {
                store.items[idx] = nw
            } else if let idx = indexBySSID[norm(nw.ssid)] {
                store.items[idx] = nw
            } else {
                store.items.append(nw)
            }
        }
    }

    private func norm(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // Hỗ trợ báo lỗi import
    private enum ImportError: Error {
        case invalidEncoding
        case empty
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

    // Chấm trạng thái riêng cho "ĐÃ LƯU"
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
            Text("Không bảo mật")
                .foregroundStyle(.secondary)
                .font(.footnote)
        } else {
            Text(String(repeating: "•", count: max(6, text.count)))
                .foregroundStyle(.secondary)
                .font(.title3)
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
