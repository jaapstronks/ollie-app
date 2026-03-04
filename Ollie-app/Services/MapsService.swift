//
//  MapsService.swift
//  Otis-app
//
//  Service for opening locations in the user's preferred maps application

import Foundation
import MapKit
import UIKit

/// Service for opening locations in external maps applications
@MainActor
enum MapsService {

    // MARK: - Public API

    /// Open a location with coordinates in the preferred maps app
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    ///   - name: Optional name for the location
    static func openLocation(latitude: Double, longitude: Double, name: String? = nil) {
        let preference = currentPreference

        switch preference {
        case .googleMaps where preference.isAvailable:
            openInGoogleMaps(latitude: latitude, longitude: longitude, name: name)
        default:
            openInAppleMaps(latitude: latitude, longitude: longitude, name: name)
        }
    }

    /// Open an address in the preferred maps app
    /// - Parameter address: The address string to search for
    static func openAddress(_ address: String) {
        let preference = currentPreference

        switch preference {
        case .googleMaps where preference.isAvailable:
            openAddressInGoogleMaps(address)
        default:
            openAddressInAppleMaps(address)
        }
    }

    /// Open directions to a location in the preferred maps app
    /// - Parameters:
    ///   - latitude: Destination latitude
    ///   - longitude: Destination longitude
    ///   - name: Optional name for the destination
    static func openDirections(latitude: Double, longitude: Double, name: String? = nil) {
        let preference = currentPreference

        switch preference {
        case .googleMaps where preference.isAvailable:
            openDirectionsInGoogleMaps(latitude: latitude, longitude: longitude)
        default:
            openDirectionsInAppleMaps(latitude: latitude, longitude: longitude, name: name)
        }
    }

    // MARK: - Current Preference

    /// Get the current preferred maps app
    private static var currentPreference: PreferredMapsApp {
        let rawValue = UserDefaults.standard.string(forKey: UserPreferences.Key.preferredMapsApp.rawValue)
        return PreferredMapsApp(rawValue: rawValue ?? "") ?? .appleMaps
    }

    // MARK: - Apple Maps

    private static func openInAppleMaps(latitude: Double, longitude: Double, name: String?) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = name
        mapItem.openInMaps()
    }

    private static func openAddressInAppleMaps(_ address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?address=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private static func openDirectionsInAppleMaps(latitude: Double, longitude: Double, name: String?) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    // MARK: - Google Maps

    private static func openInGoogleMaps(latitude: Double, longitude: Double, name: String?) {
        var urlString = "comgooglemaps://?center=\(latitude),\(longitude)&q=\(latitude),\(longitude)"
        if let name = name?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString = "comgooglemaps://?q=\(name)&center=\(latitude),\(longitude)"
        }

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to Apple Maps if Google Maps fails
                    openInAppleMaps(latitude: latitude, longitude: longitude, name: name)
                }
            }
        }
    }

    private static func openAddressInGoogleMaps(_ address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "comgooglemaps://?q=\(encoded)") {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to Apple Maps if Google Maps fails
                    openAddressInAppleMaps(address)
                }
            }
        }
    }

    private static func openDirectionsInGoogleMaps(latitude: Double, longitude: Double) {
        let urlString = "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=driving"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to Apple Maps if Google Maps fails
                    openDirectionsInAppleMaps(latitude: latitude, longitude: longitude, name: nil)
                }
            }
        }
    }
}
