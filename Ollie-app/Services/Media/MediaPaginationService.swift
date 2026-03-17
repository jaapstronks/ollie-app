//
//  MediaPaginationService.swift
//  Ollie-app
//
//  Handles paginated loading of media events from the event store.
//  Manages batch loading, offset tracking, and deduplication.
//

import Foundation
import OtisShared

/// Result of a pagination load operation
struct MediaPaginationResult {
    let events: [PuppyEvent]
    let hasMore: Bool
}

/// Service for paginated loading of media events
@MainActor
final class MediaPaginationService {

    // MARK: - Configuration

    /// Number of events to load per batch
    let batchSize: Int

    /// Maximum days to search back
    let maxDaysBack: Int

    // MARK: - State

    /// Current offset for pagination (how many days back we've searched)
    private(set) var currentDaysOffset: Int = 0

    /// Set of event IDs already loaded (for deduplication)
    private(set) var loadedEventIds: Set<UUID> = []

    /// Whether there are more events to load
    private(set) var hasMoreEvents: Bool = true

    /// Task for current batch load (to prevent overlapping loads)
    private var loadBatchTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let eventStore: EventStore

    // MARK: - Init

    init(
        eventStore: EventStore,
        batchSize: Int = 50,
        maxDaysBack: Int = 365
    ) {
        self.eventStore = eventStore
        self.batchSize = batchSize
        self.maxDaysBack = maxDaysBack
    }

    // MARK: - Public API

    /// Reset pagination state for a fresh load
    func reset() {
        loadBatchTask?.cancel()
        currentDaysOffset = 0
        loadedEventIds = []
        hasMoreEvents = true
    }

    /// Load the next batch of events with photos
    /// - Parameter onComplete: Callback with new events when load completes
    func loadNextBatch(onComplete: @escaping ([PuppyEvent]) -> Void) {
        // Cancel any existing load task
        loadBatchTask?.cancel()

        loadBatchTask = Task { [weak self] in
            guard let self = self else { return }

            let events = await self.fetchNextBatch()

            // Check if task was cancelled before calling completion
            guard !Task.isCancelled else { return }

            onComplete(events)
        }
    }

    /// Check if we're near the end of the list and should load more
    /// - Parameters:
    ///   - currentIndex: Index of the current item being viewed
    ///   - totalCount: Total number of items in the list
    ///   - threshold: How many items from the end to trigger loading (default 6)
    /// - Returns: Whether more events should be loaded
    func shouldLoadMore(currentIndex: Int, totalCount: Int, threshold: Int = 6) -> Bool {
        guard hasMoreEvents else { return false }
        let thresholdIndex = max(0, totalCount - threshold)
        return currentIndex >= thresholdIndex
    }

    /// Check for new photo events that aren't in our loaded set
    /// - Parameter allEvents: All events from the store
    /// - Returns: New events that should be added
    func findNewPhotoEvents(from allEvents: [PuppyEvent]) -> [PuppyEvent] {
        allEvents.filter { event in
            event.photo != nil && !loadedEventIds.contains(event.id)
        }
    }

    /// Mark events as loaded (for deduplication)
    func markAsLoaded(_ events: [PuppyEvent]) {
        for event in events {
            loadedEventIds.insert(event.id)
        }
    }

    /// Mark a single event as loaded
    func markAsLoaded(_ eventId: UUID) {
        loadedEventIds.insert(eventId)
    }

    /// Remove an event from tracking (when deleted)
    func removeFromTracking(_ eventId: UUID) {
        loadedEventIds.remove(eventId)
    }

    // MARK: - Private

    private func fetchNextBatch() async -> [PuppyEvent] {
        let calendar = Calendar.current
        let today = Date()

        var newEvents: [PuppyEvent] = []
        var daysSearched = 0
        var localOffset = currentDaysOffset

        // Keep searching until we have enough events or hit the max
        while newEvents.count < batchSize && localOffset < maxDaysBack {
            let searchBatchDays = 30 // Search 30 days at a time for efficiency

            guard let endDate = calendar.date(byAdding: .day, value: -localOffset, to: today),
                  let startDate = calendar.date(byAdding: .day, value: -(localOffset + searchBatchDays), to: today) else {
                break
            }

            // Use async version to avoid blocking main thread
            let batchEvents = await eventStore.getEventsAsync(from: startDate, to: endDate)

            // Check if task was cancelled
            guard !Task.isCancelled else { return [] }

            let filteredEvents = batchEvents
                .filter { $0.photo != nil && !loadedEventIds.contains($0.id) }
                .sorted { $0.time > $1.time }

            for event in filteredEvents {
                if newEvents.count < batchSize {
                    newEvents.append(event)
                    loadedEventIds.insert(event.id)
                } else {
                    break
                }
            }

            localOffset += searchBatchDays
            daysSearched += searchBatchDays

            // Safety check to prevent infinite loop
            if daysSearched > maxDaysBack {
                break
            }
        }

        // Check if task was cancelled before updating state
        guard !Task.isCancelled else { return [] }

        // Update state
        currentDaysOffset = localOffset

        // Check if we've reached the end
        if localOffset >= maxDaysBack || newEvents.isEmpty {
            hasMoreEvents = false
        }

        return newEvents
    }
}
