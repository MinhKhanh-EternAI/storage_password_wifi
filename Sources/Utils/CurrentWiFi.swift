import Foundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork

final class CurrentWiFi: NSObject, CLLocationManagerDelegate {
    static let shared = CurrentWiFi()
    private let location = CLLocationManager()
    private var cont: CheckedContinuation<Bool, Never>?

    private override init() {
        super.init()
        location.delegate = self
    }

    // Yêu cầu quyền vị trí nếu cần
    private func ensureLocation() async -> Bool {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        case .notDetermined:
            return await withCheckedContinuation { c in
                cont = c
                location.requestWhenInUseAuthorization()
            }
        default:
            return false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if let c = cont {
            cont = nil
            let ok = (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                      CLLocationManager.authorizationStatus() == .authorizedAlways)
            c.resume(returning: ok)
        }
    }

    // Đọc SSID hiện tại (trả về nil nếu không đủ quyền/entitlement)
    static func currentSSID() async -> String? {
        let ok = await CurrentWiFi.shared.ensureLocation()
        guard ok else { return nil }

        guard let ifs = CNCopySupportedInterfaces() as? [String] else { return nil }
        for iface in ifs {
            if let dict = CNCopyCurrentNetworkInfo(iface as CFString) as? [String: Any],
               let ssid = dict[kCNNetworkInfoKeySSID as String] as? String {
                return ssid
            }
        }
        return nil
    }
}
