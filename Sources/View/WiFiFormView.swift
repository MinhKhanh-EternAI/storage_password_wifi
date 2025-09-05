import SwiftUI

struct WiFiFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    var onSubmit: (WiFiNetwork) -> Void

    var body: some View {
        Form {
            Section("Thông tin cơ bản") {
                TextField("Tên mạng", text: $item.ssid)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Mật khẩu", text: $item.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Picker("Bảo mật", selection: $item.security) {
                    ForEach(WiFiNetwork.Security.allCases) { sec in
                        HStack {
                            Text(sec.rawValue)
                            if sec == item.security { Spacer(); Image(systemName: "checkmark") }
                        }.tag(sec)
                    }
                }

                Picker("Địa chỉ Wi-Fi bảo mật", selection: $item.privateAddress) {
                    ForEach(WiFiNetwork.PrivateAddressMode.allCases) { mode in
                        HStack {
                            Text(mode.rawValue)
                            if mode == item.privateAddress { Spacer(); Image(systemName: "checkmark") }
                        }.tag(mode)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Huỷ") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Lưu") {
                    onSubmit(item)
                    dismiss()
                }.bold()
            }
        }
    }
}
