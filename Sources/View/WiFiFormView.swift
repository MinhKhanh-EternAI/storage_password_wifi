import SwiftUI

struct WiFiFormView: View {
    enum Mode { case create, edit }
    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WiFiStore

    @State var item: WiFiNetwork
    @State private var showNameAlert = false

    var body: some View {
        Form {
            // THÔNG TIN
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

                    SecureField(
                        "",
                        text: passwordBinding,
                        prompt: Text("Mật khẩu")
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                }
                .padding(.vertical, 2)

            } header: {
                Text("THÔNG TIN")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            // BẢO MẬT
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
                        Text(displaySecurityText)   // hiển thị "Không có" khi không có mật khẩu
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Hủy") { dismiss() }
            }
            ToolbarItem(placement: .principal) {
                Text(mode == .create ? "Thêm Wi-Fi" : "Sửa Wi-Fi")
                    .font(.system(size: 18, weight: .bold))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Lưu") { save() }
                    .fontWeight(.bold)
                    .disabled(!isSSIDValid) // chặn lưu khi chưa nhập tên
            }
        }
        .alert("Vui lòng nhập tên Wi-Fi", isPresented: $showNameAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Helpers

    private var isSSIDValid: Bool {
        !item.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Khi không có mật khẩu, hiển thị "Không có" cho phần Bảo mật
    private var displaySecurityText: String {
        let pwd = (item.password ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return pwd.isEmpty ? SecurityType.none.rawValue : item.security.rawValue
    }

    private var passwordBinding: Binding<String> {
        Binding<String>(
            get: { item.password ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                item.password = trimmed.isEmpty ? nil : newValue
                // Nếu không có mật khẩu -> tự động chuyển bảo mật về "Không có"
                if trimmed.isEmpty {
                    item.security = .none
                }
                // Nếu có mật khẩu, giữ nguyên lựa chọn bảo mật hiện tại của người dùng
            }
        )
    }

    private func save() {
        // Bắt buộc nhập tên
        guard isSSIDValid else {
            showNameAlert = true
            return
        }
        // Nếu không có mật khẩu -> set bảo mật = Không có (đảm bảo lần cuối trước khi lưu)
        let pwdEmpty = (item.password ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if pwdEmpty { item.security = .none }

        switch mode {
        case .create:
            store.items.append(item)
            store.sortInPlace()
        case .edit:
            if let i = store.items.firstIndex(where: { $0.id == item.id }) {
                store.items[i] = item
                store.sortInPlace()
            }
        }
        dismiss()
    }
}
