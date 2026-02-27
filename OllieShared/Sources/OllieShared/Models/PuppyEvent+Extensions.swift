//
//  PuppyEvent+Extensions.swift
//  OllieShared
//
//  Filtering and sorting extensions for PuppyEvent arrays

import Foundation

// MARK: - Array Extensions for PuppyEvent

extension Array where Element == PuppyEvent {
    // MARK: - Type Filtering

    /// Filter to only potty events (pee and poop)
    public func pottyEvents() -> [PuppyEvent] {
        filter { $0.type.isPottyEvent }
    }

    /// Filter to only pee events (alias: pees)
    public func pee() -> [PuppyEvent] {
        filter { $0.type == .plassen }
    }

    /// Filter to only pee events
    public func pees() -> [PuppyEvent] {
        pee()
    }

    /// Filter to only poop events (alias: poops)
    public func poop() -> [PuppyEvent] {
        filter { $0.type == .poepen }
    }

    /// Filter to only poop events
    public func poops() -> [PuppyEvent] {
        poop()
    }

    /// Filter to only sleep events
    public func sleeps() -> [PuppyEvent] {
        filter { $0.type == .slapen }
    }

    /// Filter to only wake events
    public func wakes() -> [PuppyEvent] {
        filter { $0.type == .ontwaken }
    }

    /// Filter to only meal events
    public func meals() -> [PuppyEvent] {
        filter { $0.type == .eten }
    }

    /// Filter to only walk events
    public func walks() -> [PuppyEvent] {
        filter { $0.type == .uitlaten }
    }

    /// Filter to only training events
    public func training() -> [PuppyEvent] {
        filter { $0.type == .training }
    }

    /// Filter to only weight events
    public func weights() -> [PuppyEvent] {
        filter { $0.type == .gewicht }
    }

    /// Filter to only moment/photo events
    public func moments() -> [PuppyEvent] {
        filter { $0.type == .moment }
    }

    // MARK: - Location Filtering

    /// Filter to only outdoor potty events
    public func outdoorPotty() -> [PuppyEvent] {
        filter { $0.type.isPottyEvent && $0.location == .buiten }
    }

    /// Filter to only indoor potty events
    public func indoorPotty() -> [PuppyEvent] {
        filter { $0.type.isPottyEvent && $0.location == .binnen }
    }

    /// Filter to only outdoor events (any type)
    public func outdoor() -> [PuppyEvent] {
        filter { $0.location == .buiten }
    }

    /// Filter to only indoor events (any type)
    public func indoor() -> [PuppyEvent] {
        filter { $0.location == .binnen }
    }

    // MARK: - Additional Type Filtering

    /// Filter to only drink events
    public func drinks() -> [PuppyEvent] {
        filter { $0.type == .drinken }
    }

    /// Filter to events of specific types
    public func ofTypes(_ types: [EventType]) -> [PuppyEvent] {
        filter { types.contains($0.type) }
    }

    /// Group events by date (day)
    public func groupedByDate() -> [Date: [PuppyEvent]] {
        let calendar = Calendar.current
        return Dictionary(grouping: self) { event in
            calendar.startOfDay(for: event.time)
        }
    }

    // MARK: - Sorting

    /// Sort chronologically (oldest first)
    public func chronological() -> [PuppyEvent] {
        sorted { $0.time < $1.time }
    }

    /// Sort reverse chronologically (newest first)
    public func reverseChronological() -> [PuppyEvent] {
        sorted { $0.time > $1.time }
    }

    // MARK: - Time Filtering

    /// Filter to events after a given date
    public func after(_ date: Date) -> [PuppyEvent] {
        filter { $0.time > date }
    }

    /// Filter to events before a given date
    public func before(_ date: Date) -> [PuppyEvent] {
        filter { $0.time < date }
    }

    /// Filter to events on a specific day
    public func onDay(_ date: Date) -> [PuppyEvent] {
        let calendar = Calendar.current
        return filter { calendar.isDate($0.time, inSameDayAs: date) }
    }

    /// Filter to events in the last N hours
    public func inLastHours(_ hours: Int) -> [PuppyEvent] {
        let cutoff = Date().addingTimeInterval(-Double(hours) * 3600)
        return filter { $0.time >= cutoff }
    }

    /// Filter to events in the last N days
    public func inLastDays(_ days: Int) -> [PuppyEvent] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return filter { $0.time >= cutoff }
    }

    /// Filter to events in the last N days (alias)
    public func lastDays(_ days: Int) -> [PuppyEvent] {
        inLastDays(days)
    }

    /// Filter to today's events only
    public func today() -> [PuppyEvent] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return filter { $0.time >= startOfToday }
    }

    /// Filter to yesterday's events only
    public func yesterday() -> [PuppyEvent] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        return filter { $0.time >= startOfYesterday && $0.time < startOfToday }
    }

    // MARK: - Convenience

    /// Get the most recent event (by time)
    public var mostRecent: PuppyEvent? {
        self.max { $0.time < $1.time }
    }

    /// Get the oldest event (by time)
    public var oldest: PuppyEvent? {
        self.min { $0.time < $1.time }
    }

    /// Get all events with photos
    public func withPhotos() -> [PuppyEvent] {
        filter { $0.photo != nil }
    }

    // MARK: - Coverage Gap Filtering

    /// Filter to only coverage gap events
    public func coverageGaps() -> [PuppyEvent] {
        filter { $0.type == .coverageGap }
    }

    /// Filter to only active (ongoing) coverage gaps - where endTime is nil
    public func activeGaps() -> [PuppyEvent] {
        filter { $0.type == .coverageGap && $0.endTime == nil }
    }

    /// Check if a specific time falls within any coverage gap
    public func isTimeCoveredByGap(_ time: Date) -> Bool {
        coverageGaps().contains { gap in
            let startTime = gap.time
            let endTime = gap.endTime ?? Date.distantFuture
            return time >= startTime && time <= endTime
        }
    }

    /// Get coverage gaps that overlap with a date range
    public func gapsOverlapping(start: Date, end: Date) -> [PuppyEvent] {
        coverageGaps().filter { gap in
            let gapStart = gap.time
            let gapEnd = gap.endTime ?? Date.distantFuture
            // Overlap exists if gap starts before range ends AND gap ends after range starts
            return gapStart <= end && gapEnd >= start
        }
    }
}
