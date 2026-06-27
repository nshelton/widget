import CoreLocation

struct LocatedPlace { let location: CLLocation; let city: String? }
enum LocationError: Error { case denied }

final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var cont: CheckedContinuation<CLLocation, Error>?

    func current() async throws -> LocatedPlace {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw LocationError.denied
        }
        let loc: CLLocation
        if let last = manager.location {
            loc = last
        } else {
            loc = try await withCheckedThrowingContinuation { c in
                self.cont = c
                manager.delegate = self
                manager.requestLocation()
            }
        }
        let city = try? await reverseGeocode(loc)
        return LocatedPlace(location: loc, city: city)
    }

    private func reverseGeocode(_ loc: CLLocation) async throws -> String? {
        let marks = try await CLGeocoder().reverseGeocodeLocation(loc)
        guard let p = marks.first else { return nil }
        let city = p.locality ?? p.administrativeArea
        if let city, let state = p.administrativeArea, city != state { return "\(city), \(state)" }
        return city
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        if let l = locs.last { cont?.resume(returning: l); cont = nil }
    }
    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        cont?.resume(throwing: error); cont = nil
    }
}
