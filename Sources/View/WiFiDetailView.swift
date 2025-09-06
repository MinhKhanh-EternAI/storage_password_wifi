import SwiftUI

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false
    @State private var copied = false

    var body: some View {
        List {
            // === THÔNG TIN ===
            Section {
                let labelWidth: CGFloat = 92    // chỉnh con số này để “khoảng cách khung đỏ”

                // TÊN
                HStack(spacing: 12) {
                    Text("Tên")
                        .foregroundColor(.primary)
                        .frame(width: labelWidth, alignment: .leading)

                    TextField("", text: $item.ssid, prompt: Text("Tên mạng"))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textFieldStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 4)
                }
                .padding(.vertical, 4)

                // MẬT KHẨU
                HStack(spacing: 12) {
                    Text("Mật khẩu")
                        .foregroundColor(.primary)
                        .frame(width: labelWidth, alignment: .leading)

                    SecureField(
                        "",
                        text: Binding(
                            get: { item.password ?? "" },
                            set: { item.password = $0.isEmpty ? nil : $0 }
                        ),
                        prompt: Text("Mật khẩu")
                    )
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)

                    if let pwd = item.password, !pwd.isEmpty {
                        Button("Sao chép") {
                            UIPasteboard.general.string = pwd
                            copied = true
                        }
                        .buttonStyle(.bordered)   // giống pill xám ở mock
                    }
                }
                .padding(.vertical, 4)

            } header: {
                Text("THÔNG TIN")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            // === BẢO MẬT ===
            Section {
                NavigationLink {
                    SecurityPickerView(
                        security: $item.security,
                        privacy: $item.macPrivacy
                    )
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("BẢO MẬT")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            // === MÃ QR ===
            Section {
                HStack {
                    Spacer()
                    QRCodeView(text: item.wifiQRString)
                        .frame(width: 260, height: 260)   // nhỏ hơn một chút, căn giữa
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
            } header: {
                Text("MÃ QR")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            // === LƯU ===
            Section {
                Button {
                    store.upsert(item)
                } label: {
                    Text("Lưu thông tin")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)  // nút xanh nổi bật như mock
                .controlSize(.large)
            }
        }
        .navigationTitle(item.ssid)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Chia sẻ QR
                    if let url = QRExport(imageText: item.wifiQRString)
                        .makeTempFile(named: "WiFi-QR-\(item.ssid).png") {
                        ShareLink(item: url) {
                            Label("Chia sẻ QR", systemImage: "square.and.arrow.up")
                        }
                    }
                    // Xoá
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
