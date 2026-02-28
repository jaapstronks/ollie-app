//
//  PlacesMapViewModel.swift
//  Ollie-app
//
//  ViewModel for the expanded places map with filter state
//

import SwiftUI
import MapKit
import OllieShared
import Combine

/// Unified marker type for the places map
enum PlaceMarker: Identifiable {
    case spot(WalkSpot)
    case discoveredSpot(DiscoveredSpot)
    case contact(DogContact)
    case photoCluster(PhotoCluster)

    var id: String {
        switch self {
        case .spot(let spot): return "spot-\(spot.id)"
        case .discoveredSpot(let spot): return "discovered-\(spot.id)"
        case .contact(let contact): return "contact-\(contact.id)"
        case .photoCluster(let cluster): return "photo-\(cluster.id)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .spot(let spot):
            return CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
        case .discoveredSpot(let spot):
            return CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
        case .contact(let contact):
            guard let lat = contact.latitude, let lon = contact.longitude else {
                return CLLocationCoordinate2D()
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        case .photoCluster(let cluster):
            return CLLocationCoordinate2D(latitude: cluster.latitude, longitude: cluster.longitude)
        }
    }

    var isFavorite: Bool {
        switch self {
        case .spot(let spot): return spot.isFavorite
        case .discoveredSpot: return false
        case .contact: return false
        case .photoCluster: return false
        }
    }
}

/// ViewModel for managing the expanded places map state
@MainActor
class PlacesMapViewModel: ObservableObject {

    // MARK: - Published State

    @Published var activeFilters: Set<PlacesFilterCategory> = [.spots, .discovered, .contacts, .photos]
    @Published var selectedContactTypes: Set<ContactType> = Set(ContactType.allCases)
    @Published var selectedSpotCategories: Set<SpotCategory> = Set(SpotCategory.allCases)

    @Published var selectedMarker: PlaceMarker?
    @Published var cameraPosition: MapCameraPosition = .automatic

    // MARK: - Dependencies

    private let spotStore: SpotStore
    private let contactStore: ContactStore
    private let momentsViewModel: MomentsViewModel
    let discoveryService: DogParkDiscoveryService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        spotStore: SpotStore,
        contactStore: ContactStore,
        momentsViewModel: MomentsViewModel
    ) {
        self.spotStore = spotStore
        self.contactStore = contactStore
        self.momentsViewModel = momentsViewModel
        self.discoveryService = DogParkDiscoveryService()
    }

    // MARK: - Computed Markers

    /// All visible markers based on current filters
    var visibleMarkers: [PlaceMarker] {
        var markers: [PlaceMarker] = []

        // Add spot markers
        if activeFilters.contains(.spots) {
            let filteredSpots = spotStore.spots.filter { spot in
                // Include spot if favorites filter is off, or if it's a favorite
                let passessFavoriteFilter = !activeFilters.contains(.favorites) || spot.isFavorite

                // Include spot if it matches a selected category, or has no category
                let passesCategoryFilter: Bool
                if let category = spot.category {
                    passesCategoryFilter = selectedSpotCategories.contains(category)
                } else {
                    // Spots without category show when "other" is selected
                    passesCategoryFilter = selectedSpotCategories.contains(.other)
                }

                return passessFavoriteFilter && passesCategoryFilter
            }
            markers.append(contentsOf: filteredSpots.map { .spot($0) })
        }

        // Add discovered dog park markers
        if activeFilters.contains(.discovered) {
            markers.append(contentsOf: discoveryService.discoveredSpots.map { .discoveredSpot($0) })
        }

        // Add contact markers (only those with location)
        if activeFilters.contains(.contacts) {
            let filteredContacts = contactStore.contacts.filter { contact in
                guard contact.hasLocation else { return false }
                return selectedContactTypes.contains(contact.contactType)
            }
            markers.append(contentsOf: filteredContacts.map { .contact($0) })
        }

        // Add photo cluster markers
        if activeFilters.contains(.photos) {
            let clusters = momentsViewModel.clusterPhotos()
            markers.append(contentsOf: clusters.map { .photoCluster($0) })
        }

        // If favorites filter is active, only show favorites
        if activeFilters.contains(.favorites) {
            markers = markers.filter { $0.isFavorite }
        }

        return markers
    }

    /// Contacts with locations for the map
    var contactsWithLocation: [DogContact] {
        contactStore.contacts.filter { $0.hasLocation }
    }

    // MARK: - Map Region

    /// Calculate the map region to fit all visible markers
    func fitMapToMarkers() {
        let markers = visibleMarkers
        guard !markers.isEmpty else {
            // Default to a region if no markers
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.9225, longitude: 4.4792),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
            return
        }

        let latitudes = markers.map { $0.coordinate.latitude }
        let longitudes = markers.map { $0.coordinate.longitude }

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = max(0.01, (maxLat - minLat) * 1.5)
        let spanLon = max(0.01, (maxLon - minLon) * 1.5)

        withAnimation(.easeInOut) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
            ))
        }
    }

    /// Center on user's current location
    func centerOnUserLocation() {
        withAnimation(.easeInOut) {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }

    // MARK: - Marker Selection

    func selectSpot(_ spot: WalkSpot) {
        selectedMarker = .spot(spot)
    }

    func selectContact(_ contact: DogContact) {
        selectedMarker = .contact(contact)
    }

    func selectCluster(_ cluster: PhotoCluster) {
        selectedMarker = .photoCluster(cluster)
    }

    func clearSelection() {
        selectedMarker = nil
    }

    // MARK: - Dog Park Discovery

    /// Discover dog parks near a location
    func discoverDogParksNearby(latitude: Double, longitude: Double) async {
        await discoveryService.discoverNearby(latitude: latitude, longitude: longitude, radiusKm: 5.0)
    }

    /// Discover dog parks in the current map bounds
    func discoverDogParksInBounds(south: Double, west: Double, north: Double, east: Double) async {
        await discoveryService.discoverInBounds(south: south, west: west, north: north, east: east)
    }

    func selectDiscoveredSpot(_ spot: DiscoveredSpot) {
        selectedMarker = .discoveredSpot(spot)
    }
}
