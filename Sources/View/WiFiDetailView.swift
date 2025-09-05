import SwiftUI

struct WiFiDetailView: View {
    @State var item: WiFiNetwork
    var onUpdate: (WiFiNetwork) -> Void
    var onDelete: () -> Void

    @State private var showActions = false
    @State private var qrImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 16) {
            // QR gọn: chỉ tên + mật khẩu
            if let img = qrImage {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .clipShape(Rectangle()) // khung vuông, không bo góc
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tên mạng").foregroundStyle(.secondary)
                    Spacer()
                    Text(item.ssid)
                }
                if let pass = item.password, !pass.isEmpty {
                    HStack {
                        Text("Mật khẩu").foregroundStyle(.secondary)
                        Spacer()
                        Text(pass)
                            .textSelection(.enabled)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = pass
                                } label: { Label("Sao chép", systemImage: "doc.on.doc") }
                            }
                    }
                }
                HStack {
                    Text("Bảo mật").foregroundStyle(.secondary)
                    Spacer()
                    Text(item.security.displayName)
                }
                HStack {
                    Text("Địa chỉ bảo mật").foregroundStyle(.secondary)
                    Spacer()
                    Text(item.addressPrivacy.displayName)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Chi tiết")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        // Share QR
                        guard let img = qrImage else { return }
                        let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
                        UIApplication.shared.firstKeyWindow?.rootViewController?.present(av, animated: true)
                    } label: { Label("Chia sẻ QR", systemImage: "square.and.arrow.up") }

                    Button(role: .destructive) {
                        onDelete()
                    } label: { Label("Xoá", systemImage: "trash") }

                    NavigationLink {
                        WiFiFormView(item: item) { updated in
                            self.item = updated
                            onUpdate(updated)
                            rebuildQR()
                        }
                    } label: { Label("Sửa", systemImage: "pencil") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear { rebuildQR() }
    }

    private func rebuildQR() {
        let text = QRCodeMaker.wifiString(ssid: item.ssid,
                                          password: item.password,
                                          security: item.security)
        qrImage = QRCodeMaker.generate(from: text, scale: 6)
    }
}

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
