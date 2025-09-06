import SwiftUI
import UIKit

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    let item: WiFiNetwork
    @State private var qrImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // QR căn cho đẹp
                if let img = qrImage {
                    Image(uiImage: img)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 280)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.2)))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Thông tin").font(.headline)
                    HStack { Text("SSID"); Spacer(); Text(item.ssid) }
                    HStack { Text("Mật khẩu"); Spacer(); Text(item.password ?? "—") }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Thông tin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        shareQR()
                    } label: { Label("Chia sẻ mã QR", systemImage: "square.and.arrow.up") }

                    Button {
                        store.editing = item
                        store.presentForm = true
                    } label: { Label("Sửa", systemImage: "pencil") }

                    Button(role: .destructive) {
                        store.delete(item)
                    } label: { Label("Xóa", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            let text = QRCode.wifiString(ssid: item.ssid, password: item.password, security: item.security)
            qrImage = QRCode.make(text: text, size: CGSize(width: 1024, height: 1024))
        }
    }

    private func shareQR() {
        guard let img = qrImage else { return }
        let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
        UIApplication.shared.firstKeyWindow?.rootViewController?.present(av, animated: true)
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
