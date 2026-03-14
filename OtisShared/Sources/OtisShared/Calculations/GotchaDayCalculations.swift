//
//  GotchaDayCalculations.swift
//  OtisShared
//
//  Gotcha Day anniversary calculations and detection

import Foundation

/// Utility for Gotcha Day (adoption anniversary) calculations
public struct GotchaDayCalculations {

    /// Check if today is the gotcha day anniversary
    /// - Parameter homeDate: The date the puppy came home
    /// - Returns: True if today is the anniversary (same month and day)
    public static func isGotchaDayToday(homeDate: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()

        // Must be at least 1 year since coming home
        guard let yearsHome = calendar.dateComponents([.year], from: homeDate, to: today).year,
              yearsHome >= 1 else {
            return false
        }

        // Check if month and day match
        let homeComponents = calendar.dateComponents([.month, .day], from: homeDate)
        let todayComponents = calendar.dateComponents([.month, .day], from: today)

        return homeComponents.month == todayComponents.month &&
               homeComponents.day == todayComponents.day
    }

    /// Calculate how many years since coming home
    /// - Parameter homeDate: The date the puppy came home
    /// - Returns: Number of complete years
    public static func yearsHome(from homeDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: homeDate, to: Date())
        return components.year ?? 0
    }

    /// Calculate gotcha day statistics from all events
    /// - Parameters:
    ///   - homeDate: The date the puppy came home
    ///   - puppyName: Name of the puppy
    ///   - events: All logged events
    ///   - masteredSkillsCount: Number of skills mastered (optional)
    /// - Returns: GotchaDayStats with lifetime totals
    public static func calculateStats(
        homeDate: Date,
        puppyName: String,
        events: [PuppyEvent],
        masteredSkillsCount: Int = 0
    ) -> GotchaDayStats {
        var totalWalks = 0
        var totalWalkMinutes = 0
        var totalPhotos = 0
        var totalTrainingSessions = 0
        var totalSocialEvents = 0
        var totalPottyEvents = 0
        var outdoorPottyCount = 0

        for event in events {
            switch event.type {
            case .uitlaten:
                totalWalks += 1
                totalWalkMinutes += event.durationMin ?? 0
            case .training:
                totalTrainingSessions += 1
            case .sociaal:
                totalSocialEvents += 1
            case .plassen, .poepen:
                totalPottyEvents += 1
                if event.location == .buiten {
                    outdoorPottyCount += 1
                }
            default:
                break
            }

            if event.media.hasPhoto {
                totalPhotos += 1
            }
        }

        return GotchaDayStats(
            homeDate: homeDate,
            puppyName: puppyName,
            yearsHome: yearsHome(from: homeDate),
            totalWalks: totalWalks,
            totalWalkMinutes: totalWalkMinutes,
            totalPhotos: totalPhotos,
            totalTrainingSessions: totalTrainingSessions,
            totalSocialEvents: totalSocialEvents,
            skillsMastered: masteredSkillsCount,
            totalPottyEvents: totalPottyEvents,
            outdoorPottyCount: outdoorPottyCount
        )
    }

    /// Get the first event (typically first day photo)
    /// - Parameter events: All events sorted by time
    /// - Returns: First event with a photo, or first event overall
    public static func firstDayEvent(from events: [PuppyEvent]) -> PuppyEvent? {
        let sorted = events.sorted { $0.time < $1.time }
        // Prefer first photo event
        if let firstPhoto = sorted.first(where: { $0.media.hasPhoto }) {
            return firstPhoto
        }
        return sorted.first
    }

    /// Get the most recent event with a photo
    /// - Parameter events: All events
    /// - Returns: Most recent photo event
    public static func latestPhotoEvent(from events: [PuppyEvent]) -> PuppyEvent? {
        events
            .filter { $0.media.hasPhoto }
            .sorted { $0.time > $1.time }
            .first
    }

    /// Get events from the first week at home (for "then" comparison)
    /// - Parameters:
    ///   - homeDate: The date the puppy came home
    ///   - events: All events
    /// - Returns: Events from the first week
    public static func firstWeekEvents(homeDate: Date, from events: [PuppyEvent]) -> [PuppyEvent] {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: homeDate) else {
            return []
        }

        return events
            .filter { $0.time >= homeDate && $0.time < weekEnd }
            .sorted { $0.time < $1.time }
    }
}
