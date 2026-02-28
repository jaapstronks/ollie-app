//
//  DevelopmentRoadmapView.swift
//  Ollie-app
//
//  Age-based vertical timeline showing the puppy's developmental journey

import SwiftUI
import OllieShared

/// Vertical timeline view showing the puppy's developmental journey
struct DevelopmentRoadmapView: View {
    let profile: PuppyProfile
    @ObservedObject var milestoneStore: MilestoneStore

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Progress header
                progressHeader
                    .padding(.bottom, 24)

                // Timeline
                VStack(spacing: 0) {
                    ForEach(DevelopmentStage.allCases) { stage in
                        StageSection(
                            stage: stage,
                            profile: profile,
                            milestones: milestonesFor(stage: stage),
                            isCurrentStage: currentStage == stage
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(Strings.Development.roadmapTitle)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Progress Header

    @ViewBuilder
    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Current stage badge
            Text(Strings.Development.currentStage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(currentStage.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(currentStage.color)

            Text(currentStage.ageRange)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Progress bar
            ProgressView(value: stageProgress, total: 1.0)
                .tint(currentStage.color)
                .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(currentStage.color.opacity(colorScheme == .dark ? 0.15 : 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Computed Properties

    private var currentStage: DevelopmentStage {
        DevelopmentStage.stage(for: profile.ageInWeeks)
    }

    private var stageProgress: Double {
        let weeks = profile.ageInWeeks
        let stage = currentStage

        let stageStart = stage.startWeek
        let stageEnd = stage.endWeek

        guard stageEnd > stageStart else { return 1.0 }

        let progress = Double(weeks - stageStart) / Double(stageEnd - stageStart)
        return min(max(progress, 0), 1.0)
    }

    private func milestonesFor(stage: DevelopmentStage) -> [Milestone] {
        milestoneStore.milestones.filter { milestone in
            guard let targetWeeks = milestone.targetAgeWeeks else {
                if let targetMonths = milestone.targetAgeMonths {
                    let targetWeeksApprox = targetMonths * 4
                    return targetWeeksApprox >= stage.startWeek && targetWeeksApprox <= stage.endWeek
                }
                return false
            }
            return targetWeeks >= stage.startWeek && targetWeeks <= stage.endWeek
        }.sorted { m1, m2 in
            let w1 = m1.targetAgeWeeks ?? (m1.targetAgeMonths ?? 0) * 4
            let w2 = m2.targetAgeWeeks ?? (m2.targetAgeMonths ?? 0) * 4
            return w1 < w2
        }
    }
}

// MARK: - Development Stage

enum DevelopmentStage: String, CaseIterable, Identifiable {
    case neonatal
    case transitional
    case socialization
    case juvenile
    case adolescent
    case adult

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neonatal: return Strings.Development.stageNeonatal
        case .transitional: return Strings.Development.stageTransitional
        case .socialization: return Strings.Development.stageSocialization
        case .juvenile: return Strings.Development.stageJuvenile
        case .adolescent: return Strings.Development.stageAdolescent
        case .adult: return Strings.Development.stageAdult
        }
    }

    var ageRange: String {
        switch self {
        case .neonatal: return Strings.Development.stageNeonatalDesc
        case .transitional: return Strings.Development.stageTransitionalDesc
        case .socialization: return Strings.Development.stageSocializationDesc
        case .juvenile: return Strings.Development.stageJuvenileDesc
        case .adolescent: return Strings.Development.stageAdolescentDesc
        case .adult: return Strings.Development.stageAdultDesc
        }
    }

    var startWeek: Int {
        switch self {
        case .neonatal: return 0
        case .transitional: return 2
        case .socialization: return 3
        case .juvenile: return 16
        case .adolescent: return 26
        case .adult: return 78
        }
    }

    var endWeek: Int {
        switch self {
        case .neonatal: return 2
        case .transitional: return 3
        case .socialization: return 16
        case .juvenile: return 26
        case .adolescent: return 78
        case .adult: return 200
        }
    }

    var color: Color {
        switch self {
        case .neonatal: return .ollieSleep
        case .transitional: return .ollieInfo
        case .socialization: return .ollieAccent
        case .juvenile: return .ollieSuccess
        case .adolescent: return .ollieWarning
        case .adult: return .secondary
        }
    }

    var icon: String {
        switch self {
        case .neonatal: return "heart.fill"
        case .transitional: return "eye.fill"
        case .socialization: return "person.3.fill"
        case .juvenile: return "figure.walk"
        case .adolescent: return "figure.run"
        case .adult: return "pawprint.fill"
        }
    }

    static func stage(for weeks: Int) -> DevelopmentStage {
        switch weeks {
        case 0..<2: return .neonatal
        case 2..<3: return .transitional
        case 3..<16: return .socialization
        case 16..<26: return .juvenile
        case 26..<78: return .adolescent
        default: return .adult
        }
    }
}

// MARK: - Stage Section

private struct StageSection: View {
    let stage: DevelopmentStage
    let profile: PuppyProfile
    let milestones: [Milestone]
    let isCurrentStage: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line and marker
            VStack(spacing: 0) {
                // Connector line from above
                Rectangle()
                    .fill(lineColor)
                    .frame(width: 2, height: 20)

                // Stage marker
                ZStack {
                    Circle()
                        .fill(isCurrentStage ? stage.color : lineColor)
                        .frame(width: 24, height: 24)

                    if isCurrentStage {
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                    }
                }

                // Connector line to below
                Rectangle()
                    .fill(lineColor)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            // Stage content
            VStack(alignment: .leading, spacing: 8) {
                // Stage header
                HStack {
                    Image(systemName: stage.icon)
                        .font(.body)
                        .foregroundStyle(isCurrentStage ? stage.color : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.title)
                            .font(.headline)
                            .foregroundStyle(isCurrentStage ? .primary : .secondary)

                        Text(stage.ageRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isCurrentStage {
                        Text(Strings.Development.youAreHere)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(stage.color)
                            .clipShape(Capsule())
                    }
                }

                // Milestones in this stage
                if !milestones.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(milestones) { milestone in
                            StageMilestoneRow(
                                milestone: milestone,
                                birthDate: profile.birthDate,
                                isCurrentStage: isCurrentStage
                            )
                        }
                    }
                    .padding(.leading, 4)
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var lineColor: Color {
        isPastStage ? stage.color.opacity(0.5) : Color.secondary.opacity(0.3)
    }

    private var isPastStage: Bool {
        profile.ageInWeeks > stage.endWeek
    }
}

// MARK: - Stage Milestone Row

private struct StageMilestoneRow: View {
    let milestone: Milestone
    let birthDate: Date
    let isCurrentStage: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 24, height: 24)

                Image(systemName: statusIcon)
                    .font(.system(size: 10))
                    .foregroundStyle(statusColor)
            }

            // Milestone info
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.localizedLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(milestone.isCompleted ? .secondary : .primary)
                    .strikethrough(milestone.isCompleted)

                if let periodLabel = milestone.periodLabelWithDate(birthDate: birthDate) {
                    Text(periodLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            isCurrentStage && !milestone.isCompleted
                ? Color(.secondarySystemBackground)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusColor: Color {
        if milestone.isCompleted {
            return .ollieSuccess
        }
        let status = milestone.status(birthDate: birthDate)
        switch status {
        case .overdue: return .ollieWarning
        case .nextUp: return .ollieAccent
        default: return .secondary
        }
    }

    private var statusIcon: String {
        if milestone.isCompleted {
            return "checkmark"
        }
        let status = milestone.status(birthDate: birthDate)
        switch status {
        case .overdue: return "exclamationmark"
        case .nextUp: return "arrow.right"
        default: return "circle"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DevelopmentRoadmapView(
            profile: PuppyProfile.defaultProfile(
                name: "Luna",
                birthDate: Calendar.current.date(byAdding: .weekOfYear, value: -10, to: Date())!,
                homeDate: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())!,
                size: .medium
            ),
            milestoneStore: MilestoneStore()
        )
    }
}
