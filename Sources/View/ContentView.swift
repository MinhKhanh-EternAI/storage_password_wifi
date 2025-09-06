import SwiftUI
import UniformTypeIdentifiers

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "Theo hệ thống"
        case .light:  return "Sáng"
        case .dark:   return "Tối"
        }
    }
    var scheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct ContentView: View {
    @StateObject private var store = WiFiStore()
    @AppStorage("appearance") private var appearanceRaw: String = AppearanceMode.system.rawValue

    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var currentSSID: String? = nil

    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportURL: URL?

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var filteredItems: [WiFiNetwork] {
        let key = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return store.items }
        return store.items.filter { $0.ssid.lowercased().contains(key) }
    }

    var body: some View {
        NavigationStack {
            List {
                // ---- MẠNG HIỆN TẠI (ngay dưới ô tìm kiếm) ----
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tên mạng").font(.subheadline).foregroundStyle(.secondary)
                            Text(currentSSID ?? "Không xác định").font(.headline)
                        }
                        Spacer()
                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus.circle.fill").imageScale(.large)
                        }
                        .accessibilityLabel("Thêm mạng")
                    }
                    .padding(.vertical, 4)
                }

                // ---- DANH SÁCH ĐÃ LƯU ----
                Section("Đã lưu") {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            WiFiDetailView(item: item,
                                           onUpdate: { store.update($0) },
                                           onDelete: { store.delete(item) })
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.ssid).font(.headline)
                                    Text(item.security.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                // Icon QR nhỏ bên phải
                                Image(systemName: "qrcode")
                                    .imageScale(.medium)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.delete(item)
                            } label: { Label("Xoá", systemImage: "trash") }
                        }
                    }
                }
            }
            .navigationTitle("Wi-Fi")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Tìm theo tên mạng")
            .toolbar {
                // Nút thêm (góc phải) — thêm Wi-Fi
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: { Image(systemName: "plus") }
                }
                // Menu nhập/xuất + chế độ sáng/tối
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Nhập/Xuất
                        Button {
                            if let url = store.tempExportURL() {
                                exportURL = url
                                showExporter = true
                            }
                        } label: { Label("Xuất danh sách", systemImage: "square.and.arrow.up") }

                        Button {
                            showImporter = true
                        } label: { Label("Nhập danh sách", systemImage: "square.and.arrow.down") }

                        Divider()

                        // Chế độ giao diện
                        Picker("Giao diện", selection: $appearanceRaw) {
                            ForEach(AppearanceMode.allCases) { m in
                                Text(m.title).tag(m.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .preferredColorScheme(appearance.scheme)
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                WiFiFormView(
                    item: WiFiNetwork(ssid: "", password: nil, security: .wpa2Wpa3, addressPrivacy: .off)
                ) { newItem in
                    store.upsert(newItem)
                }
                .navigationTitle("Thêm Wi-Fi")
            }
            .presentationDetents([.medium, .large])
        }
        // Exporter (chia sẻ file JSON)
        .sheet(isPresented: $showExporter) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        // Importer (chọn file JSON)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first,
                      let data = try? Data(contentsOf: url) else { return }
                do {
                    try store.importData(data, merge: true)
                } catch {
                    print("Import error:", error)
                }
            case .failure(let err):
                print("Importer failed:", err)
            }
        }
        .task {
            currentSSID = await CurrentWiFi.currentSSID()
        }
    }
}

// MARK: - ShareSheet helper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
