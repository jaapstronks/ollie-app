//
//  GrowthPhotoSelector.swift
//  Otis-app
//
//  Smart photo selection service for growth shareable cards
//

import Foundation
import OtisShared

/// A photo selection for growth cards with age context
struct GrowthPhotoSelection: Identifiable {
    let id: UUID
    let event: PuppyEvent
    let ageLabel: String  // "8 weeks", "3 months"
    let ageWeeks: Int
    let ageMonths: Int
    let weight: Double?   // kg, if available near this date
}

/// Service for selecting photos for growth comparison cards
@MainActor
final class GrowthPhotoSelector {

    // MARK: - Photo Selection

    /// Find the earliest photo (for "Then")
    func findFirstPhoto(from events: [PuppyEvent], birthDate: Date) -> GrowthPhotoSelection? {
        let photosChronological = events
            .filter { $0.photo != nil }
            .sorted { $0.time < $1.time }

        guard let firstEvent = photosChronological.first else { return nil }

        return makeSelection(from: firstEvent, birthDate: birthDate, measurements: [])
    }

    /// Find the latest photo (for "Now")
    func findLatestPhoto(from events: [PuppyEvent], birthDate: Date) -> GrowthPhotoSelection? {
        let photosChronological = events
            .filter { $0.photo != nil }
            .sorted { $0.time > $1.time }

        guard let latestEvent = photosChronological.first else { return nil }

        return makeSelection(from: latestEvent, birthDate: birthDate, measurements: [])
    }

    /// Find monthly photos for grid (one per month)
    /// Returns up to maxMonths photos, one for each month starting from birth
    func findMonthlyPhotos(
        from events: [PuppyEvent],
        birthDate: Date,
        measurements: [WeightMeasurement] = [],
        maxMonths: Int = 6
    ) -> [GrowthPhotoSelection] {
        let calendar = Calendar.current
        let photosWithDate = events
            .filter { $0.photo != nil }
            .sorted { $0.time < $1.time }

        guard !photosWithDate.isEmpty else { return [] }

        var selections: [GrowthPhotoSelection] = []
        var usedMonths = Set<Int>()

        // Group photos by month of age
        for event in photosWithDate {
            let ageMonths = calendar.dateComponents([.month], from: birthDate, to: event.time).month ?? 0

            // Only include months 1-maxMonths (skip month 0)
            guard ageMonths >= 1 && ageMonths <= maxMonths else { continue }
            guard !usedMonths.contains(ageMonths) else { continue }

            usedMonths.insert(ageMonths)

            let selection = makeSelection(from: event, birthDate: birthDate, measurements: measurements)
            selections.append(selection)

            if selections.count >= maxMonths {
                break
            }
        }

        return selections.sorted { $0.ageMonths < $1.ageMonths }
    }

    /// Find weight measurement closest to a photo date
    func findWeightNear(date: Date, measurements: [WeightMeasurement], maxDaysDifference: Int = 7) -> Double? {
        let calendar = Calendar.current

        let nearby = measurements
            .compactMap { measurement -> (measurement: WeightMeasurement, daysDiff: Int)? in
                let days = abs(calendar.dateComponents([.day], from: measurement.date, to: date).day ?? Int.max)
                guard days <= maxDaysDifference else { return nil }
                return (measurement, days)
            }
            .sorted { $0.daysDiff < $1.daysDiff }

        return nearby.first?.measurement.weightKg
    }

    // MARK: - Photo Pair Selection

    /// Get the best "then vs now" photo pair
    func findThenNowPair(
        from events: [PuppyEvent],
        birthDate: Date,
        measurements: [WeightMeasurement] = []
    ) -> (then: GrowthPhotoSelection, now: GrowthPhotoSelection)? {
        let photosChronological = events
            .filter { $0.photo != nil }
            .sorted { $0.time < $1.time }

        guard photosChronological.count >= 2 else { return nil }

        let firstEvent = photosChronological.first!
        let latestEvent = photosChronological.last!

        let thenSelection = makeSelection(from: firstEvent, birthDate: birthDate, measurements: measurements)
        let nowSelection = makeSelection(from: latestEvent, birthDate: birthDate, measurements: measurements)

        return (thenSelection, nowSelection)
    }

    // MARK: - Helper Methods

    private func makeSelection(
        from event: PuppyEvent,
        birthDate: Date,
        measurements: [WeightMeasurement]
    ) -> GrowthPhotoSelection {
        let calendar = Calendar.current

        let ageWeeks = calendar.dateComponents([.weekOfYear], from: birthDate, to: event.time).weekOfYear ?? 0
        let ageMonths = calendar.dateComponents([.month], from: birthDate, to: event.time).month ?? 0

        // Build age label - use weeks if < 4 months, otherwise months
        let ageLabel: String
        if ageMonths < 4 {
            ageLabel = Strings.GrowthCards.ageWeeks(max(1, ageWeeks))
        } else {
            ageLabel = Strings.GrowthCards.ageMonths(ageMonths)
        }

        let weight = findWeightNear(date: event.time, measurements: measurements)

        return GrowthPhotoSelection(
            id: event.id,
            event: event,
            ageLabel: ageLabel,
            ageWeeks: ageWeeks,
            ageMonths: ageMonths,
            weight: weight
        )
    }

    // MARK: - Availability Checks

    /// Check if we have enough photos for a Then vs Now card
    func canCreateThenNowCard(from events: [PuppyEvent]) -> Bool {
        events.filter { $0.photo != nil }.count >= 2
    }

    /// Check if we have enough photos for a monthly grid card
    func canCreateMonthlyGridCard(from events: [PuppyEvent], birthDate: Date) -> Bool {
        let monthlyPhotos = findMonthlyPhotos(from: events, birthDate: birthDate, maxMonths: 6)
        return monthlyPhotos.count >= 2
    }
}
