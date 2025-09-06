import SwiftUI
import UniformTypeIdentifiers

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false
    @State private var copied = false

    var body: some View {
        List {
            Section("THÔNG TIN") {
                TextField("Tên", text: $item.ssid)
                HStack {
                    SecureField("Mật khẩu", text: Binding(
                        get: { item.password ?? "" },
                        set: { item.password = $0.isEmpty ? nil : $0 }
                    ))
                    if let pwd = item.password, !pwd.isEmpty {
                        Button("Sao chép") {
                            UIPasteboard.general.string = pwd
                            copied = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Section("BẢO MẬT") {
                NavigationLink {
                    SecurityPickerView(security: $item.security)
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("MÃ QR") {
                QRCodeView(text: item.wifiQRString)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 4)
            }

            Section {
                Button {
                    store.upsert(item)
                } label: {
                    Text("Lưu thông tin")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle(item.ssid)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: QRExport(imageText: item.wifiQRString)) {
                        Label("Chia sẻ QR", systemImage: "square.and.arrow.up")
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
        .alert("Bạn có chắc chắn muốn xóa?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Chắc chắn", role: .destructive) {
                store.delete(item.id)
                dismiss()
            }
        }
        .toast(isPresented: $copied, text: "Đã sao chép mật khẩu")
    }
}

// MARK: - Share support

import CoreImage.CIFilterBuiltins

struct QRExport: Transferable {
    let imageText: String
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { qr in
            let context = CIContext()
            let filter = CIFilter.qrCodeGenerator()
            filter.setValue(Data(qr.imageText.utf8), forKey: "inputMessage")
            let img = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
            let cgimg = context.createCGImage(img, from: img.extent)!
            let ui = UIImage(cgImage: cgimg)
            return ui.pngData()!
        }
    }
}

// MARK: - Tiny toast

fileprivate struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                Text(text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { isPresented = false }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: isPresented)
    }
}

fileprivate extension View {
    func toast(isPresented: Binding<Bool>, text: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, text: text))
    }
}
