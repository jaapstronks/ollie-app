//
//  GroomingCareSection.swift
//  Otis-app
//
//  Grooming and care section for the Health tab
//

import SwiftUI
import OtisShared

/// Section showing grooming care status in the Health tab
struct GroomingCareSection: View {
    @EnvironmentObject private var routineStore: RoutineStore
    @EnvironmentObject private var profileStore: ProfileStore

    let onShowSchedule: () -> Void
    let onLogActivity: (GroomingType?) -> Void

    private var dueActivities: [GroomingActivity] {
        routineStore.dueGroomingActivities
    }

    private var overdueCount: Int {
        routineStore.overdueGroomingActivities.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with "See all" link
            HStack {
                InsightsSectionHeader(
                    title: Strings.Grooming.title,
                    icon: "comb.fill",
                    tint: .purple
                )

                Spacer()

                Button {
                    onShowSchedule()
                } label: {
                    Text(Strings.Common.seeAll)
                        .font(.subheadline)
                        .foregroundStyle(Color.otisAccent)
                }
            }

            // Content card
            groomingContent
        }
    }

    @ViewBuilder
    private var groomingContent: some View {
        if dueActivities.isEmpty {
            // All caught up state
            allCaughtUpCard
        } else {
            // Due activities card
            dueActivitiesCard
        }
    }

    @ViewBuilder
    private var allCaughtUpCard: some View {
        Button {
            onShowSchedule()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Grooming.allCaughtUp)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(Strings.Grooming.noDueActivities)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var dueActivitiesCard: some View {
        VStack(spacing: 0) {
            // Show up to 3 due activities
            ForEach(Array(dueActivities.prefix(3).enumerated()), id: \.element.id) { index, activity in
                GroomingActivityRow(
                    activity: activity,
                    onMarkComplete: {
                        routineStore.markGroomingCompleted(activity)
                    },
                    onTap: {
                        onLogActivity(activity.type)
                    }
                )

                if index < min(dueActivities.count, 3) - 1 {
                    Divider()
                        .padding(.horizontal)
                }
            }

            // Show more link if needed
            if dueActivities.count > 3 {
                Divider()
                    .padding(.horizontal)

                Button {
                    onShowSchedule()
                } label: {
                    HStack {
                        Text(Strings.Grooming.moreActivities(dueActivities.count - 3))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Grooming Activity Row

private struct GroomingActivityRow: View {
    let activity: GroomingActivity
    let onMarkComplete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(activity.isOverdue ? Color.orange.opacity(0.2) : Color.purple.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: activity.type.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(activity.isOverdue ? Color.orange : Color.purple)
                }

                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.type.label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(activity.statusLabel)
                        .font(.caption)
                        .foregroundStyle(activity.isOverdue ? .orange : .secondary)
                }

                Spacer()

                // Quick complete button
                Button {
                    HapticFeedback.success()
                    onMarkComplete()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            GroomingCareSection(
                onShowSchedule: {},
                onLogActivity: { _ in }
            )
            .environmentObject(RoutineStore())
            .environmentObject(ProfileStore())
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
