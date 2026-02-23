//
//  LocationManager.swift
//  Ollie-app
//
//  Wrapper for CLLocationManager with async/await support

import Foundation
import CoreLocation
import Combine

/// Service for handling location requests
@MainActor
class LocationManager: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isRequestingLocation = false
    @Published var lastError: Error?

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Request "When In Use" authorization
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Check if location services are authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// Check if authorization has been determined
    var authorizationDetermined: Bool {
        authorizationStatus != .notDetermined
    }

    /// Request a single location update
    func requestLocation() async throws -> CLLocation {
        // If we already have a recent location (< 30 seconds), use it
        if let location = currentLocation,
           Date().timeIntervalSince(location.timestamp) < 30 {
            return location
        }

        // Request authorization if needed
        if !authorizationDetermined {
            requestAuthorization()
            // Wait a moment for user to respond
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        guard isAuthorized else {
            throw LocationError.notAuthorized
        }

        isRequestingLocation = true
        lastError = nil

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    /// Get current coordinates if available
    var currentCoordinates: (latitude: Double, longitude: Double)? {
        guard let location = currentLocation else { return nil }
        return (location.coordinate.latitude, location.coordinate.longitude)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            currentLocation = location
            isRequestingLocation = false
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastError = error
            isRequestingLocation = false
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case notAuthorized
    case locationUnavailable
    case timeout

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return Strings.WalkLocations.locationNotAuthorized
        case .locationUnavailable:
            return Strings.WalkLocations.locationUnavailable
        case .timeout:
            return Strings.WalkLocations.locationTimeout
        }
    }
}
