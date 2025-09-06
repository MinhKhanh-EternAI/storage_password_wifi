import Foundation
import CoreLocation
import NetworkExtension

final class CurrentWiFi: NSObject, CLLocationManagerDelegate {
    private let location = CLLocationManager()
    private var completion: ((String?) -> Void)?

    func fetchSSID(_ completion: @escaping (String?) -> Void) {
        self.completion = completion

        switch location.authorizationStatus {
        case .notDetermined:
            location.delegate = self
            location.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            readSSID()
        default:
            completion(nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            readSSID()
        } else {
            completion?(nil)
            completion = nil
        }
    }

    private func readSSID() {
        // NEHotspotNetwork.fetchCurrent hoạt động nếu app có quyền phù hợp.
        NEHotspotNetwork.fetchCurrent { network in
            DispatchQueue.main.async {
                self.completion?(network?.ssid)
                self.completion = nil
            }
        }
    }
}
