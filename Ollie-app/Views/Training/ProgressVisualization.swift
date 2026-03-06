//
//  ProgressVisualization.swift
//  Ollie-app
//
//  Advanced visualization components for skill training progress.
//  Shows phase timeline, 3D proofing levels, and context badges.
//

import SwiftUI
import OtisShared

// MARK: - Phase Timeline

/// Horizontal timeline showing skill progression through learning phases
struct SkillPhaseTimeline: View {
    let currentPhase: SkillLearningPhase
    let isCompact: Bool

    @Environment(\.colorScheme) private var colorScheme

    private let phases: [SkillLearningPhase] = [
        .luring, .addingCue, .proofing, .generalizing, .maintaining
    ]

    var body: some View {
        HStack(spacing: isCompact ? 4 : 8) {
            ForEach(Array(phases.enumerated()), id: \.element) { index, phase in
                phaseNode(phase, index: index)

                if index < phases.count - 1 {
                    connector(from: phase)
                }
            }
        }
    }

    @ViewBuilder
    private func phaseNode(_ phase: SkillLearningPhase, index: Int) -> some View {
        let isActive = phase == currentPhase || (currentPhase == .needsWork && phase == .maintaining)
        let isCompleted = isPhasePast(phase)
        let isNeedsWork = currentPhase == .needsWork && phase == .maintaining

        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(nodeBackground(isActive: isActive, isCompleted: isCompleted, isNeedsWork: isNeedsWork))
                    .frame(width: isCompact ? 20 : 28, height: isCompact ? 20 : 28)

                if isNeedsWork {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: isCompact ? 9 : 12, weight: .bold))
                        .foregroundStyle(Color.otisDanger)
                } else if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: isCompact ? 9 : 12, weight: .bold))
                        .foregroundStyle(.white)
                } else if isActive {
                    Image(systemName: phaseIcon(phase))
                        .font(.system(size: isCompact ? 9 : 12, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: isCompact ? 9 : 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            if !isCompact {
                Text(phaseShortLabel(phase))
                    .font(.system(size: 9))
                    .foregroundStyle(isActive ? .primary : .secondary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    @ViewBuilder
    private func connector(from phase: SkillLearningPhase) -> some View {
        let isCompleted = isPhasePast(phase)
        Rectangle()
            .fill(isCompleted ? Color.otisSuccess : Color.secondary.opacity(0.3))
            .frame(width: isCompact ? 8 : 16, height: 2)
    }

    private func nodeBackground(isActive: Bool, isCompleted: Bool, isNeedsWork: Bool) -> Color {
        if isNeedsWork {
            return colorScheme == .dark ? Color.otisDanger.opacity(0.2) : Color.otisDanger.opacity(0.15)
        }
        if isCompleted {
            return Color.otisSuccess
        }
        if isActive {
            return Color.otisAccent
        }
        return colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }

    private func isPhasePast(_ phase: SkillLearningPhase) -> Bool {
        let phaseOrder: [SkillLearningPhase] = [.notStarted, .luring, .addingCue, .proofing, .generalizing, .maintaining]
        guard let currentIndex = phaseOrder.firstIndex(of: currentPhase),
              let phaseIndex = phaseOrder.firstIndex(of: phase) else {
            return false
        }
        // needsWork is special - it means maintaining has regressed
        if currentPhase == .needsWork {
            return phaseIndex < phaseOrder.firstIndex(of: .maintaining) ?? 0
        }
        return phaseIndex < currentIndex
    }

    private func phaseIcon(_ phase: SkillLearningPhase) -> String {
        switch phase {
        case .luring: return "hand.point.right.fill"
        case .addingCue: return "speaker.wave.2.fill"
        case .proofing: return "chart.bar.fill"
        case .generalizing: return "location.fill"
        case .maintaining: return "checkmark.seal.fill"
        default: return "circle"
        }
    }

    private func phaseShortLabel(_ phase: SkillLearningPhase) -> String {
        switch phase {
        case .luring: return "Lure"
        case .addingCue: return "Cue"
        case .proofing: return "Proof"
        case .generalizing: return "Gen."
        case .maintaining: return "Done"
        default: return ""
        }
    }
}

// MARK: - 3D Proofing Indicator

/// Visual bars showing Duration, Distance, Distraction levels (0-5)
struct Proofing3DIndicator: View {
    let levels: ProofingLevels
    let isCompact: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: isCompact ? 8 : 12) {
            dimensionBar(.duration, level: levels.duration)
            dimensionBar(.distance, level: levels.distance)
            dimensionBar(.distraction, level: levels.distraction)
        }
    }

    @ViewBuilder
    private func dimensionBar(_ dimension: ProofingDimension, level: Int) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < level ? dimensionColor(dimension) : Color.secondary.opacity(0.2))
                        .frame(width: isCompact ? 4 : 6, height: isCompact ? 12 : 16)
                }
            }

            if !isCompact {
                HStack(spacing: 2) {
                    Image(systemName: dimension.icon)
                        .font(.system(size: 8))
                    Text("\(level)")
                        .font(.system(size: 9, weight: .medium))
                        .monospacedDigit()
                }
                .foregroundStyle(level > 0 ? dimensionColor(dimension) : .secondary)
            }
        }
    }

    private func dimensionColor(_ dimension: ProofingDimension) -> Color {
        switch dimension {
        case .duration: return Color.otisInfo
        case .distance: return Color.otisPurple
        case .distraction: return Color.otisWarning
        }
    }
}

