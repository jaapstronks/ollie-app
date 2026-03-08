//
//  AppointmentNudgeCard.swift
//  Otis-app
//
//  Contextual nudge card prompting users to schedule appointments for upcoming milestones
//  Shows on Today tab when vaccinations/vet visits are due soon
//

import SwiftUI
import OtisShared

/// Contextual nudge to schedule appointments for upcoming milestones
struct AppointmentNudgeCard: View {
    let candidate: AppointmentNudgeCandidate
    let puppyName: String
    let showNapContext: Bool
    let onSchedule: () -> Void
    let onAlreadyDone: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Tint color based on urgency
    private var tintColor: Color {
        if candidate.isOverdue {
            return .orange
        } else if candidate.daysUntil <= 7 {
            return .blue
        } else {
            return .blue.opacity(0.7)
        }
    }

    /// Icon for the appointment type
    private var icon: String {
        candidate.appointmentType.icon
    }

    /// Title text
    private var title: String {
        let milestoneName = candidate.milestone.localizedLabel
        if candidate.isOverdue {
            return Strings.AppointmentNudge.overdueTitle(milestone: milestoneName)
        } else {
            return Strings.AppointmentNudge.upcomingTitle(milestone: milestoneName)
        }
    }

    /// Subtitle text
    private var subtitle: String {
        let days = abs(candidate.daysUntil)
        if candidate.isOverdue {
            return Strings.AppointmentNudge.overdueSubtitle(days: days)
        } else if candidate.daysUntil <= 7 {
            return Strings.AppointmentNudge.soonSubtitle(days: days)
        } else {
            return Strings.AppointmentNudge.upcomingSubtitle(days: days)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Optional nap context header
            if showNapContext {
                HStack {
                    Text(Strings.AppointmentNudge.whilePuppyNaps(name: puppyName))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(tintColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(tintColor)
                }
                .accessibilityHidden(true)

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Action buttons - 3 options stacked vertically for clarity
            VStack(spacing: 8) {
                // Primary actions row
                HStack(spacing: 10) {
                    // Already done button (for when vaccination was already given)
                    Button {
                        onAlreadyDone()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                            Text(Strings.AppointmentNudge.alreadyDone)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.otisSuccess)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.otisSuccess.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        )
                    }

                    // Schedule button
                    Button {
                        onSchedule()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.caption)
                            Text(Strings.AppointmentNudge.scheduleNow)
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(tintColor)
                        )
                    }
                }

                // Remind later as secondary action
                Button {
                    onDismiss()
                } label: {
                    Text(Strings.AppointmentNudge.remindLater)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .glassStatusCard(tintColor: tintColor.opacity(0.15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

// MARK: - Preview

#Preview("Upcoming Vaccination") {
    let milestone = Milestone(
        category: .health,
        labelKey: "milestone.secondVaccination",
        targetAgeWeeks: 12,
        icon: "syringe.fill"
    )

    VStack(spacing: 16) {
        AppointmentNudgeCard(
            candidate: AppointmentNudgeCandidate(
                milestone: milestone,
                daysUntil: 5,
                isOverdue: false,
                appointmentType: .vetVaccination
            ),
            puppyName: "Ollie",
            showNapContext: true,
            onSchedule: { print("Schedule tapped") },
            onAlreadyDone: { print("Already done tapped") },
            onDismiss: { print("Dismissed") }
        )

        AppointmentNudgeCard(
            candidate: AppointmentNudgeCandidate(
                milestone: milestone,
                daysUntil: -3,
                isOverdue: true,
                appointmentType: .vetVaccination
            ),
            puppyName: "Ollie",
            showNapContext: false,
            onSchedule: { print("Schedule tapped") },
            onAlreadyDone: { print("Already done tapped") },
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
}
