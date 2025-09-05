import CoreImage.CIFilterBuiltins
import UIKit

/// Helper tạo chuỗi QR chuẩn cho Wi-Fi + render ảnh QR
enum QRCodeMaker {
    /// Tạo chuỗi QR theo chuẩn WIFI:… (dùng cho Airdrop/Android scanner, iOS mở sẽ ra sheet kết nối)
    static func wifiString(ssid: String, password: String, security: SecurityType) -> String {
        // Theo chuẩn: WIFI:T:<auth>;S:<ssid>;P:<password>;H:<hidden>;;
        // Với không mật khẩu -> NOPASS
        let auth = security.qrAuthToken ?? "nopass"
        // Escape ký tự đặc biệt theo chuẩn
        func esc(_ s: String) -> String {
            s
              .replacingOccurrences(of: "\\", with: "\\\\")
              .replacingOccurrences(of: ";", with: "\\;")
              .replacingOccurrences(of: ",", with: "\\,")
              .replacingOccurrences(of: ":", with: "\\:")
              .replacingOccurrences(of: "\"", with: "\\\"")
        }

        if auth.lowercased() == "nopass" {
            return "WIFI:T:nopass;S:\(esc(ssid));;"
        } else {
            return "WIFI:T:\(auth);S:\(esc(ssid));P:\(esc(password));;"
        }
    }

    /// Sinh UIImage từ string (QR)
    static func generate(from text: String, scale: CGFloat = 8) -> UIImage? {
        let data = Data(text.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.correctionLevel = "M" // cân bằng

        guard let outImage = filter.outputImage else { return nil }
        let transformed = outImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        if let cgimg = context.createCGImage(transformed, from: transformed.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
}
    