import SwiftUI
import NetworkExtension

struct WiFiDetailView: View {
    var item: WiFiNetwork
    var onUpdate: (WiFiNetwork) -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void

    @StateObject private var wifiInfo = CurrentWiFi()
    @State private var showShareSheet = false
    @State private var copied = false
    @State private var connectMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // QR vuông
                QRCodeView(text: item.qrPayload, size: 240)
                    .padding(.top, 8)

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        infoRow("Tên mạng", item.ssid)
                        passwordRow()
                        infoRow("Bảo mật", item.security.rawValue)
                        infoRow("Địa chỉ Wi-Fi bảo mật", item.privateAddress.rawValue)
                    }
                }

                Button {
                    connect(item)
                } label: {
                    Label("Kết nối mạng này", systemImage: "wifi")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle(item.ssid)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showShareSheet = true } label: {
                        Label("Chia sẻ mã QR", systemImage: "square.and.arrow.up")
                    }
                    Button { onEdit() } label: {
                        Label("Sửa", systemImage: "pencil")
                    }
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Xoá", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [UIImage.qr(from: item.qrPayload, size: 1024)])
        }
        .onAppear { wifiInfo.requestAndFetch() }
        .alert("Kết nối", isPresented: Binding(get: { connectMessage != nil }, set: { if !$0 { connectMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(connectMessage ?? "") }
        .overlay(alignment: .bottom) {
            if copied {
                Text("Đã sao chép mật khẩu")
                    .font(.callout)
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder private func infoRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body)
            Divider()
        }
    }

    @ViewBuilder private func passwordRow() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mật khẩu").font(.caption).foregroundStyle(.secondary)
            Text(item.security == .open ? "(Không cần)" : item.password)
                .font(.body)
                .textSelection(.disabled)
                .onLongPressGesture {
                    if item.security != .open {
                        UIPasteboard.general.string = item.password
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { copied = false }
                        }
                    }
                }
            Divider()
        }
    }

    private func connect(_ item: WiFiNetwork) {
        wifiInfo.connect(ssid: item.ssid,
                         password: item.security == .open ? nil : item.password,
                         security: item.security,
                         joinOnce: false) { err in
            DispatchQueue.main.async {
                if let nsErr = err as NSError? {
                    if nsErr.domain == NEHotspotConfigurationErrorDomain,
                       nsErr.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                        connectMessage = "Đã kết nối với \(item.ssid)."
                    } else {
                        connectMessage = "Kết nối thất bại: \(nsErr.localizedDescription)"
                    }
                } else {
                    connectMessage = "Đã gửi yêu cầu kết nối \(item.ssid). Có thể hệ thống hiện prompt xác nhận."
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
