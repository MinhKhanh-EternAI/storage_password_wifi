import SwiftUI

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false
    @State private var copied = false
    @State private var revealPassword = false

    var body: some View {
        List {
            infoSection
            securitySection
            qrSection
            saveSection
        }
        .navigationTitle(item.ssid.isEmpty ? "Wi-Fi" : item.ssid)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { topMenu }
        .alert("Bạn có chắc chắn muốn xóa?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                store.delete(item.id)
                dismiss()
            }
        }
        .toast(isPresented: $copied, text: "Đã sao chép mật khẩu")
    }

    // MARK: - Sections

    private var infoSection: some View {
        Section {
            let labelWidth: CGFloat = 92

            // TÊN
            HStack(spacing: 12) {
                Text("Tên")
                    .foregroundColor(.primary)
                    .frame(width: labelWidth, alignment: .leading)

                TextField(
                    "",
                    text: $item.ssid,
                    prompt: Text("Tên mạng")
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)
            }
            .padding(.vertical, 2)

            // MẬT KHẨU
            HStack(spacing: 12) {
                Text("Mật khẩu")
                    .foregroundColor(.primary)
                    .frame(width: labelWidth, alignment: .leading)

                ZStack(alignment: .trailing) {
                    Group {
                        if revealPassword {
                            TextField(
                                "",
                                text: passwordBinding,
                                prompt: Text("Mật khẩu")
                            )
                        } else {
                            SecureField(
                                "",
                                text: passwordBinding,
                                prompt: Text("Mật khẩu")
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    // Chạm vào vùng nhập để hiện/ẩn
                    .contentShape(Rectangle())
                    .onTapGesture { revealPassword.toggle() }
                    // Long-press để copy nhanh
                    .onLongPressGesture {
                        let pwd = (item.password ?? "")
                        if !pwd.isEmpty {
                            UIPasteboard.general.string = pwd
                            copied = true
                        }
                    }

                    HStack(spacing: 8) {
                        // Nút hiện/ẩn mắt
                        Button {
                            revealPassword.toggle()
                        } label: {
                            Image(systemName: revealPassword ? "eye.slash" : "eye")
                                .imageScale(.medium)
                        }

                        // Nút Sao chép (chỉ hiện khi có mật khẩu)
                        if let pwd = item.password, !pwd.isEmpty {
                            Button("Sao chép") {
                                UIPasteboard.general.string = pwd
                                copied = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(.vertical, 2)

        } header: {
            Text("THÔNG TIN")
                .textCase(.uppercase)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var securitySection: some View {
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
    }

    private var qrSection: some View {
        Section {
            // QR gọn và cân đối
            VStack {
                let size = min(UIScreen.main.bounds.width - 64, 300)
                QRCodeView(text: item.wifiQRString)
                    .frame(width: size, height: size)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        } header: {
            Text("MÃ QR")
                .textCase(.uppercase)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                store.upsert(item)
            } label: {
                Text("Lưu thông tin")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Toolbar

    private var topMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                // Chia sẻ ảnh QR
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

    // MARK: - Bindings

    private var passwordBinding: Binding<String> {
        Binding(
            get: { item.password ?? "" },
            set: { item.password = $0.isEmpty ? nil : $0 }
        )
    }
}
