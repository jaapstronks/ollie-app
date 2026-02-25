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
