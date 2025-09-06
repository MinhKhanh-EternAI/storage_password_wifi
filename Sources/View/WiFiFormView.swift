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
                    ZStack(alignment: .trailing) {
                        if item.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Tên mạng")
                                .foregroundStyle(.tertiary)   // placeholder mờ
                        }
                        TextField("", text: $item.ssid)
                            .multilineTextAlignment(.trailing) // text nằm bên phải
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                } label: {
                    Text("Tên").foregroundStyle(.primary)       // nhãn đen cố định
                }

                // MẬT KHẨU
                LabeledContent {
                    ZStack(alignment: .trailing) {
                        if (item.password ?? "").isEmpty {
                            Text("Mật khẩu")
                                .foregroundStyle(.tertiary)     // placeholder mờ
                        }
                        SecureField("", text: passwordBinding)
                            .multilineTextAlignment(.trailing)
                    }
                } label: {
                    Text("Mật khẩu").foregroundStyle(.primary)  // nhãn đen cố định
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
                    SecurityPickerView(security: $item.security)
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    SecurityPickerView(security: $item.security, privacy: $item.macPrivacy)
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)        // hiện đúng tiếng Việt
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
            // ✅ Không có store.add: thêm trực tiếp rồi sort
            store.items.append(item)
            store.sortInPlace()
        case .edit:
            // ✅ Không có store.update: tự thay phần tử theo id
            if let i = store.items.firstIndex(where: { $0.id == item.id }) {
                store.items[i] = item
                store.sortInPlace()
            }
        }
        dismiss()
    }
}
