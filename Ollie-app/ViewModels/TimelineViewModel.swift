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

    /// Sheet coordinator for all sheet presentations
    @Published var sheetCoordinator = SheetCoordinator()

    let eventStore: EventStore
    let profileStore: ProfileStore
    var notificationService: NotificationService?

    init(eventStore: EventStore, profileStore: ProfileStore, notificationService: NotificationService? = nil) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.notificationService = notificationService
        loadEvents()
    }

    // MARK: - Convenience Accessors for Sheet State

    /// Pending event type from sheet coordinator
    var pendingEventType: EventType? {
        sheetCoordinator.pendingEventType
    }

    /// Media picker source from sheet coordinator
    var mediaPickerSource: MediaPickerSource {
        sheetCoordinator.mediaPickerSource
    }

    /// Event pending deletion from sheet coordinator
    var eventToDelete: PuppyEvent? {
        sheetCoordinator.eventToDelete
    }

    /// Whether undo banner is showing
    var showingUndoBanner: Bool {
        sheetCoordinator.showingUndoBanner
    }

    /// Last deleted event for undo
    var lastDeletedEvent: PuppyEvent? {
        sheetCoordinator.lastDeletedEvent
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

    // MARK: - Premium/Monetization

    /// Whether the user can log events (premium or still in free period)
    var canLogEvents: Bool {
        profileStore.profile?.canLogEvents ?? true
    }

    /// Days remaining in free trial (-1 if premium)
    var freeDaysRemaining: Int {
        profileStore.profile?.freeDaysRemaining ?? 21
    }

    /// Whether to show the trial banner (last 7 days of trial)
    var shouldShowTrialBanner: Bool {
        guard let profile = profileStore.profile else { return false }
        return !profile.isPremiumUnlocked && profile.freeDaysRemaining > 0 && profile.freeDaysRemaining <= 7
    }

    // MARK: - Quick Log

    func quickLog(type: EventType) {
        guard canLogEvents else {
            sheetCoordinator.presentSheet(.upgradePrompt)
            return
        }
        // V2: All events now go through QuickLogSheet for time adjustment
        sheetCoordinator.presentSheet(.quickLog(type))
    }

    /// Quick log with immediate location (used by FAB quick actions)
    func quickLogWithLocation(type: EventType, location: EventLocation) {
        guard canLogEvents else {
            sheetCoordinator.presentSheet(.upgradePrompt)
            return
        }
        // Log immediately with the provided location
        logEvent(type: type, location: location)
        HapticFeedback.success()
    }

    /// Log event with time, location, and note from QuickLogSheet
    func logFromQuickSheet(time: Date, location: EventLocation?, note: String?) {
        guard let type = pendingEventType else { return }
        logEvent(type: type, time: time, location: location, note: note)
        sheetCoordinator.dismissSheet()
    }

    func cancelQuickLogSheet() {
        sheetCoordinator.dismissSheet()
    }

    // Legacy: kept for backwards compatibility
    func logWithLocation(location: EventLocation) {
        guard let type = pendingEventType else { return }
        logEvent(type: type, location: location)
        sheetCoordinator.dismissSheet()
    }

    func cancelLocationPicker() {
        sheetCoordinator.dismissSheet()
    }

    func openLogSheet(for type: EventType) {
        sheetCoordinator.presentSheet(.logEvent(type))
    }

    func showAllEvents() {
        guard canLogEvents else {
            sheetCoordinator.presentSheet(.upgradePrompt)
            return
        }
        sheetCoordinator.presentSheet(.allEvents)
    }

    // MARK: - Potty Quick Log (V3: combined plassen/poepen)

    func showPottySheet() {
        guard canLogEvents else {
            sheetCoordinator.presentSheet(.upgradePrompt)
            return
        }
        sheetCoordinator.presentSheet(.potty)
    }

    func cancelPottySheet() {
        sheetCoordinator.dismissSheet()
    }

    func logPottyEvent(selection: PottySelection, time: Date, location: EventLocation, note: String?) {
        switch selection {
        case .plassen:
            logEvent(type: .plassen, time: time, location: location, note: note)
        case .poepen:
            logEvent(type: .poepen, time: time, location: location, note: note)
        case .beide:
            // Log both events at the same time
            logEvent(type: .plassen, time: time, location: location, note: note)
            logEvent(type: .poepen, time: time, location: location, note: note)
        }
        sheetCoordinator.dismissSheet()
    }

    // MARK: - Quick Log Context

    var quickLogContext: QuickLogContext {
        QuickLogContext(
            sleepState: currentSleepState,
            mealSchedule: profileStore.profile?.mealSchedule,
            todayEvents: events
        )
    }

    // MARK: - Photo Moment Capture

    func openCamera() {
        guard canLogEvents else {
            sheetCoordinator.presentSheet(.upgradePrompt)
            return
        }
        sheetCoordinator.presentSheet(.mediaPicker(.camera))
    }

    func openPhotoLibrary() {
        guard canLogEvents else {
            sheetCoordinator.presentSheet(.upgradePrompt)
            return
        }
        sheetCoordinator.presentSheet(.mediaPicker(.library))
    }

    func dismissMediaPicker() {
        sheetCoordinator.dismissSheet()
    }

    func showLogMomentSheet() {
        sheetCoordinator.presentSheet(.logMoment)
    }

    func dismissLogMomentSheet() {
        sheetCoordinator.dismissSheet()
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
        refreshNotifications()
    }

    /// Add a pre-built event (used for photo moments)
    func addEvent(_ event: PuppyEvent) {
        eventStore.addEvent(event)
        loadEvents()
        refreshNotifications()
    }

    // MARK: - Delete with Confirmation

    /// Request to delete an event (shows confirmation)
    func requestDeleteEvent(_ event: PuppyEvent) {
        sheetCoordinator.requestDeleteEvent(event)
    }

    /// Confirm deletion after user approval
    func confirmDeleteEvent() {
        guard let event = sheetCoordinator.eventToDelete else { return }
        deleteEventWithUndo(event)
        sheetCoordinator.clearDeleteConfirmation()
    }

    /// Cancel deletion
    func cancelDeleteEvent() {
        sheetCoordinator.clearDeleteConfirmation()
    }

    /// Binding for delete confirmation dialog
    var showingDeleteConfirmation: Binding<Bool> {
        Binding(
            get: { self.sheetCoordinator.showingDeleteConfirmation },
            set: { self.sheetCoordinator.showingDeleteConfirmation = $0 }
        )
    }

    /// Delete event with undo capability
    func deleteEventWithUndo(_ event: PuppyEvent) {
        // Actually delete
        eventStore.deleteEvent(event)
        loadEvents()
        refreshNotifications()

        HapticFeedback.warning()

        // Show undo banner
        sheetCoordinator.showUndo(for: event)
    }

    /// Direct delete (from swipe, no confirmation needed but with undo)
    func deleteEvent(_ event: PuppyEvent) {
        deleteEventWithUndo(event)
    }

    /// Undo the last deletion
    func undoDelete() {
        guard let event = sheetCoordinator.popLastDeletedEvent() else { return }
        eventStore.addEvent(event)
        loadEvents()
        refreshNotifications()
        HapticFeedback.success()
    }

    /// Dismiss the undo banner
    func dismissUndoBanner() {
        sheetCoordinator.dismissUndoBanner()
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
            return Strings.TimeFormat.noData
        }

        if minutes < 60 {
            return Strings.TimeFormat.minutesAgo(minutes)
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return Strings.TimeFormat.hoursAgo(hours)
            }
            return Strings.TimeFormat.hoursMinutesAgo(hours: hours, minutes: mins)
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

    /// Predicted time for next potty break (for weather alerts)
    var predictedNextPlasTime: Date? {
        guard let minutes = predictedNextPlasMinutes else { return nil }
        return Date().addingTimeInterval(Double(minutes) * 60)
    }

    // MARK: - Sleep Status

    /// Current sleep state (sleeping, awake, or unknown)
    var currentSleepState: SleepState {
        let recentEvents = getRecentEvents()
        return SleepCalculations.currentSleepState(events: recentEvents)
    }

    // MARK: - Poop Slot Status

    /// Current poop slot status for the day
    var poopSlotStatus: PoopSlotStatus {
        PoopCalculations.calculateStatus(todayEvents: events)
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

    // MARK: - Upcoming Events

    /// Upcoming meals and walks for today, with optional weather forecasts
    func upcomingItems(forecasts: [HourForecast] = []) -> [UpcomingItem] {
        guard let profile = profileStore.profile else { return [] }
        return UpcomingCalculations.calculateUpcoming(
            events: events,
            mealSchedule: profile.mealSchedule,
            walkSchedule: profile.walkSchedule,
            forecasts: forecasts,
            date: currentDate
        )
    }

    /// Whether current view is showing today
    var isShowingToday: Bool {
        Calendar.current.isDateInToday(currentDate)
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

    // MARK: - Notifications

    /// Refresh scheduled notifications after events change
    private func refreshNotifications() {
        guard let service = notificationService,
              let profile = profileStore.profile else { return }

        Task {
            let recentEvents = getRecentEvents()
            await service.refreshNotifications(events: recentEvents, profile: profile)
        }
    }
}
