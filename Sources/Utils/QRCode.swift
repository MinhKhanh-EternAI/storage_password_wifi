import CoreImage.CIFilterBuiltins
import UIKit

/// Helper tạo chuỗi QR chuẩn cho Wi-Fi + render ảnh QR
enum QRCodeMaker {
    /// Chuẩn WIFI: T:<auth>;S:<ssid>;P:<password>;H:<hidden>;;
    static func wifiString(ssid: String, password: String?, security: SecurityType) -> String {
        let auth = security.qrAuthToken ?? "nopass"

        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: ";", with: "\\;")
             .replacingOccurrences(of: ",", with: "\\,")
             .replacingOccurrences(of: ":", with: "\\:")
             .replacingOccurrences(of: "\"", with: "\\\"")
        }

        if auth.lowercased() == "nopass" || (password ?? "").isEmpty {
            return "WIFI:T:nopass;S:\(esc(ssid));;"
        } else {
            return "WIFI:T:\(auth);S:\(esc(ssid));P:\(esc(password!));;"
        }
    }

    static func generate(from text: String, scale: CGFloat = 7) -> UIImage? {
        let data = Data(text.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.correctionLevel = "M"

        guard let outImage = filter.outputImage else { return nil }
        let transformed = outImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgimg = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgimg)
    }
}
