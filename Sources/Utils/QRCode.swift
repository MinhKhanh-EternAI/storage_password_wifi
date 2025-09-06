import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum QRCode {
    static func wifiString(ssid: String, password: String?, security: SecurityType) -> String {
        let t = (security == .none) ? "nopass" : "WPA"
        let p = password ?? ""
        // Theo chuẩn: WIFI:T:<auth>;S:<ssid>;P:<password>;;
        return "WIFI:T:\(t);S:\(ssid);P:\(p);;"
    }

    static func make(text: String, size: CGSize) -> UIImage? {
        let ctx = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(text.utf8), forKey: "inputMessage")

        guard let output = filter.outputImage else { return nil }
        let scaleX = size.width / output.extent.size.width
        let scaleY = size.height / output.extent.size.height
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        if let cg = ctx.createCGImage(scaled, from: scaled.extent) {
            return UIImage(cgImage: cg)
        }
        return nil
    }
}
