import Foundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

final class CurrentWiFi: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentSSID: String? = nil
    private let location = CLLocationManager()

    override init() {
        super.init()
        location.delegate = self
    }

    func requestAndFetch() {
        switch location.authorizationStatus {
        case .notDetermined: location.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: fetchSSID()
        default: currentSSID = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            fetchSSID()
        } else { currentSSID = nil }
    }

    private func fetchSSID() {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { [weak self] net in
                if let s = net?.ssid, !s.isEmpty {
                    DispatchQueue.main.async { self?.currentSSID = s }
                } else { self?.fetchWithCaptive() }
            }
        } else { fetchWithCaptive() }
    }

    private func fetchWithCaptive() {
        guard let ifs = CNCopySupportedInterfaces() as? [String] else {
            DispatchQueue.main.async { self.currentSSID = nil }; return
        }
        for ifname in ifs {
            if let dict = CNCopyCurrentNetworkInfo(ifname as CFString) as? [String: Any],
               let s = dict[kCNNetworkInfoKeySSID as String] as? String, !s.isEmpty {
                DispatchQueue.main.async { self.currentSSID = s }; return
            }
        }
        DispatchQueue.main.async { self.currentSSID = nil }
    }

    func connect(ssid: String, password: String?, security: WiFiNetwork.Security, joinOnce: Bool = false, completion: @escaping (Error?) -> Void) {
        // Enterprise không hỗ trợ qua API public
        if security.isEnterprise {
            completion(NSError(domain: "WiFi", code: -10, userInfo: [NSLocalizedDescriptionKey: "Không hỗ trợ kết nối mạng Doanh nghiệp."]))
            return
        }
        let conf: NEHotspotConfiguration
        switch security.configFlavor {
        case .open:
            conf = NEHotspotConfiguration(ssid: ssid)
        case .wep:
            conf = NEHotspotConfiguration(ssid: ssid, passphrase: password ?? "", isWEP: true)
        case .wpa:
            conf = NEHotspotConfiguration(ssid: ssid, passphrase: password ?? "", isWEP: false)
        }
        conf.joinOnce = joinOnce
        NEHotspotConfigurationManager.shared.apply(conf, completionHandler: completion)
    }
}
