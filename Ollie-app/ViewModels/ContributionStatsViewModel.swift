//
//  ContributionStatsViewModel.swift
//  Otis-app
//
//  View model for managing contribution statistics
//

import Foundation
import Combine
import OtisShared

@Observable
@MainActor
final class ContributionStatsViewModel {
    private(set) var stats: [ContributionStats] = []
    private(set) var summary: ContributionSummary?
    private(set) var currentUserStats: ContributionStats?
    var selectedPeriod: ContributionPeriod = .thisWeek

    @ObservationIgnored
    private let eventStore: EventStore

    init(eventStore: EventStore) {
        self.eventStore = eventStore
    }

    /// Refresh contribution stats for the selected period
    /// PERFORMANCE: Use async event fetch to avoid blocking main thread
    func refresh() {
        Task {
            await refreshAsync()
        }
    }

    /// Async refresh implementation
    private func refreshAsync() async {
        let period = selectedPeriod.dateInterval
        // PERFORMANCE: Use async version to avoid blocking main thread
        let events = await eventStore.getEventsAsync(from: period.start, to: period.end)
        let currentUserRecordID = UserIdentityStore.shared.currentUserRecordID

        // Calculate stats with name resolution via ParticipantResolver
        let calculated = ContributionCalculations.calculate(
            events: events,
            period: period,
            currentUserRecordID: currentUserRecordID
        ) { recordID in
            ParticipantResolver.shared.resolve(cloudKitRecordID: recordID).displayName
        }

        stats = calculated
        summary = ContributionCalculations.getSummary(stats: calculated)
        currentUserStats = calculated.first { $0.isCurrentUser }
    }

    /// Change the selected period and refresh
    func selectPeriod(_ period: ContributionPeriod) {
        selectedPeriod = period
        refresh()
    }

    /// Whether there are multiple contributors (team mode)
    var hasTeam: Bool {
        stats.count > 1
    }
}
