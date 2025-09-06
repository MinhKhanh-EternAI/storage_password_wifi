import Foundation

enum CurrentWiFi {
    /// Trả về SSID hiện tại (stub để build — nếu có entitlement bạn có thể thay thế)
    static func currentSSID() async -> String? {
        // TODO: thay bằng API/NEHotspotNetwork nếu có entitlement
        return nil
    }
}
