//
//  TimelineViewModel.swift
//  Ollie-app
//

import Foundation
import OllieShared
import SwiftUI
import Combine

/// Unified timeline item - either a regular event or a sleep session
/// Moved to ViewModel to avoid recomputation on every view render
enum TimelineItem: Identifiable {
    case event(PuppyEvent)
    case sleepSession(SleepSession, note: String?)

    var id: UUID {
        switch self {
        case .event(let event): return event.id
        case .sleepSession(let session, _): return session.id
        }
    }

    var sortTime: Date {
        switch self {
        case .event(let event): return event.time
        case .sleepSession(let session, _): return session.startTime
        }
    }
}

/// ViewModel for the timeline view, manages event display and logging
@MainActor
class TimelineViewModel: ObservableObject {
    @Published var currentDate: Date = Date()
    @Published var events: [PuppyEvent] = []

    /// Pre-computed timeline items (events + sleep sessions)
    /// Updated only when events change to avoid O(n²) recomputation on every view render
    @Published private(set) var timelineItems: [TimelineItem] = []

    /// Celebration trigger for milestone moments
    @Published var showCelebration = false
    @Published var celebrationStyle: CelebrationStyle = .milestone

    /// Sheet coordinator for all sheet presentations
    @Published var sheetCoordinator = SheetCoordinator()

    // MARK: - Activity State

    /// Activity tracking manager (handles walk/nap lifecycle)
    let activityManager = ActivityTrackingManager()

    /// Currently in-progress activity (walk or nap) - delegates to activityManager
    var currentActivity: InProgressActivity? {
        get { activityManager.currentActivity }
        set { activityManager.currentActivity = newValue }
    }

    /// Whether a walk is currently in progress
    var isWalkInProgress: Bool {
        activityManager.isWalkInProgress
    }

    /// Whether a nap is currently in progress
    var isNapInProgress: Bool {
        activityManager.isNapInProgress
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

    // MARK: - Combined Sleep + Potty State

    /// Captured potty state at wake time (for post-wake tracking)
    @Published private(set) var wakeTimePottyState: WakeTimePottyState?

    /// Time of last potty event (for clearing post-wake state)
    private var lastPottyLogTime: Date?

    /// Background notification task (stored for cancellation)
    private var notificationTask: Task<Void, Never>?

    /// Subscription to forward SheetCoordinator changes
    private var sheetCoordinatorCancellable: AnyCancellable?

    /// Subscription to forward ActivityTrackingManager changes
    private var activityManagerCancellable: AnyCancellable?

    /// Subscription to observe EventStore events
    private var eventStoreCancellable: AnyCancellable?

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

        // Forward ActivityTrackingManager's objectWillChange to this ViewModel
        activityManagerCancellable = activityManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        // Set up activity manager callbacks
        setupActivityManagerCallbacks()

        // Observe EventStore's events and sync to this ViewModel
        // This ensures events are updated when EventStore loads them asynchronously
        eventStoreCancellable = eventStore.$events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadedEvents in
                guard let self = self else { return }
                self.events = loadedEvents
                // Rebuild timeline items and refresh stats since events changed
                self.rebuildTimelineItems()
                self.refreshCachedStats(force: true)
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
        // Don't immediately copy eventStore.events here - it's stale because
        // EventStore.loadEvents() defers the actual load to the next run loop.
        // The subscription at init (eventStoreCancellable) will receive the
        // updated events and call rebuildTimelineItems() + refreshCachedStats().
    }

