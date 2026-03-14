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
import Observation
import OtisShared
import SwiftUI
import Combine
import Sentry

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
/// Uses @Observable for granular view updates (only re-renders views that access changed properties)
@Observable
@MainActor
class TimelineViewModel {
    var currentDate: Date = Date()
    var events: [PuppyEvent] = []

    /// Events filtered for timeline display (excludes weight events which belong on Health tab only)
    var timelineDisplayEvents: [PuppyEvent] {
        events.filter { $0.type != .gewicht }
    }

    /// Pre-computed timeline items (events + sleep sessions)
    /// Updated only when events change to avoid O(n²) recomputation on every view render
    private(set) var timelineItems: [TimelineItem] = []

    /// Cached recent photo events (7 days) - updated only when events change
    /// PERFORMANCE: Avoids synchronous Core Data fetch on every view render
    private(set) var recentPhotoEventsCache: [PuppyEvent] = []

    /// Cached partner activity summary - updated only when events change
    /// PERFORMANCE: Avoids synchronous Core Data fetch on every view render
    private(set) var partnerActivitySummaryCache: PartnerActivitySummary?

    /// Cached combined sleep/potty state - updated only when events change
    /// PERFORMANCE: Avoids recomputation on every view render
    private(set) var cachedCombinedState: CombinedSleepPottyState = .unknown

    /// Cached separated upcoming items - updated only when events/forecasts change
    /// PERFORMANCE: Avoids UpcomingCalculations + AI reordering on every view render
    private(set) var cachedSeparatedItems: (actionable: [ActionableItem], upcoming: [UpcomingItem]) = ([], [])

    /// Cached vertical timeline items - updated only when events change
    /// PERFORMANCE: buildVerticalItems was called 3+ times per render (for filtering)
    private(set) var cachedVerticalTimelineItems: [VerticalTimelineItem] = []

    /// Celebration trigger for milestone moments
    var showCelebration = false
    var celebrationStyle: CelebrationPreset = .milestone
    var celebrationStreakCount: Int?
    private var pendingCelebrationStyle: CelebrationPreset?
    private var pendingCelebrationStreakCount: Int?

    /// Refresh trigger for forcing view updates when external state changes
    /// Increment this to trigger a view update (used with @Observable)
    var refreshTrigger: Int = 0

    /// Sheet coordinator for all sheet presentations
    var sheetCoordinator = SheetCoordinator()

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

    // MARK: - Shared Event Data Provider

    /// Centralized event data cache (single fetch, shared across services)
    let eventDataProvider: EventDataProvider

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
    var cachedGapStats: GapStats { statsCache.gapStats }

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
    private(set) var wakeTimePottyState: WakeTimePottyState?

    /// Time of last potty event (for clearing post-wake state)
    internal var lastPottyLogTime: Date?

    /// Date when user dismissed the assumed overnight sleep card (reset daily)
    internal var dismissedAssumedSleepDate: Date?

    /// Date when user dismissed the stale logging banner (reset daily)
    internal var dismissedStaleLoggingDate: Date?

    /// Whether user has dismissed the first run welcome card (persisted)
    internal var dismissedFirstRunWelcome: Bool = UserDefaults.standard.bool(forKey: "dismissedFirstRunWelcome")

    /// Background notification task (stored for cancellation)
    private var notificationTask: Task<Void, Never>?

    /// Background refresh task for stats/predictions (coalesces rapid event changes)
    private var backgroundRefreshTask: Task<Void, Never>?

    /// Subscription for sheet dismissal handling
    private var activeSheetCancellable: AnyCancellable?

    /// Subscription to observe EventStore events
    private var eventStoreCancellable: AnyCancellable?

    /// Subscription for moment notification handling
    private var momentNotificationCancellable: AnyCancellable?

    /// Subscription to reset to today when app becomes active on a new day
    private var appBecameActiveCancellable: AnyCancellable?

