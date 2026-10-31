import CoreLocation
import Foundation

/// Measures GPS distance during a workout, including while the screen is locked.
@MainActor
final class LocationTracker: NSObject, CLLocationManagerDelegate {
    /// Fixes less accurate than this (meters) are ignored.
    private static let maxHorizontalAccuracy: CLLocationAccuracy = 25
    /// Jumps faster than this (m/s, about 43 km/h) aren't plausible on foot and are treated as GPS noise.
    private static let maxPlausibleSpeed: Double = 12

    private let manager = CLLocationManager()
    private(set) var distance: CLLocationDistance = 0
    private(set) var hasFix = false
    private(set) var isTracking = false
    private var wantsTracking = false
    private var isPaused = false
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
    }

    var isAuthorized: Bool {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return true
        default: return false
        }
    }

    var isDenied: Bool {
        switch manager.authorizationStatus {
        case .denied, .restricted: return true
        default: return false
        }
    }

    func start() {
        distance = 0
        hasFix = false
        lastLocation = nil
        isPaused = false
        wantsTracking = true
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        beginUpdatesIfPossible()
    }

    func pause() {
        isPaused = true
        lastLocation = nil
    }

    func resume() {
        isPaused = false
    }

    func stop() {
        wantsTracking = false
        guard isTracking else { return }
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        isTracking = false
    }

    private func beginUpdatesIfPossible() {
        guard wantsTracking, !isTracking, isAuthorized else { return }
        // Requires the "location" background mode, which is declared in Info.plist.
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
        isTracking = true
    }

    private func handle(_ locations: [CLLocation]) {
        guard isTracking, !isPaused else { return }
        for location in locations {
            guard location.horizontalAccuracy >= 0,
                  location.horizontalAccuracy <= Self.maxHorizontalAccuracy,
                  abs(location.timestamp.timeIntervalSinceNow) < 15 else { continue }
            hasFix = true
            if let last = lastLocation {
                let delta = location.distance(from: last)
                let seconds = location.timestamp.timeIntervalSince(last.timestamp)
                if seconds > 0, delta / seconds < Self.maxPlausibleSpeed {
                    distance += delta
                }
            }
            lastLocation = location
        }
    }

    // MARK: CLLocationManagerDelegate
    // The manager is created on the main thread, so it calls back on the main thread.

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            handle(locations)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            beginUpdatesIfPossible()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Transient failures (e.g. no signal indoors) are expected; distance falls back to the pedometer.
    }
}
