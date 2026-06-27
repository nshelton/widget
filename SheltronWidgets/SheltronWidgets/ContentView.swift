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
            manager.requestLocation()
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
    @State private var model: DayModel?
    @State private var lastUpdate: Date?
    @State private var loading = false

    private var granted: Bool {
        auth.status == .authorizedWhenInUse || auth.status == .authorizedAlways
    }

    // Medium-widget aspect ratio so this matches what's on the home screen.
    private let widgetAspect: CGFloat = 360.0 / 170.0

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "sun.max.fill").foregroundStyle(.orange)
                Text("Daytime").font(.headline)
            }

            // Identical render of the widget canvas
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(.black)
                if let model {
                    if model.locationDenied {
                        Text("Enable location")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        DayChartView(model: model, now: Date())
                    }
                } else {
                    ProgressView().tint(.white)
                }
            }
            .aspectRatio(widgetAspect, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.08)))

            Button {
                refresh()
            } label: {
                Label(loading ? "Updating…" : "Update", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading)

            if !granted {
                Button(auth.status == .notDetermined ? "Allow Location" : "Open Settings in iOS") {
                    auth.request()
                }
                .buttonStyle(.bordered)
            }

            VStack(spacing: 2) {
                Text(model?.city ?? "—")
                if let lastUpdate {
                    Text("updated \(lastUpdate.formatted(date: .omitted, time: .standard))")
                }
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
        .onAppear {
            if auth.status == .notDetermined { auth.request() }
            refresh()
        }
        .onChange(of: auth.status) { _, _ in refresh() }
    }

    private func refresh() {
        loading = true
        Task {
            let m = await DayModelBuilder.build(now: Date())
            await MainActor.run {
                self.model = m
                self.lastUpdate = Date()
                self.loading = false
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

#Preview {
    ContentView()
}
