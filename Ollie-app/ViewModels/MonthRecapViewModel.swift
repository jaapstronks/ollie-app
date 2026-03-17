//
//  MonthRecapViewModel.swift
//  Otis-app
//
//  ViewModel for the Monthly Recap feature

import Combine
import OtisShared
import SwiftUI

@Observable
@MainActor
final class MonthRecapViewModel {

    // MARK: - State

    var currentStats: MonthSummaryStats?
    var photoEvents: [PuppyEvent] = []
    var selectedMonth: Date
    var availableMonths: [Date] = []
    var isLoading: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let eventStore: EventStore
    @ObservationIgnored private let profileStore: ProfileStore
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(eventStore: EventStore, profileStore: ProfileStore, initialMonth: Date? = nil) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.selectedMonth = initialMonth ?? Date().previousMonth

        setupBindings()
        loadAvailableMonths()
        loadStats(for: selectedMonth)
    }

    // MARK: - Public Methods

    /// Navigate to the previous month
    func goToPreviousMonth() {
        guard canGoToPreviousMonth else { return }
        selectedMonth = selectedMonth.previousMonth
        loadStats(for: selectedMonth)
    }

    /// Navigate to the next month
    func goToNextMonth() {
        guard canGoToNextMonth else { return }
        let calendar = Calendar.current
        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        loadStats(for: selectedMonth)
    }

    /// Select a specific month
    func selectMonth(_ month: Date) {
        selectedMonth = month
        loadStats(for: selectedMonth)
    }

    /// Refresh data for the current month
    func refresh() {
        loadAvailableMonths()
        loadStats(for: selectedMonth)
    }

    // MARK: - Computed Properties

    /// Puppy name from profile
    var puppyName: String {
        profileStore.profile?.name ?? "Your pup"
    }

    /// Whether we can navigate to the previous month
    var canGoToPreviousMonth: Bool {
        guard let firstMonth = availableMonths.last else { return false }
        return selectedMonth > firstMonth
    }

    /// Whether we can navigate to the next month (can't go beyond current month)
    var canGoToNextMonth: Bool {
        selectedMonth < Date().startOfMonth
    }

    /// Whether the selected month has any data
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
                self.loadAvailableMonths()
                self.loadStats(for: self.selectedMonth)
            }
            .store(in: &cancellables)
    }

    private func loadAvailableMonths() {
        availableMonths = MonthCalculations.availableMonths(from: eventStore.events)
    }

    private func loadStats(for month: Date) {
        isLoading = true

        currentStats = MonthCalculations.calculateMonthStats(
            month: month,
            puppyName: puppyName,
            events: eventStore.events
        )

        photoEvents = MonthCalculations.photoEvents(for: month, from: eventStore.events)

        isLoading = false
    }
}

// MARK: - Tease Card Logic

extension MonthRecapViewModel {

    /// Whether to show the recap tease card on TodayView
    /// Shows on days 28-31 ("Month almost complete") or days 1-3 ("Your recap is ready!")
    static func shouldShowRecapCard(for date: Date = Date()) -> Bool {
        date.isNearEndOfMonth || date.isStartOfMonth
    }

    /// Title for the recap card based on timing
    static func recapCardTitle(for date: Date = Date(), puppyName: String) -> String {
        if date.isStartOfMonth {
            return Strings.Recap.cardTitleReady
        } else {
            return "\(Strings.Recap.cardTitle) \(puppyName)"
        }
    }

    /// Subtitle for the recap card
    static func recapCardSubtitle(for date: Date = Date()) -> String {
        if date.isStartOfMonth {
            return Strings.Recap.viewRecap
        } else {
            return Strings.Recap.almostComplete
        }
    }

    /// The month to show for the recap (previous month if at start, current month otherwise)
    static func recapMonth(for date: Date = Date()) -> Date {
        if date.isStartOfMonth {
            return date.previousMonth
        } else {
            return date
        }
    }
}