    /// Rebuild the pre-computed timeline items from current events
    /// This avoids O(n²) session building on every view render
    private func rebuildTimelineItems() {
        // Build sleep sessions (O(n) with optimized lookup)
        let sessions = SleepSession.buildSessions(from: events)

        // Create a lookup dictionary for event IDs -> notes (O(1) lookup instead of O(n))
        let eventNotes: [UUID: String] = Dictionary(
            uniqueKeysWithValues: events.compactMap { event in
                guard let note = event.note else { return nil }
                return (event.id, note)
            }
        )

        // Get IDs of events that are part of sessions
        var sessionEventIds: Set<UUID> = []
        var sessionNotes: [UUID: String] = [:]

        for session in sessions {
            sessionEventIds.insert(session.startEventId)
            if let endId = session.endEventId {
                sessionEventIds.insert(endId)
            }
            // Get note from the sleep event using O(1) dictionary lookup
            if let note = eventNotes[session.startEventId] {
                sessionNotes[session.id] = note
            }
        }

        // Build timeline items
        var items: [TimelineItem] = []

        // Add non-sleep events
        for event in events where !sessionEventIds.contains(event.id) {
            items.append(.event(event))
        }

        // Add sleep sessions
        for session in sessions {
            items.append(.sleepSession(session, note: sessionNotes[session.id]))
        }

        // Sort by time (oldest first for timeline display)
        timelineItems = items.sorted { $0.sortTime < $1.sortTime }
    }

