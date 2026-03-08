//
//  ContributionStatsViewModel.swift
//  Otis-app
//
//  View model for managing contribution statistics
//

import Foundation
import Combine
import OtisShared

@MainActor
final class ContributionStatsViewModel: ObservableObject {
    @Published private(set) var stats: [ContributionStats] = []
    @Published private(set) var summary: ContributionSummary?
    @Published private(set) var currentUserStats: ContributionStats?
    @Published var selectedPeriod: ContributionPeriod = .thisWeek

    private let eventStore: EventStore

    init(eventStore: EventStore) {
        self.eventStore = eventStore
    }

    /// Refresh contribution stats for the selected period
    func refresh() {
        let period = selectedPeriod.dateInterval
        let events = eventStore.getEvents(from: period.start, to: period.end)
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
