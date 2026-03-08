//
//  GroomingCard.swift
//  Otis-app
//
//  Card showing due and overdue grooming activities
//

import SwiftUI
import OtisShared

/// Card showing grooming activities that are due or overdue
struct GroomingCard: View {
    let activities: [GroomingActivity]
    let onMarkComplete: (GroomingActivity) -> Void
    let onTap: () -> Void

    private var dueActivities: [GroomingActivity] {
        activities.due.sortedByUrgency()
    }

    private var overdueActivities: [GroomingActivity] {
        activities.overdue
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                if dueActivities.isEmpty {
                    allCaughtUpView
                } else {
                    // Show up to 3 due activities
                    ForEach(dueActivities.prefix(3)) { activity in
                        GroomingActivityRow(
                            activity: activity,
                            onMarkComplete: { onMarkComplete(activity) }
                        )

                        if activity.id != dueActivities.prefix(3).last?.id {
                            Divider()
                        }
                    }

                    // Show count if more
                    if dueActivities.count > 3 {
                        HStack {
                            Spacer()
                            Text("+\(dueActivities.count - 3) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var allCaughtUpView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Grooming.allCaughtUp)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(Strings.Grooming.noDueActivities)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Grooming Activity Row

private struct GroomingActivityRow: View {
    let activity: GroomingActivity
    let onMarkComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: activity.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(activity.isOverdue ? .red : .purple)
                .frame(width: 32, height: 32)
                .background(
                    (activity.isOverdue ? Color.red : Color.purple)
                        .opacity(0.1)
                )
                .clipShape(Circle())

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.type.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(activity.statusLabel)
                    .font(.caption)
                    .foregroundStyle(activity.isOverdue ? .red : .secondary)
            }

            Spacer()

            // Mark complete button
            Button(action: onMarkComplete) {
                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(.purple)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // With due activities
        GroomingCard(
            activities: [
                GroomingActivity(type: .nailTrim, lastCompleted: Date().addingTimeInterval(-25 * 24 * 60 * 60)),
                GroomingActivity(type: .brushing, lastCompleted: Date().addingTimeInterval(-5 * 24 * 60 * 60)),
                GroomingActivity(type: .earCleaning, lastCompleted: Date().addingTimeInterval(-16 * 24 * 60 * 60))
            ],
            onMarkComplete: { _ in },
            onTap: {}
        )

        // All caught up
        GroomingCard(
            activities: [
                GroomingActivity(type: .brushing, lastCompleted: Date())
            ],
            onMarkComplete: { _ in },
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