// MARK: - Context Badges

/// Compact icons showing where skill has been practiced
struct ContextBadges: View {
    let contexts: [TrainingContext]
    let maxVisible: Int

    @Environment(\.colorScheme) private var colorScheme

    init(contexts: [TrainingContext], maxVisible: Int = 5) {
        self.contexts = contexts.sorted { $0.lastSuccessAt > $1.lastSuccessAt }
        self.maxVisible = maxVisible
    }

    var body: some View {
        HStack(spacing: -4) {
            ForEach(Array(contexts.prefix(maxVisible).enumerated()), id: \.element.id) { index, context in
                contextBadge(context, zIndex: Double(maxVisible - index))
            }

            if contexts.count > maxVisible {
                overflowBadge
            }
        }
    }

    @ViewBuilder
    private func contextBadge(_ context: TrainingContext, zIndex: Double) -> some View {
        let standardContext = StandardTrainingContext(rawValue: context.id)
        let icon = standardContext?.icon ?? "mappin.circle.fill"
        let isSuccess = context.successRate >= 0.8

        ZStack {
            Circle()
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(isSuccess ? Color.otisSuccess : .secondary)
        }
        .zIndex(zIndex)
    }

    private var overflowBadge: some View {
        ZStack {
            Circle()
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

            Text("+\(contexts.count - maxVisible)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Maintenance Schedule Indicator

/// Shows next review date and maintenance tier
struct MaintenanceScheduleIndicator: View {
    let tier: Int
    let nextReviewDate: Date?
    let isCompact: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var daysUntilReview: Int? {
        guard let date = nextReviewDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    private var isOverdue: Bool {
        guard let days = daysUntilReview else { return false }
        return days < 0
    }

    private var isDueSoon: Bool {
        guard let days = daysUntilReview else { return false }
        return days >= 0 && days <= 1
    }

    var body: some View {
        HStack(spacing: isCompact ? 4 : 6) {
            // Tier badge
            tierBadge

            if !isCompact {
                // Next review info
                if let days = daysUntilReview {
                    reviewText(days)
                }
            }
        }
        .padding(.horizontal, isCompact ? 6 : 10)
        .padding(.vertical, isCompact ? 4 : 6)
        .background(badgeBackground)
        .clipShape(Capsule())
    }

    private var tierBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: isCompact ? 10 : 12))

            if !isCompact {
                Text(tierLabel)
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .foregroundStyle(statusColor)
    }

    @ViewBuilder
    private func reviewText(_ days: Int) -> some View {
        if isOverdue {
            Text(Strings.Training.dueForReview)
                .font(.caption2)
                .foregroundStyle(Color.otisDanger)
        } else if days == 0 {
            Text(Strings.Common.today)
                .font(.caption2)
                .foregroundStyle(Color.otisWarning)
        } else if days == 1 {
            Text(Strings.Common.tomorrow)
                .font(.caption2)
                .foregroundStyle(Color.otisWarning)
        } else {
            Text("\(days)d")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var tierLabel: String {
        switch tier {
        case 1: return "1d"
        case 2: return "3d"
        case 3: return "1w"
        case 4: return "2w"
        case 5: return "1m"
        default: return "2m+"
        }
    }

    private var statusColor: Color {
        if isOverdue { return Color.otisDanger }
        if isDueSoon { return Color.otisWarning }
        return Color.otisSuccess
    }

    private var badgeBackground: some View {
        Capsule()
            .fill(statusColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
    }
}

// MARK: - Combined Progress Card

/// Full progress visualization combining phase, 3Ds, and contexts
struct SkillProgressCard: View {
    let phase: SkillLearningPhase
    let proofingLevels: ProofingLevels?
    let contexts: [TrainingContext]
    let confidenceScore: Double?
    let maintenanceTier: Int?
    let nextReviewDate: Date?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Phase timeline
            SkillPhaseTimeline(currentPhase: phase, isCompact: false)

            Divider()

            // 3D progress (only show in proofing phase or later)
            if let levels = proofingLevels, shouldShow3Ds {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3Ds Progress")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Proofing3DIndicator(levels: levels, isCompact: false)
                }
            }

            // Contexts (only show in generalizing phase or later)
            if !contexts.isEmpty && shouldShowContexts {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Practiced in")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(contexts.filter { $0.successRate >= 0.8 }.count)/\(contexts.count) reliable")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    ContextBadges(contexts: contexts)
                }
            }

            // Maintenance schedule (only in maintaining phase)
            if let tier = maintenanceTier, phase == .maintaining || phase == .needsWork {
                MaintenanceScheduleIndicator(
                    tier: tier,
                    nextReviewDate: nextReviewDate,
                    isCompact: false
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
        )
    }

    private var shouldShow3Ds: Bool {
        switch phase {
        case .proofing, .generalizing, .maintaining, .needsWork:
            return true
        default:
            return false
        }
    }

    private var shouldShowContexts: Bool {
        switch phase {
        case .generalizing, .maintaining, .needsWork:
            return true
        default:
            return false
        }
    }
}

// MARK: - Inline Progress Summary

/// Compact inline summary for use in skill rows
struct InlineProgressSummary: View {
    let phase: SkillLearningPhase
    let proofingLevels: ProofingLevels?
    let contextCount: Int
    let confidenceScore: Double?

    var body: some View {
        HStack(spacing: 8) {
            // Phase indicator
            phaseIndicator

            // 3D mini-indicator (if in proofing)
            if let levels = proofingLevels, phase == .proofing {
                mini3DIndicator(levels)
            }

            // Context count (if generalizing)
            if phase == .generalizing && contextCount > 0 {
                contextIndicator
            }
        }
    }

    private var phaseIndicator: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(phaseColor)
                .frame(width: 6, height: 6)

            Text(phaseLabel)
                .font(.caption2)
                .foregroundStyle(phaseColor)
        }
    }

    @ViewBuilder
    private func mini3DIndicator(_ levels: ProofingLevels) -> some View {
        HStack(spacing: 2) {
            ForEach([levels.duration, levels.distance, levels.distraction], id: \.self) { level in
                Rectangle()
                    .fill(level > 0 ? Color.otisAccent : Color.secondary.opacity(0.3))
                    .frame(width: 3, height: CGFloat(4 + level * 2))
            }
        }
    }

    private var contextIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "location.fill")
                .font(.system(size: 8))
            Text("\(contextCount)")
                .font(.caption2)
        }
        .foregroundStyle(Color.otisSuccess)
    }

    private var phaseColor: Color {
        switch phase {
        case .notStarted: return .secondary
        case .luring: return Color.otisInfo
        case .addingCue: return Color.otisPurple
        case .proofing: return Color.otisAccent
        case .generalizing: return Color.otisSuccess.opacity(0.8)
        case .maintaining: return Color.otisSuccess
        case .needsWork: return Color.otisDanger
        }
    }

    private var phaseLabel: String {
        switch phase {
        case .notStarted: return "Not started"
        case .luring: return "Luring"
        case .addingCue: return "Adding cue"
        case .proofing: return "Proofing"
        case .generalizing: return "Generalizing"
        case .maintaining: return "Mastered"
        case .needsWork: return "Needs work"
        }
    }
}

