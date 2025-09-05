import Foundation

struct WiFiNetwork: Identifiable, Codable, Equatable {
    enum Security: String, CaseIterable, Codable, Identifiable {
        case open = "Không có"
        case wep = "WEP"
        case wpa = "WPA"
        case wpa2wpa3 = "WPA2/WPA3"
        case wpa3 = "WPA3"
        case wpaEnterprise = "WPA Doanh nghiệp"
        case wpa2Enterprise = "WPA2 Doanh nghiệp"
        case wpa3Enterprise = "WPA3 Doanh nghiệp"

        var id: String { rawValue }

        // dùng cho NEHotspotConfiguration: gom nhóm tương thích
        var isEnterprise: Bool {
            switch self {
            case .wpaEnterprise, .wpa2Enterprise, .wpa3Enterprise: return true
            default: return false
            }
        }
        var configFlavor: BasicConfigFlavor {
            switch self {
            case .open: return .open
            case .wep: return .wep
            case .wpa, .wpa2wpa3, .wpa3: return .wpa
            default: return .wpa // enterprise không hỗ trợ qua API public
            }
        }
        enum BasicConfigFlavor { case open, wep, wpa }
    }

    enum PrivateAddressMode: String, CaseIterable, Codable, Identifiable {
        case off = "Tắt"
        case fixed = "Cố định"
        case rotating = "Luân chuyển"
        var id: String { rawValue }
    }

    let id: UUID
    var ssid: String
    var password: String
    var security: Security
    var privateAddress: PrivateAddressMode

    init(id: UUID = UUID(),
         ssid: String,
         password: String,
         security: Security = .wpa2wpa3,                   // mặc định WPA2/WPA3
         privateAddress: PrivateAddressMode = .off) {      // “Địa chỉ Wi-Fi bảo mật” mặc định Tắt
        self.id = id
        self.ssid = ssid
        self.password = password
        self.security = security
        self.privateAddress = privateAddress
    }

    // QR payload giữ nguyên chuẩn phổ biến
    var qrPayload: String {
        let t: String
        switch security {
        case .open: t = "nopass"
        case .wep: t = "WEP"
        case .wpa: t = "WPA"
        case .wpa2wpa3: t = "WPA"
        case .wpa3: t = "WPA" // nhiều app/thiết bị vẫn dùng WPA ở QR
        default: t = "WPA"
        }
        let escSSID = ssid.replacingOccurrences(of: "\\", with: "\\\\")
                           .replacingOccurrences(of: ";", with: "\\;")
        let escPWD  = password.replacingOccurrences(of: "\\", with: "\\\\")
                              .replacingOccurrences(of: ";", with: "\\;")
        return "WIFI:T:\(t);S:\(escSSID);P:\(escPWD);;"
    }
}
