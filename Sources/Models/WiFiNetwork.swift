import Foundation

enum SecurityType: String, Codable, CaseIterable, Identifiable {
    case none = "Không có"
    case wep = "WEP"
    case wpa = "WPA"
    case wpa2 = "WPA2"
    case wpa3 = "WPA3"
    case wpa2wpa3 = "WPA2/WPA3"
    case wpaEnterprise = "WPA Doanh nghiệp"
    case wpa2Enterprise = "WPA2 Doanh nghiệp"
    case wpa3Enterprise = "WPA3 Doanh nghiệp"

    var id: String { rawValue }
}

enum MACPolicy: String, Codable, CaseIterable, Identifiable {
    case off = "Tắt"
    case fixed = "Cố định"
    case random = "Luân chuyển"

    var id: String { rawValue }
}

struct WiFiNetwork: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var ssid: String
    var password: String?
    var security: SecurityType = .wpa2wpa3
    var macPolicy: MACPolicy = .off
}
