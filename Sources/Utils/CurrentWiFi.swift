import Foundation
import NetworkExtension

struct CurrentWiFi {
    static func ssid() -> String? {
        // Không có API công khai để lấy SSID trên iOS 16+ nếu không dùng API private.
        // Trả về nil hoặc sử dụng NEHotspotConfiguration error fallback.
        return nil
    }

    @MainActor
    static func connect(ssid: String, password: String?, isWEP: Bool = false) async throws {
        // Chỉ hoạt động khi app KÝ với entitlement HotspotConfiguration
        var config: NEHotspotConfiguration
        if let pwd = password, !pwd.isEmpty {
            config = NEHotspotConfiguration(ssid: ssid, passphrase: pwd, isWEP: isWEP)
        } else {
            config = NEHotspotConfiguration(ssid: ssid)
        }
        config.joinOnce = false
        try await NEHotspotConfigurationManager.shared.apply(config)
    }
}
