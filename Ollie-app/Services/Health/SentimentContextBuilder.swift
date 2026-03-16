//
//  SentimentContextBuilder.swift
//  Ollie-app
//
//  Builds context summaries for sentiment check-in questions.
//  Shows the user what we know about their logged activity before asking how things are going.
//

import Foundation
import OtisShared

struct SentimentContextBuilder {

    /// Build a context summary for a category based on logged events.
    /// Returns a string like "78% outdoor success this week, 2 accidents today."
    static func buildContext(
        for category: SentimentCategory,
        events: [PuppyEvent],
        profile: PuppyProfile
    ) -> String {
        switch category {
        case .pottyTraining:
            return buildPottyContext(events: events)
        case .benchTraining:
            return buildBenchContext(events: events)
        case .sleeping:
            return buildSleepContext(events: events)
        case .walks:
            return buildWalksContext(events: events)
        case .skillsTraining:
            return buildSkillsContext()
        case .nipping, .leashBehavior, .jumping, .resourceGuarding,
             .chewing, .barking, .separationAnxiety, .carTravel, .handlingTolerance:
            // These don't have logged events, just ask directly
            return Strings.Sentiment.noDataYet
        }
    }

    // MARK: - Private Builders

    private static func buildPottyContext(events: [PuppyEvent]) -> String {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let startOfToday = calendar.startOfDay(for: now)

        // Filter potty events
        let weekPotty = events.filter { event in
            event.time >= weekAgo &&
            (event.type == .plassen || event.type == .poepen)
        }

        let todayPotty = weekPotty.filter { $0.time >= startOfToday }

        guard !weekPotty.isEmpty else {
            return Strings.Sentiment.noDataYet
        }

        let outdoorCount = weekPotty.filter { $0.location == .buiten }.count
        let totalCount = weekPotty.count
        let outdoorPercent = totalCount > 0 ? (outdoorCount * 100 / totalCount) : 0

        let accidentsToday = todayPotty.filter { $0.location == .binnen }.count

        return Strings.Sentiment.pottyContext(outdoorPercent: outdoorPercent, accidentsToday: accidentsToday)
    }

    private static func buildBenchContext(events: [PuppyEvent]) -> String {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        // Filter naps (sleep events) this week
        let weekNaps = events.filter { event in
            event.time >= weekAgo && event.type == .slapen
        }

        guard !weekNaps.isEmpty else {
            return Strings.Sentiment.noDataYet
        }

        // Check nap location - crate is indicated by napLocation property
        let napsInCrate = weekNaps.filter { $0.napLocation == .crate }.count
        let totalNaps = weekNaps.count

        return Strings.Sentiment.benchContext(napsInCrate: napsInCrate, totalNaps: totalNaps)
    }

    private static func buildSleepContext(events: [PuppyEvent]) -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        // Simplified: count naps today and estimate avg night sleep
        let todayNaps = events.filter { event in
            event.time >= startOfToday && event.type == .slapen
        }.count

        // Try to calculate average night sleep (simplified - just count overnight sleep events)
        let weekSleepEvents = events.filter { event in
            event.time >= weekAgo && event.type == .slapen
        }

        // Rough estimate: assume average night is ~8 hours for a puppy
        // In reality we'd need to pair sleep/wake events
        let avgNightHours = weekSleepEvents.isEmpty ? 0.0 : 8.0

        if weekSleepEvents.isEmpty {
            return Strings.Sentiment.noDataYet
        }

        return Strings.Sentiment.sleepContext(avgNightHours: avgNightHours, napsToday: todayNaps)
    }

    private static func buildWalksContext(events: [PuppyEvent]) -> String {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let walks = events.filter { event in
            event.time >= weekAgo && event.type == .uitlaten
        }

        guard !walks.isEmpty else {
            return Strings.Sentiment.noDataYet
        }

        let walksCount = walks.count
        let totalDuration = walks.compactMap { $0.durationMin }.reduce(0, +)
        let avgDuration = walksCount > 0 ? totalDuration / walksCount : 0

        return Strings.Sentiment.walksContext(walksThisWeek: walksCount, avgDuration: avgDuration)
    }

    private static func buildSkillsContext() -> String {
        // Skill progress requires injected store - return generic message
        // The actual context would be provided by views that have access to the store
        return Strings.Sentiment.noDataYet
    }
}
