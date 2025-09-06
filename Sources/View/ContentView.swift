import SwiftUI
import UniformTypeIdentifiers

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "Hệ thống"
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
                // Mạng hiện tại (trên cùng)
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tên mạng")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(currentSSID ?? "Không xác định")
                                .font(.headline)
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

                // Đã lưu
                Section("Đã lưu") {
                    if filteredItems.isEmpty && searchText.isEmpty && store.items.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "wifi")
                                .font(.system(size: 36, weight: .regular))
                                .foregroundStyle(.secondary)
                            Text("Chưa có Wi-Fi nào được lưu.")
                                .foregroundStyle(.secondary)
                            Text("Nhấn dấu “+” để thêm mạng từ Wi-Fi hiện tại hoặc nhập thủ công.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredItems) { item in
                            // Tuỳ biến hàng: chỉ còn icon QR, không hiện mũi tên hệ thống
                            ZStack {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.ssid).font(.headline)
                                        Text(item.security.displayName)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "qrcode")
                                        .imageScale(.medium)
                                        .foregroundStyle(.secondary)
                                }
                                // NavigationLink ẩn để không có chevron
                                NavigationLink {
                                    WiFiDetailView(
                                        item: item,
                                        onUpdate: { store.update($0) },
                                        onDelete: { store.delete(item) }
                                    )
                                } label: { EmptyView() }
                                .opacity(0.0)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // điều hướng khi chạm
                                // (SwiftUI sẽ kích hoạt NavigationLink ẩn)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.delete(item)
                                } label: { Label("Xoá", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Wi-Fi")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Tìm theo tên mạng")
            .toolbar {
                // Menu giao diện ở GÓC TRÁI
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            appearanceRaw = AppearanceMode.system.rawValue
                        } label: { Label("Hệ thống", systemImage: "circle.dashed") }

                        Button {
                            appearanceRaw = AppearanceMode.light.rawValue
                        } label: { Label("Sáng", systemImage: "sun.max") }

                        Button {
                            appearanceRaw = AppearanceMode.dark.rawValue
                        } label: { Label("Tối", systemImage: "moon") }
                    } label: {
                        Image(systemName: "paintpalette")
                    }
                }

                // Nút thêm ở GÓC PHẢI
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: { Image(systemName: "plus") }
                }
            }
        }
        .preferredColorScheme(appearance.scheme)
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                WiFiFormView(
                    mode: .add,
                    item: WiFiNetwork(
                        ssid: currentSSID ?? "",
                        password: nil,
                        security: .wpa2Wpa3,
                        addressPrivacy: .off
                    )
                ) { newItem in
                    store.upsert(newItem)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            currentSSID = await CurrentWiFi.currentSSID()
        }
    }
}
