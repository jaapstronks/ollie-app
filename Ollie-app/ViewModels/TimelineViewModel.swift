//
//  TimelineViewModel.swift
//  Ollie-app
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for the timeline view, manages event display and logging
@MainActor
class TimelineViewModel: ObservableObject {
    @Published var currentDate: Date = Date()
    @Published var events: [PuppyEvent] = []
    @Published var showingLogSheet: Bool = false
    @Published var selectedEventType: EventType?
    @Published var showingLocationPicker: Bool = false
    @Published var pendingPottyType: EventType?

    // Quick log sheet state (V2: time adjustment)
    @Published var showingQuickLogSheet: Bool = false
    @Published var pendingEventType: EventType?

    // All events sheet state (V2: expandable bar)
    @Published var showingAllEventsSheet: Bool = false

    // Confirmation dialog state
    @Published var showingDeleteConfirmation: Bool = false
    @Published var eventToDelete: PuppyEvent?

    // Undo state
    @Published var showingUndoBanner: Bool = false
    @Published var lastDeletedEvent: PuppyEvent?
    private var undoTask: Task<Void, Never>?

    let eventStore: EventStore
    let profileStore: ProfileStore

    init(eventStore: EventStore, profileStore: ProfileStore) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        loadEvents()
    }

    // MARK: - Navigation

    var dateTitle: String {
        currentDate.relativeDayString
    }

    var canGoForward: Bool {
        !Calendar.current.isDateInToday(currentDate)
    }

    func goToPreviousDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        loadEvents()
    }

    func goToNextDay() {
        guard canGoForward else { return }
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        loadEvents()
    }

    func goToToday() {
        currentDate = Date()
        loadEvents()
    }

    func goToDate(_ date: Date) {
        currentDate = date
        loadEvents()
    }

    // MARK: - Event Loading

    func loadEvents() {
        eventStore.loadEvents(for: currentDate)
        events = eventStore.events
    }

    // MARK: - Quick Log

    func quickLog(type: EventType) {
        // V2: All events now go through QuickLogSheet for time adjustment
        pendingEventType = type
        showingQuickLogSheet = true
    }

    /// Log event with time, location, and note from QuickLogSheet
    func logFromQuickSheet(time: Date, location: EventLocation?, note: String?) {
        guard let type = pendingEventType else { return }
        logEvent(type: type, time: time, location: location, note: note)
        pendingEventType = nil
        showingQuickLogSheet = false
    }

    func cancelQuickLogSheet() {
        pendingEventType = nil
        showingQuickLogSheet = false
    }

    // Legacy: kept for backwards compatibility
    func logWithLocation(location: EventLocation) {
        guard let type = pendingPottyType else { return }
        logEvent(type: type, location: location)
        pendingPottyType = nil
        showingLocationPicker = false
    }

    func cancelLocationPicker() {
        pendingPottyType = nil
        showingLocationPicker = false
    }

    func openLogSheet(for type: EventType) {
        selectedEventType = type
        showingLogSheet = true
    }

    func showAllEvents() {
        showingAllEventsSheet = true
    }

    // MARK: - Event CRUD

    func logEvent(
        type: EventType,
        time: Date = Date(),
        location: EventLocation? = nil,
        note: String? = nil,
        who: String? = nil,
        exercise: String? = nil,
        result: String? = nil,
        durationMin: Int? = nil
    ) {
        let event = PuppyEvent(
            time: time,
            type: type,
            location: location,
            note: note,
            who: who,
            exercise: exercise,
            result: result,
            durationMin: durationMin
        )

        eventStore.addEvent(event)
        loadEvents()
    }

    // MARK: - Delete with Confirmation

    /// Request to delete an event (shows confirmation)
    func requestDeleteEvent(_ event: PuppyEvent) {
        eventToDelete = event
        showingDeleteConfirmation = true
    }

    /// Confirm deletion after user approval
    func confirmDeleteEvent() {
        guard let event = eventToDelete else { return }
        deleteEventWithUndo(event)
        eventToDelete = nil
        showingDeleteConfirmation = false
    }

    /// Cancel deletion
    func cancelDeleteEvent() {
        eventToDelete = nil
        showingDeleteConfirmation = false
    }

    /// Delete event with undo capability
    func deleteEventWithUndo(_ event: PuppyEvent) {
        // Store for undo
        lastDeletedEvent = event
        showingUndoBanner = true

        // Actually delete
        eventStore.deleteEvent(event)
        loadEvents()

        HapticFeedback.warning()

        // Auto-hide undo banner after 5 seconds
        undoTask?.cancel()
        undoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled {
                dismissUndoBanner()
            }
        }
    }

    /// Direct delete (from swipe, no confirmation needed but with undo)
    func deleteEvent(_ event: PuppyEvent) {
        deleteEventWithUndo(event)
    }

    /// Undo the last deletion
    func undoDelete() {
        guard let event = lastDeletedEvent else { return }
        eventStore.addEvent(event)
        loadEvents()
        dismissUndoBanner()
        HapticFeedback.success()
    }

    /// Dismiss the undo banner
    func dismissUndoBanner() {
        undoTask?.cancel()
        undoTask = nil
        showingUndoBanner = false
        lastDeletedEvent = nil
    }

    // MARK: - Stats

    var lastPlasEvent: PuppyEvent? {
        eventStore.lastEvent(ofType: .plassen)
    }

    var minutesSinceLastPlas: Int? {
        guard let last = lastPlasEvent else { return nil }
        return Date().minutesSince(last.time)
    }

    var timeSinceLastPlasText: String {
        guard let minutes = minutesSinceLastPlas else {
            return "Geen data"
        }

        if minutes < 60 {
            return "\(minutes) min geleden"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) uur geleden"
            }
            return "\(hours)u \(mins)m geleden"
        }
    }

    /// Predicted minutes until next potty break
    var predictedNextPlasMinutes: Int? {
        guard let profile = profileStore.profile else { return nil }
        let config = profile.predictionConfig

        // Simple prediction: default gap minus time since last
        guard let minutesSince = minutesSinceLastPlas else {
            return config.defaultGapMinutes
        }

        let remaining = config.defaultGapMinutes - minutesSince
        return max(0, remaining)
    }

    // MARK: - Sleep Status

    /// Current sleep state (sleeping, awake, or unknown)
    var currentSleepState: SleepState {
        let recentEvents = getRecentEvents()
        return SleepCalculations.currentSleepState(events: recentEvents)
    }

    // MARK: - Potty Predictions

    /// Current potty prediction with urgency level and triggers
    var pottyPrediction: PottyPrediction {
        guard let profile = profileStore.profile else {
            return PottyPrediction(
                urgency: .unknown,
                trigger: .none,
                expectedGapMinutes: 90,
                minutesSinceLast: nil,
                lastWasIndoor: false
            )
        }

        let recentEvents = getRecentEvents()
        return PredictionCalculations.calculatePrediction(
            events: recentEvents,
            config: profile.predictionConfig
        )
    }

    /// Puppy name for display
    var puppyName: String {
        profileStore.profile?.name ?? "Puppy"
    }

    // MARK: - Streaks

    /// Current streak information
    var streakInfo: StreakInfo {
        // Get all events for accurate streak calculation
        let allEvents = getAllEvents()
        return StreakCalculations.getStreakInfo(events: allEvents)
    }

    // MARK: - Daily Digest

    /// Daily digest summary for current date
    var dailyDigest: DailyDigest {
        DigestCalculations.generateDigest(
            events: events,
            profile: profileStore.profile,
            date: currentDate
        )
    }

    // MARK: - Pattern Analysis

    /// Pattern analysis for last 7 days
    var patternAnalysis: PatternAnalysis {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())
        return PatternCalculations.analyzePatterns(events: recentEvents, periodDays: 7)
    }

    /// Get all events (up to 30 days back for streak history)
    private func getAllEvents() -> [PuppyEvent] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return eventStore.getEvents(from: thirtyDaysAgo, to: Date())
    }

    // MARK: - Private Helpers

    /// Get events from today and yesterday (for cross-midnight tracking)
    private func getRecentEvents() -> [PuppyEvent] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        return eventStore.getEvents(from: yesterday, to: currentDate)
    }
}
