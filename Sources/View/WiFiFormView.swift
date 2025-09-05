import SwiftUI

struct WiFiFormView: View {
    @Environment(\.dismiss) private var dismiss

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
                    ForEach(AddressPrivacy.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }
        }
        .navigationTitle("Sửa Wi-Fi")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Huỷ") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Lưu") {
                    onSave(item)
                    dismiss()
                }.disabled(item.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
