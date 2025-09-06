import Foundation
import CoreLocation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

final class CurrentWiFi: NSObject, CLLocationManagerDelegate {
    private let lm = CLLocationManager()
    private var waiters: [(String?) -> Void] = []

    override init() {
        super.init()
        lm.delegate = self
    }

    func fetchSSID(_ completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            self.waiters.append(completion)

            // Bỏ API deprecated: dùng instance property trên iOS 14+
            let status: CLAuthorizationStatus
            if #available(iOS 14.0, *) {
                status = self.lm.authorizationStatus
            } else {
                status = CLLocationManager.authorizationStatus()
            }

            if status == .notDetermined {
                self.lm.requestWhenInUseAuthorization()
                return
            }
            self.resolveSSID()
        }
    }

    private func resolveSSID() {
        var ssid: String? = nil
        if let ifaces = CNCopySupportedInterfaces() as? [CFString] {
            for i in ifaces {
                if let info = CNCopyCurrentNetworkInfo(i) as? [String: AnyObject],
                   let s = info[kCNNetworkInfoKeySSID as String] as? String {
                    ssid = s
                    break
                }
            }
        }
        let cbs = waiters; waiters.removeAll()
        cbs.forEach { $0(ssid) }
    }

    // iOS 14+ delegate mới (khuyến nghị)
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            resolveSSID()
        } else {
            resolveSSID() // trả nil -> UI hiển thị không khả dụng
        }
    }

    // ✅ Giữ delegate cũ cho iOS < 14
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            resolveSSID()
        } else {
            resolveSSID() // trả nil -> UI hiển thị không khả dụng
        }
    }
}
