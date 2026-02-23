//
//  EventFilters.swift
//  Ollie-app
//
//  Array extensions for filtering PuppyEvent collections.
//  Eliminates repeated .filter { $0.type == ... } patterns across the codebase.

import Foundation

// MARK: - Event Filtering Extensions

extension Array where Element == PuppyEvent {

    // MARK: - Type-Based Filtering

    /// Filter to potty events (plassen + poepen)
    func potty() -> [PuppyEvent] {
        filter { $0.type == .plassen || $0.type == .poepen }
    }

    /// Filter to pee events only
    func pee() -> [PuppyEvent] {
        filter { $0.type == .plassen }
    }

    /// Filter to poop events only
    func poop() -> [PuppyEvent] {
        filter { $0.type == .poepen }
    }

    /// Filter to meal events
    func meals() -> [PuppyEvent] {
        filter { $0.type == .eten }
    }

    /// Filter to walk events
    func walks() -> [PuppyEvent] {
        filter { $0.type == .uitlaten }
    }

    /// Filter to sleep events
    func sleeps() -> [PuppyEvent] {
        filter { $0.type == .slapen }
    }

    /// Filter to wake events
    func wakes() -> [PuppyEvent] {
        filter { $0.type == .ontwaken }
    }

    /// Filter to training events
    func training() -> [PuppyEvent] {
        filter { $0.type == .training }
    }

    /// Filter to social events
    func social() -> [PuppyEvent] {
        filter { $0.type == .sociaal }
    }

    /// Filter to weight events
    func weights() -> [PuppyEvent] {
        filter { $0.type == .gewicht }
    }

    /// Filter to moment (photo) events
    func moments() -> [PuppyEvent] {
        filter { $0.type == .moment }
    }

    /// Filter to milestone events
    func milestones() -> [PuppyEvent] {
        filter { $0.type == .milestone }
    }

    /// Filter to events of a specific type
    func ofType(_ type: EventType) -> [PuppyEvent] {
        filter { $0.type == type }
    }

    /// Filter to events of multiple types
    func ofTypes(_ types: [EventType]) -> [PuppyEvent] {
        filter { types.contains($0.type) }
    }

    // MARK: - Location-Based Filtering

    /// Filter to outdoor events
    func outdoor() -> [PuppyEvent] {
        filter { $0.location == .buiten }
    }

    /// Filter to indoor events
    func indoor() -> [PuppyEvent] {
        filter { $0.location == .binnen }
    }

    /// Filter to outdoor potty events (pee or poop outside)
    func outdoorPotty() -> [PuppyEvent] {
        filter { ($0.type == .plassen || $0.type == .poepen) && $0.location == .buiten }
    }

    /// Filter to indoor potty events (accidents)
    func indoorPotty() -> [PuppyEvent] {
        filter { ($0.type == .plassen || $0.type == .poepen) && $0.location == .binnen }
    }

    /// Filter to outdoor pee events
    func outdoorPee() -> [PuppyEvent] {
        filter { $0.type == .plassen && $0.location == .buiten }
    }

    /// Filter to outdoor poop events
    func outdoorPoop() -> [PuppyEvent] {
        filter { $0.type == .poepen && $0.location == .buiten }
    }

    // MARK: - Date-Based Filtering

    /// Filter to events from today
    func today() -> [PuppyEvent] {
        filter { $0.time.isToday }
    }

    /// Filter to events from a specific date
    func onDate(_ date: Date) -> [PuppyEvent] {
        filter { $0.time.isSameDay(as: date) }
    }

    /// Filter to events within a date range
    func between(start: Date, end: Date) -> [PuppyEvent] {
        filter { $0.time >= start && $0.time <= end }
    }

    /// Filter to events from the last N days
    func lastDays(_ days: Int) -> [PuppyEvent] {
        let cutoff = Date().addingDays(-days)
        return filter { $0.time >= cutoff }
    }

    // MARK: - Media Filtering

    /// Filter to events with photos
    func withPhotos() -> [PuppyEvent] {
        filter { $0.photo != nil || $0.thumbnailPath != nil }
    }

    /// Filter to events with videos
    func withVideos() -> [PuppyEvent] {
        filter { $0.video != nil }
    }

    /// Filter to events with any media
    func withMedia() -> [PuppyEvent] {
        filter { $0.photo != nil || $0.video != nil || $0.thumbnailPath != nil }
    }

    // MARK: - Sorting

    /// Sort chronologically (oldest first)
    func chronological() -> [PuppyEvent] {
        sorted { $0.time < $1.time }
    }

    /// Sort reverse chronologically (newest first)
    func reverseChronological() -> [PuppyEvent] {
        sorted { $0.time > $1.time }
    }

    // MARK: - Aggregations

    /// Get the most recent event
    var mostRecent: PuppyEvent? {
        self.max(by: { $0.time < $1.time })
    }

    /// Get the oldest event
    var oldest: PuppyEvent? {
        self.min(by: { $0.time < $1.time })
    }

    /// Get the most recent event of a specific type
    func mostRecent(ofType type: EventType) -> PuppyEvent? {
        ofType(type).mostRecent
    }

    /// Count events by type
    func countByType() -> [EventType: Int] {
        var counts: [EventType: Int] = [:]
        for event in self {
            counts[event.type, default: 0] += 1
        }
        return counts
    }

    /// Group events by date (start of day)
    func groupedByDate() -> [Date: [PuppyEvent]] {
        Dictionary(grouping: self) { $0.time.startOfDay }
    }
}
