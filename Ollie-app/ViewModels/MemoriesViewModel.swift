//
//  MemoriesViewModel.swift
//  Otis-app
//
//  ViewModel for "On This Day" memories feature

import Foundation
import SwiftUI
import OtisShared
import Combine

/// ViewModel for the "On This Day" memories card on Today view
@Observable
@MainActor
class MemoriesViewModel {

    // MARK: - State

    /// The best memory to display (with photo/notes prioritized)
    var memoryItem: MemoryItem?

    /// All memorable events from the target date
    var allMemoriesForDay: [PuppyEvent] = []

    // MARK: - Dependencies

    @ObservationIgnored private let eventStore: EventStore
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Whether to show the memories card
    var shouldShowCard: Bool {
        memoryItem != nil
    }

    /// The time frame being displayed
    var timeFrame: MemoryItem.TimeFrame {
        memoryItem?.timeFrame ?? computedTimeFrame
    }

    /// Computed time frame based on months of data
    private var computedTimeFrame: MemoryItem.TimeFrame {
        let months = monthsOfData
        if months > 12 {
            return .year
        } else if months >= 4 {
            return .month
        } else {
            return .week
        }
    }

    /// Number of months of logged data
    var monthsOfData: Int {
        guard let earliestDate = eventStore.getEarliestEventDate() else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: earliestDate, to: Date())
        return components.month ?? 0
    }

    /// Number of additional events beyond the primary memory
    var additionalEventCount: Int {
        max(0, allMemoriesForDay.count - 1)
    }

    // MARK: - Init

    init(eventStore: EventStore) {
        self.eventStore = eventStore

        setupObservers()
        refresh()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Watch for event changes with debounce to prevent rapid refreshes during active logging
        // Note: EventStore is @Observable, not ObservableObject, so we use notifications
        NotificationCenter.default.publisher(for: .eventsDidChange)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    // MARK: - Refresh

    func refresh() {
        let timeFrame = computedTimeFrame
        let today = Date()

        // Calculate target date
        guard let targetDate = timeFrame.targetDate(from: today) else {
            memoryItem = nil
            allMemoriesForDay = []
            return
        }

        // Check if user has enough data
        guard let earliestDate = eventStore.getEarliestEventDate() else {
            memoryItem = nil
            allMemoriesForDay = []
            return
        }

        // Don't show memories if target date is before first event
        if targetDate < earliestDate {
            memoryItem = nil
            allMemoriesForDay = []
            return
        }

        // Minimum 1 week of data required
        let daysSinceFirstEvent = Calendar.current.dateComponents([.day], from: earliestDate, to: today).day ?? 0
        if daysSinceFirstEvent < 7 {
            memoryItem = nil
            allMemoriesForDay = []
            return
        }

        // Fetch events for target date
        let calendar = Calendar.current
        let startOfTargetDay = calendar.startOfDay(for: targetDate)
        guard let endOfTargetDay = calendar.date(byAdding: .day, value: 1, to: startOfTargetDay) else {
            memoryItem = nil
            allMemoriesForDay = []
            return
        }

        let events = eventStore.getEvents(from: startOfTargetDay, to: endOfTargetDay)

        // Filter to memorable events only
        let memorableEvents = events.filter { $0.type.isMemorableEvent }

        if memorableEvents.isEmpty {
            memoryItem = nil
            allMemoriesForDay = []
            return
        }

        // Sort events by priority: photo > notes > type
        let sortedEvents = memorableEvents.sorted { a, b in
            // Photos first
            let aHasPhoto = a.photo != nil
            let bHasPhoto = b.photo != nil
            if aHasPhoto != bHasPhoto {
                return aHasPhoto
            }

            // Notes second
            let aHasNote = a.note != nil && !a.note!.isEmpty
            let bHasNote = b.note != nil && !b.note!.isEmpty
            if aHasNote != bHasNote {
                return aHasNote
            }

            // High-priority types third
            let highPriorityTypes: [EventType] = [.milestone, .sociaal, .training]
            let aIsHighPriority = highPriorityTypes.contains(a.type)
            let bIsHighPriority = highPriorityTypes.contains(b.type)
            if aIsHighPriority != bIsHighPriority {
                return aIsHighPriority
            }

            // Fall back to time (earlier first for storytelling)
            return a.time < b.time
        }

        allMemoriesForDay = sortedEvents

        // Select best memory
        if let bestEvent = sortedEvents.first {
            memoryItem = MemoryItem(event: bestEvent, timeFrame: timeFrame)
        } else {
            memoryItem = nil
        }
    }
}
