//
//  WalkSpot.swift
//  OllieShared
//

import Foundation

/// A saved walk location that can be reused
public struct WalkSpot: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date
    public var isFavorite: Bool
    public var notes: String?
    public var visitCount: Int

    public init(
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

/// Category for walk spots
public enum SpotCategory: String, Codable, CaseIterable, Sendable {
    case park
    case trail
    case neighborhood
    case beach
    case forest
    case other

    public var label: String {
        switch self {
        case .park: return Strings.WalkLocations.categoryPark
        case .trail: return Strings.WalkLocations.categoryTrail
        case .neighborhood: return Strings.WalkLocations.categoryNeighborhood
        case .beach: return Strings.WalkLocations.categoryBeach
        case .forest: return Strings.WalkLocations.categoryForest
        case .other: return Strings.WalkLocations.categoryOther
        }
    }

    public var icon: String {
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
