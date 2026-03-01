//
//  Breed.swift
//  OtisShared
//
//  Breed data model for TheDogAPI integration

import Foundation

/// Dog breed information from TheDogAPI
public struct Breed: Codable, Identifiable, Sendable, Hashable {
    public let id: Int
    public let name: String
    public let weightRange: WeightRange
    public let heightRange: HeightRange?
    public let lifeSpan: String?
    public let temperament: [String]
    public let breedGroup: String?
    public let origin: String?

    public init(
        id: Int,
        name: String,
        weightRange: WeightRange,
        heightRange: HeightRange? = nil,
        lifeSpan: String? = nil,
        temperament: [String] = [],
        breedGroup: String? = nil,
        origin: String? = nil
    ) {
        self.id = id
        self.name = name
        self.weightRange = weightRange
        self.heightRange = heightRange
        self.lifeSpan = lifeSpan
        self.temperament = temperament
        self.breedGroup = breedGroup
        self.origin = origin
    }

    /// Weight range in kilograms
    public struct WeightRange: Codable, Sendable, Hashable {
        public let minKg: Double
        public let maxKg: Double

        public init(minKg: Double, maxKg: Double) {
            self.minKg = minKg
            self.maxKg = maxKg
        }

        /// Midpoint of the weight range (typical adult weight)
        public var midpoint: Double {
            (minKg + maxKg) / 2
        }

        /// Formatted weight range string for display
        public var displayString: String {
            if minKg == maxKg {
                return String(format: "%.0f kg", minKg)
            }
            return String(format: "%.0f-%.0f kg", minKg, maxKg)
        }

        /// Inferred size category based on midpoint weight
        public var sizeCategory: PuppyProfile.SizeCategory {
            switch midpoint {
            case 0..<10:
                return .small
            case 10..<25:
                return .medium
            case 25..<40:
                return .large
            default:
                return .extraLarge
            }
        }
    }

    /// Height range in centimeters
    public struct HeightRange: Codable, Sendable, Hashable {
        public let minCm: Double
        public let maxCm: Double

        public init(minCm: Double, maxCm: Double) {
            self.minCm = minCm
            self.maxCm = maxCm
        }

        /// Midpoint of the height range
        public var midpoint: Double {
            (minCm + maxCm) / 2
        }
    }
}

// MARK: - API Response Parsing

extension Breed {
    /// Initialize from TheDogAPI response JSON
    public init?(from apiBreed: TheDogAPIBreed) {
        guard let weightRange = Self.parseWeightRange(apiBreed.weight?.metric) else {
            return nil
        }

        self.id = apiBreed.id
        self.name = apiBreed.name
        self.weightRange = weightRange
        self.heightRange = Self.parseHeightRange(apiBreed.height?.metric)
        self.lifeSpan = apiBreed.life_span
        self.temperament = apiBreed.temperament?
            .components(separatedBy: ", ")
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        self.breedGroup = apiBreed.breed_group
        self.origin = apiBreed.origin
    }

    /// Parse weight string like "25 - 34" or "25" to WeightRange
    private static func parseWeightRange(_ weightString: String?) -> WeightRange? {
        guard let weightString = weightString else { return nil }

        let cleaned = weightString.replacingOccurrences(of: " ", with: "")
        let parts = cleaned.components(separatedBy: "-")

        guard let first = parts.first, let minKg = Double(first) else {
            return nil
        }

        if parts.count >= 2, let maxKg = Double(parts[1]) {
            return WeightRange(minKg: minKg, maxKg: maxKg)
        } else {
            // Single value - use as both min and max
            return WeightRange(minKg: minKg, maxKg: minKg)
        }
    }

    /// Parse height string like "56 - 61" to HeightRange
    private static func parseHeightRange(_ heightString: String?) -> HeightRange? {
        guard let heightString = heightString else { return nil }

        let cleaned = heightString.replacingOccurrences(of: " ", with: "")
        let parts = cleaned.components(separatedBy: "-")

        guard let first = parts.first, let minCm = Double(first) else {
            return nil
        }

        if parts.count >= 2, let maxCm = Double(parts[1]) {
            return HeightRange(minCm: minCm, maxCm: maxCm)
        } else {
            return HeightRange(minCm: minCm, maxCm: minCm)
        }
    }
}

// MARK: - TheDogAPI Response Types

/// Raw breed response from TheDogAPI
public struct TheDogAPIBreed: Codable, Sendable {
    public let id: Int
    public let name: String
    public let weight: Measurement?
    public let height: Measurement?
    public let life_span: String?
    public let temperament: String?
    public let breed_group: String?
    public let origin: String?

    public struct Measurement: Codable, Sendable {
        public let imperial: String?
        public let metric: String?
    }
}
