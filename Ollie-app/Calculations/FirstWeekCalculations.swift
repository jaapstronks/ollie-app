//
//  FirstWeekCalculations.swift
//  Otis-app
//
//  Calculations for the first week card - tracks early crate training
//  and potty training progress with human-friendly messaging
//

import Foundation
import OtisShared

/// First week statistics for the daily summary card
struct FirstWeekStats {
    let daysHome: Int
    let puppyName: String

    // Potty training stats (yesterday, for morning summary)
    let outdoorPottyCount: Int
    let totalPottyCount: Int

    // Crate training stats (yesterday)
    let crateNapCount: Int
    let totalQualifyingNaps: Int
    let napsWithLocationSpecified: Int

    // Historical context
    let hasEverSpecifiedNapLocation: Bool
    let daysWithNapsLogged: Int

    /// Whether user appears uninterested in crate training
    /// (7+ days of naps logged, zero with location specified)
    var suppressCrateTraining: Bool {
        daysWithNapsLogged >= 7 && !hasEverSpecifiedNapLocation
    }

    /// Crate percentage (of naps where location was specified)
    var cratePercentage: Int? {
        guard napsWithLocationSpecified > 0 else { return nil }
        return Int(Double(crateNapCount) / Double(napsWithLocationSpecified) * 100)
    }

    /// Whether we have enough data to show crate stats
    var hasEnoughCrateData: Bool {
        totalQualifyingNaps >= 3
    }

    /// Whether we have location data for crate tracking
    var hasLocationData: Bool {
        napsWithLocationSpecified > 0
    }
}

/// Calculations for the first week summary card
struct FirstWeekCalculations {

    /// Minimum nap duration to count for crate training (matches SleepCalculations)
    static let minimumNapMinutes = 15

    /// Days threshold for suppressing crate messaging
    static let suppressionDaysThreshold = 7

    /// Calculate first week stats from events and profile
    static func calculateStats(
        profile: PuppyProfile,
        todayEvents: [PuppyEvent],
        yesterdayEvents: [PuppyEvent],
        historicalEvents: [PuppyEvent]
    ) -> FirstWeekStats {

        // Potty stats from yesterday (for morning summary)
        let yesterdayPotties = yesterdayEvents.filter { $0.type == .plassen || $0.type == .poepen }
        let outdoorPottyCount = yesterdayPotties.filter { $0.location == .buiten }.count
        let totalPottyCount = yesterdayPotties.count

        // Crate training stats from yesterday
        let yesterdayNaps = qualifyingNaps(from: yesterdayEvents)
        let crateNapCount = yesterdayNaps.filter { $0.napLocation == .crate }.count
        let napsWithLocation = yesterdayNaps.filter { $0.napLocation != nil }.count

        // Historical context for suppression logic
        let allEvents = historicalEvents + todayEvents
        let allNaps = qualifyingNaps(from: allEvents)
        let hasEverSpecifiedLocation = allNaps.contains { $0.napLocation != nil }

        // Count days with naps logged
        let daysWithNaps = countDaysWithNaps(events: allEvents)

        return FirstWeekStats(
            daysHome: profile.daysHome,
            puppyName: profile.name,
            outdoorPottyCount: outdoorPottyCount,
            totalPottyCount: totalPottyCount,
            crateNapCount: crateNapCount,
            totalQualifyingNaps: yesterdayNaps.count,
            napsWithLocationSpecified: napsWithLocation,
            hasEverSpecifiedNapLocation: hasEverSpecifiedLocation,
            daysWithNapsLogged: daysWithNaps
        )
    }

    /// Get qualifying naps (duration >= 15 minutes)
    private static func qualifyingNaps(from events: [PuppyEvent]) -> [PuppyEvent] {
        events.filter { event in
            event.type == .slapen &&
            (event.durationMin ?? 0) >= minimumNapMinutes
        }
    }

    /// Count unique days that have naps logged
    private static func countDaysWithNaps(events: [PuppyEvent]) -> Int {
        let calendar = Calendar.current
        let naps = qualifyingNaps(from: events)
        let uniqueDays = Set(naps.map { calendar.startOfDay(for: $0.time) })
        return uniqueDays.count
    }
}

// MARK: - Message Generation

extension FirstWeekStats {

    /// Main message for the first week card
    var mainMessage: String {
        switch daysHome {
        case 0, 1:
            return Strings.FirstWeek.day1Message
        case 2, 3:
            return Strings.FirstWeek.days2to3Message
        case 4, 5:
            return Strings.FirstWeek.days4to5Message
        case 6, 7:
            return Strings.FirstWeek.days6to7Message
        default:
            return Strings.FirstWeek.days6to7Message
        }
    }

    /// Potty training line (nil if no data or day 1)
    var pottyLine: String? {
        guard daysHome > 1 else { return nil }
        guard totalPottyCount > 0 else { return nil }

        return Strings.FirstWeek.outdoorPottyCount(count: outdoorPottyCount)
    }

    /// Crate training line (nil if suppressed, no data, or day 1)
    var crateLine: String? {
        guard daysHome > 1 else { return nil }
        guard !suppressCrateTraining else { return nil }

        // Not enough naps logged yet
        if !hasEnoughCrateData {
            return nil
        }

        // Naps logged but no locations specified
        if !hasLocationData {
            return Strings.FirstWeek.logNapLocationTip
        }

        // We have location data - show crate count
        if crateNapCount == 0 {
            return Strings.FirstWeek.noCrateNapsYet
        } else if crateNapCount == totalQualifyingNaps && crateNapCount > 0 {
            return Strings.FirstWeek.allNapsInCrate(count: crateNapCount)
        } else {
            return Strings.FirstWeek.crateNapCount(count: crateNapCount)
        }
    }

    /// Encouragement line
    var encouragementLine: String {
        Strings.FirstWeek.encouragement
    }
}
