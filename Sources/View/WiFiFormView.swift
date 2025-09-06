import SwiftUI

struct WiFiFormView: View {
    enum Mode { case create, edit }
    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WiFiStore

    @State var item: WiFiNetwork

    var body: some View {
        Form {
            // THÔNG TIN
            Section {
                // TÊN
                LabeledContent {
                    TextField(
                        "",                       // không title để placeholder hiển thị
                        text: $item.ssid,
                        prompt: Text("Tên mạng")  // ⚠️ bỏ foregroundStyle để hợp iOS 16
                    )
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                } label: {
                    Text("Tên").foregroundStyle(.primary)
                }

                // MẬT KHẨU
                LabeledContent {
                    SecureField(
                        "",
                        text: passwordBinding,
                        prompt: Text("Mật khẩu")  // ⚠️ bỏ foregroundStyle để hợp iOS 16
                    )
                } label: {
                    Text("Mật khẩu").foregroundStyle(.primary)
                }
            } header: {
                Text("THÔNG TIN")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // BẢO MẬT
            Section {
                NavigationLink {
                    SecurityPickerView(
                        security: $item.security,
                        privacy: $item.macPrivacy   // dùng đúng field trong model
                    )
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("BẢO MẬT")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
                Button("Lưu") { save() }.fontWeight(.bold)
            }
        }
    }

    // MARK: - Helpers

    private var passwordBinding: Binding<String> {
        Binding<String>(
            get: { item.password ?? "" },
            set: { item.password = $0.isEmpty ? nil : $0 }
        )
    }

    private func save() {
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
