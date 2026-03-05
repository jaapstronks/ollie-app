//
//  MedicalCareSheet.swift
//  Otis-app
//
//  Comprehensive sheet for medical care - single source of truth for health milestones
//

import SwiftUI
import OtisShared

/// Comprehensive sheet showing medical care timeline, upcoming and overdue items
struct MedicalCareSheet: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var milestoneStore: MilestoneStore
    @EnvironmentObject var weightStore: WeightStore

    var onNavigateToDevelopment: (() -> Void)?
    var onSelectMilestone: ((Milestone) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showCompletedSection = false

    private var profile: PuppyProfile? {
        profileStore.profile
    }

    private var birthDate: Date {
        profile?.birthDate ?? Date()
    }

    private var healthMilestones: [Milestone] {
        milestoneStore.milestones(for: .health)
    }

    // Overdue milestones (past target date, not completed)
    private var overdueMilestones: [Milestone] {
        let today = Date()

        return healthMilestones.filter { milestone in
            guard !milestone.isCompleted else { return false }
            guard let targetDate = milestone.targetDate(birthDate: birthDate) else { return false }
            return targetDate < today
        }.sorted { m1, m2 in
            let date1 = m1.targetDate(birthDate: birthDate) ?? .distantFuture
            let date2 = m2.targetDate(birthDate: birthDate) ?? .distantFuture
            return date1 < date2
        }
    }

    // Due soon milestones (next 14 days)
    private var dueSoonMilestones: [Milestone] {
        let today = Date()
        let calendar = Calendar.current
        let twoWeeksFromNow = calendar.date(byAdding: .day, value: 14, to: today)!

        return healthMilestones.filter { milestone in
            guard !milestone.isCompleted else { return false }
            guard let targetDate = milestone.targetDate(birthDate: birthDate) else { return false }
            return targetDate >= today && targetDate <= twoWeeksFromNow
        }.sorted { m1, m2 in
            let date1 = m1.targetDate(birthDate: birthDate) ?? .distantFuture
            let date2 = m2.targetDate(birthDate: birthDate) ?? .distantFuture
            return date1 < date2
        }
    }

    // Upcoming milestones (next 90 days, excluding due soon)
    private var upcomingMilestones: [Milestone] {
        let today = Date()
        let calendar = Calendar.current
        let twoWeeksFromNow = calendar.date(byAdding: .day, value: 14, to: today)!
        let threeMonthsFromNow = calendar.date(byAdding: .day, value: 90, to: today)!

        return healthMilestones.filter { milestone in
            guard !milestone.isCompleted else { return false }
            guard let targetDate = milestone.targetDate(birthDate: birthDate) else { return false }
            return targetDate > twoWeeksFromNow && targetDate <= threeMonthsFromNow
        }.sorted { m1, m2 in
            let date1 = m1.targetDate(birthDate: birthDate) ?? .distantFuture
            let date2 = m2.targetDate(birthDate: birthDate) ?? .distantFuture
            return date1 < date2
        }
    }

    // Completed milestones (most recent first)
    private var completedMilestones: [Milestone] {
        healthMilestones.filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero header with puppy name
                    heroHeader

                    // Action needed section (overdue + due soon)
                    if !overdueMilestones.isEmpty || !dueSoonMilestones.isEmpty {
                        actionNeededSection
                    }

                    // Upcoming milestones
                    if !upcomingMilestones.isEmpty {
                        upcomingSection
                    }

                    // Completed milestones (collapsible)
                    if !completedMilestones.isEmpty {
                        completedSection
                    }

                    // Weight summary (compact)
                    weightSummarySection

                    // Cross-links
                    crossLinksSection
                }
                .padding()
            }
            .navigationTitle(Strings.Health.medicalTimeline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Hero Header

    @ViewBuilder
    private var heroHeader: some View {
        VStack(spacing: 16) {
            // Health icon
            ZStack {
                Circle()
                    .fill(Color.otisHealth.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "cross.case.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.otisHealth)
            }

            // Puppy name and status
            VStack(spacing: 4) {
                if let name = profile?.name {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // Status summary
                if !overdueMilestones.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("\(overdueMilestones.count) overdue")
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.otisWarning)
                } else if !dueSoonMilestones.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("\(dueSoonMilestones.count) due soon")
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.otisAccent)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text(Strings.Health.upcomingMilestones)
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.otisSuccess)
                }
            }

            // Progress stats
            HStack(spacing: 24) {
                progressStat(
                    value: "\(completedMilestones.count)",
                    label: Strings.Health.completedMilestones,
                    color: .otisSuccess
                )

                progressStat(
                    value: "\(healthMilestones.count - completedMilestones.count)",
                    label: Strings.Health.upcomingMilestones,
                    color: .otisHealth
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.otisHealth.opacity(colorScheme == .dark ? 0.1 : 0.05))
        )
    }

    @ViewBuilder
    private func progressStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Action Needed Section

    @ViewBuilder
    private var actionNeededSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color.otisWarning)
                Text(Strings.Health.nextUp)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 8) {
                // Overdue items (red)
                ForEach(overdueMilestones) { milestone in
                    MedicalMilestoneRow(
                        milestone: milestone,
                        birthDate: birthDate,
                        style: .overdue,
                        onTap: {
                            if let onSelect = onSelectMilestone {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onSelect(milestone)
                                }
                            }
                        }
                    )
                }

                // Due soon items (orange)
                ForEach(dueSoonMilestones) { milestone in
                    MedicalMilestoneRow(
                        milestone: milestone,
                        birthDate: birthDate,
                        style: .dueSoon,
                        onTap: {
                            if let onSelect = onSelectMilestone {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onSelect(milestone)
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Upcoming Section

    @ViewBuilder
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Health.upcomingMilestones)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(upcomingMilestones.prefix(5)) { milestone in
                    MedicalMilestoneRow(
                        milestone: milestone,
                        birthDate: birthDate,
                        style: .upcoming,
                        onTap: {
                            if let onSelect = onSelectMilestone {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onSelect(milestone)
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Completed Section

    @ViewBuilder
    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showCompletedSection.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.otisSuccess)
                    Text(Strings.Health.completedMilestones)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(completedMilestones.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Image(systemName: showCompletedSection ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showCompletedSection {
                VStack(spacing: 8) {
                    ForEach(completedMilestones.prefix(10)) { milestone in
                        MedicalMilestoneRow(
                            milestone: milestone,
                            birthDate: birthDate,
                            style: .completed,
                            onTap: nil
                        )
                    }
                }
            }
        }
    }

    // MARK: - Weight Summary Section

    @ViewBuilder
    private var weightSummarySection: some View {
        if let latest = weightStore.latestWeight {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Health.weight)
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 16) {
                    // Weight icon
                    ZStack {
                        Circle()
                            .fill(Color.otisPurple.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.otisPurple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f kg", latest.weight))
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Delta if available
                    if let delta = weightStore.weightDelta {
                        let sign = delta.delta >= 0 ? "+" : ""
                        VStack(alignment: .trailing) {
                            Text("\(sign)\(String(format: "%.1f", delta.delta)) kg")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(delta.delta >= 0 ? Color.otisSuccess : Color.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Cross-links Section

    @ViewBuilder
    private var crossLinksSection: some View {
        if let onNavigate = onNavigateToDevelopment {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Common.seeAlso)
                    .font(.headline)
                    .fontWeight(.semibold)

                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onNavigate()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.otisPurple.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.otisPurple)
                        }

                        Text(Strings.Development.roadmapTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Medical Milestone Row

private struct MedicalMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let style: RowStyle
    let onTap: (() -> Void)?

    enum RowStyle {
        case overdue
        case dueSoon
        case upcoming
        case completed
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 36, height: 36)

                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(iconColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.localizedLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(style == .completed ? .secondary : .primary)
                        .strikethrough(style == .completed)

                    if style == .completed, let completedDate = milestone.completedDate {
                        Text(completedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else if let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
                        Text(periodLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Timing badge
                if style != .completed {
                    if let days = milestone.daysUntil(birthDate: birthDate) {
                        timingBadge(days: days)
                    }
                }

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    @ViewBuilder
    private func timingBadge(days: Int) -> some View {
        if days < 0 {
            Text(Strings.Health.daysOverdue(abs(days)))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.otisWarning)
                .clipShape(Capsule())
        } else if days == 0 {
            Text(Strings.Health.today)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.otisHealth)
                .clipShape(Capsule())
        } else if days <= 7 {
            Text(Strings.Health.inDays(days))
                .font(.caption)
                .foregroundStyle(Color.otisAccent)
        } else {
            Text(Strings.Health.inDays(days))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var iconName: String {
        switch style {
        case .overdue: return "exclamationmark"
        case .dueSoon: return "clock.fill"
        case .upcoming: return milestone.icon
        case .completed: return "checkmark"
        }
    }

    private var iconColor: Color {
        switch style {
        case .overdue: return .otisWarning
        case .dueSoon: return .otisAccent
        case .upcoming: return .otisHealth
        case .completed: return .otisSuccess
        }
    }

    private var iconBackgroundColor: Color {
        iconColor.opacity(0.2)
    }

    private var backgroundColor: Color {
        switch style {
        case .overdue: return Color.otisWarning.opacity(0.1)
        case .dueSoon: return Color.otisAccent.opacity(0.1)
        case .upcoming, .completed: return Color(.secondarySystemGroupedBackground)
        }
    }
}

// MARK: - Preview

#Preview {
    MedicalCareSheet(
        onNavigateToDevelopment: { print("Navigate to development") },
        onSelectMilestone: { milestone in print("Selected: \(milestone.labelKey)") }
    )
    .environmentObject(ProfileStore())
    .environmentObject(MilestoneStore())
    .environmentObject(WeightStore())
}
