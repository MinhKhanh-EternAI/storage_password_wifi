import Foundation

/// Kiểu bảo mật Wi-Fi (đã Việt hoá)
enum SecurityType: String, Codable, CaseIterable, Identifiable, Hashable {
    case none            = "none"              // Không có
    case wep             = "wep"               // WEP
    case wpa             = "wpa"               // WPA
    case wpa2Wpa3        = "wpa2_wpa3"         // WPA2/WPA3 (mặc định)
    case wpa3            = "wpa3"              // WPA3
    case wpaEnterprise   = "wpa_enterprise"    // WPA Doanh nghiệp
    case wpa2Enterprise  = "wpa2_enterprise"   // WPA2 Doanh nghiệp
    case wpa3Enterprise  = "wpa3_enterprise"   // WPA3 Doanh nghiệp

    var id: String { rawValue }

    /// Tên hiển thị tiếng Việt
    var displayName: String {
        switch self {
        case .none:            return "Không có"
        case .wep:             return "WEP"
        case .wpa:             return "WPA"
        case .wpa2Wpa3:        return "WPA2/WPA3"
        case .wpa3:            return "WPA3"
        case .wpaEnterprise:   return "WPA Doanh nghiệp"
        case .wpa2Enterprise:  return "WPA2 Doanh nghiệp"
        case .wpa3Enterprise:  return "WPA3 Doanh nghiệp"
        }
    }

    /// Dùng cho QR (chuẩn WIFI:…)
    var qrAuthToken: String? {
        switch self {
        case .none:            return nil
        case .wep:             return "WEP"
        case .wpa, .wpa2Wpa3:  return "WPA"
        case .wpa3:            return "WPA3"
        case .wpaEnterprise,
             .wpa2Enterprise,
             .wpa3Enterprise:  return "WPA" // enterprise không chuẩn hoá trong QR phổ biến—để WPA
        }
    }
}

/// Tuỳ chọn “Địa chỉ Wi-Fi bảo mật”
enum AddressPrivacy: String, Codable, CaseIterable, Identifiable, Hashable {
    case off       = "off"        // Tắt
    case fixed     = "fixed"      // Cố định
    case rotating  = "rotating"   // Luân chuyển

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off:      return "Tắt"
        case .fixed:    return "Cố định"
        case .rotating: return "Luân chuyển"
        }
    }
}

/// Model Wi-Fi (Hashable để dùng với NavigationLink(value:) & navigationDestination)
struct WiFiNetwork: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var ssid: String
    var password: String?
    var security: SecurityType
    var addressPrivacy: AddressPrivacy

    init(
        id: UUID = UUID(),
        ssid: String,
        password: String? = nil,
        security: SecurityType = .wpa2Wpa3,          // mặc định theo yêu cầu
        addressPrivacy: AddressPrivacy = .off        // mặc định Tắt
    ) {
        self.id = id
        self.ssid = ssid
        self.password = password
        self.security = security
        self.addressPrivacy = addressPrivacy
    }
}
