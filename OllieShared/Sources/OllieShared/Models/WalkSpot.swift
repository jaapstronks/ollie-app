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
    public var modifiedAt: Date
    public var isFavorite: Bool
    public var notes: String?
    public var visitCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        createdAt: Date = Date(),
        modifiedAt: Date? = nil,
        isFavorite: Bool = false,
        notes: String? = nil,
        visitCount: Int = 1
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt ?? createdAt
        self.isFavorite = isFavorite
        self.notes = notes
        self.visitCount = visitCount
    }

    // MARK: - Coding Keys

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case isFavorite = "is_favorite"
        case notes
        case visitCount = "visit_count"
    }

    // MARK: - Custom Decoding (handle missing modifiedAt for migration)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? createdAt
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        visitCount = try container.decodeIfPresent(Int.self, forKey: .visitCount) ?? 1
    }

    // MARK: - Mutation Helpers

    /// Returns a copy with updated modifiedAt timestamp
    public func withUpdatedTimestamp() -> WalkSpot {
        var copy = self
        copy.modifiedAt = Date()
        return copy
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
