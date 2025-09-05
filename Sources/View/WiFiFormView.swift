import SwiftUI

struct WiFiFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    var onSubmit: (WiFiNetwork) -> Void = { _ in }

    var body: some View {
        Form {
            Section("Thông tin cơ bản") {
                TextField("SSID", text: $item.ssid)
                    .textInputAutocapitalization(.never)
                SecureField("Mật khẩu", text: $item.password)
                    .textInputAutocapitalization(.never)
                Picker("Bảo mật", selection: $item.security) {
                    ForEach(WiFiNetwork.Security.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
            }
            Section("Ghi chú") {
                TextField("Ghi chú (tuỳ chọn)", text: Binding(
                    get: { item.note ?? "" },
                    set: { item.note = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    onSubmit(item)
                } label: {
                    Label("Lưu", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(item.ssid.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}
