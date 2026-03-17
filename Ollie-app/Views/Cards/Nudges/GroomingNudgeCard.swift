//
//  GroomingNudgeCard.swift
//  Otis-app
//
//  Contextual nudge card showing overdue or due soon grooming activities
//  Shows on Today tab when grooming tasks need attention
//

import SwiftUI
import OtisShared

/// Contextual nudge for overdue grooming activities
struct GroomingNudgeCard: View {
    let activities: [GroomingActivity]
    let puppyName: String
    let onMarkComplete: (GroomingActivity) -> Void
    let onDismiss: () -> Void
    let onViewAll: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Most urgent activity to highlight
    private var primaryActivity: GroomingActivity? {
        activities.sortedByUrgency().first
    }

    /// Additional activities to show
    private var additionalActivities: [GroomingActivity] {
        Array(activities.sortedByUrgency().dropFirst().prefix(2))
    }

    /// Tint color based on urgency
    private var tintColor: Color {
        guard let primary = primaryActivity else { return .blue }
        if primary.isOverdue {
            return .orange
        } else {
            return .blue
        }
    }

    /// Title text
    private var title: String {
        guard let primary = primaryActivity else { return "" }

        if primary.isOverdue {
            if activities.count > 1 {
                return Strings.GroomingNudge.multipleOverdueTitle(count: activities.count)
            } else {
                return Strings.GroomingNudge.overdueTitle(activity: primary.type.label)
            }
        } else {
            return Strings.GroomingNudge.dueTitle(activity: primary.type.label)
        }
    }

    /// Subtitle text
    private var subtitle: String {
        guard let primary = primaryActivity else { return "" }

        if primary.isOverdue, let days = primary.daysUntilDue {
            return Strings.GroomingNudge.overdueSubtitle(days: abs(days), name: puppyName)
        } else if let lastDone = primary.formattedLastCompleted {
            return Strings.GroomingNudge.lastDoneSubtitle(date: lastDone)
        } else {
            return Strings.GroomingNudge.neverDoneSubtitle
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Main content
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(tintColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: primaryActivity?.type.icon ?? "comb.fill")
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

                    // Show additional overdue items
                    if !additionalActivities.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(additionalActivities) { activity in
                                HStack(spacing: 4) {
                                    Image(systemName: activity.type.icon)
                                        .font(.caption2)
                                    Text(activity.type.label)
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer()
            }

            // Action buttons
            VStack(spacing: 8) {
                // Primary actions row
                HStack(spacing: 10) {
                    // Mark complete button
                    if let primary = primaryActivity {
                        Button {
                            HapticFeedback.success()
                            onMarkComplete(primary)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                Text(Strings.Grooming.markComplete)
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.otisSuccess)
                            )
                        }
                    }

                    // View all button (if multiple activities)
                    if activities.count > 1 {
                        Button {
                            onViewAll()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "list.bullet")
                                    .font(.caption)
                                Text(Strings.Common.seeAll)
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(tintColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(tintColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                            )
                        }
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

#Preview("Single Overdue") {
    let activity = GroomingActivity(
        type: .bathing,
        intervalDays: 30,
        lastCompleted: Calendar.current.date(byAdding: .day, value: -35, to: Date()),
        isEnabled: true
    )

    GroomingNudgeCard(
        activities: [activity],
        puppyName: "Ollie",
        onMarkComplete: { _ in print("Marked complete") },
        onDismiss: { print("Dismissed") },
        onViewAll: { print("View all") }
    )
    .padding()
}

#Preview("Multiple Overdue") {
    let activities = [
        GroomingActivity(
            type: .bathing,
            intervalDays: 30,
            lastCompleted: Calendar.current.date(byAdding: .day, value: -35, to: Date()),
            isEnabled: true
        ),
        GroomingActivity(
            type: .nailTrim,
            intervalDays: 21,
            lastCompleted: Calendar.current.date(byAdding: .day, value: -28, to: Date()),
            isEnabled: true
        ),
        GroomingActivity(
            type: .earCleaning,
            intervalDays: 14,
            lastCompleted: Calendar.current.date(byAdding: .day, value: -20, to: Date()),
            isEnabled: true
        )
    ]

    GroomingNudgeCard(
        activities: activities,
        puppyName: "Ollie",
        onMarkComplete: { _ in print("Marked complete") },
        onDismiss: { print("Dismissed") },
        onViewAll: { print("View all") }
    )
    .padding()
}
