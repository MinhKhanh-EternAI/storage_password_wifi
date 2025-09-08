import Foundation
import CoreLocation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

final class CurrentWiFi: NSObject, CLLocationManagerDelegate {
    private let lm = CLLocationManager()

    // Giữ nguyên API cũ
    private var ssidWaiters: [(String?) -> Void] = []
    // API mới: trả SSID + BSSID
    private var currentWaiters: [((String?, String?)) -> Void] = []

    override init() {
        super.init()
        lm.delegate = self
    }

    // ===== API CŨ (giữ nguyên chữ ký)
    func fetchSSID(_ completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            self.ssidWaiters.append(completion)
            self.guardAndResolve()
        }
    }

    // ===== API MỚI: trả SSID + BSSID (ẩn dùng trong Form)
    func fetchCurrent(_ completion: @escaping (_ ssid: String?, _ bssid: String?) -> Void) {
        DispatchQueue.main.async {
            self.currentWaiters.append(completion)
            self.guardAndResolve()
        }
    }

    // MARK: - Core

    private func guardAndResolve() {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = lm.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        if status == .notDetermined {
            lm.requestWhenInUseAuthorization()
            return
        }
        resolve()
    }

    private func resolve() {
        // Ưu tiên iOS 14+: NEHotspotNetwork (có BSSID)
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { net in
                let ssid = net?.ssid
                let bssid = net?.bssid
                self.flush(ssid: ssid, bssid: bssid)
            }
            return
        }

        // Fallback: CNCopyCurrentNetworkInfo
        var ssid: String? = nil
        var bssid: String? = nil
        if let ifaces = CNCopySupportedInterfaces() as? [CFString] {
            for i in ifaces {
                if let info = CNCopyCurrentNetworkInfo(i) as? [String: AnyObject] {
                    if ssid == nil, let s = info[kCNNetworkInfoKeySSID as String] as? String { ssid = s }
                    if bssid == nil, let b = info[kCNNetworkInfoKeyBSSID as String] as? String { bssid = b }
                    if ssid != nil { break }
                }
            }
        }
        flush(ssid: ssid, bssid: bssid)
    }

    private func flush(ssid: String?, bssid: String?) {
        let ssidCbs = ssidWaiters; ssidWaiters.removeAll()
        ssidCbs.forEach { $0(ssid) }

        let curCbs = currentWaiters; currentWaiters.removeAll()
        curCbs.forEach { $0((ssid, bssid)) }
    }

    // iOS 14+
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        resolve()
    }

    // iOS < 14
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        resolve()
    }
}
