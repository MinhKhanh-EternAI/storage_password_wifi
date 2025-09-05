import Foundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

/// Quản lý SSID hiện tại + kết nối Wi-Fi bằng NEHotspotConfiguration.
final class CurrentWiFi: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var currentSSID: String? = nil

    private let location = CLLocationManager()

    override init() {
        super.init()
        location.delegate = self
    }

    // MARK: - Quyền + fetch SSID

    func requestAndFetch() {
        switch location.authorizationStatus {
        case .notDetermined:
            location.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            fetchSSID()
        default:
            currentSSID = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            fetchSSID()
        } else {
            currentSSID = nil
        }
    }

    private func fetchSSID() {
        // Ưu tiên NEHotspotNetwork (iOS 14+)
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { [weak self] net in
                if let s = net?.ssid, !s.isEmpty {
                    DispatchQueue.main.async { self?.currentSSID = s }
                } else {
                    self?.fetchWithCaptive()
                }
            }
        } else {
            fetchWithCaptive()
        }
    }

    private func fetchWithCaptive() {
        guard let ifs = CNCopySupportedInterfaces() as? [String] else {
            DispatchQueue.main.async { self.currentSSID = nil }; return
        }
        for ifname in ifs {
            if let dict = CNCopyCurrentNetworkInfo(ifname as CFString) as? [String: Any],
               let s = dict[kCNNetworkInfoKeySSID as String] as? String, !s.isEmpty {
                DispatchQueue.main.async { self.currentSSID = s }
                return
            }
        }
        DispatchQueue.main.async { self.currentSSID = nil }
    }

    // MARK: - Kết nối Wi-Fi (best effort)

    /// Kết nối tới SSID/password/security bằng NEHotspotConfiguration.
    func connect(ssid: String,
                 password: String?,
                 security: WiFiNetwork.Security,
                 joinOnce: Bool = false,
                 completion: @escaping (Error?) -> Void) {

        let conf: NEHotspotConfiguration
        switch security {
        case .open:
            conf = NEHotspotConfiguration(ssid: ssid)
        case .wep:
            // ✅ ĐÚNG: dùng passphrase + isWEP: true (không có init với nhãn `wep:`)
            conf = NEHotspotConfiguration(ssid: ssid,
                                          passphrase: password ?? "",
                                          isWEP: true)
        case .wpa, .wpa2, .wpa3:
            conf = NEHotspotConfiguration(ssid: ssid,
                                          passphrase: password ?? "",
                                          isWEP: false)
        }
        conf.joinOnce = joinOnce
        NEHotspotConfigurationManager.shared.apply(conf) { err in
            completion(err)
        }
    }
}
