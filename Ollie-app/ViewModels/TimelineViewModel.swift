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

    // MARK: - Activity State

    /// Currently in-progress activity (walk or nap)
    @Published var currentActivity: InProgressActivity?

    /// Whether a walk is currently in progress
    var isWalkInProgress: Bool {
        currentActivity?.type == .walk
    }

    /// Whether a nap is currently in progress
    var isNapInProgress: Bool {
        currentActivity?.type == .nap
    }

    // MARK: - Cached Stats (to avoid recomputation every frame)

    /// Cached pattern analysis (updated when events change)
    @Published private(set) var cachedPatternAnalysis: PatternAnalysis?

    /// Cached recent events for stats (7 days)
    @Published private(set) var cachedRecentEvents: [PuppyEvent] = []

    /// Cached week stats for insights view
    @Published private(set) var cachedWeekStats: [DayStats] = []

    /// Last time stats were computed
    private var lastStatsUpdate: Date?

    /// Background notification task (stored for cancellation)
    private var notificationTask: Task<Void, Never>?

    /// Subscription to forward SheetCoordinator changes
    private var sheetCoordinatorCancellable: AnyCancellable?

    let eventStore: EventStore
    let profileStore: ProfileStore
    var notificationService: NotificationService?
    var spotStore: SpotStore?
    var locationManager: LocationManager?
    var medicationStore: MedicationStore?

    init(
        eventStore: EventStore,
        profileStore: ProfileStore,
        notificationService: NotificationService? = nil,
        spotStore: SpotStore? = nil,
        locationManager: LocationManager? = nil,
        medicationStore: MedicationStore? = nil
    ) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.notificationService = notificationService
        self.spotStore = spotStore
        self.locationManager = locationManager
        self.medicationStore = medicationStore

        // Forward SheetCoordinator's objectWillChange to this ViewModel
        // This ensures views are notified when sheet state changes
        sheetCoordinatorCancellable = sheetCoordinator.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        loadEvents()
    }

    // MARK: - Convenience Accessors for Sheet State

    /// Active sheet binding for SwiftUI sheet(item:) modifier
    /// This binding is needed because $viewModel.sheetCoordinator.activeSheet
    /// doesn't properly trigger view updates with nested ObservableObjects
    var activeSheetBinding: Binding<SheetCoordinator.ActiveSheet?> {
        Binding(
            get: { self.sheetCoordinator.activeSheet },
            set: { self.sheetCoordinator.activeSheet = $0 }
        )
    }

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
        !currentDate.isToday
    }

    func goToPreviousDay() {
        currentDate = currentDate.addingDays(-1)
        loadEvents()
    }

    func goToNextDay() {
        guard canGoForward else { return }
        currentDate = currentDate.addingDays(1)
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
        refreshCachedStats()
    }

    /// Refresh cached stats (debounced, only if data changed)
    private func refreshCachedStats() {
        // Debounce: only update if more than 1 second since last update
        let now = Date()
        if let lastUpdate = lastStatsUpdate, now.timeIntervalSince(lastUpdate) < 1.0 {
            return
        }
        lastStatsUpdate = now

        // Update cached recent events
        let sevenDaysAgo = Date().addingDays(-7)
        cachedRecentEvents = eventStore.getEvents(from: sevenDaysAgo, to: Date())

        // Update cached pattern analysis
        cachedPatternAnalysis = PatternCalculations.analyzePatterns(
            events: cachedRecentEvents,
            periodDays: 7
        )

        // Update cached week stats
        cachedWeekStats = WeekCalculations.calculateWeekStats { date in
            let startOfDay = date.startOfDay
            let endOfDay = date.addingDays(1).startOfDay
            return eventStore.getEvents(from: startOfDay, to: endOfDay)
        }
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

    func quickLog(type: EventType, suggestedTime: Date? = nil) {
        guard canLogEvents else {
            sheetCoordinator.presentSheet(.upgradePrompt)
            return
        }
        // V2: All events now go through QuickLogSheet for time adjustment
        // Pass suggested time for overdue items (e.g., scheduled meal time)
        sheetCoordinator.presentSheet(.quickLog(type, suggestedTime: suggestedTime))
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

    // MARK: - Activity Tracking (Walks & Naps)

    /// Start a new activity (walk or nap)
    func startActivity(type: ActivityType) {
        currentActivity = InProgressActivity(type: type, startTime: Date())
        sheetCoordinator.dismissSheet()
        HapticFeedback.success()
    }

    /// End the current activity
    func endActivity(minutesAgo: Int, note: String?) {
        guard let activity = currentActivity else { return }

        let endTime = Date().addingTimeInterval(-Double(minutesAgo) * 60)
        let duration = Int(endTime.timeIntervalSince(activity.startTime) / 60)

        // Log the appropriate event type
        let eventType: EventType = activity.type == .walk ? .uitlaten : .slapen

        // Generate sleepSessionId for nap activities to link sleep + wake events
        let sleepSessionId: UUID? = activity.type == .nap ? UUID() : nil

        logEvent(
            type: eventType,
            time: activity.startTime,
            location: eventType == .uitlaten ? .buiten : nil,
            note: note,
            durationMin: max(1, duration),
            sleepSessionId: sleepSessionId
        )

        // If it was a nap, also log wake-up with same session ID
        if activity.type == .nap {
            logEvent(type: .ontwaken, time: endTime, sleepSessionId: sleepSessionId)
        }

        currentActivity = nil
        sheetCoordinator.dismissSheet()
        HapticFeedback.success()
    }

    /// Cancel/discard the current activity without logging
    func cancelActivity() {
        currentActivity = nil
        sheetCoordinator.dismissSheet()
    }

    /// Log a wake-up event at the specified time (for EndSleepSheet)
    func logWakeUp(time: Date) {
        // Find the ongoing sleep session ID to link this wake event
        let recentEvents = getRecentEvents()
        let sleepSessionId = SleepSession.ongoingSleepSessionId(from: recentEvents)
        logEvent(type: .ontwaken, time: time, sleepSessionId: sleepSessionId)
        sheetCoordinator.dismissSheet()
        HapticFeedback.success()
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
        durationMin: Int? = nil,
        sleepSessionId: UUID? = nil
    ) {
        // Auto-generate sleepSessionId for sleep events
        let sessionId: UUID?
        if type == .slapen {
            sessionId = sleepSessionId ?? UUID()
        } else {
            sessionId = sleepSessionId
        }

        let event = PuppyEvent(
            time: time,
            type: type,
            location: location,
            note: note,
            who: who,
            exercise: exercise,
            result: result,
            durationMin: durationMin,
            sleepSessionId: sessionId
        )

        eventStore.addEvent(event)
        loadEvents()
        refreshNotifications()
    }

    /// Log a walk event with optional spot information
    func logWalkEvent(
        time: Date = Date(),
        spot: WalkSpot? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        note: String? = nil
    ) {
        let event = PuppyEvent(
            time: time,
            type: .uitlaten,
            note: note,
            latitude: latitude ?? spot?.latitude,
            longitude: longitude ?? spot?.longitude,
            spotId: spot?.id,
            spotName: spot?.name
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

    /// Update an existing event
    func updateEvent(_ event: PuppyEvent) {
        eventStore.updateEvent(event)
        loadEvents()
        refreshNotifications()
    }

    /// Show edit sheet for an event
    func editEvent(_ event: PuppyEvent) {
        sheetCoordinator.presentSheet(.editEvent(event))
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

    // MARK: - Poop Status

    /// Current poop status with pattern-based insights
    var poopStatus: PoopStatus {
        let ageInWeeks = profileStore.profile?.ageInWeeks ?? 26
        let historicalEvents = getHistoricalEvents(days: PoopCalculations.patternAnalysisDays)

        return PoopCalculations.calculateStatus(
            todayEvents: events,
            historicalEvents: historicalEvents,
            ageInWeeks: ageInWeeks
        )
    }

    /// Get events from the past N days (for pattern analysis)
    private func getHistoricalEvents(days: Int) -> [PuppyEvent] {
        let startDate = Date().addingDays(-days)
        return eventStore.getEvents(from: startDate, to: Date())
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

    // MARK: - Medications

    /// Pending medications for the current date
    var pendingMedications: [PendingMedication] {
        guard let profile = profileStore.profile,
              let store = medicationStore else { return [] }
        return store.pendingMedications(
            schedule: profile.medicationSchedule,
            for: currentDate
        )
    }

    /// Complete a pending medication and log to timeline
    func completeMedication(_ pending: PendingMedication, medicationName: String) {
        // Mark as complete in medication store
        medicationStore?.markComplete(
            medicationId: pending.medication.id,
            timeId: pending.time.id,
            for: currentDate
        )

        // Log medication event to timeline
        let event = PuppyEvent(
            time: Date(),
            type: .medicatie,
            note: medicationName
        )
        eventStore.addEvent(event)

        objectWillChange.send()
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

    /// Pattern analysis for last 7 days (uses cached value for performance)
    var patternAnalysis: PatternAnalysis {
        // Return cached value if available
        if let cached = cachedPatternAnalysis {
            return cached
        }
        // Fallback to computing (shouldn't happen often)
        let sevenDaysAgo = Date().addingDays(-7)
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
        currentDate.isToday
    }

    /// Get all events (up to 30 days back for streak history)
    private func getAllEvents() -> [PuppyEvent] {
        let thirtyDaysAgo = Date().addingDays(-30)
        return eventStore.getEvents(from: thirtyDaysAgo, to: Date())
    }

    // MARK: - Private Helpers

    /// Get events from today and yesterday (for cross-midnight tracking)
    private func getRecentEvents() -> [PuppyEvent] {
        let yesterday = currentDate.addingDays(-1)
        return eventStore.getEvents(from: yesterday, to: currentDate)
    }

    // MARK: - Notifications

    /// Refresh scheduled notifications after events change
    private func refreshNotifications() {
        guard let service = notificationService,
              let profile = profileStore.profile else { return }

        // Cancel any existing notification task to prevent pile-up
        notificationTask?.cancel()

        notificationTask = Task {
            guard !Task.isCancelled else { return }
            let recentEvents = getRecentEvents()
            await service.refreshNotifications(events: recentEvents, profile: profile)
        }
    }
}
