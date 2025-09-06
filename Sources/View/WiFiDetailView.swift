import SwiftUI

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false
    @State private var copied = false

    var body: some View {
        List {
            Section("THÔNG TIN") {
                TextField("Tên", text: $item.ssid)
                HStack {
                    SecureField("Mật khẩu", text: Binding(
                        get: { item.password ?? "" },
                        set: { item.password = $0.isEmpty ? nil : $0 }
                    ))
                    if let pwd = item.password, !pwd.isEmpty {
                        Button("Sao chép") {
                            UIPasteboard.general.string = pwd
                            copied = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Section("BẢO MẬT") {
                NavigationLink {
                    SecurityPickerView(security: $item.security)
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("MÃ QR") {
                QRCodeView(text: item.wifiQRString)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
            }

            Section {
                Button {
                    store.upsert(item)
                } label: {
                    Text("Lưu thông tin")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle(item.ssid)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Chia sẻ QR qua file PNG tạm
                    if let url = QRExport(imageText: item.wifiQRString)
                        .makeTempFile(named: "WiFi-QR-\(item.ssid).png") {
                        ShareLink(item: url) {
                            Label("Chia sẻ QR", systemImage: "square.and.arrow.up")
                        }
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Bạn có chắc chắn muốn xóa?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                store.delete(item.id)
                dismiss()
            }
        }
        .toast(isPresented: $copied, text: "Đã sao chép mật khẩu")
    }
}
