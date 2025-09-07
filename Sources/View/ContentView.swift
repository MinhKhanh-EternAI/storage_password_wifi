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

    @State private var selecting = false
    @State private var selectedIDs = Set<UUID>()

    // ✓ Nới lỏng loại tệp: thêm public.data để tránh “chọn được nhưng không mở”
    private let importerTypes: [UTType] = {
        var types: [UTType] = []
        if let json = UTType(filenameExtension: "json") { types.append(json) }
        if let js   = UTType(filenameExtension: "js")   { types.append(js) }
        if let mjs  = UTType(filenameExtension: "mjs")  { types.append(mjs) }
        if let cjs  = UTType(filenameExtension: "cjs")  { types.append(cjs) }
        if let txt  = UTType(filenameExtension: "txt")  { types.append(txt) }
        if let data = UTType(importedAs: "public.data") { types.append(data) } // fallback
        return types
    }()

    var body: some View {
        NavigationStack {
            listContent
                .listStyle(.insetGrouped)
                .listSectionSpacingCompat(4)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { topToolbar }
                // ✓ Search luôn cố định khi cuộn
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .always),
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
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDoc,
            contentType: .json,
            defaultFilename: "wifi_networks.json",
            onCompletion: { _ in }
        )
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: importerTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        // Thanh hành động khi đang chọn nhiều — chỉ có nút XÓA màu đỏ
        .safeAreaInset(edge: .bottom) {
            if selecting {
                Button(role: .destructive) {
                    deleteSelected()
                } label: {
                    Text(selectedIDs.isEmpty ? "Xóa" : "Xóa (\(selectedIDs.count))")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
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
                        pathToForm(with: WiFiNetwork(ssid: ssid, password: nil, security: .wpa2wpa3))
                    } else {
                        pathToForm(with: newItem())
                    }
                } label: {
                    Image(systemName: "plus").font(.title3)
                }
                .buttonStyle(.borderless)
                .disabled(selecting)
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
                .disabled(selecting)
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
            ForEach(Array(groupedKeys.enumerated()), id: \.element) { index, key in
                let items = filteredItemsByKey[key] ?? []
                Section {
                    ForEach(items) { network in
                        if selecting {
                            Button {
                                toggleSelect(network.id)
                            } label: {
                                row(for: network, selecting: true, selected: selectedIDs.contains(network.id))
                            }
                            .buttonStyle(.plain)
                            .swipeActions { }
                        } else {
                            NavigationLink {
                                WiFiDetailView(item: network).environmentObject(store)
                            } label: {
                                row(for: network, selecting: false, selected: false)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { confirmDelete = network.id } label: {
                                    Label("Xóa", systemImage: "trash")
                                }.tint(.red)
                            }
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
        // Trái
        ToolbarItem(placement: .topBarLeading) {
            if selecting {
                Button("Xong") {
                    selecting = false
                    selectedIDs.removeAll()
                }
            } else {
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
            if selecting {
                Button("Hủy") {
                    selecting = false
                    selectedIDs.removeAll()
                }
            } else {
                Button { pathToForm(with: newItem()) } label: {
                    Image(systemName: "plus")
                }
                Menu {
                    Button {
                        selecting = true
                        selectedIDs.removeAll()
                    } label: {
                        Label("Chọn Wi-Fi", systemImage: "checkmark.circle")
                    }
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
    }

    // MARK: - Helpers

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

    private func row(for item: WiFiNetwork, selecting: Bool, selected: Bool) -> some View {
        HStack(spacing: 12) {
            if selecting {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected ? Color.blue : Color.secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ssid).font(.headline)
                HStack(spacing: 8) {
                    SecureDots(text: item.password ?? "")
                }
            }
            Spacer()
            if !selecting {
                Image(systemName: "qrcode")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    private func toggleSelect(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }

    private func deleteSelected() {
        guard !selectedIDs.isEmpty else { return }
        store.items.removeAll { selectedIDs.contains($0.id) }
        selectedIDs.removeAll()
        selecting = false
    }

    private func newItem() -> WiFiNetwork {
        WiFiNetwork(ssid: "", password: nil, security: .wpa2wpa3)
    }

    private func refreshSSID() {
        currentWiFi.fetchSSID { ssid in
            DispatchQueue.main.async { store.currentSSID = ssid }
        }
    }

    private func prepareExport() {
        exportDoc = WiFiJSONDocument(networks: store.items)
    }

    // MARK: - Import

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }

            do {
                let rawData = try Data(contentsOf: url)
                let ext = url.pathExtension.lowercased()

                let dataForDecode: Data
                if ["js", "txt", "mjs", "cjs"].contains(ext) {
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
                guard let list = imported, !list.isEmpty else { throw ImportError.empty }

                let sanitized: [WiFiNetwork] = list.map { n in
                    var x = n
                    if let p = x.password {
                        let cleaned = p.filter { !$0.isWhitespace }
                        x.password = cleaned.isEmpty ? nil : cleaned
                        if x.password == nil { x.security = .none }
                    }
                    return x
                }
                merge(sanitized)
                store.sortInPlace()

            } catch {
                print("Import failed:", error.localizedDescription)
            }

        case .failure(let err):
            print("Picker error:", err.localizedDescription)
        }
    }

    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first, first == "[" || first == "{" { return trimmed }
        if let s = trimmed.firstIndex(of: "["), let e = trimmed.lastIndex(of: "]"), s < e {
            return String(trimmed[s...e])
        }
        if let s = trimmed.firstIndex(of: "{"), let e = trimmed.lastIndex(of: "}"), s < e {
            return String(trimmed[s...e])
        }
        return trimmed
    }

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

    private enum ImportError: Error { case invalidEncoding, empty }

    private var isConnected: Bool {
        if let s = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !s.isEmpty { return true }
        return false
    }

    private var statusDot: some View {
        Circle().fill(isConnected ? Color.green : Color.red).frame(width: 8, height: 8)
    }
    private var savedStatusDot: some View {
        Circle().fill(hasSavedNetworks ? Color.green : Color.orange).frame(width: 8, height: 8)
    }
    private var hasSavedNetworks: Bool { !store.items.isEmpty }
}

// MARK: - Small helpers

private struct SecureDots: View {
    let text: String
    var body: some View {
        if text.isEmpty {
            Text("Không bảo mật").foregroundStyle(.secondary).font(.footnote)
        } else {
            Text(String(repeating: "•", count: max(6, text.count)))
                .foregroundStyle(.secondary).font(.title3)
        }
    }
}

private extension String {
    var firstGroupKey: String {
        guard let first = trimmingCharacters(in: .whitespacesAndNewlines).first else { return "#" }
        let s = String(first).folding(options: .diacriticInsensitive, locale: .current)
        let u = s.uppercased()
        if u.range(of: "[A-Z0-9]", options: .regularExpression) != nil { return u }
        return "#"
    }
}

// MARK: - Compat

extension View {
    @ViewBuilder
    func listSectionSpacingCompat(_ spacing: CGFloat) -> some View {
        if #available(iOS 17.0, *) { self.listSectionSpacing(spacing) } else { self }
    }
}
