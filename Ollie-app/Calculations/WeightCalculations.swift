//
//  WeightCalculations.swift
//  Ollie-app
//
//  Weight tracking calculations: deltas, growth comparison, chart data

import Foundation

/// Weight measurement with age context
struct WeightMeasurement: Identifiable {
    let id: UUID
    let date: Date
    let weightKg: Double
    let ageWeeks: Int
}

/// Growth comparison result
struct GrowthComparison {
    let currentWeight: Double
    let referenceWeight: Double
    let percentageDifference: Double  // positive = above reference, negative = below

    var isWithinBand: Bool {
        abs(percentageDifference) <= GrowthCurves.tolerancePercent * 100
    }

    var statusMessage: String {
        if isWithinBand {
            return Strings.Health.weightOnTrack
        } else if percentageDifference > 0 {
            return Strings.Health.weightAboveReference
        } else {
            return Strings.Health.weightBelowReference
        }
    }
}

enum WeightCalculations {
    /// Extract weight measurements from events
    static func weightMeasurements(
        events: [PuppyEvent],
        birthDate: Date
    ) -> [WeightMeasurement] {
        let calendar = Calendar.current

        return events
            .filter { $0.type == .gewicht && $0.weightKg != nil }
            .compactMap { event -> WeightMeasurement? in
                guard let weight = event.weightKg else { return nil }

                let ageWeeks = calendar.dateComponents(
                    [.weekOfYear],
                    from: birthDate,
                    to: event.time
                ).weekOfYear ?? 0

                return WeightMeasurement(
                    id: event.id,
                    date: event.time,
                    weightKg: weight,
                    ageWeeks: max(0, ageWeeks)
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// Get the most recent weight measurement
    static func latestWeight(events: [PuppyEvent]) -> (weight: Double, date: Date)? {
        let weightEvents = events
            .filter { $0.type == .gewicht && $0.weightKg != nil }
            .sorted { $0.time > $1.time }

        guard let latest = weightEvents.first, let weight = latest.weightKg else {
            return nil
        }

        return (weight, latest.time)
    }

    /// Calculate weight change since previous measurement
    static func weightDelta(events: [PuppyEvent]) -> (delta: Double, previousDate: Date)? {
        let weightEvents = events
            .filter { $0.type == .gewicht && $0.weightKg != nil }
            .sorted { $0.time > $1.time }

        guard weightEvents.count >= 2,
              let currentWeight = weightEvents[0].weightKg,
              let previousWeight = weightEvents[1].weightKg else {
            return nil
        }

        return (currentWeight - previousWeight, weightEvents[1].time)
    }

    /// Compare current weight to reference curve
    static func compareToReference(
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
    static func interpolatedReferenceWeight(at weeks: Int, curve: [GrowthReference]) -> Double {
        // Find surrounding reference points
        guard !curve.isEmpty else { return 0 }

        // Clamp to curve bounds
        if weeks <= curve.first!.weeks {
            return curve.first!.kg
        }
        if weeks >= curve.last!.weeks {
            return curve.last!.kg
        }

        // Find the two surrounding points
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

        // Linear interpolation
        let weekRange = Double(upper.weeks - lower.weeks)
        let kgRange = upper.kg - lower.kg
        let weekProgress = Double(weeks - lower.weeks)

        return lower.kg + (kgRange * weekProgress / weekRange)
    }

    /// Format weight for display
    static func formatWeight(_ kg: Double) -> String {
        if kg >= 10 {
            return String(format: "%.1f kg", kg)
        } else {
            return String(format: "%.2f kg", kg)
        }
    }

    /// Format weight delta for display
    static func formatDelta(_ delta: Double) -> String {
        let sign = delta >= 0 ? "+" : ""
        return String(format: "%@%.2f kg", sign, delta)
    }

    /// Get reference band (min/max) for a given age
    static func referenceBand(at weeks: Int, curve: [GrowthReference]) -> (min: Double, max: Double) {
        let center = interpolatedReferenceWeight(at: weeks, curve: curve)
        let tolerance = center * GrowthCurves.tolerancePercent
        return (center - tolerance, center + tolerance)
    }
}
