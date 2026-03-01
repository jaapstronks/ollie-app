//
//  WeightCalculations.swift
//  OtisShared
//
//  Weight tracking calculations: deltas, growth comparison, chart data

import Foundation

/// Growth story data for visual weight journey display
public struct GrowthStory: Sendable {
    public let firstWeight: Double
    public let firstWeightDate: Date
    public let currentWeight: Double
    public let currentWeightDate: Date
    public let growthRatio: Double      // current / first (e.g., 2.0 = doubled)
    public let estimatedAdultWeight: Double
    public let percentToAdult: Double   // 0-100%
    public let daysSinceFirst: Int

    public init(
        firstWeight: Double,
        firstWeightDate: Date,
        currentWeight: Double,
        currentWeightDate: Date,
        growthRatio: Double,
        estimatedAdultWeight: Double,
        percentToAdult: Double,
        daysSinceFirst: Int
    ) {
        self.firstWeight = firstWeight
        self.firstWeightDate = firstWeightDate
        self.currentWeight = currentWeight
        self.currentWeightDate = currentWeightDate
        self.growthRatio = growthRatio
        self.estimatedAdultWeight = estimatedAdultWeight
        self.percentToAdult = percentToAdult
        self.daysSinceFirst = daysSinceFirst
    }

    /// Formatted growth multiplier for display (e.g., "2x", "1.5x", "3x")
    public var formattedMultiplier: String {
        if growthRatio >= 2.95 && growthRatio < 3.05 {
            return "3x"
        } else if growthRatio >= 1.95 && growthRatio < 2.05 {
            return "2x"
        } else if growthRatio >= 1.45 && growthRatio < 1.55 {
            return "1.5x"
        } else {
            return String(format: "%.1fx", growthRatio)
        }
    }

    /// Whether growth is significant enough to show story (at least 10% increase)
    public var isSignificant: Bool {
        growthRatio >= 1.1
    }
}

/// Weight measurement with age context (used for chart display)
/// Note: This is distinct from the WeightMeasurement domain model in Models/
public struct WeightChartPoint: Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let weightKg: Double
    public let ageWeeks: Int

    public init(id: UUID, date: Date, weightKg: Double, ageWeeks: Int) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.ageWeeks = ageWeeks
    }
}

/// Growth comparison result
public struct GrowthComparison: Sendable {
    public let currentWeight: Double
    public let referenceWeight: Double
    public let percentageDifference: Double

    public init(currentWeight: Double, referenceWeight: Double, percentageDifference: Double) {
        self.currentWeight = currentWeight
        self.referenceWeight = referenceWeight
        self.percentageDifference = percentageDifference
    }

    public var isWithinBand: Bool {
        abs(percentageDifference) <= GrowthCurves.tolerancePercent * 100
    }

    public var statusMessage: String {
        if isWithinBand {
            return Strings.Health.weightOnTrack
        } else if percentageDifference > 0 {
            return Strings.Health.weightAboveReference
        } else {
            return Strings.Health.weightBelowReference
        }
    }
}

public enum WeightCalculations {

    // MARK: - Chart Points (for display)