    /// Refresh cached stats (debounced, only if data changed)
    /// - Parameter force: When true, bypasses debounce (use after event changes)
    private func refreshCachedStats(force: Bool = false) {
        // Debounce: only update if more than 1 second since last update
        // Skip debounce when force is true (e.g., after event edits)
        let now = Date()
        if !force, let lastUpdate = lastStatsUpdate, now.timeIntervalSince(lastUpdate) < 1.0 {
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

    // MARK: - Subscription

    /// Subscription manager for Ollie+ status
    var subscriptionManager: SubscriptionManager {
        SubscriptionManager.shared
    }

    /// Whether user has Ollie+ access
    var hasOlliePlus: Bool {
        subscriptionManager.effectiveStatus.hasOlliePlus
    }

    /// Whether to show the Ollie+ upsell banner
    /// Shows after first week of use if user is on free tier
    var shouldShowOlliePlusBanner: Bool {
        guard let profile = profileStore.profile else { return false }
        // Show if free tier and has been using app for at least 7 days
        return !hasOlliePlus && profile.daysHome >= 7
    }

    /// Whether to show the trial banner (during trial period)
    var shouldShowTrialBanner: Bool {
        subscriptionManager.effectiveStatus.isInTrial
    }

    /// Days remaining in trial period (0 if not in trial)
    var freeDaysRemaining: Int {
        subscriptionManager.effectiveStatus.trialDaysRemaining ?? 0
    }

    // MARK: - Quick Log

    func quickLog(type: EventType, suggestedTime: Date? = nil) {
        // Core logging is always free - no paywall check needed
        // V2: All events now go through QuickLogSheet for time adjustment
        // Pass suggested time for overdue items (e.g., scheduled meal time)
        sheetCoordinator.presentSheet(.quickLog(type, suggestedTime: suggestedTime))
    }

    /// Quick log with immediate location (used by FAB quick actions)
    func quickLogWithLocation(type: EventType, location: EventLocation) {
        // Core logging is always free - no paywall check needed
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

    // MARK: - Activity Tracking Setup

    /// Configure activity manager callbacks
    private func setupActivityManagerCallbacks() {
        // Log event callback
        activityManager.onLogEvent = { [weak self] type, time, location, note, duration, sleepSessionId in
            self?.logEvent(type: type, time: time ?? Date(), location: location, note: note, durationMin: duration, sleepSessionId: sleepSessionId)
        }

        // Dismiss sheet callback
        activityManager.onDismiss = { [weak self] in
            self?.sheetCoordinator.dismissSheet()
        }

        // Delete sleep event callback (returns the event if found)
        activityManager.onDeleteSleepEvent = { [weak self] sessionId -> PuppyEvent? in
            guard let self = self else { return nil }
            return self.events.first(where: { $0.sleepSessionId == sessionId && $0.type == .slapen })
        }
    }

    // MARK: - Activity Tracking (Walks & Naps)

    /// Start a new activity (walk or nap)
    /// - Parameters:
    ///   - type: The type of activity to start
    ///   - startTime: Optional custom start time (defaults to now)
    func startActivity(type: ActivityType, startTime: Date = Date()) {
        activityManager.startActivity(type: type, startTime: startTime)
    }

    /// End the current activity
    func endActivity(minutesAgo: Int, note: String?) {
        // Get info before ending (for note update on naps)
        let sleepSessionId = activityManager.currentActivity?.sleepSessionId
        let activityType = activityManager.currentActivity?.type

        // End the activity (this logs events via callbacks)
        _ = activityManager.endActivity(minutesAgo: minutesAgo, note: note)

        // Update sleep event note if needed (for naps)
        if activityType == .nap,
           let note = note, !note.isEmpty,
           let sessionId = sleepSessionId,
           let sleepEvent = events.first(where: { $0.sleepSessionId == sessionId && $0.type == .slapen }) {
            var updated = sleepEvent
            updated.note = note
            updateEvent(updated)
        }
    }

    /// Cancel/discard the current activity without logging
    func cancelActivity() {
        // Cancel and check if we need to delete a sleep event
        if let result = activityManager.cancelActivity(),
           result.shouldDeleteSleep,
           let sessionId = result.sessionId,
           let sleepEvent = events.first(where: { $0.sleepSessionId == sessionId && $0.type == .slapen }) {
            eventStore.deleteEvent(sleepEvent)

            // Immediately sync for instant UI updates
            self.events = eventStore.events
            rebuildTimelineItems()
        }
    }

    /// Log a wake-up event at the specified time (for EndSleepSheet)
    func logWakeUp(time: Date) {
        // Capture potty state BEFORE logging wake (for post-wake tracking)
        // Only capture if potty is urgent/overdue
        if pottyPrediction.urgency.isUrgent {
            wakeTimePottyState = CombinedStatusCalculations.captureWakeTimePottyState(
                pottyPrediction: pottyPrediction
            )
        }

        // Use the currentActivity's sleepSessionId if available (for naps started via activity tracking)
        // Otherwise find it from recent events (for naps logged directly without activity tracking)
        let sleepSessionId: UUID?
        if let sessionId = activityManager.prepareWakeUp() {
            sleepSessionId = sessionId
        } else {
            let recentEvents = getRecentEvents()
            sleepSessionId = SleepSession.ongoingSleepSessionId(from: recentEvents)
        }

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
        // Core logging is always free - no paywall check needed
        sheetCoordinator.presentSheet(.allEvents)
    }

    // MARK: - Potty Quick Log (V3: combined plassen/poepen)

    func showPottySheet() {
        // Core logging is always free - no paywall check needed
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
        // Photo/video attachments require Ollie+
        guard subscriptionManager.hasAccess(to: .photoVideoAttachments) else {
            sheetCoordinator.presentSheet(.olliePlus)
            return
        }
        sheetCoordinator.presentSheet(.mediaPicker(.camera))
    }

    func openPhotoLibrary() {
        // Photo/video attachments require Ollie+
        guard subscriptionManager.hasAccess(to: .photoVideoAttachments) else {
            sheetCoordinator.presentSheet(.olliePlus)
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
        // Note: sleepSessionId is auto-generated for sleep events in PuppyEvent init
        let event = PuppyEvent(
            time: time,
            type: type,
            location: location,
            note: note,
            who: who,
            exercise: exercise,
            result: result,
            durationMin: durationMin,
            sleepSessionId: sleepSessionId
        )

        // Track potty event time for post-wake state clearing
        if type == .plassen || type == .poepen {
            lastPottyLogTime = Date()
            // Clear post-wake state when potty is logged
            wakeTimePottyState = nil
        }

        // Check if this is the user's very first event (before adding)
        let isFirstEvent = events.isEmpty && eventStore.getEvents(
            from: Date.distantPast,
            to: Date()
        ).isEmpty

        eventStore.addEvent(event)

        // Immediately sync events from EventStore to ensure status cards update
        // Don't wait for the deferred subscription - sync now for instant UI updates
        self.events = eventStore.events
        rebuildTimelineItems()

        refreshNotifications()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()

        // Trigger celebration for first-ever event
        if isFirstEvent {
            triggerCelebration(.milestone)
        }
    }

    /// Trigger a celebration animation
    func triggerCelebration(_ style: CelebrationStyle) {
        celebrationStyle = style
        showCelebration = true
    }

    /// Log a walk event with optional spot information and potty events
    func logWalkEvent(
        time: Date = Date(),
        durationMin: Int? = nil,
        didPee: Bool = false,
        didPoop: Bool = false,
        spot: WalkSpot? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        note: String? = nil
    ) {
        let walkEvent = PuppyEvent.walk(
            time: time,
            durationMin: durationMin,
            note: note,
            spot: spot,
            latitude: latitude,
            longitude: longitude
        )

        eventStore.addEvent(walkEvent)

        // Log potty events linked to this walk
        if didPee {
            let peeEvent = PuppyEvent.potty(
                type: .plassen,
                time: time,
                location: .buiten,
                parentWalkId: walkEvent.id
            )
            eventStore.addEvent(peeEvent)
        }

        if didPoop {
            let poopEvent = PuppyEvent.potty(
                type: .poepen,
                time: time,
                location: .buiten,
                parentWalkId: walkEvent.id
            )
            eventStore.addEvent(poopEvent)
        }

        // Immediately sync for instant UI updates
        self.events = eventStore.events
        rebuildTimelineItems()

        refreshNotifications()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()
    }

    /// Log a completed nap with start and end time (creates both sleep and wake events)
    func logCompletedNap(startTime: Date, endTime: Date, note: String?) {
        let sessionId = UUID()

        // Log sleep event at start time
        let sleepEvent = PuppyEvent(
            time: startTime,
            type: .slapen,
            note: note,
            sleepSessionId: sessionId
        )
        eventStore.addEvent(sleepEvent)

        // Log wake event at end time
        let wakeEvent = PuppyEvent(
            time: endTime,
            type: .ontwaken,
            sleepSessionId: sessionId
        )
        eventStore.addEvent(wakeEvent)

        // Immediately sync for instant UI updates
        self.events = eventStore.events
        rebuildTimelineItems()

        refreshNotifications()

        // Provide audio + haptic feedback for successful log
        FeedbackManager.logEvent()
    }

    /// Add a pre-built event (used for photo moments)
    func addEvent(_ event: PuppyEvent) {
        eventStore.addEvent(event)

        // Immediately sync for instant UI updates
        self.events = eventStore.events
        rebuildTimelineItems()

        refreshNotifications()
    }

    /// Update an existing event
    func updateEvent(_ event: PuppyEvent) {
        eventStore.updateEvent(event)

        // Immediately sync for instant UI updates
        self.events = eventStore.events
        rebuildTimelineItems()

        // Force refresh stats to ensure week view updates immediately
        refreshCachedStats(force: true)
        refreshNotifications()

        // Sync activity manager if this is the current nap's sleep event
        // This ensures the banner shows the correct start time after editing
        if event.type == .slapen,
           let sessionId = event.sleepSessionId,
           activityManager.currentActivity?.sleepSessionId == sessionId {
            activityManager.updateActivityStartTime(to: event.time)
        }
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

        // Immediately sync for instant UI updates
        self.events = eventStore.events
        rebuildTimelineItems()

        // Force refresh stats to ensure week view updates immediately
        refreshCachedStats(force: true)
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

        // Immediately sync for instant UI updates
        self.events = eventStore.events
        rebuildTimelineItems()
        // Force refresh stats to ensure week view updates immediately
        refreshCachedStats(force: true)
        refreshNotifications()
        HapticFeedback.success()
    }

    /// Dismiss the undo banner
    func dismissUndoBanner() {
        sheetCoordinator.dismissUndoBanner()
    }

    // MARK: - Predictions

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

    // MARK: - Combined Sleep + Potty Status

    /// Combined state for sleep + potty status display
    /// Determines which card(s) to show based on current conditions
    var combinedSleepPottyState: CombinedSleepPottyState {
        // Check if wake state should be cleared
        if CombinedStatusCalculations.shouldClearWakeState(
            wakeState: wakeTimePottyState,
            pottyWasLoggedSince: lastPottyLogTime
        ) {
            // Clear it asynchronously
            Task { @MainActor in
                self.wakeTimePottyState = nil
            }
        }

        return CombinedStatusCalculations.calculateCombinedState(
            sleepState: currentSleepState,
            pottyPrediction: pottyPrediction,
            wakeTimePottyState: wakeTimePottyState
        )
    }

    /// Clear the post-wake potty state manually
    func clearPostWakeState() {
        wakeTimePottyState = nil
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
    /// Uses in-memory events for today + Core Data for historical data
    private func getHistoricalEvents(days: Int) -> [PuppyEvent] {
        let calendar = Calendar.current
        let today = Date()
        let startDate = today.addingDays(-days)
        let startOfToday = calendar.startOfDay(for: today)

        // Get historical events (before today) from Core Data
        let historicalEvents = eventStore.getEvents(from: startDate, to: startOfToday)

        // Use in-memory events for today (always fresh)
        let todayEvents = events.filter { calendar.isDateInToday($0.time) }

        return (historicalEvents + todayEvents).sorted { $0.time > $1.time }
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
        let event = PuppyEvent.medication(medicationName: medicationName)
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
    /// Returns legacy format with all items combined
    func upcomingItems(forecasts: [HourForecast] = []) -> [UpcomingItem] {
        guard let profile = profileStore.profile else { return [] }
        return UpcomingCalculations.calculateUpcoming(
            events: events,
            mealSchedule: profile.mealSchedule,
            walkSchedule: profile.walkSchedule,
            forecasts: forecasts,
            date: currentDate,
            isWalkInProgress: isWalkInProgress
        )
    }

    /// Separated actionable and upcoming items
    /// - Actionable: items within 10 min or overdue (shown prominently)
    /// - Upcoming: items more than 10 min away (shown in compact list)
    func separatedUpcomingItems(forecasts: [HourForecast] = []) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        guard let profile = profileStore.profile else { return ([], []) }
        return UpcomingCalculations.calculateUpcoming(
            events: events,
            mealSchedule: profile.mealSchedule,
            walkSchedule: profile.walkSchedule,
            forecasts: forecasts,
            date: currentDate,
            isWalkInProgress: isWalkInProgress
        )
    }

    /// Whether current view is showing today
    var isShowingToday: Bool {
        currentDate.isToday
    }

    /// Whether user can log events (only for today)
    var canLogEvents: Bool {
        currentDate.isToday
    }

    /// Get all events (up to 30 days back for streak history)
    private func getAllEvents() -> [PuppyEvent] {
        let thirtyDaysAgo = Date().addingDays(-30)
        return eventStore.getEvents(from: thirtyDaysAgo, to: Date())
    }

    // MARK: - Private Helpers

    /// Get events from today and yesterday (for cross-midnight tracking)
    /// Uses in-memory events for today (fresh) + Core Data for yesterday (stable)
    /// This ensures status cards update immediately when events are logged
    func getRecentEvents() -> [PuppyEvent] {
        let calendar = Calendar.current
        let today = Date()

        // For today's events, use in-memory array (always fresh)
        // For yesterday, fetch from Core Data (stable)
        let yesterday = today.addingDays(-1)
        let startOfToday = calendar.startOfDay(for: today)

        // Get yesterday's events from Core Data
        let yesterdayEvents = eventStore.getEvents(from: yesterday, to: startOfToday)

        // Use in-memory events for today (these are always up-to-date)
        let todayEvents = events.filter { calendar.isDateInToday($0.time) }

        // Combine and return
        return (yesterdayEvents + todayEvents).sorted { $0.time > $1.time }
    }

    // MARK: - Notifications

    /// Refresh scheduled notifications after events change
    private func refreshNotifications() {
        guard let service = notificationService,
              let profile = profileStore.profile else { return }

        // Cancel any existing notification task to prevent pile-up
        notificationTask?.cancel()

        // Capture walk state before async task
        let walkInProgress = isWalkInProgress

        notificationTask = Task {
            guard !Task.isCancelled else { return }
            let recentEvents = getRecentEvents()
            await service.refreshNotifications(
                events: recentEvents,
                profile: profile,
                isWalkInProgress: walkInProgress
            )
        }
    }
}
