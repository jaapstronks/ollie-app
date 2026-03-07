//
//  AppointmentNudgeCalculations.swift
//  Ollie-app
//
//  Core logic for detecting when to show appointment scheduling nudges
//  Prompts users to schedule appointments for upcoming milestones (vaccinations, vet visits)
//

import Foundation
import OtisShared

// MARK: - Appointment Nudge Candidate

/// Represents a milestone that needs an appointment scheduled
struct AppointmentNudgeCandidate: Equatable {
    let milestone: Milestone
    let daysUntil: Int
    let isOverdue: Bool
    let appointmentType: AppointmentType

    /// Priority score for sorting (lower = higher priority)
    /// Overdue items come first, then by how soon they're due
    var priorityScore: Int {
        if isOverdue {
            return -1000 + daysUntil  // Most overdue = lowest score
        }
        return daysUntil  // Soonest upcoming = lowest score
    }
}

// MARK: - Calculations

enum AppointmentNudgeCalculations {

    // MARK: - Constants

    /// Show nudge for milestones within this many days
    static let nudgeWindowDays = 28

    /// Minimum days before milestone to start showing nudge
    static let minimumDaysBefore = 1

    /// Days to suppress nudge after dismissal
    static let dismissalCooldownDays = 7

    /// Window around milestone target date to check for existing appointments (±14 days)
    static let appointmentMatchWindowDays = 14

    // MARK: - Milestone to AppointmentType Mapping

    /// Maps milestone labelKeys to their corresponding appointment types
    /// Returns nil for milestones that don't need appointments
    static func appointmentType(for labelKey: String) -> AppointmentType? {
        switch labelKey {
        case "milestone.firstVaccination",
             "milestone.secondVaccination",
             "milestone.thirdVaccination",
             "milestone.yearlyVaccination":
            return .vetVaccination

        case "milestone.firstVetVisit",
             "milestone.neuteredDiscussion":
            return .vetCheckup

        default:
            return nil
        }
    }

    // MARK: - Top Nudge Candidate

    /// Find the most urgent milestone that needs an appointment scheduled
    /// - Parameters:
    ///   - milestones: All milestones
    ///   - appointments: All scheduled appointments
    ///   - birthDate: Puppy's birth date (for calculating target dates)
    ///   - dismissals: Dictionary of labelKey -> dismissal date
    /// - Returns: Most urgent nudge candidate, or nil if none needed
    static func topNudgeCandidate(
        milestones: [Milestone],
        appointments: [DogAppointment],
        birthDate: Date,
        dismissals: [String: Date]
    ) -> AppointmentNudgeCandidate? {
        let now = Date()
        let calendar = Calendar.current

        var candidates: [AppointmentNudgeCandidate] = []

        for milestone in milestones {
            // Skip completed milestones
            guard !milestone.isCompleted else { continue }

            // Skip milestones that don't map to appointment types
            guard let appointmentType = appointmentType(for: milestone.labelKey) else { continue }

            // Calculate days until milestone
            guard let targetDate = milestone.targetDate(birthDate: birthDate),
                  let daysUntil = milestone.daysUntil(birthDate: birthDate, from: now) else {
                continue
            }

            let isOverdue = daysUntil < 0

            // Check if within nudge window (1-28 days before, or overdue)
            if !isOverdue {
                guard daysUntil >= minimumDaysBefore && daysUntil <= nudgeWindowDays else {
                    continue
                }
            }

            // Check dismissal cooldown
            if let dismissedDate = dismissals[milestone.labelKey] {
                let daysSinceDismissal = calendar.dateComponents([.day], from: dismissedDate, to: now).day ?? 0
                if daysSinceDismissal < dismissalCooldownDays {
                    continue
                }
            }

            // Check if appointment already exists for this milestone type within ±14 days of target
            let hasAppointment = hasMatchingAppointment(
                appointmentType: appointmentType,
                targetDate: targetDate,
                appointments: appointments
            )
            guard !hasAppointment else { continue }

            candidates.append(AppointmentNudgeCandidate(
                milestone: milestone,
                daysUntil: daysUntil,
                isOverdue: isOverdue,
                appointmentType: appointmentType
            ))
        }

        // Sort by priority and return the top candidate
        return candidates.sorted { $0.priorityScore < $1.priorityScore }.first
    }

    // MARK: - Helpers

    /// Check if an appointment of the given type exists within ±14 days of the target date
    private static func hasMatchingAppointment(
        appointmentType: AppointmentType,
        targetDate: Date,
        appointments: [DogAppointment]
    ) -> Bool {
        let calendar = Calendar.current

        guard let windowStart = calendar.date(byAdding: .day, value: -appointmentMatchWindowDays, to: targetDate),
              let windowEnd = calendar.date(byAdding: .day, value: appointmentMatchWindowDays, to: targetDate) else {
            return false
        }

        return appointments.contains { appointment in
            appointment.appointmentType == appointmentType &&
            appointment.startDate >= windowStart &&
            appointment.startDate <= windowEnd &&
            !appointment.isCompleted
        }
    }

    // MARK: - Suggested Appointment Date

    /// Calculate a suggested appointment date for a milestone
    /// - Suggests 3 days before target date for vaccinations (buffer for any reactions)
    /// - Suggests 7 days before for vet visits (more flexibility)
    static func suggestedAppointmentDate(for candidate: AppointmentNudgeCandidate, birthDate: Date) -> Date? {
        guard let targetDate = candidate.milestone.targetDate(birthDate: birthDate) else {
            return nil
        }

        let calendar = Calendar.current
        let bufferDays: Int

        switch candidate.appointmentType {
        case .vetVaccination:
            bufferDays = -3  // 3 days before
        case .vetCheckup:
            bufferDays = -7  // 7 days before
        default:
            bufferDays = 0
        }

        // If overdue, suggest tomorrow
        if candidate.isOverdue {
            return calendar.date(byAdding: .day, value: 1, to: Date())
        }

        guard let suggestedDate = calendar.date(byAdding: .day, value: bufferDays, to: targetDate) else {
            return targetDate
        }

        // Don't suggest dates in the past
        if suggestedDate < Date() {
            return calendar.date(byAdding: .day, value: 1, to: Date())
        }

        return suggestedDate
    }
}
