import Foundation

// MARK: - Kiểu bảo mật
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

// MARK: - Chính sách địa chỉ MAC
enum MACAddressPrivacy: String, CaseIterable, Codable, Identifiable {
    case off = "Tắt"
    case fixed = "Cố định"
    case rotating = "Luân chuyển"

    var id: String { rawValue }
}

// MARK: - Mô hình mạng Wi-Fi
struct WiFiNetwork: Identifiable, Codable, Equatable {
    var id: UUID
    var ssid: String
    var password: String?
    var security: SecurityType
    /// Chính sách địa chỉ MAC (random hóa MAC). Mặc định .off để tương thích JSON cũ.
    var macPrivacy: MACAddressPrivacy
    /// NEW: BSSID (ẩn ở form thêm, chỉ hiển thị ở chi tiết)
    var bssid: String?

    // Init thuận tiện cho code nội bộ
    init(
        id: UUID = UUID(),
        ssid: String,
        password: String?,
        security: SecurityType = .wpa2wpa3,
        macPrivacy: MACAddressPrivacy = .off,
        bssid: String? = nil
    ) {
        self.id = id
        self.ssid = ssid
        self.password = password
        self.security = security
        self.macPrivacy = macPrivacy
        self.bssid = bssid
    }

    // MARK: - Decodable tùy biến để không vỡ dữ liệu JSON cũ
    private enum CodingKeys: String, CodingKey {
        case id, ssid, password, security, macPrivacy, bssid
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.ssid = try c.decodeIfPresent(String.self, forKey: .ssid) ?? ""
        self.password = try c.decodeIfPresent(String.self, forKey: .password)
        self.security = try c.decodeIfPresent(SecurityType.self, forKey: .security) ?? .wpa2wpa3
        self.macPrivacy = try c.decodeIfPresent(MACAddressPrivacy.self, forKey: .macPrivacy) ?? .off
        self.bssid = try c.decodeIfPresent(String.self, forKey: .bssid) // JSON cũ không có -> nil
    }
}

// MARK: - QR text chuẩn WIFI:
extension WiFiNetwork {
    /// Chuỗi QR theo format: WIFI:T:<auth>;S:<ssid>;P:<password>;H:false;;
    var wifiQRString: String {
        let auth: String = {
            switch security {
            case .none: return "nopass"
            case .wep:  return "WEP"
            default:    return "WPA" // gộp WPA/WPA2/WPA3/Enterprise về WPA
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
