import SwiftUI

struct WiFiFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State var item: WiFiNetwork
    var onSave: (WiFiNetwork) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("THÔNG TIN CƠ BẢN") {
                    TextField("Tên mạng", text: $item.ssid)
                    SecureField("Mật khẩu", text: $item.password)

                    NavigationLink {
                        Picker("Bảo mật", selection: $item.security) {
                            ForEach(WiFiSecurity.allCases) { sec in
                                HStack {
                                    Text(sec.rawValue)
                                    Spacer()
                                    if item.security == sec { Image(systemName: "checkmark") }
                                }.tag(sec)
                            }
                        }
                        .navigationTitle("Bảo mật")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("Bảo mật")
                            Spacer()
                            Text(item.security.rawValue).foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        Picker("Địa chỉ Wi-Fi bảo mật", selection: $item.privateAddressing) {
                            ForEach(PrivateAddressing.allCases) { m in
                                HStack {
                                    Text(m.rawValue)
                                    Spacer()
                                    if item.privateAddressing == m { Image(systemName: "checkmark") }
                                }.tag(m)
                            }
                        }
                        .navigationTitle("Địa chỉ Wi-Fi bảo mật")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("Địa chỉ Wi-Fi bảo mật")
                            Spacer()
                            Text(item.privateAddressing.rawValue).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(item.id == .init() ? "Thêm Wi-Fi" : "Sửa Wi-Fi")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Huỷ") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu") {
                        onSave(item); dismiss()
                    }.disabled(item.ssid.isEmpty)
                }
            }
        }
    }
}
