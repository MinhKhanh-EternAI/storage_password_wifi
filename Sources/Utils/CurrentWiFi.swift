import Foundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork

/// Helper lấy SSID hiện tại (chạy trên thiết bị thật, iOS 13+ cần quyền Location)
enum CurrentWiFi {
    static func currentSSID() async -> String? {
        let auth = await ensureLocationAuthorized()
        guard auth else { return nil }

        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        for iface in interfaces {
            if let info = CNCopyCurrentNetworkInfo(iface as CFString) as? [String: AnyObject],
               let ssid = info[kCNNetworkInfoKeySSID as String] as? String {
                return ssid
            }
        }
        return nil
    }

    // MARK: - Location permission (đơn giản)
    private static func ensureLocationAuthorized() async -> Bool {
        class Delegate: NSObject, CLLocationManagerDelegate {
            var continuation: CheckedContinuation<CLAuthorizationStatus, Never>?
            func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
                continuation?.resume(returning: manager.authorizationStatus)
                continuation = nil
            }
        }

        let manager = CLLocationManager()
        let status = manager.authorizationStatus

        if status == .authorizedWhenInUse || status == .authorizedAlways { return true }
        if status == .denied || status == .restricted { return false }

        let delegate = Delegate()
        manager.delegate = delegate
        manager.requestWhenInUseAuthorization()

        let newStatus = await withCheckedContinuation { (cc: CheckedContinuation<CLAuthorizationStatus, Never>) in
            delegate.continuation = cc
        }
        return newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways
    }
}
