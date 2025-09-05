import Foundation

enum WiFiSecurity: String, CaseIterable, Codable, Identifiable {
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

enum PrivateAddressing: String, CaseIterable, Codable, Identifiable {
    case off = "Tắt"
    case fixed = "Cố định"
    case rotating = "Luân chuyển"

    var id: String { rawValue }
}

struct WiFiNetwork: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var ssid: String
    var password: String
    var security: WiFiSecurity = .wpa2wpa3
    var privateAddressing: PrivateAddressing = .off
}
