//
//  YearRecapViewModel.swift
//  Otis-app
//
//  ViewModel for the Year in Review feature

import Combine
import OtisShared
import SwiftUI

@MainActor
final class YearRecapViewModel: ObservableObject {

    // MARK: - Published State

    @Published var recap: YearRecap?
    @Published var photoEvents: [PuppyEvent] = []
    @Published var selectedYear: Int
    @Published var availableYears: [Int] = []
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let eventStore: EventStore
    private let profileStore: ProfileStore
    private let weightStore: WeightStore
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        eventStore: EventStore,
        profileStore: ProfileStore,
        weightStore: WeightStore,
        initialYear: Int? = nil
    ) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.weightStore = weightStore

        // Default to recap year (previous year in January, current year otherwise)
        self.selectedYear = initialYear ?? Self.recapYear()

        setupBindings()
        loadAvailableYears()
        loadRecap(for: selectedYear)
    }

    // MARK: - Public Methods

    /// Navigate to the previous year
    func goToPreviousYear() {
        guard canGoToPreviousYear else { return }
        selectedYear -= 1
        loadRecap(for: selectedYear)
    }

    /// Navigate to the next year
    func goToNextYear() {
        guard canGoToNextYear else { return }
        selectedYear += 1
        loadRecap(for: selectedYear)
    }

    /// Select a specific year
    func selectYear(_ year: Int) {
        selectedYear = year
        loadRecap(for: selectedYear)
    }

    /// Refresh data for the current year
    func refresh() {
        loadAvailableYears()
        loadRecap(for: selectedYear)
    }

    // MARK: - Computed Properties

    /// Puppy name from profile
    var puppyName: String {
        profileStore.profile?.name ?? "Your pup"
    }

    /// Whether we can navigate to the previous year
    var canGoToPreviousYear: Bool {
        guard let firstYear = availableYears.last else { return false }
        return selectedYear > firstYear
    }

    /// Whether we can navigate to the next year
    var canGoToNextYear: Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        return selectedYear < currentYear
    }

    /// Whether the selected year has any data
    var hasData: Bool {
        recap?.hasData ?? false
    }

    /// Up to 6 photos for display in the sheet
    var displayPhotos: [PuppyEvent] {
        Array(photoEvents.prefix(6))
    }

    /// Up to 4 photos for the share card
    var shareCardPhotos: [PuppyEvent] {
        Array(photoEvents.prefix(4))
    }

    /// Best photo for the share card (first one)
    var bestPhoto: PuppyEvent? {
        photoEvents.first
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Reload when events change
        eventStore.$events
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.loadAvailableYears()
                self.loadRecap(for: self.selectedYear)
            }
            .store(in: &cancellables)
    }

    private func loadAvailableYears() {
        availableYears = YearCalculations.availableYears(from: eventStore.events)
    }

    private func loadRecap(for year: Int) {
        isLoading = true

        let profile = profileStore.profile
        let birthDate = profile?.birthDate

        recap = YearCalculations.generateRecap(
            year: year,
            events: eventStore.events,
            puppyName: puppyName,
            weightMeasurements: weightStore.measurements,
            birthDate: birthDate
        )

        photoEvents = YearCalculations.photoEvents(for: year, from: eventStore.events)

        isLoading = false
    }
}

// MARK: - Tease Card Logic

extension YearRecapViewModel {

    /// Whether to show the year recap tease card on TodayView
    /// Shows December 15 - January 15
    static func shouldShowRecapCard(for date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // December 15-31
        if month == 12 && day >= 15 {
            return true
        }

        // January 1-15
        if month == 1 && day <= 15 {
            return true
        }

        return false
    }

    /// The year to show for the recap
    /// Previous year in January, current year otherwise
    static func recapYear(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        // In January, show previous year's recap
        if month == 1 {
            return year - 1
        }

        return year
    }

    /// Title for the recap card
    static func recapCardTitle(for date: Date = Date()) -> String {
        let month = Calendar.current.component(.month, from: date)

        if month == 1 {
            return Strings.Recap.yearRecapReady
        } else {
            return Strings.Recap.yearInReview
        }
    }

    /// Subtitle for the recap card
    static func recapCardSubtitle(for date: Date = Date(), puppyName: String) -> String {
        let year = recapYear(for: date)
        return Strings.Recap.yearWith(year: year, name: puppyName)
    }
}
