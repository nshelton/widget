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
    @State private var theme = WidgetTheme.load()
    @State private var showSettings = false

    private var granted: Bool {
        auth.status == .authorizedWhenInUse || auth.status == .authorizedAlways
    }

    private let widgetAspect: CGFloat = 360.0 / 170.0

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "sun.max.fill").foregroundStyle(.orange)
                Text("Today").font(.headline)
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "paintpalette").font(.title3)
                }
            }

            // Identical render of the widget canvas
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(theme.background.color)
                if let model {
                    if model.locationDenied {
                        Text("Enable location")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(theme.text.color)
                    } else {
                        DayChartView(model: model, now: Date(), theme: theme)
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
                Text("auth: \(statusName(auth.status))")
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
        .onChange(of: theme) { _, newTheme in
            newTheme.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(theme: $theme)
        }
    }

    private func statusName(_ s: CLAuthorizationStatus) -> String {
        switch s {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
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
