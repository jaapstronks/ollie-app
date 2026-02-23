//
//  WalkSpot.swift
//  Ollie-app
//
//  Model for saved walk locations/spots

import Foundation

/// A saved walk location that can be reused
struct WalkSpot: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var isFavorite: Bool
    var notes: String?
    var visitCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        notes: String? = nil,
        visitCount: Int = 1
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.notes = notes
        self.visitCount = visitCount
    }
}

/// Category for walk spots (future expansion)
enum SpotCategory: String, Codable, CaseIterable {
    case park
    case trail
    case neighborhood
    case beach
    case forest
    case other

    var label: String {
        switch self {
        case .park: return Strings.WalkLocations.categoryPark
        case .trail: return Strings.WalkLocations.categoryTrail
        case .neighborhood: return Strings.WalkLocations.categoryNeighborhood
        case .beach: return Strings.WalkLocations.categoryBeach
        case .forest: return Strings.WalkLocations.categoryForest
        case .other: return Strings.WalkLocations.categoryOther
        }
    }

    var icon: String {
        switch self {
        case .park: return "tree.fill"
        case .trail: return "figure.hiking"
        case .neighborhood: return "house.fill"
        case .beach: return "beach.umbrella.fill"
        case .forest: return "leaf.fill"
        case .other: return "mappin"
        }
    }
}
