//
//  TimelineViewModel.swift
//  Ollie-app
//
//  Core timeline view model - manages event display and state
//  Functionality is split across extensions:
//  - TimelineViewModel+Navigation.swift - Date navigation
//  - TimelineViewModel+Events.swift - Event CRUD operations
//  - TimelineViewModel+Predictions.swift - Potty/sleep predictions and stats
//  - TimelineViewModel+CoverageGaps.swift - Coverage gap tracking
//  - TimelineViewModel+Activities.swift - Walk/nap activity tracking
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
    @Published internal(set) var wakeTimePottyState: WakeTimePottyState?

    /// Time of last potty event (for clearing post-wake state)
    internal var lastPottyLogTime: Date?

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
    internal func rebuildTimelineItems() {
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
    internal func refreshCachedStats(force: Bool = false) {
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

    // MARK: - Medication Helpers

    /// Get pending medications for today
    var pendingMedications: [PendingMedication] {
        guard let store = medicationStore,
              let profile = profileStore.profile else { return [] }
        return store.pendingMedications(schedule: profile.medicationSchedule, for: Date())
    }

    /// Mark a pending medication as complete
    func completeMedication(_ pending: PendingMedication, medicationName: String) {
        guard let store = medicationStore else { return }
        store.markComplete(
            medicationId: pending.medication.id,
            timeId: pending.time.id,
            for: pending.scheduledDate
        )
        HapticFeedback.success()
    }

    // MARK: - Activity Tracking Setup

    /// Configure activity manager callbacks
    private func setupActivityManagerCallbacks() {
        // Log event callback
        activityManager.onLogEvent = { [weak self] request in
            self?.logEvent(
                type: request.type,
                time: request.time ?? Date(),
                location: request.location,
                note: request.note,
                durationMin: request.durationMin,
                sleepSessionId: request.sleepSessionId
            )
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

    // MARK: - Internal Helper Properties (for extensions)

    /// Puppy name for display
    var puppyName: String {
        profileStore.profile?.name ?? "Puppy"
    }

    // MARK: - Internal Helper Methods (for extensions)

    /// Sync events from EventStore to local array
    func syncEventsFromStore() {
        self.events = eventStore.events
        rebuildTimelineItems()
    }

    /// Notify to refresh notifications
    func notifyRefreshNotifications() {
        refreshNotifications()
    }

    /// Notify to force refresh stats
    func notifyForceRefreshStats() {
        refreshCachedStats(force: true)
    }

    /// Record potty log time for post-wake state tracking
    func recordPottyLogTime() {
        lastPottyLogTime = Date()
        // Clear post-wake state when potty is logged
        wakeTimePottyState = nil
    }

    /// Capture wake time potty state for post-wake tracking
    func captureWakeTimePottyState() {
        wakeTimePottyState = CombinedStatusCalculations.captureWakeTimePottyState(
            pottyPrediction: pottyPrediction
        )
    }

    /// Clear the post-wake potty state manually
    func clearPostWakeState() {
        wakeTimePottyState = nil
    }

    /// Get events from the past N days (for pattern analysis)
    /// Uses in-memory events for today + Core Data for historical data
    func getHistoricalEvents(days: Int) -> [PuppyEvent] {
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

    /// Get all events (up to 30 days back for streak history)
    func getAllEvents() -> [PuppyEvent] {
        let thirtyDaysAgo = Date().addingDays(-30)
        return eventStore.getEvents(from: thirtyDaysAgo, to: Date())
    }

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

    // MARK: - Private Helpers

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
