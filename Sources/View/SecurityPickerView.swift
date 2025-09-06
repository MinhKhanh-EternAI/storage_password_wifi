import SwiftUI

struct SecurityPickerView: View {
    @Binding var security: SecurityType
    @Binding var privacy: MACAddressPrivacy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Dòng dẫn tới chọn địa chỉ Wi-Fi bảo mật
            NavigationLink {
                MACPrivacyPickerView(privacy: $privacy)
            } label: {
                HStack {
                    Text("Địa chỉ Wi-Fi bảo mật")
                    Spacer()
                    Text(privacy.rawValue)               // Tắt / Cố định / Luân chuyển
                        .foregroundStyle(.secondary)
                }
            }

            // Danh sách kiểu bảo mật
            Section {
                ForEach(SecurityType.allCases) { option in
                    HStack {
                        Text(option.rawValue)            // Không có, WEP, WPA, WPA2/WPA3, ...
                        Spacer()
                        if option == security { Image(systemName: "checkmark") }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { security = option; dismiss() }
                }
            }
        }
        .navigationTitle("Bảo mật")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// View con: chọn Địa chỉ Wi-Fi bảo mật
struct MACPrivacyPickerView: View {
    @Binding var privacy: MACAddressPrivacy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(MACAddressPrivacy.allCases) { option in
                HStack {
                    Text(option.rawValue)               // Tắt / Cố định / Luân chuyển
                    Spacer()
                    if option == privacy { Image(systemName: "checkmark") }
                }
                .contentShape(Rectangle())
                .onTapGesture { privacy = option; dismiss() }
            }
        }
        .navigationTitle("Địa chỉ Wi-Fi bảo mật")
        .navigationBarTitleDisplayMode(.inline)
    }
}
