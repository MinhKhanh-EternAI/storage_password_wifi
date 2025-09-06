import Foundation

enum SecurityType: String, Codable, CaseIterable, Identifiable {
    case none
    case wep
    case wpa
    case wpa2Wpa3
    case wpa3
    case wpaEnterprise
    case wpa2Enterprise
    case wpa3Enterprise

    var id: String { rawValue }

    var displayName: String {
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

    var qrAuthToken: String? {
        switch self {
        case .none: return "nopass"
        case .wep: return "WEP"
        case .wpa, .wpa2Wpa3, .wpa3: return "WPA"
        case .wpaEnterprise, .wpa2Enterprise, .wpa3Enterprise: return "WPA"
        }
    }
}

enum AddressPrivacy: String, Codable, CaseIterable, Identifiable {
    case off
    case fixed
    case rotating

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .off: return "Tắt"
        case .fixed: return "Cố định"
        case .rotating: return "Luân chuyển"
        }
    }
}

struct WiFiNetwork: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ssid: String
    var password: String?
    var security: SecurityType
    var addressPrivacy: AddressPrivacy

    init(id: UUID = UUID(),
         ssid: String,
         password: String?,
         security: SecurityType = .wpa2Wpa3,
         addressPrivacy: AddressPrivacy = .off) {
        self.id = id
        self.ssid = ssid
        self.password = password
        self.security = security
        self.addressPrivacy = addressPrivacy
    }
}
