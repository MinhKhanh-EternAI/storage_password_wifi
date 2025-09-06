import Foundation
import CoreImage.CIFilterBuiltins
import SwiftUI

enum QRCode {
    static func wifiString(ssid: String, password: String?, security: SecurityType) -> String {
        let sec = security.rawValue
        return "WIFI:T:\(sec);S:\(ssid);P:\(password ?? "");;"
    }

    static func make(text: String, size: CGSize) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        let transform = CGAffineTransform(scaleX: size.width / 31, y: size.height / 31)

        if let output = filter.outputImage?.transformed(by: transform) {
            let context = CIContext()
            if let cg = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cg)
            }
        }
        return nil
    }
}
