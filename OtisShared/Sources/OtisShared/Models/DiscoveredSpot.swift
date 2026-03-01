//
//  DiscoveredSpot.swift
//  OtisShared
//
//  A dog park or dog-friendly location discovered from external data sources.
//  These are read-only spots that can be saved to the user's WalkSpot collection.
//

import Foundation

/// A dog park discovered from external open data sources
public struct DiscoveredSpot: Codable, Identifiable, Equatable, Sendable {
    public var id: String  // Source-specific ID (e.g., "osm:way:123456")
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var source: DiscoveredSpotSource
    public var sourceId: String  // Original ID from source (e.g., "123456")
    public var category: DiscoveredSpotCategory
    public var address: String?
    public var amenities: [String]
    public var isFenced: Bool?
    public var surface: String?
    public var fetchedAt: Date

    public init(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        source: DiscoveredSpotSource,
        sourceId: String,
        category: DiscoveredSpotCategory = .dogPark,
        address: String? = nil,
        amenities: [String] = [],
        isFenced: Bool? = nil,
        surface: String? = nil,
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.source = source
        self.sourceId = sourceId
        self.category = category
        self.address = address
        self.amenities = amenities
        self.isFenced = isFenced
        self.surface = surface
        self.fetchedAt = fetchedAt
    }
}

/// Data source for discovered spots
public enum DiscoveredSpotSource: String, Codable, CaseIterable, Sendable {
    case openStreetMap = "osm"
    case governmentNL = "gov_nl"
    case governmentDE = "gov_de"
    case governmentUS = "gov_us"
    case governmentAU = "gov_au"
    case governmentUK = "gov_uk"

    public var displayName: String {
        switch self {
        case .openStreetMap: return "OpenStreetMap"
        case .governmentNL: return "Overheid.nl"
        case .governmentDE: return "GovData.de"
        case .governmentUS: return "Data.gov"
        case .governmentAU: return "data.gov.au"
        case .governmentUK: return "data.gov.uk"
        }
    }

    public var attribution: String {
        switch self {
        case .openStreetMap:
            return "Data © OpenStreetMap contributors"
        case .governmentNL:
            return "Data: Overheid.nl (CC0)"
        case .governmentDE:
            return "Data: GovData.de"
        case .governmentUS:
            return "Data: Data.gov"
        case .governmentAU:
            return "Data: data.gov.au"
        case .governmentUK:
            return "Data: data.gov.uk"
        }
    }
}

/// Category for discovered spots
public enum DiscoveredSpotCategory: String, Codable, CaseIterable, Sendable {
    // Dog areas
    case dogPark = "dog_park"
    case offLeashArea = "off_leash"
    case dogBeach = "dog_beach"
    case dogForest = "dog_forest"
    case dogFriendlyPark = "dog_friendly"
    // Services
    case vetClinic = "vet_clinic"
    case petStore = "pet_store"
    // Dog-friendly establishments
    case dogFriendlyCafe = "dog_friendly_cafe"

    public var label: String {
        switch self {
        case .dogPark: return Strings.PlacesDiscovery.categoryDogPark
        case .offLeashArea: return Strings.PlacesDiscovery.categoryOffLeash
        case .dogBeach: return Strings.PlacesDiscovery.categoryDogBeach
        case .dogForest: return Strings.PlacesDiscovery.categoryDogForest
        case .dogFriendlyPark: return Strings.PlacesDiscovery.categoryDogFriendly
        case .vetClinic: return Strings.PlacesDiscovery.categoryVetClinic
        case .petStore: return Strings.PlacesDiscovery.categoryPetStore
        case .dogFriendlyCafe: return Strings.PlacesDiscovery.categoryDogFriendlyCafe
        }
    }

    public var icon: String {
        switch self {
        case .dogPark: return "dog.fill"
        case .offLeashArea: return "figure.walk.motion"
        case .dogBeach: return "beach.umbrella.fill"
        case .dogForest: return "tree.fill"
        case .dogFriendlyPark: return "leaf.fill"
        case .vetClinic: return "stethoscope"
        case .petStore: return "bag.fill"
        case .dogFriendlyCafe: return "cup.and.saucer.fill"
        }
    }

    /// Group for filtering UI
    public var filterGroup: DiscoveredSpotFilterGroup {
        switch self {
        case .dogPark, .offLeashArea, .dogBeach, .dogForest, .dogFriendlyPark:
            return .dogAreas
        case .vetClinic:
            return .vets
        case .petStore:
            return .petStores
        case .dogFriendlyCafe:
            return .dogFriendly
        }
    }
}

/// Filter groups for discovered spots
public enum DiscoveredSpotFilterGroup: String, CaseIterable, Sendable {
    case dogAreas = "dog_areas"
    case vets = "vets"
    case petStores = "pet_stores"
    case dogFriendly = "dog_friendly_places"

    public var label: String {
        switch self {
        case .dogAreas: return Strings.PlacesDiscovery.filterDogAreas
        case .vets: return Strings.PlacesDiscovery.filterVets
        case .petStores: return Strings.PlacesDiscovery.filterPetStores
        case .dogFriendly: return Strings.PlacesDiscovery.filterDogFriendly
        }
    }

    public var icon: String {
        switch self {
        case .dogAreas: return "dog.fill"
        case .vets: return "stethoscope"
        case .petStores: return "bag.fill"
        case .dogFriendly: return "cup.and.saucer.fill"
        }
    }

    public var categories: [DiscoveredSpotCategory] {
        switch self {
        case .dogAreas:
            return [.dogPark, .offLeashArea, .dogBeach, .dogForest, .dogFriendlyPark]
        case .vets:
            return [.vetClinic]
        case .petStores:
            return [.petStore]
        case .dogFriendly:
            return [.dogFriendlyCafe]
        }
    }
}

// MARK: - Conversion to WalkSpot

extension DiscoveredSpot {
    /// Convert to a WalkSpot for saving to user's collection
    public func toWalkSpot() -> WalkSpot {
        WalkSpot(
            name: name,
            latitude: latitude,
            longitude: longitude,
            notes: buildNotes(),
            category: mapToSpotCategory()
        )
    }

    private func buildNotes() -> String? {
        var parts: [String] = []

        if let surface = surface {
            parts.append("Surface: \(surface)")
        }
        if let fenced = isFenced, fenced {
            parts.append("Fenced")
        }
        if !amenities.isEmpty {
            parts.append("Amenities: \(amenities.joined(separator: ", "))")
        }
        parts.append("Source: \(source.displayName)")

        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    private func mapToSpotCategory() -> SpotCategory {
        switch category {
        case .dogPark, .offLeashArea, .dogFriendlyPark:
            return .park
        case .dogBeach:
            return .beach
        case .dogForest:
            return .forest
        case .vetClinic, .petStore, .dogFriendlyCafe:
            return .other
        }
    }
}
