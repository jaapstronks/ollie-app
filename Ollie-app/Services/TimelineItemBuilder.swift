//
//  TimelineItemBuilder.swift
//  Otis-app
//
//  Extracted from TimelineViewModel+VerticalTimeline.swift
//  Pure functions for building timeline items from events
//

import Foundation
import OtisShared

/// Pure functions for building timeline items from events and appointments
/// Extracted from TimelineViewModel to improve testability and separation of concerns
struct TimelineItemBuilder {

    // MARK: - Vertical Timeline Items

    /// Build items for vertical timeline display
    /// Groups sleep sessions, walks with duration, point events, and appointments
    /// Sorted newest-first (future at top, past at bottom)
    static func buildVerticalItems(
        events: [PuppyEvent],
        appointments: [DogAppointment],
        puppyName: String
    ) -> [VerticalTimelineItem] {
        var items: [VerticalTimelineItem] = []

        // Track which event IDs are already included in sessions
        var processedEventIds: Set<UUID> = []

        // Build lookup dictionary for child events by parentWalkId - O(n) once instead of O(n) per walk
        let childEventsByWalkId: [UUID: [PuppyEvent]] = Dictionary(
            grouping: events.filter { $0.parentWalkId != nil },
            by: { $0.parentWalkId! }
        )

        // Build lookup dictionary for events by ID - O(1) lookup instead of O(n)
        let eventsById: [UUID: PuppyEvent] = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })

        // 1. Build sleep sessions
        let sleepSessions = SleepSession.buildSessions(from: events)
        for session in sleepSessions {
            processedEventIds.insert(session.startEventId)
            if let endId = session.endEventId {
                processedEventIds.insert(endId)
            }

            // Get photo from sleep event - O(1) lookup
            let sleepEvent = eventsById[session.startEventId]
            let photoThumbnail = sleepEvent?.thumbnailPath

            let description = sleepDescription(for: session, puppyName: puppyName)

            items.append(VerticalTimelineItem(
                id: session.id,
                type: .sleepSession(session),
                startTime: session.startTime,
                endTime: session.endTime,
                photoThumbnail: photoThumbnail,
                note: sleepEvent?.note,
                description: description,
                track: .activity  // Sleep sessions go on the left (activity) track
            ))
        }

        // 2. Process walk events (with duration as blocks) - use walk track
        let walks = events.filter { $0.type == .uitlaten }
        for walk in walks {
            processedEventIds.insert(walk.id)

            // Mark child potty events as processed - O(1) lookup instead of O(n) filter
            if let childEvents = childEventsByWalkId[walk.id] {
                for child in childEvents {
                    processedEventIds.insert(child.id)
                }
            }

            let durationMin = walk.durationMin ?? 20 // Default 20 minutes if not specified
            let endTime = walk.time.addingTimeInterval(Double(durationMin) * 60)

            let description = walkDescription(for: walk, childEventsByWalkId: childEventsByWalkId, puppyName: puppyName)

            items.append(VerticalTimelineItem(
                id: walk.id,
                type: .walkEvent(walk),
                startTime: walk.time,
                endTime: endTime,
                photoThumbnail: walk.thumbnailPath,
                note: walk.note,
                description: description,
                track: .activity  // Walks go on the left (activity) track
            ))
        }

        // 3. Build training sessions (groups of training events within 15 min)
        let trainingSessions = TrainingSession.buildSessions(from: events)
        for session in trainingSessions {
            // Mark all events in this session as processed
            for eventId in session.eventIds {
                processedEventIds.insert(eventId)
            }

            let description = trainingSessionDescription(for: session, puppyName: puppyName)

            items.append(VerticalTimelineItem(
                id: session.id,
                type: .trainingSession(session),
                startTime: session.startTime,
                endTime: nil,
                photoThumbnail: nil,
                note: nil,
                description: description,
                track: .main
            ))
        }

        // 4. Process remaining point events
        // Skip wake events (ontwaken) - they're legacy data from the old two-event sleep model
        for event in events where !processedEventIds.contains(event.id) && event.type != .ontwaken {
            let description = eventDescription(for: event, puppyName: puppyName)

            // Potty events (pee/poo) go on the right track, others on main
            let trackType: VerticalTimelineItem.TrackType = (event.type == .plassen || event.type == .poepen) ? .potty : .main

            items.append(VerticalTimelineItem(
                id: event.id,
                type: .pointEvent(event),
                startTime: event.time,
                endTime: nil,
                photoThumbnail: event.thumbnailPath,
                note: event.note,
                description: description,
                track: trackType
            ))
        }

        // 5. Add appointments
        for appointment in appointments {
            let description = appointmentDescription(for: appointment)

            items.append(VerticalTimelineItem(
                id: appointment.id,
                type: .appointmentItem(appointment),
                startTime: appointment.startDate,
                endTime: appointment.endDate,
                photoThumbnail: nil,
                note: appointment.notes,
                description: description,
                track: .main
            ))
        }

        // Sort by start time (newest first - future at top, past at bottom)
        return items.sorted { $0.startTime > $1.startTime }
    }

    // MARK: - Timeline Items (Unified)

    /// Build unified timeline items from events (for timeline display)
    /// Combines regular events with sleep sessions
    static func buildTimelineItems(from events: [PuppyEvent]) -> [TimelineItem] {
        // Build sleep sessions (O(n) with optimized lookup)
        let sessions = SleepSession.buildSessions(from: events)

        // Create a lookup dictionary for event IDs -> notes (O(1) lookup instead of O(n))
        let eventNotes: [UUID: String] = Dictionary(
            uniqueKeysWithValues: events.compactMap { event in
                guard let note = event.note else { return nil }
                return (event.id, note)
            }
        )

        // Get IDs of events that are part of sessions
        var sessionEventIds: Set<UUID> = []
        var sessionNotes: [UUID: String] = [:]

        for session in sessions {
            sessionEventIds.insert(session.startEventId)
            if let endId = session.endEventId {
                sessionEventIds.insert(endId)
            }
            // Get note from the sleep event using O(1) dictionary lookup
            if let note = eventNotes[session.startEventId] {
                sessionNotes[session.id] = note
            }
        }

        // Build timeline items
        var items: [TimelineItem] = []

        // Add non-sleep events (excluding weight events which belong on Health tab only)
        for event in events where !sessionEventIds.contains(event.id) && event.type != .gewicht {
            items.append(.event(event))
        }

        // Add sleep sessions
        for session in sessions {
            items.append(.sleepSession(session, note: sessionNotes[session.id]))
        }

        // Sort by time (oldest first for timeline display)
        return items.sorted { $0.sortTime < $1.sortTime }
    }

    // MARK: - Walk Concurrent Events

    /// Get set of event IDs that occurred during walks (for dual-track layout)
    static func walkConcurrentEventIds(from events: [PuppyEvent]) -> Set<UUID> {
        Set(events.compactMap { $0.parentWalkId != nil ? $0.id : nil })
    }

    // MARK: - Timeline Bounds

    /// Calculate timeline start time (6am or first event - 1 hour, whichever is earlier)
    static func verticalTimelineStartTime(events: [PuppyEvent], currentDate: Date) -> Date {
        let calendar = Calendar.current
        let dayStart = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: currentDate) ?? currentDate

        guard let firstEvent = events.min(by: { $0.time < $1.time }) else {
            return dayStart
        }

        let eventHour = calendar.component(.hour, from: firstEvent.time)
        if eventHour < 6 {
            // Event before 6am - start 1 hour before
            return calendar.date(bySettingHour: eventHour - 1, minute: 0, second: 0, of: currentDate) ?? dayStart
        }

        return dayStart
    }

    /// Calculate timeline end time (10pm or last event + 1 hour, whichever is later)
    static func verticalTimelineEndTime(events: [PuppyEvent], currentDate: Date, isShowingToday: Bool) -> Date {
        let calendar = Calendar.current
        let dayEnd = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: currentDate) ?? currentDate

        // For today, use current time if after 10pm
        if isShowingToday {
            let now = Date()
            let currentHour = calendar.component(.hour, from: now)
            if currentHour >= 22 {
                return calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            }
        }

        guard let lastEvent = events.max(by: { $0.time < $1.time }) else {
            return dayEnd
        }

        let eventTime = lastEvent.time
        let eventHour = calendar.component(.hour, from: eventTime)

        if eventHour >= 22 {
            // Event after 10pm - extend to event + 1 hour
            return calendar.date(byAdding: .hour, value: 1, to: eventTime) ?? dayEnd
        }

        return dayEnd
    }

    // MARK: - Natural Language Descriptions

    static func sleepDescription(for session: SleepSession, puppyName: String) -> String {
        let durationMin = session.durationMinutes

        if session.isOngoing {
            return Strings.VerticalTimeline.sleepingNow(name: puppyName)
        }

        // Night sleep (> 4 hours)
        if durationMin >= 240 {
            return Strings.VerticalTimeline.sleptThroughNight(name: puppyName)
        }

        // Short nap (< 15 min)
        if durationMin < 15 {
            return Strings.VerticalTimeline.tookShortNap(name: puppyName)
        }

        // Regular nap
        return Strings.VerticalTimeline.tookNap(name: puppyName)
    }

    static func walkDescription(for walk: PuppyEvent, childEventsByWalkId: [UUID: [PuppyEvent]], puppyName: String) -> String {
        // Check for child potty events using O(1) lookup
        let childPottyEvents = childEventsByWalkId[walk.id] ?? []
        let didPee = childPottyEvents.contains { $0.type == .plassen }
        let didPoop = childPottyEvents.contains { $0.type == .poepen }

        if didPee && didPoop {
            return Strings.VerticalTimeline.wentForWalkPeedPooped(name: puppyName)
        } else if didPee {
            return Strings.VerticalTimeline.wentForWalkPeed(name: puppyName)
        } else if didPoop {
            return Strings.VerticalTimeline.wentForWalkPooped(name: puppyName)
        }

        return Strings.VerticalTimeline.wentForWalk(name: puppyName)
    }

    static func eventDescription(for event: PuppyEvent, puppyName: String) -> String {
        switch event.type {
        case .plassen:
            if event.location == .buiten {
                return Strings.VerticalTimeline.peedOutside(name: puppyName)
            } else {
                return Strings.VerticalTimeline.hadAccidentPee(name: puppyName)
            }

        case .poepen:
            if event.location == .buiten {
                return Strings.VerticalTimeline.poopedOutside(name: puppyName)
            } else {
                return Strings.VerticalTimeline.hadAccidentPoop(name: puppyName)
            }

        case .eten:
            let mealName = mealNameForTime(event.time)
            return Strings.VerticalTimeline.hadMeal(name: puppyName, meal: mealName)

        case .drinken:
            return Strings.VerticalTimeline.hadWater(name: puppyName)

        case .training:
            if let exercise = event.exercise {
                return Strings.VerticalTimeline.trainedExercise(name: puppyName, exercise: exercise)
            }
            return Strings.VerticalTimeline.didTraining(name: puppyName)

        case .sociaal:
            if let who = event.who {
                return Strings.VerticalTimeline.metSomeone(name: puppyName, who: who)
            }
            return Strings.VerticalTimeline.socializing(name: puppyName)

        case .tuin:
            return Strings.VerticalTimeline.wentToGarden(name: puppyName)

        case .bench:
            return Strings.VerticalTimeline.wentToCrate(name: puppyName)

        case .milestone:
            return Strings.VerticalTimeline.achievedMilestone(name: puppyName)

        case .gedrag:
            return Strings.VerticalTimeline.behaviorNote(name: puppyName)

        case .gewicht:
            if let weight = event.weightKg {
                return Strings.VerticalTimeline.weighed(name: puppyName, weight: String(format: "%.1f", weight))
            }
            return Strings.VerticalTimeline.wasWeighed(name: puppyName)

        case .moment:
            return Strings.VerticalTimeline.capturedMoment(name: puppyName)

        case .medicatie:
            return Strings.VerticalTimeline.tookMedication(name: puppyName)

        case .coverageGap:
            if let gapType = event.gapType {
                return Strings.VerticalTimeline.wasWith(name: puppyName, caregiver: gapType.label)
            }
            return Strings.VerticalTimeline.wasWithCaregiver(name: puppyName)

        default:
            return event.type.label
        }
    }

    static func mealNameForTime(_ time: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)

        if hour < 10 {
            return Strings.VerticalTimeline.mealBreakfast
        } else if hour < 14 {
            return Strings.VerticalTimeline.mealLunch
        } else if hour < 18 {
            return Strings.VerticalTimeline.mealSnack
        } else {
            return Strings.VerticalTimeline.mealDinner
        }
    }

    static func appointmentDescription(for appointment: DogAppointment) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        let timeString = timeFormatter.string(from: appointment.startDate)

        return Strings.VerticalTimeline.scheduledFor(time: timeString)
    }

    static func trainingSessionDescription(for session: TrainingSession, puppyName: String) -> String {
        let skills = session.skillNames
        if skills.isEmpty {
            return Strings.VerticalTimeline.trainingSessionGeneric(name: puppyName, count: session.count)
        }
        let skillList = skills.joined(separator: ", ")
        return Strings.VerticalTimeline.trainingSessionWithSkills(name: puppyName, count: session.count, skills: skillList)
    }
}