    /// Subscription to EventDataProvider changes (historical data loaded)
    private var eventDataProviderCancellable: AnyCancellable?

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
        appointmentStore: AppointmentStore? = nil,
        dailyAggregateService: DailyAggregateService? = nil
    ) {
        // PERFORMANCE: Track TimelineViewModel initialization
        let initTransaction = CrashReporter.startTransaction(
            name: "TimelineViewModel Init",
            operation: "viewmodel.init"
        )

        self.eventStore = eventStore
        self.profileStore = profileStore
        self.notificationService = notificationService
        self.spotStore = spotStore
        self.locationManager = locationManager
        self.medicationStore = medicationStore
        self.appointmentStore = appointmentStore

        // Create shared event data provider (single fetch, shared across services)
        let dataProviderSpan = initTransaction?.startChild(
            operation: "service.init",
            description: "EventDataProvider"
        )
        self.eventDataProvider = EventDataProvider(eventStore: eventStore)
        dataProviderSpan?.finish()

        // Create stats cache using shared event data provider
        let statsCacheSpan = initTransaction?.startChild(
            operation: "service.init",
            description: "TimelineStatsCache"
        )
        // Use provided aggregate service or shared instance
        let aggregateService = dailyAggregateService ?? DailyAggregateService.shared
        self.statsCache = TimelineStatsCache(
            eventDataProvider: eventDataProvider,
            profileStore: profileStore,
            dailyAggregateService: aggregateService
        )
        statsCacheSpan?.finish()

        // Create extracted services
        let servicesSpan = initTransaction?.startChild(
            operation: "service.init",
            description: "Extracted Services"
        )
        self.eventLoggingService = EventLoggingService(eventStore: eventStore, profileStore: profileStore)
        self.coverageGapService = CoverageGapService(eventStore: eventStore, profileStore: profileStore)
        self.predictionService = PredictionService(profileStore: profileStore)
        servicesSpan?.finish()

        // NOTE: With @Observable, we no longer need to forward objectWillChange from nested objects.
        // Views will only re-render when they access specific properties that change.
        // The nested services (sheetCoordinator, activityManager, etc.) still use ObservableObject
        // for now, but their changes are reflected through the properties they update on this class.

        // Flush deferred celebrations as soon as sheets are dismissed.
        // Note: SheetCoordinator is @Observable, so we use notifications instead of Combine publishers
        activeSheetCancellable = NotificationCenter.default.publisher(for: .sheetDismissed)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.flushPendingCelebrationIfNeeded()
            }

        // Set up service callbacks
        setupServiceCallbacks()

        // Set up activity manager callbacks
        setupActivityManagerCallbacks()

        // Observe EventStore's events and sync to this ViewModel
        // This ensures events are updated when EventStore loads them asynchronously
        // Note: EventStore is @Observable, not ObservableObject, so we use notifications
        eventStoreCancellable = NotificationCenter.default.publisher(for: .eventsDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.events = self.eventStore.events

                // Rebuild timeline items immediately (UI needs this)
                self.rebuildTimelineItems()

                // REACTIVITY FIX: Update combined state immediately for sleep/potty card visibility
                // This prevents stale card visibility after logging events (e.g., sleep card staying visible after wake)
                // Use fresh events (yesterday + today) instead of stale cached events
                let yesterday = Date().addingDays(-1).startOfDay
                let endOfToday = Date().endOfDay
                let freshRecentEvents = self.eventStore.getEvents(from: yesterday, to: endOfToday)
                self.cachedCombinedState = self.calculateCombinedState(withEvents: freshRecentEvents)

                // Debounce expensive stats/predictions refresh
                // This coalesces rapid event changes (e.g., bulk import, quick logging)
                self.scheduleBackgroundRefresh()
            }

        // Subscribe to EventDataProvider changes to refresh caches when historical data loads
        // This fixes the race condition where refreshCachedProperties runs before data is ready
        // PERF: Increased debounce from 200ms to 1s to coalesce rapid changes
        eventDataProviderCancellable = eventDataProvider.objectWillChange
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.refreshCachedProperties()
                }
            }

        // Listen for moment notification taps to open lightbox
        momentNotificationCancellable = NotificationCenter.default
            .publisher(for: .openMomentFromNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let eventId = notification.userInfo?["eventId"] as? UUID else { return }
                self?.openMomentFromNotification(eventId: eventId)
            }

        // Reset to today when app becomes active on a new day
        // This handles the case where user opens app on Day 2 but was last viewing Day 1
        appBecameActiveCancellable = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.resetToTodayIfNeeded()
            }

        loadEvents()

        // Finish init transaction
        initTransaction?.finish()
    }

    /// Reset to today if the current date is no longer today
    /// Called when app becomes active to ensure fresh start on new day
    private func resetToTodayIfNeeded() {
        guard !currentDate.isToday else { return }
        goToToday()
    }

    /// Open the moments lightbox for an event tapped from a notification
    private func openMomentFromNotification(eventId: UUID) {
        // Get recent moment events for the lightbox
        let momentEvents = eventStore.getEventsWithMedia(
            from: Date.daysAgo(30),
            to: Date()
        ).sorted { $0.time > $1.time }

        // Find the index of the tapped event
        guard let index = momentEvents.firstIndex(where: { $0.id == eventId }) else {
            // Event not found - maybe too old. Just show the first moment.
            if !momentEvents.isEmpty {
                sheetCoordinator.presentMomentsLightbox(events: momentEvents, startIndex: 0)
            }
            return
        }

        sheetCoordinator.presentMomentsLightbox(events: momentEvents, startIndex: index)
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

    // PERF: Debounce timestamp for rebuildTimelineItems
    private static var lastTimelineRebuild: Date = .distantPast

    /// Rebuild the pre-computed timeline items from current events
    /// This avoids O(n²) session building on every view render
    /// Delegates to TimelineItemBuilder for pure function logic
    internal func rebuildTimelineItems() {
        // PERF: Global debounce - skip if rebuilt recently by any instance
        let now = Date()
        guard now.timeIntervalSince(Self.lastTimelineRebuild) > 0.1 else {
            return
        }
        Self.lastTimelineRebuild = now

        // PERFORMANCE: Track timeline rebuild time
        let rebuildTransaction = CrashReporter.startTransaction(
            name: "Rebuild Timeline Items",
            operation: "timeline.rebuild"
        )

        let timelineSpan = rebuildTransaction?.startChild(
            operation: "timeline.build",
            description: "Build Timeline Items"
        )
        timelineItems = TimelineItemBuilder.buildTimelineItems(from: events)
        timelineSpan?.finish()

        // PERFORMANCE: Also rebuild vertical timeline items (was computed 3+ times per render)
        let verticalSpan = rebuildTransaction?.startChild(
            operation: "timeline.build",
            description: "Build Vertical Items"
        )
        let todaysAppointments: [DogAppointment]
        if let store = appointmentStore {
            todaysAppointments = store.appointments(for: currentDate)
        } else {
            todaysAppointments = []
        }
        cachedVerticalTimelineItems = TimelineItemBuilder.buildVerticalItems(
            events: events,
            appointments: todaysAppointments,
            puppyName: puppyName
        )
        verticalSpan?.finish()

        rebuildTransaction?.finish()
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

    // MARK: - Recent Photos

    /// Get events with photos from the last 7 days, sorted most recent first
    /// PERFORMANCE: Now returns cached value instead of synchronous Core Data fetch
    /// Cache is updated asynchronously when events change
    var recentPhotoEvents: [PuppyEvent] {
        recentPhotoEventsCache
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
        // NOTE: statsCache.refresh() and refreshPredictions() are NOT needed here
        // because EventStore.$events subscription already triggers them (lines 237-247).
        // Adding them here would cause double refresh on every event log.
        eventLoggingService.onEventsChanged = { [weak self] in
            // Events are synced via EventStore.$events subscription, no need to duplicate
            // Only update first-week experience counts (not handled elsewhere)
            guard let self = self else { return }
            FirstWeekExperienceService.shared.refreshCounts(from: self.events)
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

        // NOTE: Events sync and stats refresh are handled by EventStore.$events subscription
        coverageGapService.onEventsChanged = { [weak self] in
            guard let self = self else { return }
            FirstWeekExperienceService.shared.refreshCounts(from: self.events)
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
    private func presentCelebration(_ style: CelebrationPreset, streakCount: Int? = nil) {
        celebrationStyle = style
        celebrationStreakCount = streakCount
        showCelebration = false
        DispatchQueue.main.async { [weak self] in
            self?.showCelebration = true
        }
    }

    /// Trigger celebration, deferring if a sheet is currently covering the UI.
    func triggerCelebration(_ style: CelebrationPreset, streakCount: Int? = nil) {
        guard sheetCoordinator.activeSheet == nil else {
            pendingCelebrationStyle = style
            pendingCelebrationStreakCount = streakCount
            return
        }
        presentCelebration(style, streakCount: streakCount)
    }

    /// Flush any deferred celebration when sheets are dismissed.
    func flushPendingCelebrationIfNeeded() {
        guard sheetCoordinator.activeSheet == nil,
              let pendingStyle = pendingCelebrationStyle else { return }
        let streakCount = pendingCelebrationStreakCount
        pendingCelebrationStyle = nil
        pendingCelebrationStreakCount = nil
        presentCelebration(pendingStyle, streakCount: streakCount)
    }

    /// Sync events from EventStore to local array
    func syncEventsFromStore() {
        self.events = eventStore.events
        rebuildTimelineItems()
        // Update first-week experience counts for progressive disclosure
        FirstWeekExperienceService.shared.refreshCounts(from: eventStore.events)

        // REACTIVITY FIX: Update combined state immediately for sleep/potty card visibility
        // This prevents stale card visibility after logging events (e.g., sleep card staying visible after wake)
        // Use fresh events (yesterday + today) instead of stale cached events
        let yesterday = Date().addingDays(-1).startOfDay
        let endOfToday = Date().endOfDay
        let freshRecentEvents = eventStore.getEvents(from: yesterday, to: endOfToday)
        self.cachedCombinedState = self.calculateCombinedState(withEvents: freshRecentEvents)
    }

    /// Notify to refresh notifications
    func notifyRefreshNotifications() {
        refreshNotifications()
    }

    /// Notify to force refresh stats
    func notifyForceRefreshStats() {
        statsCache.refresh(force: true)
    }

    /// Schedule a debounced background refresh of stats and predictions
    /// Coalesces rapid event changes to avoid redundant calculations
    private func scheduleBackgroundRefresh() {
        // Cancel any pending refresh
        backgroundRefreshTask?.cancel()

        // Schedule new refresh after delay
        // PERF: Increased from 150ms to 500ms to better coalesce rapid changes
        backgroundRefreshTask = Task {
            // Wait for additional events to arrive
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            // PERFORMANCE: Skip heavy refreshes while a sheet is active
            // This prevents stuttering in time pickers and other interactive elements
            guard sheetCoordinator.activeSheet == nil else {
                return
            }

            // Now run the expensive refreshes
            // PERF: Don't use force: true - let the global debounce in TimelineStatsCache work
            self.statsCache.refresh(force: false)
            self.refreshPredictions()

            // PERFORMANCE: Refresh cached properties that were previously computed
            // These use pre-fetched data from EventDataProvider (no additional DB fetch)
            await self.refreshCachedProperties()
        }
    }

    // PERF: Global timestamp to prevent multiple ViewModel instances from refreshing simultaneously
    private static var lastCachedPropertiesRefresh: Date = .distantPast

    /// Refresh cached properties that were previously expensive computed properties
    /// Uses pre-fetched data from EventDataProvider to avoid blocking main thread
    private func refreshCachedProperties() async {
        // PERF: Global debounce - skip if refreshed recently by any instance
        let now = Date()
        guard now.timeIntervalSince(Self.lastCachedPropertiesRefresh) > 0.5 else {
            return
        }
        Self.lastCachedPropertiesRefresh = now

        // PERFORMANCE: Track cached properties refresh
        let refreshTransaction = CrashReporter.startTransaction(
            name: "Refresh Cached Properties",
            operation: "cache.refresh"
        )

        // Use EventDataProvider's pre-cached week events (no DB fetch)
        let weekEvents = eventDataProvider.weekEvents

        // Calculate recent photo events from cache
        let photoSpan = refreshTransaction?.startChild(
            operation: "cache.compute",
            description: "Photo Events Filter"
        )
        let photoEvents = weekEvents.filter { $0.photo != nil }
            .sorted { $0.time > $1.time }
        photoSpan?.finish()

        // Calculate partner activity from cache (uses recentEvents from EventDataProvider)
        let partnerSpan = refreshTransaction?.startChild(
            operation: "cache.compute",
            description: "Partner Activity Summary"
        )
        let recentEvents = eventDataProvider.recentEvents
        let partnerSummary = calculatePartnerActivitySummary(from: recentEvents)
        partnerSpan?.finish()

        // Update cached properties on main thread
        self.recentPhotoEventsCache = photoEvents
        self.partnerActivitySummaryCache = partnerSummary

        // PERFORMANCE: Cache combined state (previously computed on every view render)
        // Use the recentEvents we already fetched to ensure consistency
        let stateSpan = refreshTransaction?.startChild(
            operation: "cache.compute",
            description: "Combined Sleep/Potty State"
        )
        self.cachedCombinedState = self.calculateCombinedState(withEvents: recentEvents)
        stateSpan?.finish()

        // PERFORMANCE: Cache separated upcoming items (previously computed on every view render)
        // Note: This uses empty forecasts - views can still call separatedUpcomingItems() with forecasts if needed
        let upcomingSpan = refreshTransaction?.startChild(
            operation: "cache.compute",
            description: "Separated Upcoming Items"
        )
        self.cachedSeparatedItems = self.separatedUpcomingItems(forecasts: [])
        upcomingSpan?.finish()

        refreshTransaction?.finish()
    }

    /// Refresh prediction service state (async - fetches events on background thread)
    func refreshPredictions() {
        // Fire and forget - runs async to avoid blocking main thread
        Task {
            await refreshPredictionsAsync()
        }
    }

    /// Async implementation of predictions refresh - fetches events on background thread
    private func refreshPredictionsAsync() async {
        // Fetch all event ranges concurrently on background threads
        async let recentFetch = getRecentEventsAsync()
        async let historicalFetch = getHistoricalEventsAsync(days: 7)
        async let allFetch = getAllEventsAsync()

        let (recentEvents, historicalEvents, allEvents) = await (recentFetch, historicalFetch, allFetch)

        // Now call prediction service with pre-fetched data (no blocking)
        predictionService.refresh(
            todayEvents: events,
            recentEvents: recentEvents,
            historicalEvents: historicalEvents,
            allEvents: allEvents,
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

    /// Async version - uses cached events from EventDataProvider (no DB fetch needed)
    func getHistoricalEventsAsync(days: Int) async -> [PuppyEvent] {
        // Use pre-cached data from EventDataProvider
        // This avoids redundant Core Data fetches since EventDataProvider already has the data
        switch days {
        case ...7:
            return eventDataProvider.weekEvents
        case ...8:
            return eventDataProvider.eightDayEvents
        case ...15:
            return eventDataProvider.extendedEvents
        default:
            return eventDataProvider.monthEvents
        }
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

    /// Async version - uses cached events from EventDataProvider (no DB fetch needed)
    func getAllEventsAsync() async -> [PuppyEvent] {
        // Use pre-cached 30-day data from EventDataProvider
        // EventDataProvider already combines historical + today's events
        return eventDataProvider.monthEvents
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

    /// Async version - uses cached events from EventDataProvider (no DB fetch needed)
    func getRecentEventsAsync() async -> [PuppyEvent] {
        // Use pre-cached 2-day data from EventDataProvider
        // EventDataProvider already combines yesterday + today's events
        return eventDataProvider.recentEvents
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
            // Use async version to avoid blocking
            let recentEvents = await getRecentEventsAsync()
            await service.refreshNotifications(
                events: recentEvents,
                profile: profile,
                appointments: upcomingAppointments,
                isWalkInProgress: walkInProgress
            )
        }
    }
}
