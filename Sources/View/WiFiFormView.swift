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
                    SecurityPickerView(selection: $item.security)
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text("\(item.security)") // hiển thị đơn giản, tránh lệ thuộc enum case tên gì
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
                    store.upsert(item)     // dùng upsert để tránh lỗi dynamicMember/update
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// Picker đơn giản cho kiểu bảo mật (dựa trên CaseIterable nếu enum của bạn có)
struct SecurityPickerView: View {
    @Binding var selection: WiFiNetwork.SecurityType

    var body: some View {
        List {
            ForEach(WiFiNetwork.SecurityType.allCases, id: \.self) { sec in
                HStack {
                    Text("\(sec)")
                    Spacer()
                    if sec == selection {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selection = sec }
            }
        }
        .navigationTitle("Bảo mật")
        .navigationBarTitleDisplayMode(.inline)
    }
}
