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

                // MẬT KHẨU (cấm khoảng trắng)
                HStack(spacing: 12) {
                    Text("Mật khẩu")
                        .foregroundColor(.primary)
                        .frame(width: labelWidth, alignment: .leading)

                    SecureField(
                        "",
                        text: passwordBindingNoSpace,
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

            // BẢO MẬT (người dùng tự chọn; chỉ ép .none khi Lưu nếu không có mật khẩu)
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
                    .disabled(!isSSIDValid)
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

    // Cấm khoảng trắng trong mật khẩu
    private var passwordBindingNoSpace: Binding<String> {
        Binding(
            get: { item.password ?? "" },
            set: { val in
                let cleaned = val.filter { !$0.isWhitespace }
                item.password = cleaned.isEmpty ? nil : cleaned
            }
        )
    }

    private func save() {
        // Phải có tên
        guard isSSIDValid else {
            showNameAlert = true
            return
        }

        // Chỉ lúc bấm Lưu: nếu mật khẩu trống -> ép bảo mật = Không có
        let pwdEmpty = (item.password ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if pwdEmpty {
            item.security = .none
        }

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
