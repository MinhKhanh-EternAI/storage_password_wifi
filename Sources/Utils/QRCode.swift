import CoreImage.CIFilterBuiltins
import UIKit

enum QRCodeMaker {
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
        let ctx = CIContext()
        let f = CIFilter.qrCodeGenerator()
        f.setValue(data, forKey: "inputMessage")
        f.correctionLevel = "M"
        guard let out = f.outputImage else { return nil }
        let img = out.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cg = ctx.createCGImage(img, from: img.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