// MARK: - Preview

#Preview("Phase Timeline") {
    VStack(spacing: 20) {
        ForEach(SkillLearningPhase.allCases, id: \.self) { phase in
            VStack(alignment: .leading) {
                Text(phase.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SkillPhaseTimeline(currentPhase: phase, isCompact: false)
            }
        }
    }
    .padding()
}

#Preview("3D Indicator") {
    VStack(spacing: 20) {
        Proofing3DIndicator(
            levels: ProofingLevels(duration: 3, distance: 2, distraction: 1),
            isCompact: false
        )

        Proofing3DIndicator(
            levels: ProofingLevels(duration: 5, distance: 4, distraction: 3),
            isCompact: true
        )
    }
    .padding()
}

#Preview("Context Badges") {
    ContextBadges(contexts: [
        TrainingContext(id: "home", lastSuccessAt: Date(), successRate: 0.9, totalReps: 50, successReps: 45),
        TrainingContext(id: "garden", lastSuccessAt: Date(), successRate: 0.85, totalReps: 30, successReps: 26),
        TrainingContext(id: "park", lastSuccessAt: Date(), successRate: 0.7, totalReps: 20, successReps: 14),
        TrainingContext(id: "busy_street", lastSuccessAt: Date(), successRate: 0.5, totalReps: 10, successReps: 5)
    ])
    .padding()
}

#Preview("Maintenance Indicator") {
    VStack(spacing: 12) {
        MaintenanceScheduleIndicator(tier: 3, nextReviewDate: Date().addingTimeInterval(86400 * 5), isCompact: false)
        MaintenanceScheduleIndicator(tier: 5, nextReviewDate: Date().addingTimeInterval(86400), isCompact: false)
        MaintenanceScheduleIndicator(tier: 2, nextReviewDate: Date().addingTimeInterval(-86400), isCompact: false)
    }
    .padding()
}

#Preview("Full Progress Card") {
    SkillProgressCard(
        phase: .proofing,
        proofingLevels: ProofingLevels(duration: 3, distance: 2, distraction: 1),
        contexts: [
            TrainingContext(id: "home", lastSuccessAt: Date(), successRate: 0.9, totalReps: 50, successReps: 45),
            TrainingContext(id: "garden", lastSuccessAt: Date(), successRate: 0.85, totalReps: 30, successReps: 26)
        ],
        confidenceScore: 0.82,
        maintenanceTier: nil,
        nextReviewDate: nil
    )
    .padding()
}
