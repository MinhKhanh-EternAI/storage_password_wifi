import SwiftUI

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false
    @State private var copied = false
    @State private var savedToast = false

    // soạn thảo mật khẩu (chặn space khi gõ)
    @State private var pwDraft: String = ""
    @FocusState private var focusPassword: Bool

    var body: some View {
        List {
            infoSection
            securitySection
            qrSection
        }
        .onAppear { pwDraft = item.password ?? "" }
        .scrollDismissesKeyboard(.immediately)               // scroll là ẩn phím
        .simultaneousGesture(TapGesture().onEnded {          // tap ra ngoài là ẩn phím
            focusPassword = false
        })
        .navigationTitle(item.ssid.isEmpty ? "Wi-Fi" : item.ssid)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Nút “Trở về”
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Trở về")
                    }
                }
            }
            topMenu
        }
        .alert("Bạn có chắc chắn muốn xóa?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                store.delete(item.id); dismiss()
            }
        }
        // Toasts
        .toast(isPresented: $copied, text: "Đã sao chép mật khẩu")
        .toast(isPresented: $savedToast, text: "Đã lưu thành công")
        // Nút Lưu cố định dưới
        .safeAreaInset(edge: .bottom) {
            Button {
                focusPassword = false                      // ẩn bàn phím
                if (item.password ?? "").isEmpty { item.security = .none }
                store.upsert(item)
                savedToast = true
            } label: {
                Text("Lưu thông tin")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
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

                TextField("", text: $item.ssid, prompt: Text("Tên mạng"))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
            .padding(.vertical, 2)

            // MẬT KHẨU – có icon copy bên phải, không bị chữ đè lên
            HStack(spacing: 12) {
                Text("Mật khẩu")
                    .foregroundColor(.primary)
                    .frame(width: labelWidth, alignment: .leading)

                ZStack(alignment: .trailing) {
                    if focusPassword {
                        // TextField khi đang chỉnh sửa
                        TextField("", text: $pwDraft, prompt: Text("Mật khẩu"))
                            .focused($focusPassword)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .textContentType(.password)
                            .keyboardType(.asciiCapable)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 2)
                            .padding(.trailing, 36) // chừa chỗ cho icon
                            .submitLabel(.done)
                            .onSubmit { focusPassword = false }
                            // chặn space khi gõ
                            .onChange(of: pwDraft) { newVal in
                                let cleaned = newVal.filter { !$0.isWhitespace }
                                if cleaned != newVal { pwDraft = cleaned }
                                item.password = cleaned.isEmpty ? nil : cleaned
                            }
                    } else {
                        // Dạng hiển thị rút gọn (không focus)
                        Text(truncated(pwDraft))
                            .foregroundColor(pwDraft.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 2)
                            .padding(.trailing, 36)
                            .contentShape(Rectangle())
                            .onTapGesture { focusPassword = true }
                    }

                    // Icon copy
                    Button {
                        let pwd = item.password ?? ""
                        if !pwd.isEmpty {
                            UIPasteboard.general.string = pwd
                            copied = true
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
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
                SecurityPickerView(security: $item.security, privacy: $item.macPrivacy)
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
            // giữ kích thước – KHÔNG viền trong
            let maxW = UIScreen.main.bounds.width
            let size = min(maxW - 56, 320)

            VStack {
                QRCodeView(text: item.wifiQRString)
                    .frame(width: size, height: size)
                    .padding(14)
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

    // MARK: - Toolbar (More)

    private var topMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
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

    // MARK: - Helpers

    private func truncated(_ s: String) -> String {
        guard !s.isEmpty else { return "Mật khẩu" } // giống placeholder khi rỗng
        if s.count > 20 {
            let end = s.index(s.startIndex, offsetBy: 17)
            return String(s[..<end]) + "..."
        }
        return s
    }
}
