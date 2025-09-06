import Foundation

enum SecurityType: String, Codable, CaseIterable, Identifiable {
    case none
    case wpa2wpa3   // thêm để khớp với chỗ gọi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Mở (Không mật khẩu)"
        case .wpa2wpa3: return "WPA2/WPA3"
        }
    }
}

struct WiFiNetwork: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ssid: String
    var password: String?
    var security: SecurityType

    init(id: UUID = UUID(), ssid: String, password: String?, security: SecurityType) {
        self.id = id
        self.ssid = ssid
        self.password = password
        self.security = security
    }
}
