import SwiftUI

/// Picker chung để chọn kiểu bảo mật cho Wi-Fi.
/// Lưu ý: Dựa theo model hiện tại, `SecurityType` là một enum top-level (không lồng trong WiFiNetwork).
struct SecurityPickerView: View {
    @Binding var selection: SecurityType

    var body: some View {
        List {
            ForEach(SecurityType.allCases, id: \.self) { opt in
                HStack {
                    Text(opt.rawValue) // hiển thị rawValue của enum
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
