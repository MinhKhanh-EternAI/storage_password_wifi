import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let text: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let uiImage = generate() {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
        } else {
            Color.secondary.opacity(0.1)
                .overlay(Text("QR lỗi").foregroundStyle(.secondary))
        }
    }

    private func generate() -> UIImage? {
        let data = Data(text.utf8)
        filter.setValue(data, forKey: "inputMessage")
        guard let outputImage = filter.outputImage?
                .transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        else { return nil }
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
}

extension WiFiNetwork {
    /// Chuỗi chuẩn để tạo QR
    var wifiQRString: String {
        let t: String
        switch security {
        case .none, .wep: t = "nopass" // hoặc "WEP" nếu cần
        case .wpa, .wpa2wpa3, .wpa3, .wpaEnterprise, .wpa2Enterprise, .wpa3Enterprise:
            t = "WPA"
        }
        let escapedSSID = ssid.replacingOccurrences(of: ";", with: "\\;")
        let pwd = (password ?? "").replacingOccurrences(of: ";", with: "\\;")
        return "WIFI:T:\(t);S:\(escapedSSID);P:\(pwd);H:false;"
    }
}
