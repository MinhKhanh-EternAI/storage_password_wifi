import SwiftUI

struct WiFiDetailView: View {
    var item: WiFiNetwork
    var onUpdate: (WiFiNetwork) -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void

    @StateObject private var wifiInfo = CurrentWiFi()      // 👈 NEW
    @State private var showShareSheet = false
    @State private var connectMessage: String? = nil       // 👈 NEW

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                QRCodeView(text: item.qrPayload, size: 240)
                    .padding(.top, 8)

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        row("SSID", item.ssid)
                        row("Mật khẩu", item.security == .open ? "(Không cần)" : item.password)
                        row("Bảo mật", item.security.rawValue)
                        if let note = item.note, !note.isEmpty { row("Ghi chú", note) }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        showShareSheet = true
                    } label: { Label("Chia sẻ QR", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.bordered)

                    Button {
                        connect(item)
                    } label: { Label("Kết nối mạng này", systemImage: "wifi") }   // 👈 NEW
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) { onDelete() } label: {
                        Label("Xoá", systemImage: "trash")
                    }

                    Button { onEdit() } label: { Label("Sửa", systemImage: "pencil") }
                }
            }
            .padding()
        }
        .navigationTitle(item.ssid)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [UIImage.qr(from: item.qrPayload, size: 800)])
        }
        .onAppear { wifiInfo.requestAndFetch() }
        .alert("Kết nối", isPresented: Binding(get: { connectMessage != nil }, set: { if !$0 { connectMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(connectMessage ?? "")
        }
    }

    @ViewBuilder private func row(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body)
            Divider()
        }
    }

    private func connect(_ item: WiFiNetwork) {
        wifiInfo.connect(ssid: item.ssid, password: item.security == .open ? nil : item.password, security: item.security, joinOnce: false) { err in
            DispatchQueue.main.async {
                if let err = err as NSError? {
                    if err.domain == NEHotspotConfigurationError.domain,
                       err.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                        connectMessage = "Đã kết nối với \(item.ssid)."
                    } else {
                        connectMessage = "Kết nối thất bại: \(err.localizedDescription)"
                    }
                } else {
                    connectMessage = "Đã gửi yêu cầu kết nối \(item.ssid). Có thể hệ thống hiện prompt xác nhận."
                }
            }
        }
    }
}

// ShareSheet giữ nguyên như trước
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
    