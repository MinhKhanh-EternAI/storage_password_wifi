import SwiftUI

struct SecurityPickerView: View {
    @Binding var security: SecurityType

    var body: some View {
        List {
            Section {
                NavigationLink {
                    MACPrivacyPickerView()
                } label: {
                    HStack {
                        Text("Địa chỉ Wi-Fi bảo mật")
                        Spacer()
                        Text("Tắt")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                ForEach(SecurityType.allCases) { type in
                    HStack {
                        Text(type.rawValue)
                        Spacer()
                        if type == security {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { security = type }
                }
            }
        }
        .navigationTitle("Bảo mật")
    }
}

struct MACPrivacyPickerView: View {
    @State private var selected: MACAddressPrivacy = .off

    var body: some View {
        List {
            ForEach(MACAddressPrivacy.allCases) { opt in
                HStack {
                    Text(opt.rawValue)
                    Spacer()
                    if opt == selected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selected = opt }
            }
        }
        .navigationTitle("Địa chỉ Wi-Fi bảo mật")
    }
}
