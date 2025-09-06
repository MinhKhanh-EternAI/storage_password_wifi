import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore
    @EnvironmentObject var theme: AppTheme
    @State private var currentSSID: String?

    var body: some View {
        NavigationStack {
            List {
                // Mạng hiện tại
                Section {
                    HStack {
                        Text("Tên mạng")
                        Spacer()
                        Text(currentSSID ?? "Không xác định")
                            .foregroundStyle(.secondary)
                    }
                }

                // Danh sách đã lưu
                Section {
                    ForEach(store.items) { item in
                        NavigationLink(value: item) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.ssid).font(.headline)
                                    if let pwd = item.password, !pwd.isEmpty {
                                        Text("••••••••").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "qrcode")
                                    .imageScale(.medium)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { idx in
                        idx.map { store.items[$0] }.forEach(store.delete)
                    }

                    if store.items.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "wifi")
                                .font(.system(size: 40, weight: .regular))
                                .foregroundStyle(.secondary)
                            Text("Chưa có mạng nào được lưu")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Wi-Fi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Góc trái: chọn chủ đề (icon mặt trời/mặt trăng)
                ToolbarItem(placement: .topBarLeading) {
                    ThemePickerButton()
                }

                // Góc phải: dấu ba chấm (nhập/xuất) + nút thêm
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button("Xuất danh sách") { exportWiFi() }
                        Button("Nhập danh sách") { importWiFi() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Button {
                        Task {
                            let ssid = await CurrentWiFi.currentSSID()
                            store.editing = WiFiNetwork(ssid: ssid ?? "", password: nil, security: .wpa2wpa3)
                            store.presentForm = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: WiFiNetwork.self) { item in
                WiFiDetailView(item: item)
            }
            // Sheet mở form
            .sheet(isPresented: Binding(get: { store.presentForm }, set: { store.presentForm = $0 })) {
                WiFiFormView(
                    mode: (store.editing == nil) ? .create : .edit,
                    item: store.editing ?? .init(ssid: "", password: nil, security: .wpa2wpa3)
                ) { saved in
                    store.upsert(saved)
                    store.presentForm = false
                    store.editing = nil
                }
            }
            .task {
                currentSSID = await CurrentWiFi.currentSSID()
            }
        }
    }

    // MARK: - Dummy import/export placeholder
    private func exportWiFi() { /* TODO: xuất ra JSON / file */ }
    private func importWiFi() { /* TODO: đọc JSON / file */ }
}
