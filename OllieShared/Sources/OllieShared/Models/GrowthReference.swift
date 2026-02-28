//
//  GrowthReference.swift
//  OllieShared
//
//  Reference growth data for different dog breeds/sizes

import Foundation

/// Reference growth data point for comparison charts
public struct GrowthReference: Identifiable, Sendable {
    public let id = UUID()
    public let weeks: Int
    public let kg: Double
    public let label: String

    public init(weeks: Int, kg: Double, label: String) {
        self.weeks = weeks
        self.kg = kg
        self.label = label
    }
}

/// Standard growth curves for different dog sizes
public enum GrowthCurves {
    /// Golden Retriever female reference growth curve
    public static let goldenRetrieverFemale: [GrowthReference] = [
        GrowthReference(weeks: 0, kg: 1.3, label: "Birth"),
        GrowthReference(weeks: 4, kg: 3.0, label: "4 weeks"),
        GrowthReference(weeks: 8, kg: 4.5, label: "8 weeks"),
        GrowthReference(weeks: 12, kg: 8.0, label: "12 weeks"),
        GrowthReference(weeks: 16, kg: 11.0, label: "16 weeks"),
        GrowthReference(weeks: 20, kg: 14.0, label: "20 weeks"),
        GrowthReference(weeks: 26, kg: 17.0, label: "6 months"),
        GrowthReference(weeks: 34, kg: 20.0, label: "8 months"),
        GrowthReference(weeks: 42, kg: 23.0, label: "10 months"),
        GrowthReference(weeks: 52, kg: 25.0, label: "12 months"),
        GrowthReference(weeks: 78, kg: 27.0, label: "18 months")
    ]

    // MARK: - Breed-Specific Curve Generation

    /// Generate a growth curve for a specific breed based on its expected adult weight
    /// Uses research-based growth factors for different size categories
    public static func curve(for breed: Breed) -> [GrowthReference] {
        generateCurve(
            adultWeight: breed.weightRange.midpoint,
            size: breed.weightRange.sizeCategory
        )
    }

    /// Generate a custom growth curve based on expected adult weight
    /// Growth factors are based on veterinary research on puppy development
    public static func generateCurve(adultWeight: Double, size: PuppyProfile.SizeCategory) -> [GrowthReference] {
        // Growth factors based on research:
        // Small dogs mature faster, large dogs mature slower
        let factors: [(weeks: Int, factor: Double, label: String)] = switch size {
        case .small:
            // Small dogs reach adult weight by ~10-12 months
            [
                (0, 0.05, "Birth"),        // 5% of adult weight at birth
                (4, 0.15, "4 weeks"),      // 15%
                (8, 0.25, "8 weeks"),      // 25%
                (12, 0.45, "12 weeks"),    // 45%
                (16, 0.60, "16 weeks"),    // 60%
                (20, 0.75, "20 weeks"),    // 75%
                (26, 0.85, "6 months"),    // 85%
                (34, 0.95, "8 months"),    // 95%
                (42, 0.98, "10 months"),   // 98%
                (52, 1.00, "12 months"),   // 100%
                (78, 1.00, "18 months")    // Fully grown
            ]
        case .medium:
            // Medium dogs reach adult weight by ~12-14 months
            [
                (0, 0.05, "Birth"),
                (4, 0.12, "4 weeks"),
                (8, 0.22, "8 weeks"),
                (12, 0.40, "12 weeks"),
                (16, 0.55, "16 weeks"),
                (20, 0.65, "20 weeks"),
                (26, 0.75, "6 months"),
                (34, 0.85, "8 months"),
                (42, 0.92, "10 months"),
                (52, 0.97, "12 months"),
                (78, 1.00, "18 months")
            ]
        case .large:
            // Large dogs reach adult weight by ~14-18 months
            [
                (0, 0.05, "Birth"),
                (4, 0.10, "4 weeks"),
                (8, 0.18, "8 weeks"),
                (12, 0.32, "12 weeks"),
                (16, 0.45, "16 weeks"),
                (20, 0.55, "20 weeks"),
                (26, 0.65, "6 months"),
                (34, 0.78, "8 months"),
                (42, 0.88, "10 months"),
                (52, 0.95, "12 months"),
                (78, 1.00, "18 months")
            ]
        case .extraLarge:
            // Extra large dogs reach adult weight by ~18-24 months
            [
                (0, 0.04, "Birth"),
                (4, 0.08, "4 weeks"),
                (8, 0.15, "8 weeks"),
                (12, 0.28, "12 weeks"),
                (16, 0.38, "16 weeks"),
                (20, 0.48, "20 weeks"),
                (26, 0.58, "6 months"),
                (34, 0.70, "8 months"),
                (42, 0.82, "10 months"),
                (52, 0.90, "12 months"),
                (78, 1.00, "18 months")
            ]
        }

        return factors.map { factor in
            GrowthReference(
                weeks: factor.weeks,
                kg: adultWeight * factor.factor,
                label: factor.label
            )
        }
    }

