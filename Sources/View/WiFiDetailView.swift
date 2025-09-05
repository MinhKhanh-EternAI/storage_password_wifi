import SwiftUI

struct WiFiDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WiFiStore
    @State var item: WiFiNetwork

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // QR nhỏ gọn: chỉ tên & mật khẩu
                if !item.password.isEmpty {
                    VStack(spacing: 8) {
                        if let img = QRBuilder.make(
                            text: QRBuilder.wifiString(ssid: item.ssid, password: item.password, security: item.security),
                            size: 160
                        ) {
                            Image(uiImage: img)
                                .interpolation(.none)
                                .resizable()
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Text(item.ssid).font(.headline)
                        Text(item.password).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                Group {
                    HStack { Text("Tên mạng"); Spacer(); Text(item.ssid).foregroundStyle(.secondary) }
                    Divider()
                    HStack {
                        Text("Mật khẩu"); Spacer()
                        Button {
                            UIPasteboard.general.string = item.password
                        } label: {
                            Label("Sao chép", systemImage: "doc.on.doc")
                        }.buttonStyle(.bordered)
                    }
                    Divider()
                    HStack { Text("Bảo mật"); Spacer(); Text(item.security.rawValue).foregroundStyle(.secondary) }
                    Divider()
                    HStack { Text("Đ/c Wi-Fi bảo mật"); Spacer(); Text(item.privateAddressing.rawValue).foregroundStyle(.secondary) }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle(item.ssid)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("Sửa", systemImage: "pencil") {
                        presentEdit()
                    }
                    Button("Chia sẻ QR", systemImage: "qrcode") {
                        shareQR()
                    }
                    Button(role: .destructive, action: deleteMe) {
                        Label("Xoá", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private func presentEdit() {
        let sheet = WiFiFormView(item: item) { updated in
            item = updated
            store.update(updated)
        }
        let hosting = UIHostingController(rootView: sheet.environmentObject(store))
        hosting.modalPresentationStyle = .formSheet
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController?
            .present(hosting, animated: true)
    }

    private func shareQR() {
        guard !item.password.isEmpty else { return }
        let str = QRBuilder.wifiString(ssid: item.ssid, password: item.password, security: item.security)
        let av = UIActivityViewController(activityItems: [str], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController?
            .present(av, animated: true)
    }

    private func deleteMe() {
        if let idx = store.items.firstIndex(where: { $0.id == item.id }) {
            store.items.remove(at: idx)
            store.save()
            dismiss()
        }
    }
}
