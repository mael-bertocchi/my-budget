import CoreLocation
import MapKit

@MainActor
final class LocationProvider: NSObject {
    enum Failure: LocalizedError {
        case denied
        case unavailable

        var errorDescription: String? {
            switch self {
            case .denied: return "Location is off for My Budget. Turn it on in Settings."
            case .unavailable: return "Could not find where you are right now."
            }
        }
    }

    private let manager = CLLocationManager()
    private var authorizationWaiter: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var fixWaiter: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentPlaceName() async throws -> String {
        try await authorize()
        return try await placeName(at: try await coordinate())
    }

    private func authorize() async throws {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                authorizationWaiter = continuation
                manager.requestWhenInUseAuthorization()
            }
        }
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw Failure.denied
        }
    }

    private func coordinate() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            fixWaiter = continuation
            manager.requestLocation()
        }
    }

    private func placeName(at coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { throw Failure.unavailable }
        guard let item = try await request.mapItems.first, let name = Self.label(for: item) else {
            throw Failure.unavailable
        }
        return name
    }

    private static func label(for item: MKMapItem) -> String? {
        let city = item.addressRepresentations?.cityName
        guard let place = item.name ?? item.address?.shortAddress ?? city else { return nil }
        guard let city, city.caseInsensitiveCompare(place) != .orderedSame else { return place }
        return place + ", " + city
    }

    fileprivate func resume(authorization status: CLAuthorizationStatus) {
        guard status != .notDetermined, let waiter = authorizationWaiter else { return }
        authorizationWaiter = nil
        waiter.resume(returning: status)
    }

    fileprivate func resume(fix result: Result<CLLocationCoordinate2D, Error>) {
        guard let waiter = fixWaiter else { return }
        fixWaiter = nil
        waiter.resume(with: result)
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.resume(authorization: status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in self.resume(fix: .success(coordinate)) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.resume(fix: .failure(Failure.unavailable)) }
    }
}
