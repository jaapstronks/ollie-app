//
//  MomentsViewModel.swift
//  Ollie-app
//

import Foundation
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
}
