//
//  PlacesMapViewModel.swift
//  Otis-app
//
//  ViewModel for the expanded places map with filter state
//

import SwiftUI
import MapKit
import OtisShared
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

}

/// ViewModel for managing the expanded places map state
@Observable
@MainActor
class PlacesMapViewModel {

    // MARK: - State

    var activeFilters: Set<PlacesFilterCategory> = [.spots, .discovered, .contacts, .photos] {
        didSet { rebuildVisibleMarkers() }
    }
    var selectedContactTypes: Set<ContactType> = Set(ContactType.allCases) {
        didSet { rebuildVisibleMarkers() }
    }
    var selectedSpotCategories: Set<SpotCategory> = Set(SpotCategory.allCases) {
        didSet { rebuildVisibleMarkers() }
    }
    var selectedDiscoveryTypes: Set<DiscoverablePlaceType> = Set(DiscoverablePlaceType.allCases) {
        didSet { rebuildVisibleMarkers() }
    }

    var selectedMarker: PlaceMarker?
    var cameraPosition: MapCameraPosition = .automatic
    private(set) var visibleMarkers: [PlaceMarker] = []

    // MARK: - Dependencies

    @ObservationIgnored private let spotStore: SpotStore
    @ObservationIgnored private let contactStore: ContactStore
    @ObservationIgnored private let momentsViewModel: MomentsViewModel
    @ObservationIgnored let discoveryService: DogParkDiscoveryService
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

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

        // Rebuild markers when underlying sources change.
        // Note: SpotStore and ContactStore are @Observable via CRUDStore, so we use notifications
        NotificationCenter.default.publisher(for: .crudStoreItemsDidChange)
            .filter { notification in
                guard let identifier = notification.userInfo?["storeIdentifier"] as? String else { return false }
                return identifier.contains("SpotStore") || identifier.contains("ContactStore")
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildVisibleMarkers()
            }
            .store(in: &cancellables)

        // DogParkDiscoveryService is @Observable, use observation tracking
        observeDiscoveryService()

        // MomentsViewModel is @Observable, use notification pattern
        // Note: MomentsViewModel updates cachedPhotoClusters internally when events change
        NotificationCenter.default.publisher(for: .eventsDidChange)
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildVisibleMarkers()
            }
            .store(in: &cancellables)

        rebuildVisibleMarkers()
    }

    /// Observe DogParkDiscoveryService changes using Swift Observation framework
    private func observeDiscoveryService() {
        withObservationTracking {
            _ = discoveryService.discoveredSpots
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.rebuildVisibleMarkers()
                self?.observeDiscoveryService()
            }
        }
    }

    // MARK: - Markers

    /// Rebuild markers based on current filters and source data.
    private func rebuildVisibleMarkers() {
        var markers: [PlaceMarker] = []

        // Add spot markers
        if activeFilters.contains(.spots) {
            let filteredSpots = spotStore.spots.filter { spot in
                // Include spot if it matches a selected category, or has no category
                let passesCategoryFilter: Bool
                if let category = spot.category {
                    passesCategoryFilter = selectedSpotCategories.contains(category)
                } else {
                    // Spots without category show when "other" is selected
                    passesCategoryFilter = selectedSpotCategories.contains(.other)
                }

                return passesCategoryFilter
            }
            markers.append(contentsOf: filteredSpots.map { .spot($0) })
        }

        // Add discovered markers (filtered by selected discovery types)
        if activeFilters.contains(.discovered) {
            let filteredDiscovered = discoveryService.discoveredSpots.filter { spot in
                // Check if this spot's category matches any of the selected discovery types
                for type in selectedDiscoveryTypes {
                    switch type {
                    case .dogParks:
                        if [.dogPark, .offLeashArea, .dogBeach, .dogForest, .dogFriendlyPark].contains(spot.category) {
                            return true
                        }
                    case .vetClinics:
                        if spot.category == .vetClinic {
                            return true
                        }
                    case .petStores:
                        if spot.category == .petStore {
                            return true
                        }
                    case .dogFriendlyPlaces:
                        if spot.category == .dogFriendlyCafe {
                            return true
                        }
                    }
                }
                return false
            }
            markers.append(contentsOf: filteredDiscovered.map { .discoveredSpot($0) })
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
            let clusters = momentsViewModel.cachedPhotoClusters
            markers.append(contentsOf: clusters.map { .photoCluster($0) })
        }

        visibleMarkers = markers
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

    // MARK: - Camera Positioning for Sheet Presentation

    /// Pan the map so the given coordinate appears in the upper portion of the screen,
    /// leaving room for a sheet to appear below without obscuring the location.
    /// - Parameter coordinate: The location to keep visible above the sheet
    func panForSheetPresentation(coordinate: CLLocationCoordinate2D) {
        // Get current span from camera position, or use a reasonable default
        let currentSpan = currentMapSpan

        // Offset the center southward so the pin appears in the upper third.
        // A medium sheet covers ~50% of the screen, so we shift down by ~30% of the visible span.
        let latitudeOffset = currentSpan.latitudeDelta * 0.3
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: coordinate.latitude - latitudeOffset,
            longitude: coordinate.longitude
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: adjustedCenter,
                span: currentSpan
            ))
        }
    }

    /// Extract the current map span from the camera position
    private var currentMapSpan: MKCoordinateSpan {
        // Try to get region from the current position using region property
        cameraPosition.region?.span ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    }

    // MARK: - Place Discovery

    /// Discover places near a location based on selected place types
    func discoverPlacesNearby(latitude: Double, longitude: Double) async {
        // Sync selected types to the service
        discoveryService.activePlaceTypes = selectedDiscoveryTypes
        // Discover all active types
        await discoveryService.discoverAllActiveTypes(latitude: latitude, longitude: longitude)
    }

    /// Discover dog parks near a location (legacy method for backwards compatibility)
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

    /// Refresh discovery with current selected types
    func refreshDiscovery(latitude: Double, longitude: Double) async {
        discoveryService.activePlaceTypes = selectedDiscoveryTypes
        await discoveryService.discoverAllActiveTypes(latitude: latitude, longitude: longitude)
    }
}
