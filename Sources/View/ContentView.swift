import SwiftUI
import UniformTypeIdentifiers
import UIKit

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
    @State private var errorMessage: String?
    @State private var addedToast = false
    @State private var syncing = false   // để disable nút khi đang chạy

    var body: some View {
        NavigationStack {
            listContent
                .listStyle(.insetGrouped)
                .listSectionSpacingCompat(4)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { topToolbar }
                .searchable(text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: "Search")
                .onAppear { refreshSSID() }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("wifiDidAdd"))) { _ in
                    addedToast = true
                }
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
        .alert("Lỗi", isPresented: Binding(get: { errorMessage != nil },
                                          set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .toast(isPresented: $addedToast, text: "Đã thêm Wi-Fi")
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
                VStack(alignment: .leading, spacing: 4) {
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
                        presentForm(item: WiFiNetwork(ssid: ssid, password: nil, security: .wpa2wpa3))
                    } else {
                        presentForm(item: newItem())
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
                HStack(spacing: 4) {
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
                // PLUS TRÊN TOOLBAR: luôn mở form TRỐNG
                Button { presentForm(item: newItem()) } label: {
                    Image(systemName: "plus")
                }
                Menu {
                    Button {
                        selecting = true
                        selectedIDs.removeAll()
                    } label: {
                        Label("Chọn Wi-Fi", systemImage: "checkmark.circle")
                    }
                    Button { performExport() } label: {
                        Label("Xuất dữ liệu", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        syncFromFirebase()
                    } label: {
                        Label("Đồng bộ", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Button {
                        uploadToFirebase()
                    } label: {
                        Label("Sao lưu", systemImage: "icloud.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(syncing)
            }
        }
    }

    // MARK: - Firebase actions

    private func syncFromFirebase() {
        syncing = true
        firebase.fetchNetworks { result in
            DispatchQueue.main.async {
                syncing = false
                switch result {
                case .success(let items):
                    store.items = items
                case .failure(let err):
                    errorMessage = "Lỗi đồng bộ: \(err.localizedDescription)"
                }
            }
        }
    }

    private func uploadToFirebase() {
        syncing = true
        firebase.uploadNetworks(store.items) { result in
            DispatchQueue.main.async {
                syncing = false
                switch result {
                case .success:
                    addedToast = true
                case .failure(let err):
                    errorMessage = "Lỗi sao lưu: \(err.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Helpers

    private func presentForm(item: WiFiNetwork) {
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

    private func performExport() {
        do {
            let url = try store.exportSnapshot()
            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            UIApplication.presentTop(av)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

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
                .foregroundStyle(.secondary).font(.footnote)
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

// MARK: - UI helpers

private extension UIApplication {
    static func presentTop(_ vc: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }
        root.present(vc, animated: true)
    }
}
private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first { $0.isKeyWindow } }
}
