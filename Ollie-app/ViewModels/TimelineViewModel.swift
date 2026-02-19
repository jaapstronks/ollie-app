//
//  TimelineViewModel.swift
//  Ollie-app
//

import Foundation
import SwiftUI

@Observable
@MainActor
class TimelineViewModel {
    var events: [PuppyEvent] = []
    var selectedDate: Date = Date()
    var isLoading = false
    var showingLocationPicker = false
    var pendingEventType: EventType?
    var showingNoteSheet = false
    var pendingNote: String = ""

    private let store = EventStore.shared

    var isToday: Bool {
        DateHelpers.isToday(selectedDate)
    }

    var displayDate: String {
        if isToday {
            return "Vandaag"
        }
        return DateHelpers.formatDateForDisplay(selectedDate)
    }

    init() {
        loadEvents()
    }

    func loadEvents() {
        isLoading = true
        events = store.loadEvents(for: selectedDate)
        isLoading = false
    }

    func goToToday() {
        selectedDate = Date()
        loadEvents()
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        loadEvents()
    }

    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        loadEvents()
    }

    // Quick log: called when tapping a quick log button
    func quickLog(_ type: EventType) {
        if type == .plassen || type == .poepen {
            // Need to ask for location
            pendingEventType = type
            showingLocationPicker = true
        } else {
            // Log immediately
            logEvent(type: type)
        }
    }

    // Log with location (for plassen/poepen)
    func logWithLocation(_ location: PottyLocation) {
        guard let type = pendingEventType else { return }
        logEvent(type: type, location: location)
        pendingEventType = nil
        showingLocationPicker = false
    }

    // Log event with optional parameters
    func logEvent(type: EventType, location: PottyLocation? = nil, note: String? = nil) {
        let event = PuppyEvent(
            time: Date(),
            type: type,
            location: location,
            note: note?.isEmpty == true ? nil : note
        )

        do {
            try store.saveEvent(event)
            // Reload events to show the new one
            loadEvents()
        } catch {
            print("Failed to save event: \(error)")
        }
    }

    func cancelLocationPicker() {
        pendingEventType = nil
        showingLocationPicker = false
    }
}
