import SwiftUI
import UniformTypeIdentifiers
import UIKit
import Network

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore
    @EnvironmentObject var theme: ThemeManager

    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var confirmDelete: UUID?
    private let currentWiFi = CurrentWiFi()
    private let firebase = FirebaseService()

    @State private var selecting = false
    @State private var selectedIDs = Set<UUID>()
    @State private var syncing = false

    // 🔥 Animation refresh
    @State private var isRefreshing = false

    // 🔥 Banner
    @State private var showBanner = false
    @State private var lastSuccess = false
    @State private var lastCount = 0
    @State private var lastMessage: String? = nil

    var body: some View {
        NavigationStack {
            listContent
                .listStyle(.insetGrouped)
                .listSectionSpacingCompat(4)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { topToolbar }
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: "Tìm kiếm mạng...")
                .onAppear {
                    // ❌ YÊU CẦU 1: Bỏ tự động đồng bộ
                    refreshSSID()
                }
                .alert("Bạn có chắc chắn muốn xóa?", isPresented: Binding(get: {
                    confirmDelete != nil
                }, set: { v in
                    if !v { confirmDelete = nil }
                })) {
                    Button("Hủy", role: .cancel) {}
                    Button("Xóa", role: .destructive) {
                        if let id = confirmDelete {
                            store.delete(id)
                            showBannerResult(success: true, message: "Đã xóa 1 Wi-Fi")
                        }
                    }
                }
        }
        // Việt hóa nút "Cancel" của thanh tìm kiếm
        .environment(\.locale, Locale(identifier: "vi"))
        .safeAreaInset(edge: .bottom) {
            if selecting {
                Button(role: .destructive) { deleteSelected() } label: {
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
        // 🔥 Overlay Banner (trên cùng)
        .overlay(alignment: .top) {
            if showBanner {
                BannerView(success: lastSuccess,
                           count: lastCount,
                           message: lastMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { withAnimation { showBanner = false } }
                    .gesture(DragGesture(minimumDistance: 10).onEnded { value in
                        if value.translation.height < 0 {
                            withAnimation { showBanner = false }
                        }
                    })
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showBanner = false }
                        }
                    }
                    .zIndex(999)
            }
        }
        // Nhận thông báo xóa từ WiFiDetailView (YÊU CẦU 4)
        .onReceive(NotificationCenter.default.publisher(for: .wifiDeleted)) { notif in
            let ssid = (notif.userInfo?["ssid"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let name = ssid.isEmpty ? "Wi-Fi" : ssid
            showBannerResult(success: true, message: "Đã xóa Wi-Fi: \(name)")
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
                VStack(alignment: .leading, spacing: 4) {
                    if let ssid = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines), !ssid.isEmpty {
                        Text(ssid).font(.headline)
                        Text("Đang kết nối").foregroundStyle(.secondary).font(.footnote)
                    } else {
                        Text("Không khả dụng").font(.headline)
                        Text("Vui lòng kết nối mạng").foregroundStyle(.secondary).font(.footnote)
                    }
                }
                Spacer()
                Button {
                    if let ssid = store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines), !ssid.isEmpty {
                        presentForm(item: WiFiNetwork(ssid: ssid, password: nil, security: .wpa2wpa3))
                    } else {
                        presentForm(item: newItem())
                    }
                } label: {
                    Image(systemName: "plus").font(.title3)
                }
                .buttonStyle(.borderless).disabled(selecting)
            }
        } header: {
            HStack(spacing: 8) {
                statusDot
                Text("MẠNG HIỆN TẠI").textCase(.uppercase).font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Button {
                    // YÊU CẦU 9: hiệu ứng “nảy” 0.1s
                    withAnimation(.easeInOut(duration: 0.1)) { isRefreshing = true }
                    refreshSSID()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.1)) { isRefreshing = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Làm mới")
                    }.font(.footnote).scaleEffect(isRefreshing ? 0.8 : 1.0)
                }
                .buttonStyle(.borderless).disabled(selecting)
            }.padding(.top, 4)
        }
    }

    @ViewBuilder
    private var savedListSection: some View {
        if filteredItems.isEmpty {
            Section {
                emptyState.listRowBackground(Color.clear)
            } header: {
                HStack(spacing: 4) {
                    savedStatusDot
                    Text("ĐÃ LƯU").textCase(.uppercase).font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                }.padding(.top, 4)
            }
        } else {
            ForEach(Array(groupedKeys.enumerated()), id: \.element) { index, key in
                let items = filteredItemsByKey[key] ?? []
                Section {
                    ForEach(items) { network in
                        if selecting {
                            Button { toggleSelect(network.id) } label: {
                                row(for: network, selecting: true, selected: selectedIDs.contains(network.id))
                            }.buttonStyle(.plain).swipeActions { }
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
                                Text("ĐÃ LƯU").textCase(.uppercase).font(.footnote).foregroundStyle(.secondary)
                            }.padding(.top, 4)
                        }
                        Text(key).textCase(.uppercase)
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if selecting {
                Button("Xong") { selecting = false; selectedIDs.removeAll() }
            } else {
                Menu {
                    Picker("Giao diện", selection: $theme.mode) {
                        ForEach(ThemeMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Image(systemName: theme.mode == .dark ? "moon.fill" :
                                        theme.mode == .light ? "sun.max.fill" :
                                        "circle.lefthalf.filled")
                }
            }
        }
        ToolbarItem(placement: .principal) {
            Text("Wi-Fi").font(.system(size: 18, weight: .bold))
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if selecting {
                Button("Hủy") { selecting = false; selectedIDs.removeAll() }
            } else {
                Button { presentForm(item: newItem()) } label: { Image(systemName: "plus") }
                Menu {
                    Button { selecting = true; selectedIDs.removeAll() } label: {
                        Label("Chọn Wi-Fi", systemImage: "checkmark.circle")
                    }
                    Button { performExport() } label: {
                        Label("Xuất dữ liệu", systemImage: "square.and.arrow.up")
                    }
                    Button { syncFromFirebase() } label: {
                        Label("Đồng bộ", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Button { uploadToFirebase() } label: {
                        Label("Sao lưu", systemImage: "icloud.and.arrow.up")
                    }
                } label: { Image(systemName: "ellipsis.circle") }.disabled(syncing)
            }
        }
    }

    // MARK: - Firebase actions

    /// Đồng bộ theo YÊU CẦU 1 & 5:
    /// - Fetch cloud
    /// - Merge: local THẮNG theo BSSID; thêm các BSSID mới từ cloud
    /// - Upload merged lên cloud
    /// - Cập nhật local & banner
    private func syncFromFirebase() {
        checkInternet { online in
            guard online else {
                showFailureNoInternet()
                return
            }
            syncing = true
            firebase.fetchNetworks { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let cloudItems):
                        let merged = mergeLocalAndCloud(local: store.items, cloud: cloudItems)
                        firebase.uploadNetworks(merged) { uploadResult in
                            DispatchQueue.main.async {
                                syncing = false
                                switch uploadResult {
                                case .success:
                                    store.items = merged
                                    showBannerResult(success: true, message: "Đã đồng bộ thành công", count: merged.count)
                                case .failure(let err):
                                    showBannerResult(success: false, message: err.localizedDescription)
                                }
                            }
                        }
                    case .failure(let err):
                        syncing = false
                        showBannerResult(success: false, message: err.localizedDescription)
                    }
                }
            }
        }
    }

    /// Sao lưu toàn bộ local lên cloud (YÊU CẦU 5: kiểm tra internet, banner)
    private func uploadToFirebase() {
        checkInternet { online in
            guard online else {
                showFailureNoInternet()
                return
            }
            syncing = true
            firebase.uploadNetworks(store.items) { result in
                DispatchQueue.main.async {
                    syncing = false
                    switch result {
                    case .success:
                        showBannerResult(success: true, message: "Đã sao lưu: \(store.items.count) Wi-Fi", count: store.items.count)
                    case .failure(let err):
                        showBannerResult(success: false, message: err.localizedDescription)
                    }
                }
            }
        }
    }

    private func showBannerResult(success: Bool, message: String, count: Int = 0) {
        lastSuccess = success
        lastMessage = message
        lastCount = count
        withAnimation { showBanner = true }
    }

    // MARK: - Helpers

    private func presentForm(item: WiFiNetwork) {
        showingAdd = true
        let view = WiFiFormView(mode: .create, item: item).environmentObject(store)
        let hosting = UIHostingController(rootView: NavigationStack { view })
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
           let root = scene.keyWindow?.rootViewController {
            root.present(hosting, animated: true)
        }
    }

    private var filteredItems: [WiFiNetwork] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty ? store.items : store.items.filter { $0.ssid.localizedCaseInsensitiveContains(q) }
    }

    private var filteredItemsByKey: [String: [WiFiNetwork]] {
        Dictionary(grouping: filteredItems, by: { $0.ssid.firstGroupKey })
            .mapValues { $0.sorted { $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending } }
    }

    private var groupedKeys: [String] {
        let keys = Array(filteredItemsByKey.keys)
        return keys.sorted { a, b in if a == "#" { return false }; if b == "#" { return true }; return a.localizedStandardCompare(b) == .orderedAscending }
    }

    private var emptyState: some View {
        HStack(spacing: 12) { Image(systemName: "wifi.slash"); Text("Chưa có mạng nào được lưu").foregroundStyle(.secondary) }
            .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 16)
    }

    private func row(for item: WiFiNetwork, selecting: Bool, selected: Bool) -> some View {
        HStack(spacing: 12) {
            if selecting {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle").foregroundColor(selected ? .blue : .secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ssid).font(.headline)
                SecureDots(text: item.password ?? "")
            }
            Spacer()
            if !selecting { Image(systemName: "qrcode").foregroundStyle(.secondary) }
        }.contentShape(Rectangle())
    }

    private func toggleSelect(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }

    private func deleteSelected() {
        guard !selectedIDs.isEmpty else { return }
        store.items.removeAll { selectedIDs.contains($0.id) }
        showBannerResult(success: true, message: "Đã xóa \(selectedIDs.count) Wi-Fi")
        selectedIDs.removeAll(); selecting = false
    }

    private func newItem() -> WiFiNetwork { WiFiNetwork(ssid: "", password: nil, security: .wpa2wpa3) }

    private func refreshSSID() { currentWiFi.fetchSSID { ssid in DispatchQueue.main.async { store.currentSSID = ssid } } }

    private func performExport() {
        do {
            let url = try store.exportSnapshot()
            let picker = UIDocumentPickerViewController(forExporting: [url])
            UIApplication.presentTop(picker)
            // YÊU CẦU 3: Xóa banner thông báo xuất dữ liệu (không gọi showBannerResult ở đây)
        } catch { showBannerResult(success: false, message: error.localizedDescription) }
    }

    private var isConnected: Bool { !(store.currentSSID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
    private var statusDot: some View { Circle().fill(isConnected ? .green : .red).frame(width: 8, height: 8) }
    private var savedStatusDot: some View { Circle().fill(hasSavedNetworks ? .green : .orange).frame(width: 8, height: 8) }
    private var hasSavedNetworks: Bool { !store.items.isEmpty }
}

// MARK: - Merge helpers (BSSID-based)

private func normalizeBSSID(_ bssid: String?) -> String? {
    guard let b = bssid?.trimmingCharacters(in: .whitespacesAndNewlines), !b.isEmpty else { return nil }
    return b.lowercased()
}

private func mergeLocalAndCloud(local: [WiFiNetwork], cloud: [WiFiNetwork]) -> [WiFiNetwork] {
    var merged = local
    var localByBSSID: [String: WiFiNetwork] = [:]
    for item in local {
        if let key = normalizeBSSID(item.bssid) {
            localByBSSID[key] = item
        }
    }

    for c in cloud {
        if let key = normalizeBSSID(c.bssid) {
            if localByBSSID[key] == nil {
                // BSSID chưa có ở local → thêm mới từ cloud
                merged.append(c)
            }
            // Nếu trùng BSSID: local thắng → bỏ qua c
        } else {
            // Cloud không có BSSID: tránh nhân bản vô nghĩa; chỉ thêm nếu chưa có id tương tự
            if !merged.contains(where: { $0.id == c.id }) {
                merged.append(c)
            }
        }
    }
    return merged
}

// MARK: - Network check

private func checkInternet(_ completion: @escaping (Bool) -> Void) {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "net.mon")
    monitor.pathUpdateHandler = { path in
        completion(path.status == .satisfied)
        monitor.cancel()
    }
    monitor.start(queue: queue)
}

private extension ContentView {
    func showFailureNoInternet() {
        showBannerResult(success: false, message: "Vui lòng kết nối mạng hoặc thử lại")
    }
}

// MARK: - Helpers

private struct SecureDots: View {
    let text: String
    var body: some View {
        if text.isEmpty { Text("Không bảo mật").foregroundStyle(.secondary).font(.footnote) }
        else { Text(String(repeating: "•", count: max(6, text.count))).foregroundStyle(.secondary).font(.footnote) }
    }
}

private extension String {
    var firstGroupKey: String {
        guard let first = trimmingCharacters(in: .whitespacesAndNewlines).first else { return "#" }
        let s = String(first).folding(options: .diacriticInsensitive, locale: .current)
        let u = s.uppercased()
        return u.range(of: "[A-Z0-9]", options: .regularExpression) != nil ? u : "#"
    }
}

extension View {
    @ViewBuilder func listSectionSpacingCompat(_ spacing: CGFloat) -> some View {
        if #available(iOS 17.0, *) { self.listSectionSpacing(spacing) } else { self }
    }
}

private extension UIApplication {
    static func presentTop(_ vc: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let root = scene.keyWindow?.rootViewController else { return }
        root.present(vc, animated: true)
    }
}
private extension UIWindowScene { var keyWindow: UIWindow? { windows.first { $0.isKeyWindow } } }

// Thông báo xóa để WiFiDetailView gửi, ContentView nhận (YÊU CẦU 4)
extension Notification.Name {
    static let wifiDeleted = Notification.Name("wifiDeleted")
}
