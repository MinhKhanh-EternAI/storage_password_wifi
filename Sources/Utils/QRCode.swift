import Foundation
import CoreImage
import UIKit

enum QRBuilder {
    @MainActor
    static func make(text: String, size: CGFloat = 240) -> UIImage? {
        guard let data = text.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.size.width
        let transformed = output.transformed(by: .init(scaleX: scale, y: scale))
        return UIImage(ciImage: transformed)
    }

    static func wifiString(ssid: String, password: String, security: WiFiSecurity) -> String {
        let t: String
        switch security {
        case .none: t = "nopass"
        case .wep: t = "WEP"
        case .wpa, .wpa2wpa3, .wpa3, .wpaEnterprise, .wpa2Enterprise, .wpa3Enterprise:
            t = "WPA"
        }
        return "WIFI:T:\(t);S:\(ssid);P:\(password);;"
    }
}