    /// Returns the reference curve for a given size category
    public static func curve(for size: PuppyProfile.SizeCategory) -> [GrowthReference] {
        switch size {
        case .small:
            return smallDogCurve
        case .medium:
            return mediumDogCurve
        case .large:
            return goldenRetrieverFemale
        case .extraLarge:
            return extraLargeDogCurve
        }
    }

    /// Small dog growth curve (~5-10kg adult weight)
    public static let smallDogCurve: [GrowthReference] = [
        GrowthReference(weeks: 0, kg: 0.3, label: "Birth"),
        GrowthReference(weeks: 4, kg: 0.8, label: "4 weeks"),
        GrowthReference(weeks: 8, kg: 1.5, label: "8 weeks"),
        GrowthReference(weeks: 12, kg: 2.5, label: "12 weeks"),
        GrowthReference(weeks: 16, kg: 3.5, label: "16 weeks"),
        GrowthReference(weeks: 20, kg: 4.5, label: "20 weeks"),
        GrowthReference(weeks: 26, kg: 5.5, label: "6 months"),
        GrowthReference(weeks: 34, kg: 6.5, label: "8 months"),
        GrowthReference(weeks: 42, kg: 7.0, label: "10 months"),
        GrowthReference(weeks: 52, kg: 7.5, label: "12 months"),
        GrowthReference(weeks: 78, kg: 8.0, label: "18 months")
    ]

    /// Medium dog growth curve (~15-25kg adult weight)
    public static let mediumDogCurve: [GrowthReference] = [
        GrowthReference(weeks: 0, kg: 0.8, label: "Birth"),
        GrowthReference(weeks: 4, kg: 2.0, label: "4 weeks"),
        GrowthReference(weeks: 8, kg: 3.5, label: "8 weeks"),
        GrowthReference(weeks: 12, kg: 6.0, label: "12 weeks"),
        GrowthReference(weeks: 16, kg: 8.5, label: "16 weeks"),
        GrowthReference(weeks: 20, kg: 11.0, label: "20 weeks"),
        GrowthReference(weeks: 26, kg: 14.0, label: "6 months"),
        GrowthReference(weeks: 34, kg: 17.0, label: "8 months"),
        GrowthReference(weeks: 42, kg: 19.0, label: "10 months"),
        GrowthReference(weeks: 52, kg: 20.0, label: "12 months"),
        GrowthReference(weeks: 78, kg: 21.0, label: "18 months")
    ]

    /// Extra large dog growth curve (~40-60kg adult weight)
    public static let extraLargeDogCurve: [GrowthReference] = [
        GrowthReference(weeks: 0, kg: 1.8, label: "Birth"),
        GrowthReference(weeks: 4, kg: 4.0, label: "4 weeks"),
        GrowthReference(weeks: 8, kg: 7.0, label: "8 weeks"),
        GrowthReference(weeks: 12, kg: 12.0, label: "12 weeks"),
        GrowthReference(weeks: 16, kg: 17.0, label: "16 weeks"),
        GrowthReference(weeks: 20, kg: 22.0, label: "20 weeks"),
        GrowthReference(weeks: 26, kg: 28.0, label: "6 months"),
        GrowthReference(weeks: 34, kg: 35.0, label: "8 months"),
        GrowthReference(weeks: 42, kg: 42.0, label: "10 months"),
        GrowthReference(weeks: 52, kg: 48.0, label: "12 months"),
        GrowthReference(weeks: 78, kg: 55.0, label: "18 months")
    ]

    /// Tolerance band percentage for reference curves
    public static let tolerancePercent: Double = 0.15
}
