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
            let st = CLLocationManager.authorizationStatus()
            if st == .notDetermined {
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

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        // Khi user vừa cấp quyền, lấy lại SSID
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            resolveSSID()
        } else {
            resolveSSID() // sẽ trả nil -> UI hiển thị trạng thái không khả dụng
        }
    }
}