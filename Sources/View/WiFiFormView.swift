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
                // Nhãn bên trái (đen), trường nhập bên phải (placeholder xám)
                LabeledContent {
                    TextField("", text: $item.ssid,
                              prompt: Text("Tên mạng"))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("Tên").foregroundStyle(.primary)
                }

                LabeledContent {
                    SecureField("", text: passwordBinding,
                                prompt: Text("Mật khẩu"))
                        .textContentType(.password)
                        .multilineTextAlignment(.trailing)
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
                    SecurityPickerView(selection: $item.security)
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.displayName)
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
                Button("Lưu") { save() }.bold()
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
        case .create: store.add(item)
        case .edit:   store.update(item)
        }
        dismiss()
    }
}
