import Foundation

enum WiFiSecurity: String, Codable, CaseIterable, Equatable {
    case none, wep, wpa, wpa2Wpa3, wpa3, wpaEnterprise, wpa2Enterprise, wpa3Enterprise

    var display: String {
        switch self {
        case .none: return "Không có"
        case .wep: return "WEP"
        case .wpa: return "WPA"
        case .wpa2Wpa3: return "WPA2/WPA3"
        case .wpa3: return "WPA3"
        case .wpaEnterprise: return "WPA Doanh nghiệp"
        case .wpa2Enterprise: return "WPA2 Doanh nghiệp"
        case .wpa3Enterprise: return "WPA3 Doanh nghiệp"
        }
    }

    var qrType: String {
        switch self {
        case .none: return "nopass"
        case .wep: return "WEP"
        default: return "WPA"
        }
    }
}

enum PrivateAddress: String, Codable, CaseIterable, Equatable {
    case off, fixed, rotating
    var display: String {
        switch self {
        case .off: return "Tắt"
        case .fixed: return "Cố định"
        case .rotating: return "Luân chuyển"
        }
    }
}

struct WiFiNetwork: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var ssid: String = ""
    var password: String = ""
    var security: WiFiSecurity = .wpa2Wpa3
    var privateAddress: PrivateAddress = .off

    var wifiQRString: String {
        let escSsid = ssid.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: ";", with: "\\;")
        let escPass = password.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: ";", with: "\\;")
        let passPart = security == .none ? "" : "P:\(escPass);"
        return "WIFI:T:\(security.qrType);S:\(escSsid);\(passPart)H:false;;"
    }
}
