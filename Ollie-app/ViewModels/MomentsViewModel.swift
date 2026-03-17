//
//  MomentsViewModel.swift
//  Otis-app
//

import Combine
import Foundation
import OtisShared

/// ViewModel for the moments gallery view
@Observable
@MainActor
class MomentsViewModel {
    var events: [PuppyEvent] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    private(set) var cachedPhotoClusters: [PhotoCluster] = []

    /// Whether there are more events to load
    var hasMoreEvents: Bool { paginationService.hasMoreEvents }

    // MARK: - Dependencies

    @ObservationIgnored private let eventStore: EventStore
    @ObservationIgnored private let mediaStore: MediaStore
    @ObservationIgnored private let paginationService: MediaPaginationService
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(eventStore: EventStore, mediaStore: MediaStore? = nil) {
        self.eventStore = eventStore
        self.mediaStore = mediaStore ?? MediaStore()
        self.paginationService = MediaPaginationService(eventStore: eventStore)

        // Subscribe to EventStore changes to auto-refresh when new events are added
        subscribeToEventStoreChanges()
    }

    /// Subscribe to EventStore changes to detect newly added photo events
    private func subscribeToEventStoreChanges() {
        // Note: EventStore is @Observable, not ObservableObject, so we use notifications
        NotificationCenter.default.publisher(for: .eventsDidChange)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkForNewPhotoEvents()
            }
            .store(in: &cancellables)
    }

    /// Check if there are new photo events that should be added to our list
    private func checkForNewPhotoEvents() {
        // First check today's events (most common case for new photos)
        let todayNewEvents = paginationService.findNewPhotoEvents(from: eventStore.events)

        if !todayNewEvents.isEmpty {
            addNewEventsToGallery(todayNewEvents)
            return
        }

        // If no new events from today, check the full date range asynchronously
        // This handles photos with EXIF dates from the past
        Task {
            await checkForNewPhotoEventsAsync()
        }
    }

    /// Async check for new photo events across the full date range
    /// Handles photos selected from library with past dates
    private func checkForNewPhotoEventsAsync() async {
        let calendar = Calendar.current
        let today = Date()
        guard let startDate = calendar.date(byAdding: .year, value: -1, to: today) else { return }

        // Query for all photo events in the pagination range
        let allPhotoEvents = await eventStore.getEventsWithMediaAsync(from: startDate, to: today)

        // Find events not in our loaded set
        let newEvents = allPhotoEvents.filter { !paginationService.loadedEventIds.contains($0.id) }

        guard !newEvents.isEmpty else { return }

        addNewEventsToGallery(newEvents)
    }

    /// Add new photo events to the gallery and update state
    private func addNewEventsToGallery(_ newEvents: [PuppyEvent]) {
        for event in newEvents {
            events.insert(event, at: 0)
            paginationService.markAsLoaded(event.id)
        }

        // Re-sort by time (newest first)
        events.sort { $0.time > $1.time }
        refreshPhotoClusters()
    }

    /// Load initial batch of events with photos (paginated)
    func loadEventsWithMedia() {
        guard !isLoading else { return }

        isLoading = true
        events = []
        cachedPhotoClusters = []
        paginationService.reset()

        paginationService.loadNextBatch { [weak self] newEvents in
            guard let self else { return }
            self.events.append(contentsOf: newEvents)
            self.events.sort { $0.time > $1.time }
            self.refreshPhotoClusters()
            self.isLoading = false
        }
    }

    /// Load more events when scrolling near the end
    func loadMoreIfNeeded(currentEvent: PuppyEvent) {
        guard !isLoadingMore, hasMoreEvents else { return }

        // Check if we're near the end of the list (within last 6 items)
        guard let currentIndex = events.firstIndex(where: { $0.id == currentEvent.id }),
              paginationService.shouldLoadMore(currentIndex: currentIndex, totalCount: events.count) else {
            return
        }

        isLoadingMore = true
        paginationService.loadNextBatch { [weak self] newEvents in
            guard let self else { return }
            self.events.append(contentsOf: newEvents)
            self.events.sort { $0.time > $1.time }
            self.refreshPhotoClusters()
            self.isLoadingMore = false
        }
    }

    /// Legacy method for full reload (used by pull-to-refresh)
    func reloadAllEvents() {
        loadEventsWithMedia()
    }

    /// Delete an event and its associated media files
    func deleteEvent(_ event: PuppyEvent) {
        // Delete media files
        mediaStore.deleteMedia(photoPath: event.photo, thumbnailPath: event.thumbnailPath)

        // Delete event from store
        eventStore.deleteEvent(event)

        // Remove from local list and tracking
        events.removeAll { $0.id == event.id }
        paginationService.removeFromTracking(event.id)
        refreshPhotoClusters()
    }

    /// Static DateFormatter to avoid recreation per event (performance optimization)
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }()

    /// Get events grouped by month
    var eventsByMonth: [(month: String, events: [PuppyEvent])] {
        let grouped = Dictionary(grouping: events) { event -> String in
            Self.monthFormatter.string(from: event.time)
        }

        return grouped.map { (month: $0.key, events: $0.value) }
            .sorted { lhs, rhs in
                guard let lhsDate = lhs.events.first?.time,
                      let rhsDate = rhs.events.first?.time else { return false }
                return lhsDate > rhsDate
            }
    }

    /// One photo per day for diary view (most recent photo from each day)
    var eventsPerDay: [PuppyEvent] {
        let grouped = Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.time)
        }
        // PERF: Use max(by:) O(n) instead of sorted().first O(n log n)
        return grouped.values
            .compactMap { $0.max(by: { $0.time < $1.time }) }
            .sorted { $0.time > $1.time }
    }

    // MARK: - Location-Based Filtering

    /// Find photos taken near a specific spot (within radius meters)
    func photosAtSpot(_ spot: WalkSpot, radiusMeters: Double = 100) -> [PuppyEvent] {
        PhotoClusteringService.photosAtSpot(events: events, spot: spot, radiusMeters: radiusMeters)
    }

    /// Find photos near any coordinate (within radius meters)
    func photosNear(latitude: Double, longitude: Double, radiusMeters: Double = 100) -> [PuppyEvent] {
        PhotoClusteringService.photosNear(
            events: events,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters
        )
    }

    /// Events with location data (for map display)
    var eventsWithLocation: [PuppyEvent] {
        PhotoClusteringService.eventsWithLocation(events)
    }

    /// Cluster nearby photos for map display
    /// Returns clusters with a representative location and count
    func clusterPhotos(radiusMeters: Double = PhotoClusteringService.defaultRadius) -> [PhotoCluster] {
        // Explore map uses the default radius most of the time; keep it cached.
        if abs(radiusMeters - PhotoClusteringService.defaultRadius) < 0.001 {
            return cachedPhotoClusters
        }
        return PhotoClusteringService.cluster(events: events, radiusMeters: radiusMeters)
    }

    // MARK: - Place Stats

    /// Get statistics for a specific spot by querying all events from the store
    func loadStatsForSpot(_ spot: WalkSpot) async -> PlaceStats {
        // Query all events from the last year
        let calendar = Calendar.current
        let today = Date()
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) else {
            return PlaceStats(pottySuccessCount: 0, dogsMetCount: 0, firstVisited: nil, lastVisited: nil)
        }

        let allEvents = await eventStore.getEventsAsync(from: oneYearAgo, to: today)
        return statsForSpot(spot, allEvents: allEvents)
    }

    /// Get statistics for a specific spot based on all events (not just photos)
    func statsForSpot(_ spot: WalkSpot, allEvents: [PuppyEvent]) -> PlaceStats {
        // Find events near this spot (within 100 meters)
        let eventsAtSpot = PhotoClusteringService.photosAtSpot(
            events: allEvents,
            spot: spot,
            radiusMeters: 100
        )

        // Count outdoor potty successes (buiten plas/poepen)
        let pottySuccessCount = eventsAtSpot.filter { event in
            event.isPottyEvent && event.location == .buiten
        }.count

        // Count dogs met (sociaal events)
        let dogsMetCount = eventsAtSpot.filter { $0.type == .sociaal }.count

        // Find first and last visited dates
        let sortedByTime = eventsAtSpot.sorted { $0.time < $1.time }
        let firstVisited = sortedByTime.first?.time
        let lastVisited = sortedByTime.last?.time

        return PlaceStats(
            pottySuccessCount: pottySuccessCount,
            dogsMetCount: dogsMetCount,
            firstVisited: firstVisited,
            lastVisited: lastVisited
        )
    }

    // MARK: - Cluster Cache

    private func refreshPhotoClusters() {
        cachedPhotoClusters = PhotoClusteringService.cluster(events: events)
    }
}

// MARK: - Place Stats Model

/// Statistics for a specific saved spot
struct PlaceStats {
    let pottySuccessCount: Int    // Outdoor plas/poepen events at spot
    let dogsMetCount: Int         // Sociaal events at spot
    let firstVisited: Date?       // Earliest event
    let lastVisited: Date?        // Most recent event

    /// Whether there are any meaningful stats to show
    var hasStats: Bool {
        pottySuccessCount > 0 || dogsMetCount > 0 || firstVisited != nil
    }
}

// MARK: - PuppyEvent Extension

extension PuppyEvent {
    /// Whether this is a potty event (plas or poep)
    var isPottyEvent: Bool {
        type == .plassen || type == .poepen
    }
}
