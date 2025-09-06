import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document cho Nhập/Xuất
struct WiFiDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var items: [WiFiNetwork]

    init(items: [WiFiNetwork]) {
        self.items = items
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.items = try JSONDecoder().decode([WiFiNetwork].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(items)
        return .init(regularFileWithContents: data)
    }
}

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @Environment(\.colorScheme) private var scheme

    // Mạng hiện tại
    @State private var currentSSID: String?
    @StateObject private var location = LocationService.shared

    // Tìm kiếm
    @State private var searchText: String = ""

    // Nhập / Xuất
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportDoc = WiFiDocument(items: [])

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Mạng hiện tại (dưới title, trên thanh tìm kiếm)
                    currentNetworkCard

                    // Thanh tìm kiếm nằm trong nội dung cuộn
                    searchField

                    // Danh sách mạng
                    savedList
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Wi-Fi")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $store.presentForm) {
                WiFiFormSheet()
                    .environmentObject(store)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ThemePickerButton() // icon mặt trời / mặt trăng
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Nút ba chấm: Nhập/Xuất
                    Menu {
                        Button("Xuất Wi-Fi") { beginExport() }
                        Button("Nhập Wi-Fi") { showImporter = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }

                    // Dấu cộng thêm mạng (prefill tên mạng hiện tại)
                    Button {
                        store.editing = WiFiNetwork(ssid: currentSSID ?? "", password: "", security: .wpa2wpa3)
                        store.presentForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .accessibilityLabel(Text("Thêm mạng"))
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: exportDoc,
                contentType: .json,
                defaultFilename: "WiFiOffline.json"
            ) { _ in }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                guard case .success(let urls) = result, let url = urls.first,
                      let data = try? Data(contentsOf: url),
                      let items = try? JSONDecoder().decode([WiFiNetwork].self, from: data) else { return }
                store.replaceAll(with: items)
            }
            .task {
                location.ensureAuthorized()
                await reloadSSID()
            }
            .onChange(of: location.status) { _ in
                Task { await reloadSSID() }
            }
        }
    }

    private var currentNetworkCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mạng hiện tại").font(.caption).foregroundStyle(.secondary)
            HStack {
                Text(currentSSID ?? "Không xác định")
                    .font(.title3).fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tìm kiếm").font(.caption).foregroundStyle(.secondary)
            TextField("Tìm theo Tên mạng…", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.09))
                )
        }
    }

    private var filteredItems: [WiFiNetwork] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return store.items }
        return store.items.filter { $0.ssid.localizedCaseInsensitiveContains(q) }
    }

    private var savedList: some View {
        VStack(alignment: .leading, spacing: 10) {
            if filteredItems.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "wifi")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Chưa có mạng đã lưu")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Bấm (＋) để thêm nhanh mạng đang kết nối hoặc nhập thủ công.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(filteredItems) { item in
                    NavigationLink {
                        WiFiDetailView(item: item)
                            .environmentObject(store)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "wifi")
                                .imageScale(.medium)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.ssid).font(.headline)
                                Text(securityText(item.security))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            // Chevron luôn hiển thị (đã “mất mũi tên” — thêm lại)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)
            }
        }
    }

    private func beginExport() {
        exportDoc = WiFiDocument(items: store.items)
        showExporter = true
    }

    private func reloadSSID() async {
        currentSSID = await CurrentWiFi.fetchSSID()
    }
}

// MARK: - Sheet Thêm/Sửa (tiêu đề đúng theo trạng thái)
private struct WiFiFormSheet: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    var isEditing: Bool { store.items.contains(where: { $0.id == store.editing?.id }) }

    var body: some View {
        NavigationStack {
            WiFiFormView(item: store.editing ?? .init(ssid: "", password: "", security: .wpa2wpa3)) { model in
                if isEditing { store.update(model) } else { store.add(model) }
                dismiss()
            }
            .navigationTitle(isEditing ? "Sửa Wi-Fi" : "Thêm mạng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

// An toàn khi enum security khác tên giữa các repo – dựa theo chuỗi mô tả
private func securityText(_ any: Any) -> String {
    let s = String(describing: any).lowercased()
    switch true {
    case s.contains("wpa3 enterprise"), s.contains("wpa3_doanh"):
        return "WPA3 Doanh nghiệp"
    case s.contains("wpa2 enterprise"), s.contains("wpa2_doanh"):
        return "WPA2 Doanh nghiệp"
    case s.contains("wpa2/wpa3"), s.contains("wpa2wpa3"):
        return "WPA2/WPA3"
    case s.contains("wpa3"):
        return "WPA3"
    case s.contains("wpa2"):
        return "WPA2"
    case s.contains("wpa"):
        return "WPA"
    case s.contains("wep"):
        return "WEP"
    case s.contains("none"), s.contains("không"), s.contains("open"):
        return "Không có"
    default:
        return "Khác"
    }
}
