import SwiftUI

struct SecurityPickerView: View {
    @Binding var security: SecurityType
    @Binding var privacy: MACAddressPrivacy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Dẫn tới màn chọn Địa chỉ Wi-Fi bảo mật
            NavigationLink {
                MACPrivacyPickerView(privacy: $privacy)
            } label: {
                HStack {
                    Text("Địa chỉ Wi-Fi bảo mật")
                    Spacer()
                    Text(privacy.rawValue) // Tắt / Cố định / Luân chuyển
                        .foregroundColor(.secondary)
                }
            }

            // Danh sách kiểu bảo mật
            Section {
                ForEach(SecurityType.allCases) { option in
                    Button {
                        security = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.rawValue) // Không có, WEP, WPA, WPA2/WPA3, ...
                            Spacer()
                            if option == security {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    .contentShape(Rectangle())
                }
            }
        }
        .navigationTitle("Bảo mật")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Ẩn "Back" mặc định
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Trở lại")
                    }
                }
            }
        }
    }
}

// MARK: - View con: chọn Địa chỉ Wi-Fi bảo mật
struct MACPrivacyPickerView: View {
    @Binding var privacy: MACAddressPrivacy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(MACAddressPrivacy.allCases) { option in
                Button {
                    privacy = option
                    dismiss()
                } label: {
                    HStack {
                        Text(option.rawValue) // Tắt / Cố định / Luân chuyển
                        Spacer()
                        if option == privacy {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .foregroundColor(.primary)
                .contentShape(Rectangle())
            }
        }
        .navigationTitle("Địa chỉ Wi-Fi bảo mật")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Ẩn "Bảo mật" mặc định
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Trở lại") // <- theo yêu cầu
                    }
                }
            }
        }
    }
}
