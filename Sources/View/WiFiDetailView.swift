import SwiftUI

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) var dismiss
    
    let item: WiFiNetwork
    @State private var showMenu = false
    @State private var showDeleteConfirm = false
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Thông tin mạng
            Section(header: Text("THÔNG TIN").font(.caption).foregroundColor(.secondary)) {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Tên", text: .constant(item.ssid))
                        .disabled(true)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        SecureField("Mật khẩu", text: .constant(item.password ?? ""))
                            .disabled(true)
                        Button("Sao chép") {
                            if let pass = item.password {
                                UIPasteboard.general.string = pass
                                copied = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .alert("Đã sao chép mật khẩu", isPresented: $copied) {
                            Button("OK", role: .cancel) {}
                        }
                    }
                }
            }
            
            // Bảo mật
            Section(header: Text("BẢO MẬT").font(.caption).foregroundColor(.secondary)) {
                HStack {
                    Text("Bảo mật")
                    Spacer()
                    Text(item.security.rawValue)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // QR Code
            Section(header: Text("MÃ QR").font(.caption).foregroundColor(.secondary)) {
                if let qr = QRCode.make(
                    text: QRCode.wifiString(
                        ssid: item.ssid,
                        password: item.password ?? "",
                        security: item.security
                    ),
                    size: CGSize(width: 240, height: 240)
                ) {
                    Image(uiImage: qr)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            Spacer()
            
            Button(action: {
                store.update(item)
                dismiss()
            }) {
                Text("Lưu thông tin")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .navigationTitle(item.ssid)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        shareQR()
                    } label: {
                        Label("Chia sẻ QR", systemImage: "qrcode")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Bạn có chắc chắn muốn xóa Wi-Fi này không?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Chắc chắn", role: .destructive) {
                store.delete(item)
                dismiss()
            }
            Button("Hủy", role: .cancel) {}
        }
    }
    
    private func shareQR() {
        if let image = QRCode.make(
            text: QRCode.wifiString(ssid: item.ssid, password: item.password ?? "", security: item.security),
            size: CGSize(width: 512, height: 512)
        ) {
            let avc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(avc, animated: true)
        }
    }
}
