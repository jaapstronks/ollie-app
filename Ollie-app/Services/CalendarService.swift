//
//  CalendarService.swift
//  Ollie-app
//
//  EventKit integration for adding milestones to calendar

import Foundation
import EventKit
import OllieShared
import os

/// Service for calendar integration (Ollie+ feature)
actor CalendarService {

    // MARK: - Singleton

    static let shared = CalendarService()

    // MARK: - Properties

    private let eventStore = EKEventStore()
    private let logger = Logger.ollie(category: "CalendarService")

    // MARK: - Access

    /// Request access to calendars
    func requestAccess() async throws -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            logger.info("Calendar access granted: \(granted)")
            return granted
        } catch {
            logger.error("Failed to request calendar access: \(error.localizedDescription)")
            throw CalendarError.accessDenied
        }
    }

    /// Check if we have calendar access
    func hasAccess() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == .fullAccess
    }

    // MARK: - Event Management

    /// Add a milestone to the calendar
    func addMilestone(_ milestone: Milestone, profile: PuppyProfile) async throws -> String {
        guard hasAccess() else {
            throw CalendarError.accessDenied
        }

        guard let targetDate = milestone.targetDate(birthDate: profile.birthDate) else {
            throw CalendarError.invalidDate
        }

        let event = EKEvent(eventStore: eventStore)

        // Set event details
        event.title = "\(profile.name): \(milestone.localizedLabel)"
        event.startDate = targetDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: targetDate) ?? targetDate
        event.isAllDay = true
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Add notes if available
        if let detail = milestone.localizedDetail {
            event.notes = detail
        }

        // Add reminder if configured
        if milestone.reminderDaysBefore > 0 {
            let alarm = EKAlarm(relativeOffset: TimeInterval(-milestone.reminderDaysBefore * 24 * 60 * 60))
            event.addAlarm(alarm)
        }

        // Save the event
        do {
            try eventStore.save(event, span: .thisEvent)
            logger.info("Added milestone to calendar: \(milestone.localizedLabel)")
            Analytics.trackCalendarEvent(added: true, milestoneCategory: milestone.category.rawValue)
            return event.eventIdentifier
        } catch {
            logger.error("Failed to save calendar event: \(error.localizedDescription)")
            throw CalendarError.saveFailed(error)
        }
    }

    /// Remove an event from the calendar
    func removeEvent(identifier: String) async throws {
        guard hasAccess() else {
            throw CalendarError.accessDenied
        }

        guard let event = eventStore.event(withIdentifier: identifier) else {
            logger.warning("Event not found for removal: \(identifier)")
            return // Event already removed or doesn't exist
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
            logger.info("Removed calendar event: \(identifier)")
            Analytics.trackCalendarEvent(added: false, milestoneCategory: "unknown")
        } catch {
            logger.error("Failed to remove calendar event: \(error.localizedDescription)")
            throw CalendarError.removeFailed(error)
        }
    }

    /// Get available calendars
    func availableCalendars() -> [EKCalendar] {
        eventStore.calendars(for: .event)
    }

    /// Update an existing calendar event
    func updateEvent(identifier: String, milestone: Milestone, profile: PuppyProfile) async throws {
        guard hasAccess() else {
            throw CalendarError.accessDenied
        }

        guard let event = eventStore.event(withIdentifier: identifier) else {
            // Event doesn't exist, create a new one
            _ = try await addMilestone(milestone, profile: profile)
            return
        }

        guard let targetDate = milestone.targetDate(birthDate: profile.birthDate) else {
            throw CalendarError.invalidDate
        }

        // Update event details
        event.title = "\(profile.name): \(milestone.localizedLabel)"
        event.startDate = targetDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: targetDate) ?? targetDate

        if let detail = milestone.localizedDetail {
            event.notes = detail
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            logger.info("Updated calendar event: \(milestone.localizedLabel)")
        } catch {
            logger.error("Failed to update calendar event: \(error.localizedDescription)")
            throw CalendarError.saveFailed(error)
        }
    }
}

// MARK: - Errors

enum CalendarError: LocalizedError {
    case accessDenied
    case invalidDate
    case saveFailed(Error)
    case removeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return String(localized: "Calendar access denied. Please enable calendar access in Settings.")
        case .invalidDate:
            return String(localized: "Invalid milestone date.")
        case .saveFailed(let error):
            return String(localized: "Failed to save event: \(error.localizedDescription)")
        case .removeFailed(let error):
            return String(localized: "Failed to remove event: \(error.localizedDescription)")
        }
    }
}
