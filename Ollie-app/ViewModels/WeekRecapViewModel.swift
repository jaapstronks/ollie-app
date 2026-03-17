//
//  WeekRecapViewModel.swift
//  Otis-app
//
//  ViewModel for the Weekly Recap feature

import Combine
import OtisShared
import SwiftUI

@Observable
@MainActor
final class WeekRecapViewModel {

    // MARK: - State

    var currentStats: WeekSummaryStats?
    var photoEvents: [PuppyEvent] = []
    var selectedWeekStart: Date
    var isLoading: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let eventStore: EventStore
    @ObservationIgnored private let profileStore: ProfileStore
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(eventStore: EventStore, profileStore: ProfileStore, initialWeek: Date? = nil) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.selectedWeekStart = initialWeek ?? WeekCalculations.previousWeekStart()

        setupBindings()
        loadStats(for: selectedWeekStart)
    }

    // MARK: - Public Methods

    /// Navigate to the previous week
    func goToPreviousWeek() {
        let calendar = Calendar.current
        selectedWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart) ?? selectedWeekStart
        loadStats(for: selectedWeekStart)
    }

    /// Navigate to the next week
    func goToNextWeek() {
        guard canGoToNextWeek else { return }
        let calendar = Calendar.current
        selectedWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart) ?? selectedWeekStart
        loadStats(for: selectedWeekStart)
    }

    /// Select a specific week
    func selectWeek(_ weekStart: Date) {
        selectedWeekStart = weekStart
        loadStats(for: selectedWeekStart)
    }

    /// Refresh data for the current week
    func refresh() {
        loadStats(for: selectedWeekStart)
    }

    // MARK: - Computed Properties

    /// Puppy name from profile
    var puppyName: String {
        profileStore.profile?.name ?? "Your pup"
    }

    /// Whether we can navigate to the next week (can't go to current incomplete week)
    var canGoToNextWeek: Bool {
        selectedWeekStart < WeekCalculations.previousWeekStart()
    }

    /// Whether the selected week has any data
    var hasData: Bool {
        currentStats?.hasData ?? false
    }

    /// Up to 6 photos for display in the sheet
    var displayPhotos: [PuppyEvent] {
        Array(photoEvents.prefix(6))
    }

    /// Up to 4 photos for the share card
    var shareCardPhotos: [PuppyEvent] {
        Array(photoEvents.prefix(4))
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Reload when events change
        // Note: EventStore is @Observable, not ObservableObject, so we use notifications
        NotificationCenter.default.publisher(for: .eventsDidChange)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.loadStats(for: self.selectedWeekStart)
            }
            .store(in: &cancellables)
    }

    private func loadStats(for weekStart: Date) {
        isLoading = true

        currentStats = WeekCalculations.calculateWeekSummary(
            weekStart: weekStart,
            puppyName: puppyName,
            events: eventStore.events
        )

        photoEvents = WeekCalculations.photoEvents(for: weekStart, from: eventStore.events)

        isLoading = false
    }
}

// MARK: - Tease Card Logic

extension WeekRecapViewModel {

    /// Whether to show the weekly recap tease card
    /// Shows on Sundays (end of week) or Mondays (start of new week)
    static func shouldShowRecapCard(for date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Sunday = 1, Monday = 2
        return weekday == 1 || weekday == 2
    }

    /// Title for the recap card
    static func recapCardTitle(for date: Date = Date()) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        if weekday == 2 { // Monday
            return Strings.Recap.weekRecapReady
        } else {
            return Strings.Recap.weekRecapTitle
        }
    }

    /// The week to show for the recap (previous completed week)
    static func recapWeekStart(for date: Date = Date()) -> Date {
        WeekCalculations.previousWeekStart()
    }
}
