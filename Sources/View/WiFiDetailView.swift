import SwiftUI

struct WiFiDetailView: View {
    var item: WiFiNetwork
    var onUpdate: (WiFiNetwork) -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    @State private var showShareSheet = false

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
                        if let note = item.note, !note.isEmpty {
                            row("Ghi chú", note)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Chia sẻ QR", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Xoá", systemImage: "trash")
                    }

                    Button {
                        onEdit()
                    } label: {
                        Label("Sửa", systemImage: "pencil")
                    }
                }
            }
            .padding()
        }
        .navigationTitle(item.ssid)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [UIImage.qr(from: item.qrPayload, size: 800)])
        }
    }

    @ViewBuilder
    private func row(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body)
            Divider()
        }
    }
}

// MARK: – Share Sheet helper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
