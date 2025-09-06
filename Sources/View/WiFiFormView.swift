import SwiftUI

enum FormMode {
    case create
    case edit
}

struct WiFiFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WiFiStore

    let mode: FormMode
    @State var item: WiFiNetwork

    var body: some View {
        Form {
            Section("THÔNG TIN") {
                TextField("Tên", text: $item.ssid)
                SecureField("Mật khẩu", text: Binding(
                    get: { item.password ?? "" },
                    set: { item.password = $0.isEmpty ? nil : $0 }
                ))
            }

            Section("BẢO MẬT") {
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
            }
        }
        .navigationTitle(mode == .create ? "Thêm Wi-Fi" : item.ssid)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Hủy") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Lưu") {
                    store.upsert(item)
                    dismiss()
                }
                .disabled(item.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
