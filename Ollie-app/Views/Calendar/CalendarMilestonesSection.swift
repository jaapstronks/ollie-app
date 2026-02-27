//
//  CalendarMilestonesSection.swift
//  Ollie-app
//
//  Milestones section for Calendar tab showing overdue and upcoming milestones

import SwiftUI
import OllieShared

/// Section displaying overdue and upcoming milestones
struct CalendarMilestonesSection: View {
    @ObservedObject var milestoneStore: MilestoneStore
    let birthDate: Date

    @State private var showMilestoneDetail = false
    @State private var selectedMilestone: Milestone?

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var overdueMilestones: [Milestone] {
        milestoneStore.overdueMilestones(birthDate: birthDate)
    }

    private var upcomingMilestones: [Milestone] {
        milestoneStore.upcomingMilestones(birthDate: birthDate, withinDays: 30)
            .prefix(5)
            .map { $0 }
    }

    private var hasAnyMilestones: Bool {
        !overdueMilestones.isEmpty || !upcomingMilestones.isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overdue milestones (if any)
            if !overdueMilestones.isEmpty {
                overdueMilestonesSection
            }

            // Upcoming milestones
            if !upcomingMilestones.isEmpty {
                upcomingMilestonesSection
            }

            // Empty state if no milestones
            if !hasAnyMilestones {
                emptyState
            }
        }
        // Milestone completion sheet
        .sheet(isPresented: $showMilestoneDetail) {
            if let milestone = selectedMilestone {
                MilestoneCompletionSheet(
                    milestone: milestone,
                    onDismiss: { showMilestoneDetail = false },
                    onComplete: { notes, photoID, vetClinic, completionDate in
                        milestoneStore.completeMilestone(
                            milestone,
                            notes: notes,
                            photoID: photoID,
                            vetClinicName: vetClinic,
                            completionDate: completionDate
                        )
                        showMilestoneDetail = false
                    }
                )
            }
        }
    }

    // MARK: - Overdue Milestones Section

    @ViewBuilder
    private var overdueMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: Strings.Calendar.overdueMilestones,
                icon: "exclamationmark.triangle.fill",
                tint: .ollieWarning
            )

            VStack(spacing: 8) {
                ForEach(overdueMilestones.prefix(3)) { milestone in
                    CalendarMilestoneRow(
                        milestone: milestone,
                        birthDate: birthDate,
                        isOverdue: true
                    ) {
                        selectedMilestone = milestone
                        showMilestoneDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Milestones Section

    @ViewBuilder
    private var upcomingMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(
                    title: Strings.Calendar.upcomingMilestones,
                    icon: "calendar.badge.clock",
                    tint: .ollieAccent
                )

                Spacer()

                // See all link
                NavigationLink {
                    HealthTimelineView(
                        milestones: milestoneStore.milestones,
                        birthDate: birthDate,
                        onToggle: { milestone in
                            milestoneStore.toggleMilestoneCompletion(milestone)
                        }
                    )
                    .navigationTitle(Strings.Health.milestones)
                } label: {
                    HStack(spacing: 4) {
                        Text(Strings.Common.seeAll)
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ollieAccent)
                }
            }

            VStack(spacing: 8) {
                ForEach(upcomingMilestones) { milestone in
                    CalendarMilestoneRow(
                        milestone: milestone,
                        birthDate: birthDate,
                        isOverdue: false
                    ) {
                        selectedMilestone = milestone
                        showMilestoneDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(Strings.Calendar.allMilestonesDone)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Milestone Row

struct CalendarMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let isOverdue: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isOverdue ? Color.ollieWarning : Color.ollieAccent)
                        .frame(width: 32, height: 32)

                    Image(systemName: milestone.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let period = milestone.periodLabel(birthDate: birthDate) {
                        Text(period)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Days indicator
                if let days = milestone.daysUntil(birthDate: birthDate) {
                    if days < 0 {
                        Text(Strings.Health.daysOverdue(abs(days)))
                            .font(.caption)
                            .foregroundStyle(Color.ollieWarning)
                    } else if days == 0 {
                        Text(Strings.Health.today)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.ollieAccent)
                    } else {
                        Text(Strings.Health.inDays(days))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                (isOverdue ? Color.ollieWarning : Color.ollieAccent)
                    .opacity(colorScheme == .dark ? 0.1 : 0.05)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            CalendarMilestonesSection(
                milestoneStore: MilestoneStore(),
                birthDate: Calendar.current.date(byAdding: .weekOfYear, value: -12, to: Date())!
            )
            .padding()
        }
    }
}