    /// Convert WeightMeasurement array to chart points with age context
    public static func chartPoints(
        from measurements: [WeightMeasurement],
        birthDate: Date
    ) -> [WeightChartPoint] {
        let calendar = Calendar.current

        return measurements
            .map { measurement in
                let ageWeeks = calendar.dateComponents(
                    [.weekOfYear],
                    from: birthDate,
                    to: measurement.date
                ).weekOfYear ?? 0

                return WeightChartPoint(
                    id: measurement.id,
                    date: measurement.date,
                    weightKg: measurement.weightKg,
                    ageWeeks: max(0, ageWeeks)
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// Extract weight chart points from events (deprecated - use chartPoints(from:birthDate:) with WeightMeasurement array)
    @available(*, deprecated, message: "Use chartPoints(from:birthDate:) with WeightMeasurement array instead")
    public static func weightMeasurements(
        events: [PuppyEvent],
        birthDate: Date
    ) -> [WeightChartPoint] {
        let calendar = Calendar.current

        return events.weights()
            .filter { $0.weightKg != nil }
            .compactMap { event -> WeightChartPoint? in
                guard let weight = event.weightKg else { return nil }

                let ageWeeks = calendar.dateComponents(
                    [.weekOfYear],
                    from: birthDate,
                    to: event.time
                ).weekOfYear ?? 0

                return WeightChartPoint(
                    id: event.id,
                    date: event.time,
                    weightKg: weight,
                    ageWeeks: max(0, ageWeeks)
                )
            }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Weight Stats (WeightMeasurement-based)

    /// Get the most recent weight measurement
    public static func latestWeight(from measurements: [WeightMeasurement]) -> (weight: Double, date: Date)? {
        guard let latest = measurements.sortedByDateDescending().first else {
            return nil
        }
        return (latest.weightKg, latest.date)
    }

    /// Calculate weight change since previous measurement
    public static func weightDelta(from measurements: [WeightMeasurement]) -> (delta: Double, previousDate: Date)? {
        let sorted = measurements.sortedByDateDescending()
        guard sorted.count >= 2 else { return nil }

        let current = sorted[0]
        let previous = sorted[1]
        return (current.weightKg - previous.weightKg, previous.date)
    }

    /// Get the first weight measurement (for "journey begins" state)
    public static func firstWeight(from measurements: [WeightMeasurement]) -> (weight: Double, date: Date)? {
        guard let first = measurements.sortedByDate().first else {
            return nil
        }
        return (first.weightKg, first.date)
    }

    /// Build a growth story from weight measurements
    public static func growthStory(
        from measurements: [WeightMeasurement],
        homeDate: Date,
        sizeCategory: PuppyProfile.SizeCategory,
        breed: Breed? = nil
    ) -> GrowthStory? {
        let sorted = measurements.sortedByDate()

        guard sorted.count >= 2,
              let first = sorted.first,
              let last = sorted.last,
              first.weightKg > 0 else {
            return nil
        }

        let firstWeight = first.weightKg
        let currentWeight = last.weightKg

        // Calculate growth ratio
        let growthRatio = currentWeight / firstWeight

        // Get estimated adult weight from breed-specific curve if available
        let curve: [GrowthReference]
        if let breed = breed {
            curve = GrowthCurves.curve(for: breed)
        } else {
            curve = GrowthCurves.curve(for: sizeCategory)
        }
        let estimatedAdultWeight = curve.last?.kg ?? currentWeight

        // Calculate percent to adult weight (capped at 100%)
        let percentToAdult = min(100.0, (currentWeight / estimatedAdultWeight) * 100.0)

        // Calculate days since first measurement
        let calendar = Calendar.current
        let daysSinceFirst = calendar.dateComponents([.day], from: first.date, to: last.date).day ?? 0

        return GrowthStory(
            firstWeight: firstWeight,
            firstWeightDate: first.date,
            currentWeight: currentWeight,
            currentWeightDate: last.date,
            growthRatio: growthRatio,
            estimatedAdultWeight: estimatedAdultWeight,
            percentToAdult: percentToAdult,
            daysSinceFirst: daysSinceFirst
        )
    }

    // MARK: - Legacy PuppyEvent-based methods (deprecated)

    /// Get the most recent weight measurement (deprecated - use latestWeight(from:) with WeightMeasurement array)
    @available(*, deprecated, message: "Use latestWeight(from:) with WeightMeasurement array instead")
    public static func latestWeight(events: [PuppyEvent]) -> (weight: Double, date: Date)? {
        let weightEvents = events.weights()
            .filter { $0.weightKg != nil }
            .sorted { $0.time > $1.time }

        guard let latest = weightEvents.first, let weight = latest.weightKg else {
            return nil
        }

        return (weight, latest.time)
    }

    /// Calculate weight change since previous measurement (deprecated - use weightDelta(from:) with WeightMeasurement array)
    @available(*, deprecated, message: "Use weightDelta(from:) with WeightMeasurement array instead")
    public static func weightDelta(events: [PuppyEvent]) -> (delta: Double, previousDate: Date)? {
        let weightEvents = events.weights()
            .filter { $0.weightKg != nil }
            .sorted { $0.time > $1.time }

        guard weightEvents.count >= 2,
              let currentWeight = weightEvents[0].weightKg,
              let previousWeight = weightEvents[1].weightKg else {
            return nil
        }

        return (currentWeight - previousWeight, weightEvents[1].time)
    }

    // MARK: - Reference Curve Methods

    /// Compare current weight to reference curve
    public static func compareToReference(
        currentWeight: Double,
        ageWeeks: Int,
        curve: [GrowthReference]
    ) -> GrowthComparison? {
        let referenceWeight = interpolatedReferenceWeight(at: ageWeeks, curve: curve)

        let difference = currentWeight - referenceWeight
        let percentageDiff = (difference / referenceWeight) * 100

        return GrowthComparison(
            currentWeight: currentWeight,
            referenceWeight: referenceWeight,
            percentageDifference: percentageDiff
        )
    }

    /// Get interpolated reference weight for a given age
    public static func interpolatedReferenceWeight(at weeks: Int, curve: [GrowthReference]) -> Double {
        guard !curve.isEmpty else { return 0 }

        if weeks <= curve.first!.weeks {
            return curve.first!.kg
        }
        if weeks >= curve.last!.weeks {
            return curve.last!.kg
        }

        var lower = curve.first!
        var upper = curve.last!

        for (index, point) in curve.enumerated() {
            if point.weeks <= weeks {
                lower = point
                if index + 1 < curve.count {
                    upper = curve[index + 1]
                }
            }
        }

        let weekRange = Double(upper.weeks - lower.weeks)
        let kgRange = upper.kg - lower.kg
        let weekProgress = Double(weeks - lower.weeks)

        return lower.kg + (kgRange * weekProgress / weekRange)
    }

    /// Format weight for display
    public static func formatWeight(_ kg: Double) -> String {
        if kg >= 10 {
            return String(format: "%.1f kg", kg)
        } else {
            return String(format: "%.2f kg", kg)
        }
    }

    /// Format weight delta for display
    public static func formatDelta(_ delta: Double) -> String {
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.2f kg", sign, delta)
    }

    /// Get reference band (min/max) for a given age
    public static func referenceBand(at weeks: Int, curve: [GrowthReference]) -> (min: Double, max: Double) {
        let center = interpolatedReferenceWeight(at: weeks, curve: curve)
        let tolerance = center * GrowthCurves.tolerancePercent
        return (center - tolerance, center + tolerance)
    }

    /// Build a growth story from weight events (deprecated - use growthStory(from:homeDate:sizeCategory:breed:) with WeightMeasurement array)
    /// Returns nil if there are fewer than 2 weight measurements
    /// - Parameters:
    ///   - events: All puppy events
    ///   - homeDate: Date puppy came home
    ///   - sizeCategory: Size category for default curve
    ///   - breed: Optional breed for breed-specific adult weight estimation
    @available(*, deprecated, message: "Use growthStory(from:homeDate:sizeCategory:breed:) with WeightMeasurement array instead")
    public static func growthStory(
        events: [PuppyEvent],
        homeDate: Date,
        sizeCategory: PuppyProfile.SizeCategory,
        breed: Breed? = nil
    ) -> GrowthStory? {
        let weightEvents = events.weights()
            .filter { $0.weightKg != nil }
            .sorted { $0.time < $1.time }

        guard weightEvents.count >= 2,
              let firstEvent = weightEvents.first,
              let lastEvent = weightEvents.last,
              let firstWeight = firstEvent.weightKg,
              let currentWeight = lastEvent.weightKg,
              firstWeight > 0 else {
            return nil
        }

        // Calculate growth ratio
        let growthRatio = currentWeight / firstWeight

        // Get estimated adult weight from breed-specific curve if available
        let curve: [GrowthReference]
        if let breed = breed {
            curve = GrowthCurves.curve(for: breed)
        } else {
            curve = GrowthCurves.curve(for: sizeCategory)
        }
        let estimatedAdultWeight = curve.last?.kg ?? currentWeight

        // Calculate percent to adult weight (capped at 100%)
        let percentToAdult = min(100.0, (currentWeight / estimatedAdultWeight) * 100.0)

        // Calculate days since first measurement
        let calendar = Calendar.current
        let daysSinceFirst = calendar.dateComponents([.day], from: firstEvent.time, to: lastEvent.time).day ?? 0

        return GrowthStory(
            firstWeight: firstWeight,
            firstWeightDate: firstEvent.time,
            currentWeight: currentWeight,
            currentWeightDate: lastEvent.time,
            growthRatio: growthRatio,
            estimatedAdultWeight: estimatedAdultWeight,
            percentToAdult: percentToAdult,
            daysSinceFirst: daysSinceFirst
        )
    }

    /// Compare current weight to breed-specific reference curve
    public static func compareToBreedReference(
        currentWeight: Double,
        ageWeeks: Int,
        breed: Breed
    ) -> GrowthComparison? {
        let curve = GrowthCurves.curve(for: breed)
        return compareToReference(currentWeight: currentWeight, ageWeeks: ageWeeks, curve: curve)
    }

    /// Get the expected weight for a breed at a given age
    public static func expectedWeight(at weeks: Int, breed: Breed) -> Double {
        let curve = GrowthCurves.curve(for: breed)
        return interpolatedReferenceWeight(at: weeks, curve: curve)
    }

    /// Get the expected weight for a size category at a given age
    public static func expectedWeight(at weeks: Int, size: PuppyProfile.SizeCategory) -> Double {
        let curve = GrowthCurves.curve(for: size)
        return interpolatedReferenceWeight(at: weeks, curve: curve)
    }

    /// Get the first weight measurement (for "journey begins" state) (deprecated - use firstWeight(from:) with WeightMeasurement array)
    @available(*, deprecated, message: "Use firstWeight(from:) with WeightMeasurement array instead")
    public static func firstWeight(events: [PuppyEvent]) -> (weight: Double, date: Date)? {
        let weightEvents = events.weights()
            .filter { $0.weightKg != nil }
            .sorted { $0.time < $1.time }

        guard let first = weightEvents.first, let weight = first.weightKg else {
            return nil
        }

        return (weight, first.time)
    }

    // MARK: - Smart Weigh Reminder

    /// Determines if it's time to weigh the puppy based on age and time since last measurement
    /// Returns a suggestion message if it's time to weigh, nil otherwise
    public static func weighReminder(
        lastWeightDate: Date?,
        ageInWeeks: Int,
        now: Date = Date()
    ) -> WeighReminder? {
        let calendar = Calendar.current

        // If never weighed, always suggest
        guard let lastDate = lastWeightDate else {
            return WeighReminder(
                urgency: .high,
                daysSinceLastWeigh: nil,
                recommendedIntervalDays: recommendedWeighInterval(ageInWeeks: ageInWeeks)
            )
        }

        let daysSinceLastWeigh = calendar.dateComponents([.day], from: lastDate, to: now).day ?? 0
        let recommendedInterval = recommendedWeighInterval(ageInWeeks: ageInWeeks)

        // Check if overdue
        if daysSinceLastWeigh >= recommendedInterval {
            let urgency: WeighReminder.Urgency
            if daysSinceLastWeigh >= recommendedInterval * 2 {
                urgency = .high
            } else {
                urgency = .medium
            }
            return WeighReminder(
                urgency: urgency,
                daysSinceLastWeigh: daysSinceLastWeigh,
                recommendedIntervalDays: recommendedInterval
            )
        }

        // Not due yet
        return nil
    }

    /// Recommended weighing interval based on puppy age
    /// - Young puppies (< 12 weeks): Weekly
    /// - Growing puppies (12-26 weeks): Every 2 weeks
    /// - Adolescent (26-52 weeks): Monthly
    /// - Adult (> 52 weeks): Every 2-3 months
    /// - Senior dogs (> 7 years / 364 weeks): Monthly (health monitoring)
    private static func recommendedWeighInterval(ageInWeeks: Int) -> Int {
        switch ageInWeeks {
        case ..<12:
            return 7  // Weekly for young puppies
        case 12..<26:
            return 14  // Every 2 weeks during rapid growth
        case 26..<52:
            return 30  // Monthly for adolescents
        case 52..<364:
            return 60  // Every 2 months for adults
        default:
            return 30  // Monthly for senior dogs
        }
    }
}

/// Represents a reminder to weigh the puppy
public struct WeighReminder: Sendable {
    public enum Urgency: Sendable {
        case medium  // Due soon or recently due
        case high    // Significantly overdue or never weighed
    }

    public let urgency: Urgency
    public let daysSinceLastWeigh: Int?
    public let recommendedIntervalDays: Int

    public init(urgency: Urgency, daysSinceLastWeigh: Int?, recommendedIntervalDays: Int) {
        self.urgency = urgency
        self.daysSinceLastWeigh = daysSinceLastWeigh
        self.recommendedIntervalDays = recommendedIntervalDays
    }
}
