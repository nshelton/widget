import SwiftUI
import CoreLocation
import WidgetKit
import UIKit
import Combine

final class LocationAuth: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var status: CLAuthorizationStatus

    override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func request() {
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation() // prime a fix so the widget has a location to read
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        WidgetCenter.shared.reloadAllTimelines()
    }
    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {}
}

struct ContentView: View {
    @StateObject private var auth = LocationAuth()

    private var granted: Bool {
        auth.status == .authorizedWhenInUse || auth.status == .authorizedAlways
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Daytime Widget")
                .font(.headline)
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if granted {
                Button("Refresh Widget") { WidgetCenter.shared.reloadAllTimelines() }
                    .buttonStyle(.bordered)
            } else {
                Button(auth.status == .notDetermined ? "Allow Location" : "Open Settings") {
                    auth.request()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
    }

    private var statusText: String {
        switch auth.status {
        case .notDetermined:
            return "Allow location so the widget can show the sun arc and weather for where you are."
        case .denied, .restricted:
            return "Location is off. Turn it on in Settings → SheltronWidgets → Location → While Using the App."
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location granted. Your home-screen widget will update shortly."
        @unknown default:
            return ""
        }
    }
}

#Preview {
    ContentView()
}
