import Foundation
import CoreLocation
import Combine

enum LocationAuthorizationStatus {
    case notDetermined
    case denied
    case restricted
    case authorized
}

protocol LocationProviding: AnyObject {
    var authorizationStatus: LocationAuthorizationStatus { get }
    var currentLocation: CLLocation? { get }
    var authorizationStatusPublisher: AnyPublisher<LocationAuthorizationStatus, Never> { get }
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    
    func requestAuthorization()
    func requestLocation()
}

final class CoreLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    
    @Published private var _authorizationStatus: LocationAuthorizationStatus = .notDetermined
    @Published private var _currentLocation: CLLocation?
    
    var authorizationStatus: LocationAuthorizationStatus { _authorizationStatus }
    var currentLocation: CLLocation? { _currentLocation }
    
    var authorizationStatusPublisher: AnyPublisher<LocationAuthorizationStatus, Never> {
        $_authorizationStatus.eraseToAnyPublisher()
    }
    
    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        $_currentLocation.eraseToAnyPublisher()
    }
    
    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        updateAuthorizationStatus(manager.authorizationStatus)
    }
    
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus(manager.authorizationStatus)
        if _authorizationStatus == .authorized {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        _currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Real-world: surface this to the view model for retry UX.
        // Keeping silent for now to avoid clobbering any last-known location.
    }
    
    private func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            _authorizationStatus = .notDetermined
        case .denied:
            _authorizationStatus = .denied
        case .restricted:
            _authorizationStatus = .restricted
        case .authorizedAlways, .authorizedWhenInUse:
            _authorizationStatus = .authorized
        @unknown default:
            _authorizationStatus = .notDetermined
        }
    }
}
