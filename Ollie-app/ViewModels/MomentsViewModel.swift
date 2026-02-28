//
//  MomentsViewModel.swift
//  Ollie-app
//

import Foundation
import OllieShared
import Combine

/// ViewModel for the moments gallery view
@MainActor
class MomentsViewModel: ObservableObject {
    @Published var events: [PuppyEvent] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false

    /// Whether there are more events to load
    @Published private(set) var hasMoreEvents: Bool = true

    private let eventStore: EventStore
    private let mediaStore: MediaStore

    /// Number of events to load per batch
    private let batchSize: Int = 50

    /// Current offset for pagination (how many days back we've searched)
    private var currentDaysOffset: Int = 0

    /// Maximum days to search back
    private let maxDaysBack: Int = 365

    /// Set of event IDs already loaded (for deduplication)
    private var loadedEventIds: Set<UUID> = []

    init(eventStore: EventStore, mediaStore: MediaStore? = nil) {
        self.eventStore = eventStore
        self.mediaStore = mediaStore ?? MediaStore()
    }

    /// Load initial batch of events with photos (paginated)
    func loadEventsWithMedia() {
        guard !isLoading else { return }

        isLoading = true
        events = []
        loadedEventIds = []
        currentDaysOffset = 0
        hasMoreEvents = true

        loadNextBatch()
        isLoading = false
    }

    /// Load more events when scrolling near the end
    func loadMoreIfNeeded(currentEvent: PuppyEvent) {
        guard !isLoadingMore, hasMoreEvents else { return }

        // Check if we're near the end of the list (within last 6 items)
        let thresholdIndex = max(0, events.count - 6)
        if let currentIndex = events.firstIndex(where: { $0.id == currentEvent.id }),
           currentIndex >= thresholdIndex {
            isLoadingMore = true
            loadNextBatch()
            isLoadingMore = false
        }
    }

    /// Task for current batch load (to prevent overlapping loads)
    private var loadBatchTask: Task<Void, Never>?

    /// Load the next batch of events with photos (async to avoid blocking main thread)
    private func loadNextBatch() {
        // Cancel any existing load task
        loadBatchTask?.cancel()

        loadBatchTask = Task { [weak self] in
            guard let self = self else { return }

            let calendar = Calendar.current
            let today = Date()

            var newEvents: [PuppyEvent] = []
            var daysSearched = 0
            var localOffset = self.currentDaysOffset

            // Keep searching until we have enough events or hit the max
            while newEvents.count < self.batchSize && localOffset < self.maxDaysBack {
                let searchBatchDays = 30 // Search 30 days at a time for efficiency

                let endDate = calendar.date(byAdding: .day, value: -localOffset, to: today)!
                let startDate = calendar.date(byAdding: .day, value: -(localOffset + searchBatchDays), to: today)!

                // Use async version to avoid blocking main thread
                let batchEvents = await self.eventStore.getEventsAsync(from: startDate, to: endDate)

                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                let filteredEvents = batchEvents
                    .filter { $0.photo != nil && !self.loadedEventIds.contains($0.id) }
                    .sorted { $0.time > $1.time }

                for event in filteredEvents {
                    if newEvents.count < self.batchSize {
                        newEvents.append(event)
                        self.loadedEventIds.insert(event.id)
                    } else {
                        break
                    }
                }

                localOffset += searchBatchDays
                daysSearched += searchBatchDays

                // Safety check to prevent infinite loop
                if daysSearched > self.maxDaysBack {
                    break
                }
            }

            // Check if task was cancelled before updating UI
            guard !Task.isCancelled else { return }

            // Update state on main actor
            self.currentDaysOffset = localOffset

            // Append new events and sort
            self.events.append(contentsOf: newEvents)
            self.events.sort { $0.time > $1.time }

            // Check if we've reached the end
            if localOffset >= self.maxDaysBack || newEvents.isEmpty {
                self.hasMoreEvents = false
            }
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

        // Remove from local list
        events.removeAll { $0.id == event.id }
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

    // MARK: - Location-Based Filtering

    /// Find photos taken near a specific spot (within radius meters)
    func photosAtSpot(_ spot: WalkSpot, radiusMeters: Double = 100) -> [PuppyEvent] {
        events.filter { event in
            guard let lat = event.latitude, let lon = event.longitude else { return false }
            let distance = haversineDistance(
                lat1: lat, lon1: lon,
                lat2: spot.latitude, lon2: spot.longitude
            )
            return distance <= radiusMeters
        }
    }

    /// Find photos near any coordinate (within radius meters)
    func photosNear(latitude: Double, longitude: Double, radiusMeters: Double = 100) -> [PuppyEvent] {
        events.filter { event in
            guard let lat = event.latitude, let lon = event.longitude else { return false }
            let distance = haversineDistance(
                lat1: lat, lon1: lon,
                lat2: latitude, lon2: longitude
            )
            return distance <= radiusMeters
        }
    }

    /// Events with location data (for map display)
    var eventsWithLocation: [PuppyEvent] {
        events.filter { $0.latitude != nil && $0.longitude != nil }
    }

    /// Cluster nearby photos for map display
    /// Returns clusters with a representative location and count
    func clusterPhotos(radiusMeters: Double = 50) -> [PhotoCluster] {
        let locatedEvents = eventsWithLocation
        var clustered: [PhotoCluster] = []
        var assigned = Set<UUID>()

        for event in locatedEvents {
            guard !assigned.contains(event.id),
                  let lat = event.latitude,
                  let lon = event.longitude else { continue }

            // Find all nearby unclustered photos
            var clusterEvents = [event]
            for other in locatedEvents {
                guard !assigned.contains(other.id),
                      other.id != event.id,
                      let otherLat = other.latitude,
                      let otherLon = other.longitude else { continue }

                let distance = haversineDistance(lat1: lat, lon1: lon, lat2: otherLat, lon2: otherLon)
                if distance <= radiusMeters {
                    clusterEvents.append(other)
                }
            }

            // Mark all as assigned
            for e in clusterEvents {
                assigned.insert(e.id)
            }

            // Calculate cluster center (centroid)
            let centerLat = clusterEvents.compactMap { $0.latitude }.reduce(0, +) / Double(clusterEvents.count)
            let centerLon = clusterEvents.compactMap { $0.longitude }.reduce(0, +) / Double(clusterEvents.count)

            clustered.append(PhotoCluster(
                id: event.id,
                latitude: centerLat,
                longitude: centerLon,
                events: clusterEvents.sorted { $0.time > $1.time }
            ))
        }

        return clustered
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
        // Find events near this spot
        let eventsAtSpot = allEvents.filter { event in
            guard let lat = event.latitude, let lon = event.longitude else { return false }
            let distance = haversineDistance(
                lat1: lat, lon1: lon,
                lat2: spot.latitude, lon2: spot.longitude
            )
            return distance <= 100 // Within 100 meters
        }

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

    // MARK: - Distance Calculation

    /// Calculate distance between two coordinates using Haversine formula
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius: Double = 6371000 // meters

        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}

// MARK: - Photo Cluster Model

/// A cluster of nearby photos for map display
struct PhotoCluster: Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let events: [PuppyEvent]

    var count: Int { events.count }
    var isSinglePhoto: Bool { count == 1 }
    var firstEvent: PuppyEvent? { events.first }

    /// Whether this cluster contains any milestone photos
    var hasMilestonePhoto: Bool {
        events.contains { $0.type == .milestone }
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
