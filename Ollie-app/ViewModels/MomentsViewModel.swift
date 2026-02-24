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

    private let eventStore: EventStore
    private let mediaStore: MediaStore

    init(eventStore: EventStore, mediaStore: MediaStore? = nil) {
        self.eventStore = eventStore
        self.mediaStore = mediaStore ?? MediaStore()
    }

    /// Load all events that have photos
    func loadEventsWithMedia() {
        isLoading = true

        // Get events from the last 365 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -365, to: endDate)!

        let allEvents = eventStore.getEvents(from: startDate, to: endDate)

        // Filter to only events with photos
        events = allEvents.filter { $0.photo != nil }
            .sorted { $0.time > $1.time } // Most recent first

        isLoading = false
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

    /// Get events grouped by month
    var eventsByMonth: [(month: String, events: [PuppyEvent])] {
        let grouped = Dictionary(grouping: events) { event -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "nl_NL")
            return formatter.string(from: event.time)
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
}
