//
//  WalkTrackingService.swift
//  Otis-app
//
//  Service for GPS tracking during walks
//  Handles continuous location updates and route recording
//

import Combine
import CoreLocation
import Foundation
import OtisShared
import os

/// Service for tracking walks with GPS
@Observable
@MainActor
final class WalkTrackingService: NSObject {

    // MARK: - Observable State

    /// Current walk route being recorded
    var currentRoute: WalkRoute?

    /// Whether tracking is active
    var isTracking: Bool { currentRoute != nil }

    /// Current location during tracking
    var currentLocation: CLLocation?

    /// Authorization status
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Last error encountered
    var lastError: Error?

    /// Live distance in meters
    var liveDistanceMeters: Double {
        currentRoute?.calculateDistance() ?? 0
    }

    /// Live duration in seconds
    var liveDurationSeconds: TimeInterval {
        guard let route = currentRoute else { return 0 }
        return Date().timeIntervalSince(route.startTime)
    }

    // MARK: - Private

    @ObservationIgnored
    private let locationManager = CLLocationManager()

    @ObservationIgnored
    private let logger = Logger.otis(category: "WalkTracking")

    @ObservationIgnored
    private var lastRecordedLocation: CLLocation?

    /// Minimum distance between recorded points (meters)
    private let minimumDistanceFilter: CLLocationDistance = 5.0

    /// Minimum accuracy required for recording (meters)
    private let minimumAccuracy: CLLocationAccuracy = 50.0

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumDistanceFilter
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Authorization

    /// Request location authorization for walk tracking
    func requestAuthorization() {
        // Request "When In Use" first, then can upgrade to "Always" later
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse {
            // Could request "Always" for better background tracking
            // locationManager.requestAlwaysAuthorization()
        }
    }

    /// Whether we have sufficient authorization to track
    var canTrack: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    // MARK: - Tracking Control

    /// Start tracking a new walk
    /// - Parameter startTime: When the walk started (defaults to now)
    /// - Returns: The new route being tracked
    @discardableResult
    func startTracking(startTime: Date = Date()) -> WalkRoute {
        guard currentRoute == nil else {
            logger.warning("Attempted to start tracking while already tracking")
            return currentRoute!
        }

        let route = WalkRoute(startTime: startTime)
        currentRoute = route
        lastRecordedLocation = nil
        lastError = nil

        // Start location updates
        locationManager.startUpdatingLocation()

        logger.info("Started walk tracking")
        return route
    }

    /// Stop tracking and finalize the route
    /// - Returns: The completed route
    @discardableResult
    func stopTracking() -> WalkRoute? {
        guard var route = currentRoute else {
            logger.warning("Attempted to stop tracking while not tracking")
            return nil
        }

        // Stop location updates
        locationManager.stopUpdatingLocation()

        // Finalize the route
        route.finalize()

        // Clear state
        currentRoute = nil
        lastRecordedLocation = nil

        logger.info("Stopped walk tracking: \(route.coordinates.count) points, \(route.formattedDistance())")
        return route
    }

    /// Cancel tracking without saving
    func cancelTracking() {
        locationManager.stopUpdatingLocation()
        currentRoute = nil
        lastRecordedLocation = nil
        logger.info("Cancelled walk tracking")
    }

    // MARK: - Private Methods

    private func recordLocation(_ location: CLLocation) {
        guard var route = currentRoute else { return }

        // Filter out inaccurate locations
        guard location.horizontalAccuracy <= minimumAccuracy else {
            logger.debug("Skipping inaccurate location: \(location.horizontalAccuracy)m")
            return
        }

        // Filter out locations too close to last recorded
        if let lastLocation = lastRecordedLocation {
            let distance = location.distance(from: lastLocation)
            guard distance >= minimumDistanceFilter else {
                return
            }
        }

        // Record the location
        route.addLocation(location)
        currentRoute = route
        lastRecordedLocation = location
        currentLocation = location

        logger.debug("Recorded location: \(route.coordinates.count) points")
    }
}

// MARK: - CLLocationManagerDelegate

extension WalkTrackingService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for location in locations {
                recordLocation(location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            // Ignore location unknown errors - they're common and transient
            if let clError = error as? CLError, clError.code == .locationUnknown {
                logger.debug("Location temporarily unavailable")
                return
            }

            lastError = error
            logger.error("Location error: \(error.localizedDescription)")
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            logger.info("Authorization changed: \(String(describing: status))")

            // If we're tracking and lost authorization, stop
            if isTracking && !canTrack {
                logger.warning("Lost location authorization while tracking")
                _ = stopTracking()
            }
        }
    }
}

// MARK: - Convenience Extensions

extension WalkTrackingService {

    /// Formatted live distance (e.g., "1.2 km")
    var formattedLiveDistance: String {
        let km = liveDistanceMeters / 1000
        if km < 1 {
            return String(format: "%.0f m", liveDistanceMeters)
        }
        return String(format: "%.1f km", km)
    }

    /// Formatted live duration (e.g., "23:45")
    var formattedLiveDuration: String {
        let totalSeconds = Int(liveDurationSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted live duration with hours if needed (e.g., "1:23:45")
    var formattedLiveDurationLong: String {
        let totalSeconds = Int(liveDurationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Current coordinates as tuple
    var currentCoordinates: (latitude: Double, longitude: Double)? {
        guard let location = currentLocation else { return nil }
        return (location.coordinate.latitude, location.coordinate.longitude)
    }
}
