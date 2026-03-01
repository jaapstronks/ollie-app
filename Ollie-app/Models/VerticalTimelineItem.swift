//
//  VerticalTimelineItem.swift
//  Otis-app
//
//  Item model for the vertical day-planner timeline view

import Foundation
import OtisShared

/// An item prepared for vertical day-planner timeline display
struct VerticalTimelineItem: Identifiable {
    enum ItemType {
        case sleepSession(SleepSession)
        case walkEvent(PuppyEvent)
        case pointEvent(PuppyEvent)
        case appointmentItem(DogAppointment)
    }

    /// Which track the item should render in
    enum TrackType {
        case main       // Full width - appointments
        case activity   // Left side - sleep sessions, walks (duration blocks)
        case potty      // Right side - pee, poo events
        case walk       // Legacy: same as activity (for backwards compatibility)
    }

    let id: UUID
    let type: ItemType
    let startTime: Date
    let endTime: Date?
    let photoThumbnail: String?
    let note: String?
    let track: TrackType

    /// Natural language description for the event
    var description: String {
        // Set by the factory methods below
        _description
    }

    private let _description: String

    init(
        id: UUID,
        type: ItemType,
        startTime: Date,
        endTime: Date?,
        photoThumbnail: String?,
        note: String?,
        description: String,
        track: TrackType = .main
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.photoThumbnail = photoThumbnail
        self.note = note
        self._description = description
        self.track = track
    }

    /// Duration in minutes (if applicable)
    var durationMinutes: Int? {
        guard let endTime = endTime else {
            // Ongoing - calculate from now
            switch type {
            case .sleepSession, .walkEvent:
                return Int(Date().timeIntervalSince(startTime) / 60)
            case .pointEvent, .appointmentItem:
                return nil
            }
        }
        return Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// Whether this is an ongoing activity (sleep in progress)
    var isOngoing: Bool {
        switch type {
        case .sleepSession(let session):
            return session.isOngoing
        case .walkEvent, .pointEvent, .appointmentItem:
            return false
        }
    }

    /// Whether this item has duration (vs point-in-time)
    var hasDuration: Bool {
        switch type {
        case .sleepSession, .walkEvent, .appointmentItem:
            return true
        case .pointEvent:
            return false
        }
    }

    /// Whether this is an appointment (for special styling)
    var isAppointment: Bool {
        if case .appointmentItem = type { return true }
        return false
    }

    /// Whether this is a potty event (pee or poo)
    var isPottyEvent: Bool {
        if case .pointEvent(let event) = type {
            return event.type == .plassen || event.type == .poepen
        }
        return false
    }

    /// Whether this is an activity block (sleep or walk)
    var isActivityBlock: Bool {
        switch type {
        case .sleepSession, .walkEvent:
            return true
        default:
            return false
        }
    }

    /// Formatted duration string
    var durationString: String? {
        guard let minutes = durationMinutes, hasDuration else { return nil }
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
    }

    /// Icon for this item
    var icon: String {
        switch type {
        case .sleepSession:
            return "moon.zzz.fill"
        case .walkEvent:
            return "figure.walk"
        case .pointEvent(let event):
            return event.type.icon
        case .appointmentItem(let appointment):
            return appointment.appointmentType.icon
        }
    }
}
