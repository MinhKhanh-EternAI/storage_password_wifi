import SwiftUI

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    let item: WiFiNetwork

    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // QR code căn đẹp, nét, khung vuông
                if let qr = QRCode.make(
                    text: QRCode.wifiString(ssid: item.ssid, password: item.password, security: item.security),
                    size: CGSize(width: 600, height: 600)
                ) {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.top, 8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Thông tin").font(.headline)
                    row("Tên mạng", item.ssid)
                    row("Mật khẩu", item.password)
                        .contextMenu {
                            Button("Sao chép mật khẩu") {
                                UIPasteboard.general.string = item.password
                            }
                        }
                    row("Bảo mật", securityText(item.security))
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Thông tin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topTrailing) {
                Menu {
                    Button("Chia sẻ mã QR") { shareQR() }
                    Button("Sửa") { editItem() }
                    Button(role: .destructive) { deleteItem() } label: { Text("Xóa") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ActivityView(activityItems: [img])
            }
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).multilineTextAlignment(.trailing)
        }
        .font(.body)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func shareQR() {
        let str = QRCode.wifiString(ssid: item.ssid, password: item.password, security: item.security)
        if let image = QRCode.make(text: str, size: CGSize(width: 1024, height: 1024)) {
            shareImage = image
            showShareSheet = true
        }
    }

    private func editItem() {
        store.editing = item
        store.presentForm = true
    }

    private func deleteItem() {
        store.delete(item)
        dismiss()
    }
}

// Wrapper share sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

// Tạo text hiển thị bảo mật an toàn, không phụ thuộc enum tên gì trong repo
private func securityText(_ any: Any) -> String {
    let s = String(describing: any).lowercased()
    switch true {
    case s.contains("wpa3 enterprise"), s.contains("wpa3_doanh"):
        return "WPA3 Doanh nghiệp"
    case s.contains("wpa2 enterprise"), s.contains("wpa2_doanh"):
        return "WPA2 Doanh nghiệp"
    case s.contains("wpa3"):
        return "WPA3"
    case s.contains("wpa2/wpa3"), s.contains("wpa2wpa3"):
        return "WPA2/WPA3"
    case s.contains("wpa2"):
        return "WPA2"
    case s.contains("wpa"):
        return "WPA"
    case s.contains("wep"):
        return "WEP"
    case s.contains("none"), s.contains("không"), s.contains("open"):
        return "Không có"
    default:
        return "Khác"
    }
}
