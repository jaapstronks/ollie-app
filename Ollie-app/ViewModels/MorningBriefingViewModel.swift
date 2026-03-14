//
//  MorningBriefingViewModel.swift
//  Otis-app
//
//  ViewModel for loading and managing morning briefing data.
//

import Foundation
import Combine
import OtisShared
import os

private let logger = Logger.otis(category: "MorningBriefing")

@MainActor
final class MorningBriefingViewModel: ObservableObject {

    @Published private(set) var briefing: MorningBriefingResponse?
    @Published private(set) var isLoading = false

    /// Whether the card should be visible
    var shouldShow: Bool {
        isLoading || briefing != nil
    }

    // MARK: - Data Loading

    func loadBriefing(profile: PuppyProfile?, eventStore: EventStore) async {
        // Check first-week experience gate
        guard FirstWeekExperienceService.shared.shouldShowAIInsights else {
            logger.debug("First week experience: not showing AI insights yet")
            return
        }

        guard let profile = profile else {
            logger.debug("No profile available yet")
            return
        }

        // Check if AI is available
        guard AI.isAvailable(for: profile) else {
            logger.debug("AI not available for profile")
            return
        }

        // Check for cached result first
        if let cached = AI.cachedMorningBriefing(profileId: profile.id) {
            logger.debug("Using cached briefing")
            self.briefing = cached
            return
        }

        logger.debug("Loading fresh briefing...")
        isLoading = true
        defer { isLoading = false }

        // Morning briefing needs recent history for context
        // PERFORMANCE: Use async version to avoid blocking main thread
        let recentEvents = await eventStore.getEventsAsync(from: Date.daysAgo(14), to: Date())
        logger.debug("Got \(recentEvents.count) events from last 14 days")

        let result = await AI.requestMorningBriefing(
            profile: profile,
            events: recentEvents
        )

        switch result {
        case .success(let response):
            logger.debug("Success: \(response.headline)")
            self.briefing = response

        case .shadow(let response):
            logger.debug("Shadow mode: \(response.headline)")
            self.briefing = response

        case .fallback(let reason):
            logger.debug("Fallback: \(reason)")
        }
    }
}
