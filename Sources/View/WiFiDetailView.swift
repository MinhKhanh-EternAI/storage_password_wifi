import SwiftUI

struct WiFiDetailView: View {
    @State var item: WiFiNetwork
    var onUpdate: (WiFiNetwork) -> Void
    var onDelete: () -> Void

    @State private var qrImage: UIImage? = nil
    @State private var showShare = false

    var body: some View {
        Form {
            Section {
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
                } else {
                    HStack {
                        Text("Mật khẩu").foregroundStyle(.secondary)
                        Spacer()
                        Text("—")
                            .foregroundStyle(.secondary)
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

            Section("QR Wi-Fi") {
                if let img = qrImage {
                    Image(uiImage: img)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220)
                        .clipShape(Rectangle()) // khung vuông
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Button {
                    guard let img = qrImage else { return }
                    let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
                    UIApplication.shared.firstKeyWindow?.rootViewController?.present(av, animated: true)
                } label: { Label("Chia sẻ mã QR", systemImage: "square.and.arrow.up") }
            }
        }
        .navigationTitle("Chi tiết")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink {
                    WiFiFormView(item: item) { updated in
                        self.item = updated
                        onUpdate(updated)
                        rebuildQR()
                    }
                } label: { Image(systemName: "pencil") }

                Button(role: .destructive) {
                    onDelete()
                } label: { Image(systemName: "trash") }
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
