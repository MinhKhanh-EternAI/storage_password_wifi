import Foundation

/// Mẫu dữ liệu cho 1 mạng Wi-Fi
struct WiFiNetwork: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var ssid: String
    var password: String
    var security: Security = .wpa2
    var note: String? = nil
    var createdAt: Date = .init()
    var updatedAt: Date = .init()

    enum Security: String, Codable, CaseIterable, Identifiable {
        case open = "Open", wep = "WEP", wpa = "WPA", wpa2 = "WPA2", wpa3 = "WPA3"
        var id: String { rawValue }
    }
}

/// QR theo chuẩn: WIFI:T:WPA;S:MySSID;P:mypass;;
extension WiFiNetwork {
    var qrPayload: String {
        let t: String
        switch security {
        case .open: t = "nopass"
        case .wep:  t = "WEP"
        case .wpa, .wpa2: t = "WPA"
        case .wpa3: t = "WPA3"
        }
        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: ";", with: "\\;")
             .replacingOccurrences(of: ",", with: "\\,")
             .replacingOccurrences(of: ":", with: "\\:")
             .replacingOccurrences(of: "\"", with: "\\\"")
        }
        var parts = ["WIFI", "T:\(t)", "S:\(esc(ssid))"]
        if security != .open { parts.append("P:\(esc(password))") }
        return parts.joined(separator: ";") + ";;"
    }
}
