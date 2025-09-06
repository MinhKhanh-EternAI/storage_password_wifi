import SwiftUI

enum FormMode { case add, edit }

struct WiFiFormView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: FormMode
    @State var item: WiFiNetwork
    var onSave: (WiFiNetwork) -> Void

    var body: some View {
        Form {
            Section("Thông tin") {
                TextField("Tên mạng", text: Binding(
                    get: { item.ssid },
                    set: { item.ssid = $0 }
                ))
                .textInputAutocapitalization(.none)

                SecureField("Mật khẩu", text: Binding(
                    get: { item.password ?? "" },
                    set: { item.password = $0.isEmpty ? nil : $0 }
                ))
            }

            Section("Bảo mật") {
                Picker("Bảo mật", selection: $item.security) {
                    ForEach(SecurityType.allCases) { sec in
                        Text(sec.displayName).tag(sec)
                    }
                }
                Picker("Địa chỉ Wi-Fi bảo mật", selection: $item.addressPrivacy) {
                    ForEach(AddressPrivacy.allCases) { m in
                        Text(m.displayName).tag(m)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(mode == .add ? "Thêm mạng" : "Sửa Wi-Fi")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // Vừa có mũi tên back (hệ thống), vừa có "Huỷ" theo yêu cầu
                Button("Huỷ") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Lưu") {
                    onSave(item)
                    dismiss()
                }
                .disabled(item.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
