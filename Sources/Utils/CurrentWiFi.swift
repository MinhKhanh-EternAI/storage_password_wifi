import Foundation
import SystemConfiguration.CaptiveNetwork
import CoreLocation

class CurrentWiFi: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var ssid: String? = nil
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        refresh()
    }

    func refresh() {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse else {
            ssid = nil
            return
        }
        if let ifaces = CNCopySupportedInterfaces() as? [String] {
            for i in ifaces {
                if let info = CNCopyCurrentNetworkInfo(i as CFString) as? [String: AnyObject],
                   let s = info[kCNNetworkInfoKeySSID as String] as? String {
                    ssid = s
                    return
                }
            }
        }
        ssid = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refresh()
    }
}
