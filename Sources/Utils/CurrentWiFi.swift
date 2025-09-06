import Foundation
import CoreLocation
import NetworkExtension

enum CurrentWiFi {
    /// Lấy SSID hiện tại (nếu có quyền). iOS 14+: ưu tiên NEHotspotNetwork, fallback CaptiveNetwork.
    static func fetchSSID() async -> String? {
        if #available(iOS 14.0, *) {
            if let n = await fetchSSIDByNEHotspot() { return n }
        }
        return fetchSSIDByCaptiveNetwork()
    }

    @available(iOS 14.0, *)
    private static func fetchSSIDByNEHotspot() async -> String? {
        await withCheckedContinuation { c in
            NEHotspotNetwork.fetchCurrent { net in
                c.resume(returning: net?.ssid)
            }
        }
    }

    private static func fetchSSIDByCaptiveNetwork() -> String? {
        let s = CLLocationManager.authorizationStatus()
        guard s == .authorizedWhenInUse || s == .authorizedAlways else { return nil }

        // Dùng CaptiveNetwork làm fallback (mặc dù deprecated).
        // Nếu bạn đã bỏ import CaptiveNetwork trong repo, giữ nguyên phần NEHotspotNetwork là đủ.
        if let ifaces = CNCopySupportedInterfaces() as? [String] {
            for i in ifaces {
                if let info = CNCopyCurrentNetworkInfo(i as CFString) as? [String: AnyObject],
                   let ssid = info[kCNNetworkInfoKeySSID as String] as? String {
                    return ssid
                }
            }
        }
        return nil
    }
}
