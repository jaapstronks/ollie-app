//
//  TimelineViewModel.swift
//  Otis-app
//
//  Core timeline view model - acts as a coordinator delegating to focused services.
//  Functionality is split across extensions:
//  - TimelineViewModel+Navigation.swift - Date navigation
//  - TimelineViewModel+Events.swift - Event CRUD operations (delegates to EventLoggingService)
//  - TimelineViewModel+Predictions.swift - Potty/sleep predictions (delegates to PredictionService)
//  - TimelineViewModel+CoverageGaps.swift - Coverage gap tracking (delegates to CoverageGapService)
//  - TimelineViewModel+Activities.swift - Walk/nap activity tracking
//  - TimelineViewModel+Stats.swift - Stats (delegates to TodayStatsProvider)
//  - TimelineViewModel+VerticalTimeline.swift - Timeline items (delegates to TimelineItemBuilder)
//

import Foundation
import OtisShared
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

    /// Events filtered for timeline display (excludes weight events which belong on Health tab only)
    var timelineDisplayEvents: [PuppyEvent] {
        events.filter { $0.type != .gewicht }
    }

    /// Pre-computed timeline items (events + sleep sessions)
    /// Updated only when events change to avoid O(n²) recomputation on every view render
    @Published private(set) var timelineItems: [TimelineItem] = []

    /// Celebration trigger for milestone moments
    @Published var showCelebration = false
    @Published var celebrationStyle: CelebrationPreset = .milestone
    private var pendingCelebrationStyle: CelebrationPreset?

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

    // MARK: - Stats Cache (extracted to separate service)

    /// Stats cache service (manages cached stats to avoid recomputation)
    let statsCache: TimelineStatsCache

    // Convenience accessors for cached stats (forward to statsCache)
    var cachedPatternAnalysis: PatternAnalysis? { statsCache.patternAnalysis }
    var cachedRecentEvents: [PuppyEvent] { statsCache.recentEvents }
    var cachedWeekStats: [DayStats] { statsCache.weekStats }
    var cachedRecentWalks: [PuppyEvent] { statsCache.recentWalks }
    var cachedWeekWalkStats: (count: Int, totalMinutes: Int) { statsCache.weekWalkStats }
    var walkStats: WalkStats? { statsCache.walkStats }

    // MARK: - Extracted Services

    /// Event logging service (handles CRUD and undo)
    let eventLoggingService: EventLoggingService

    /// Coverage gap service (handles gap detection and catch-up)
    let coverageGapService: CoverageGapService

    /// Prediction service (handles potty/sleep predictions, streaks)
    let predictionService: PredictionService

    // MARK: - Combined Sleep + Potty State (delegates to PredictionService)

    /// Captured potty state at wake time (for post-wake tracking)
    /// Delegates to PredictionService
    @Published private(set) var wakeTimePottyState: WakeTimePottyState?

    /// Time of last potty event (for clearing post-wake state)
    internal var lastPottyLogTime: Date?

    /// Date when user dismissed the assumed overnight sleep card (reset daily)
    @Published internal var dismissedAssumedSleepDate: Date?

    /// Date when user dismissed the stale logging banner (reset daily)
    @Published internal var dismissedStaleLoggingDate: Date?

    /// Whether user has dismissed the first run welcome card (persisted)
    @Published internal var dismissedFirstRunWelcome: Bool = UserDefaults.standard.bool(forKey: "dismissedFirstRunWelcome")

    /// Background notification task (stored for cancellation)
    private var notificationTask: Task<Void, Never>?

    /// Subscription to forward SheetCoordinator changes
    private var sheetCoordinatorCancellable: AnyCancellable?
    private var activeSheetCancellable: AnyCancellable?

    /// Subscription to forward ActivityTrackingManager changes
    private var activityManagerCancellable: AnyCancellable?

    /// Subscription to observe EventStore events
    private var eventStoreCancellable: AnyCancellable?

    /// Subscription to forward TimelineStatsCache changes
    private var statsCacheCancellable: AnyCancellable?

    /// Subscription to forward EventLoggingService changes
    private var eventLoggingServiceCancellable: AnyCancellable?

    /// Subscription to forward PredictionService changes
    private var predictionServiceCancellable: AnyCancellable?

    let eventStore: EventStore
    let profileStore: ProfileStore
    var notificationService: NotificationService?
    var spotStore: SpotStore?
    var locationManager: LocationManager?
    var medicationStore: MedicationStore?
    var appointmentStore: AppointmentStore?

    init(
        eventStore: EventStore,
        profileStore: ProfileStore,
        notificationService: NotificationService? = nil,
        spotStore: SpotStore? = nil,
        locationManager: LocationManager? = nil,
        medicationStore: MedicationStore? = nil,
        appointmentStore: AppointmentStore? = nil
    ) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.notificationService = notificationService
        self.spotStore = spotStore
        self.locationManager = locationManager
        self.medicationStore = medicationStore
        self.appointmentStore = appointmentStore

        // Create stats cache (extracted service)
        self.statsCache = TimelineStatsCache(eventStore: eventStore, profileStore: profileStore)

        // Create extracted services
        self.eventLoggingService = EventLoggingService(eventStore: eventStore, profileStore: profileStore)
        self.coverageGapService = CoverageGapService(eventStore: eventStore, profileStore: profileStore)
        self.predictionService = PredictionService(profileStore: profileStore)

        // Forward SheetCoordinator's objectWillChange to this ViewModel
        // This ensures views are notified when sheet state changes
        sheetCoordinatorCancellable = sheetCoordinator.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        // Flush deferred celebrations as soon as sheets are dismissed.
        activeSheetCancellable = sheetCoordinator.$activeSheet
            .sink { [weak self] activeSheet in
                guard activeSheet == nil else { return }
                self?.flushPendingCelebrationIfNeeded()
            }

        // Forward ActivityTrackingManager's objectWillChange to this ViewModel
        activityManagerCancellable = activityManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        // Forward TimelineStatsCache's objectWillChange to this ViewModel
        statsCacheCancellable = statsCache.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        // Forward EventLoggingService's objectWillChange to this ViewModel
        eventLoggingServiceCancellable = eventLoggingService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        // Note: CoverageGapService uses callbacks, not ObservableObject

        // Forward PredictionService's objectWillChange to this ViewModel
        predictionServiceCancellable = predictionService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        // Set up service callbacks
        setupServiceCallbacks()

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
                self.statsCache.refresh(force: true)
                // Also refresh predictions
                self.refreshPredictions()
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

    /// Whether celebration banner is showing
    var showingCelebrationBanner: Bool {
        sheetCoordinator.showingCelebrationBanner
    }

    /// Celebration message to display
    var celebrationMessage: String {
        sheetCoordinator.celebrationMessage
    }

    /// Dismiss the celebration banner
    func dismissCelebrationBanner() {
        sheetCoordinator.dismissCelebrationBanner()
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
    /// Delegates to TimelineItemBuilder for pure function logic
    internal func rebuildTimelineItems() {
        timelineItems = TimelineItemBuilder.buildTimelineItems(from: events)
    }


    // MARK: - Subscription

    /// Subscription manager for Otis+ status
    var subscriptionManager: SubscriptionManager {
        SubscriptionManager.shared
    }

    /// Whether user has Otis+ access
    var hasOtisPlus: Bool {
        subscriptionManager.effectiveStatus.hasOtisPlus
    }

    /// Whether to show the Otis+ upsell banner
    /// Shows after first week of use if user is on free tier
    var shouldShowOtisPlusBanner: Bool {
        guard let profile = profileStore.profile else { return false }
        // Show if free tier and has been using app for at least 7 days
        return !hasOtisPlus && profile.daysHome >= 7
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

    // MARK: - Service Callbacks Setup

    /// Configure callbacks for all extracted services
    private func setupServiceCallbacks() {
        // EventLoggingService callbacks
        eventLoggingService.onEventsChanged = { [weak self] in
            self?.syncEventsFromStore()
            self?.statsCache.refresh(force: true)
            self?.refreshPredictions()
        }

        eventLoggingService.onCelebration = { [weak self] style, message in
            self?.triggerCelebration(style)
            if let msg = message {
                self?.sheetCoordinator.showCelebration(message: msg)
            }
        }

        eventLoggingService.onRefreshNotifications = { [weak self] in
            self?.refreshNotifications()
        }

        eventLoggingService.onRecordPottyLogTime = { [weak self] in
            self?.recordPottyLogTime()
        }

        // CoverageGapService callbacks
        coverageGapService.onShowSheet = { [weak self] sheet in
            self?.sheetCoordinator.presentSheet(sheet)
        }

        coverageGapService.onEventsChanged = { [weak self] in
            self?.syncEventsFromStore()
            self?.statsCache.refresh(force: true)
        }

        coverageGapService.onUpdateEvent = { [weak self] event in
            self?.updateEvent(event)
        }

        coverageGapService.onLogEvent = { [weak self] type, time, location, note in
            self?.logEvent(type: type, time: time, location: location, note: note)
        }
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
                sleepSessionId: request.sleepSessionId,
                napLocation: request.napLocation
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

    /// Trigger celebration immediately, pulsing the boolean to retrigger reliably.
    private func presentCelebration(_ style: CelebrationPreset) {
        celebrationStyle = style
        showCelebration = false
        DispatchQueue.main.async { [weak self] in
            self?.showCelebration = true
        }
    }

    /// Trigger celebration, deferring if a sheet is currently covering the UI.
    func triggerCelebration(_ style: CelebrationPreset) {
        guard sheetCoordinator.activeSheet == nil else {
            pendingCelebrationStyle = style
            return
        }
        presentCelebration(style)
    }

    /// Flush any deferred celebration when sheets are dismissed.
    func flushPendingCelebrationIfNeeded() {
        guard sheetCoordinator.activeSheet == nil,
              let pendingStyle = pendingCelebrationStyle else { return }
        pendingCelebrationStyle = nil
        presentCelebration(pendingStyle)
    }

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
        statsCache.refresh(force: true)
    }

    /// Refresh prediction service state
    func refreshPredictions() {
        predictionService.refresh(
            todayEvents: events,
            recentEvents: getRecentEvents(),
            historicalEvents: getHistoricalEvents(days: 7),
            allEvents: getAllEvents(),
            currentDate: currentDate,
            isShowingToday: isShowingToday,
            hasActiveCoverageGap: activeCoverageGap != nil
        )
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
    /// Uses in-memory events for today (fresh) + Core Data for historical (stable)
    func getAllEvents() -> [PuppyEvent] {
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = today.addingDays(-30)
        let startOfToday = calendar.startOfDay(for: today)

        // Get historical events (before today) from Core Data
        let historicalEvents = eventStore.getEvents(from: thirtyDaysAgo, to: startOfToday)

        // Use in-memory events for today (always fresh)
        let todayEvents = events.filter { calendar.isDateInToday($0.time) }

        return (historicalEvents + todayEvents).sorted { $0.time > $1.time }
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

        // Capture walk state and appointments before async task
        let walkInProgress = isWalkInProgress
        let upcomingAppointments = appointmentStore?.upcomingAppointments ?? []

        notificationTask = Task {
            guard !Task.isCancelled else { return }
            let recentEvents = getRecentEvents()
            await service.refreshNotifications(
                events: recentEvents,
                profile: profile,
                appointments: upcomingAppointments,
                isWalkInProgress: walkInProgress
            )
        }
    }
}
