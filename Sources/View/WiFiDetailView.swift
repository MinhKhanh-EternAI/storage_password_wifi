import SwiftUI
import UIKit

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section("THÔNG TIN") {
                TextField("Tên", text: $item.ssid)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                HStack(spacing: 8) {
                    Text("Mật khẩu")
                    Spacer()
                    TextField("Mật khẩu", text: Binding(
                        get: { item.password ?? "" },
                        set: { item.password = $0.isEmpty ? nil : $0 }
                    ))
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .privacySensitive(true)
                    .contextMenu {
                        Button("Sao chép") { UIPasteboard.general.string = item.password ?? "" }
                    }
                }
            }

            Section("BẢO MẬT") {
                NavigationLink {
                    SecurityPickerView(selection: $item.security)
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section("MÃ QR") {
                QRCodeView(item: item)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .listRowBackground(Color.clear)
            }

            Section {
                Button {
                    store.upsert(item)
                    dismiss()
                } label: {
                    Text("Lưu thông tin")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(item.ssid.isEmpty ? "Chi tiết Wi-Fi" : item.ssid)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        shareQR()
                    } label: {
                        Label("Chia sẻ QR", systemImage: "qrcode")
                    }
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Xóa mạng Wi-Fi?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) { }
            Button("Chắc chắn", role: .destructive) {
                // KHÔNG gọi persist() (private); sửa danh sách để Store tự lưu (thường didSet)
                if let idx = store.items.firstIndex(of: item) {
                    store.items.remove(at: idx)
                }
                dismiss()
            }
        } message: {
            Text("Bạn có chắc chắn muốn xóa “\(item.ssid)”?")
        }
    }

    private func shareQR() {
        let str = QRCode.wifiString(
            ssid: item.ssid,
            password: item.password,
            security: item.security // <-- truyền SecurityType, KHÔNG dùng rawValue
        )
        guard let img = QRCode.make(text: str, size: CGSize(width: 1024, height: 1024)) else { return }
        let avc = UIActivityViewController(activityItems: [img], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(avc, animated: true)
        }
    }
}

private struct QRCodeView: View {
    let item: WiFiNetwork
    var body: some View {
        let str = QRCode.wifiString(
            ssid: item.ssid,
            password: item.password,
            security: item.security // <-- truyền SecurityType
        )
        if let img = QRCode.make(text: str, size: CGSize(width: 600, height: 600)) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
        } else {
            Text("Không tạo được QR")
                .foregroundStyle(.secondary)
        }
    }
}
