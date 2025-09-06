import SwiftUI

enum FormMode { case create, edit }

struct WiFiFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WiFiStore

    let mode: FormMode
    @State var item: WiFiNetwork

    var body: some View {
        Form {
            Section("THÔNG TIN") {
                TextField("Tên mạng", text: $item.ssid)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Mật khẩu", text: Binding(
                    get: { item.password ?? "" },
                    set: { item.password = $0.isEmpty ? nil : $0 }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .privacySensitive(true)
            }

            Section("BẢO MẬT") {
                NavigationLink {
                    SecurityPickerView(selection: $item.security) // <-- Binding<SecurityType>
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue) // <-- hiển thị tên từ enum
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle(mode == .create ? "Thêm Wi-Fi" : item.ssid)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Hủy") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Lưu") {
                    store.upsert(item)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}
