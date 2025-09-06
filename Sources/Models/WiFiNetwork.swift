import Foundation

enum SecurityType: String, CaseIterable, Codable, Identifiable {
    case none = "Không có"
    case wep = "WEP"
    case wpa = "WPA"
    case wpa2wpa3 = "WPA2/WPA3"
    case wpa3 = "WPA3"
    case wpaEnterprise = "WPA Doanh nghiệp"
    case wpa2Enterprise = "WPA2 Doanh nghiệp"
    case wpa3Enterprise = "WPA3 Doanh nghiệp"

    var id: String { rawValue }
}

enum MACAddressPrivacy: String, CaseIterable, Codable, Identifiable {
    case off = "Tắt"
    case fixed = "Cố định"
    case rotating = "Luân chuyển"

    var id: String { rawValue }
}

struct WiFiNetwork: Identifiable, Codable, Equatable {
    var id: UUID
    var ssid: String
    var password: String?
    var security: SecurityType
    var privacy: MACAddressPrivacy?

    init(id: UUID = UUID(),
         ssid: String,
         password: String?,
         security: SecurityType = .wpa2wpa3,
         macPrivacy: MACAddressPrivacy = .off) {
        self.id = id
        self.ssid = ssid
        self.password = password
        self.security = security
        self.macPrivacy = macPrivacy
    }
}

// MARK: - QR text cho chuẩn WIFI:
extension WiFiNetwork {
    /// Chuỗi QR theo format: WIFI:T:<auth>;S:<ssid>;P:<password>;H:false;;
    var wifiQRString: String {
        let auth: String = {
            switch security {
            case .none: return "nopass"
            case .wep: return "WEP"
            default: return "WPA" // gộp WPA/WPA2/WPA3/Enterprise về WPA
            }
        }()

        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: ";", with: "\\;")
             .replacingOccurrences(of: ",", with: "\\,")
             .replacingOccurrences(of: ":", with: "\\:")
        }

        let s = escape(ssid)
        let p = escape(password ?? "")
        return "WIFI:T:\(auth);S:\(s);P:\(p);H:false;;"
    }
}
