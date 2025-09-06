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
                        Text(item.security)
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

// Picker danh sách bảo mật dạng String (khớp model hiện tại)
private struct SecurityPickerView: View {
    @Binding var selection: String

    static let options: [String] = [
        "Không có",
        "WEP",
        "WPA",
        "WPA2/WPA3",
        "WPA3",
        "WPA Doanh nghiệp",
        "WPA2 Doanh nghiệp",
        "WPA3 Doanh nghiệp"
    ]

    var body: some View {
        List {
            ForEach(Self.options, id: \.self) { opt in
                HStack {
                    Text(opt)
                    Spacer()
                    if opt == selection {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selection = opt }
            }
        }
        .navigationTitle("Bảo mật")
        .navigationBarTitleDisplayMode(.inline)
    }
}
