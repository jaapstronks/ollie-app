//
//  HealthTimelineView.swift
//  Ollie-app
//
//  Vertical timeline of health milestones (vaccinations, deworming, vet visits)

import SwiftUI
import OllieShared

/// Vertical timeline showing milestones with status indicators
struct HealthTimelineView: View {
    let milestones: [Milestone]
    let birthDate: Date
    let onToggle: (Milestone) -> Void

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showCompletionSheet = false
    @State private var selectedMilestone: Milestone?
    @State private var showAddSheet = false

    // MARK: - Grouped Milestones

    private var groupedMilestones: (nextUp: [Milestone], upcoming: [Milestone], completed: [Milestone]) {
        var nextUp: [Milestone] = []
        var upcoming: [Milestone] = []
        var completed: [Milestone] = []

        for milestone in milestones {
            let status = milestone.status(birthDate: birthDate)
            switch status {
            case .completed:
                completed.append(milestone)
            case .nextUp, .overdue:
                nextUp.append(milestone)
            case .upcoming:
                upcoming.append(milestone)
            }
        }

        // Sort by target date
        nextUp.sort { ($0.targetDate(birthDate: birthDate) ?? .distantFuture) < ($1.targetDate(birthDate: birthDate) ?? .distantFuture) }
        upcoming.sort { ($0.targetDate(birthDate: birthDate) ?? .distantFuture) < ($1.targetDate(birthDate: birthDate) ?? .distantFuture) }
        completed.sort { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }

        return (nextUp, upcoming, completed)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Add button (Ollie+ gated)
            HStack {
                SectionHeader(
                    title: Strings.Health.milestones,
                    icon: "heart.fill",
                    tint: .ollieDanger
                )

                Spacer()

                // Add button (premium)
                if subscriptionManager.hasAccess(to: .customMilestones) {
                    Button {
                        showAddSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text(Strings.Health.addMilestone)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.ollieAccent)
                    }
                }
            }

            // Next Up section
            if !groupedMilestones.nextUp.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Health.nextUp)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.ollieAccent)
                        .padding(.leading, 4)

                    ForEach(groupedMilestones.nextUp) { milestone in
                        MilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            isProminent: true
                        ) {
                            selectedMilestone = milestone
                            showCompletionSheet = true
                        }
                    }
                }
            }

            // Coming Up section
            if !groupedMilestones.upcoming.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Health.upcomingMilestones)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    ForEach(groupedMilestones.upcoming) { milestone in
                        MilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            isProminent: false
                        ) {
                            selectedMilestone = milestone
                            showCompletionSheet = true
                        }
                    }
                }
            }

            // Completed section (collapsible)
            if !groupedMilestones.completed.isEmpty {
                DisclosureGroup {
                    ForEach(groupedMilestones.completed) { milestone in
                        MilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            isProminent: false
                        ) {
                            // Toggle uncomplete
                            onToggle(milestone)
                        }
                    }
                } label: {
                    HStack {
                        Text(Strings.Health.completedMilestones)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(groupedMilestones.completed.count)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.leading, 4)
                }
                .tint(.secondary)
            }
        }
        .sheet(isPresented: $showCompletionSheet) {
            if let milestone = selectedMilestone {
                MilestoneCompletionSheet(
                    milestone: milestone,
                    isPresented: $showCompletionSheet,
                    onComplete: { notes, photoID, vetClinic, completionDate in
                        var updated = milestone
                        updated.isCompleted = true
                        updated.completedDate = completionDate
                        updated.completionNotes = notes
                        updated.completionPhotoID = photoID
                        updated.vetClinicName = vetClinic
                        onToggle(updated)
                    }
                )
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddMilestoneSheet(isPresented: $showAddSheet) { milestone in
                onToggle(milestone)
            }
        }
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let isProminent: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var status: MilestoneStatus {
        milestone.status(birthDate: birthDate)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                statusIndicator

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.localizedLabel)
                        .font(.subheadline)
                        .fontWeight(isProminent ? .semibold : .regular)
                        .foregroundStyle(textColor)
                        .strikethrough(status == .completed)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        if let period = milestone.periodLabel(birthDate: birthDate) {
                            Text(period)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let dateStr = milestone.formattedTargetDate(birthDate: birthDate) {
                            Text(dateStr)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Detail text
                    if let detail = milestone.localizedDetail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Completion indicator / days until
                trailingContent
            }
            .padding()
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(indicatorBackgroundColor)
                .frame(width: 32, height: 32)

            Image(systemName: indicatorIcon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(indicatorForegroundColor)
        }
    }

    @ViewBuilder
    private var trailingContent: some View {
        switch status {
        case .completed:
            if let date = milestone.completedDate {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        case .overdue:
            if let days = milestone.daysUntil(birthDate: birthDate) {
                Text(Strings.Health.daysOverdue(abs(days)))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ollieWarning)
            }
        case .nextUp:
            if let days = milestone.daysUntil(birthDate: birthDate) {
                if days == 0 {
                    Text(Strings.Health.today)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.ollieAccent)
                } else {
                    Text(Strings.Health.inDays(days))
                        .font(.caption)
                        .foregroundStyle(Color.ollieAccent)
                }
            }
        case .upcoming:
            if let days = milestone.daysUntil(birthDate: birthDate) {
                Text(Strings.Health.inDays(days))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Styling

    private var indicatorBackgroundColor: Color {
        switch status {
        case .completed: return .ollieSuccess
        case .nextUp: return .ollieAccent
        case .upcoming: return .secondary.opacity(0.2)
        case .overdue: return .ollieWarning
        }
    }

    private var indicatorForegroundColor: Color {
        switch status {
        case .completed, .nextUp, .overdue: return .white
        case .upcoming: return .secondary
        }
    }

    private var indicatorIcon: String {
        switch status {
        case .completed: return "checkmark"
        case .nextUp: return "arrow.right"
        case .upcoming: return "circle"
        case .overdue: return "exclamationmark"
        }
    }

    private var textColor: Color {
        switch status {
        case .completed: return .primary.opacity(0.5)
        case .nextUp: return .primary
        case .upcoming: return .secondary
        case .overdue: return .ollieWarning
        }
    }

    private var rowBackground: Color {
        switch status {
        case .nextUp:
            return colorScheme == .dark ? Color.ollieAccent.opacity(0.1) : Color.ollieAccent.opacity(0.05)
        case .overdue:
            return colorScheme == .dark ? Color.ollieWarning.opacity(0.1) : Color.ollieWarning.opacity(0.05)
        default:
            return .clear
        }
    }
}

// MARK: - Preview

#Preview {
    let milestones = DefaultMilestones.create()
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -10, to: Date())!

    return NavigationStack {
        ScrollView {
            HealthTimelineView(
                milestones: milestones,
                birthDate: birthDate,
                onToggle: { milestone in
                    print("Toggled: \(milestone.localizedLabel)")
                }
            )
            .padding()
        }
        .navigationTitle("Health")
    }
    .environmentObject(SubscriptionManager.shared)
}
