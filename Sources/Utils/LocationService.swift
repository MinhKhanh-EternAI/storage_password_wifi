import Foundation
import CoreLocation

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published var status: CLAuthorizationStatus = .notDetermined
    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
    }

    func ensureAuthorized() {
        status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
    }
}
