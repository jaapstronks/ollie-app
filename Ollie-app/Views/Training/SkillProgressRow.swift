//
//  SkillProgressRow.swift
//  Otis-app
//
//  Unified row component showing skill status in the all-skills list
//

import SwiftUI
import OtisShared

/// Data structure for displaying a skill with its status
struct SkillProgressInfo: Identifiable {
    var id: String { skill.id }
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let isLocked: Bool
    let isNextUp: Bool
    let missingRequirements: [Skill]

    // MARK: - Enhanced Training Progress (optional, from SkillProgress)

    /// Current learning phase from smart training system (nil if not tracked yet)
    var learningPhase: SkillLearningPhase?

    /// Confidence score from recent sessions (0.0 - 1.0)
    var confidenceScore: Double?

    /// Whether this skill is due for a maintenance review
    var isDueForReview: Bool = false

    /// Days until next review (nil if not in maintenance)
    var daysUntilReview: Int?

    /// Whether this skill is in regression state (needs work)
    var isInRegression: Bool {
        learningPhase == .needsWork
    }

    // MARK: - Enhanced Progress Data (for visualization)

    /// Current proofing levels (Duration, Distance, Distraction)
    var proofingLevels: ProofingLevels?

    /// Contexts where skill has been practiced
    var practicedContexts: [TrainingContext] = []

    /// Current maintenance tier (1-6+) for spaced repetition
    var maintenanceTier: Int?

    /// Next scheduled review date
    var nextReviewDate: Date?

    /// Initialize with basic info only (for backwards compatibility)
    init(
        skill: Skill,
        status: SkillStatus,
        sessionCount: Int,
        isLocked: Bool,
        isNextUp: Bool,
        missingRequirements: [Skill]
    ) {
        self.skill = skill
        self.status = status
        self.sessionCount = sessionCount
        self.isLocked = isLocked
        self.isNextUp = isNextUp
        self.missingRequirements = missingRequirements
    }

    /// Initialize with full enhanced progress info
    init(
        skill: Skill,
        status: SkillStatus,
        sessionCount: Int,
        isLocked: Bool,
        isNextUp: Bool,
        missingRequirements: [Skill],
        learningPhase: SkillLearningPhase?,
        confidenceScore: Double?,
        isDueForReview: Bool,
        daysUntilReview: Int?
    ) {
        self.skill = skill
        self.status = status
        self.sessionCount = sessionCount
        self.isLocked = isLocked
        self.isNextUp = isNextUp
        self.missingRequirements = missingRequirements
        self.learningPhase = learningPhase
        self.confidenceScore = confidenceScore
        self.isDueForReview = isDueForReview
        self.daysUntilReview = daysUntilReview
    }

    /// Initialize with complete progress data including proofing and contexts
    init(
        skill: Skill,
        status: SkillStatus,
        sessionCount: Int,
        isLocked: Bool,
        isNextUp: Bool,
        missingRequirements: [Skill],
        learningPhase: SkillLearningPhase?,
        confidenceScore: Double?,
        isDueForReview: Bool,
        daysUntilReview: Int?,
        proofingLevels: ProofingLevels?,
        practicedContexts: [TrainingContext],
        maintenanceTier: Int?,
        nextReviewDate: Date?
    ) {
        self.skill = skill
        self.status = status
        self.sessionCount = sessionCount
        self.isLocked = isLocked
        self.isNextUp = isNextUp
        self.missingRequirements = missingRequirements
        self.learningPhase = learningPhase
        self.confidenceScore = confidenceScore
        self.isDueForReview = isDueForReview
        self.daysUntilReview = daysUntilReview
        self.proofingLevels = proofingLevels
        self.practicedContexts = practicedContexts
        self.maintenanceTier = maintenanceTier
        self.nextReviewDate = nextReviewDate
    }
}

/// Unified row for displaying any skill with its current status
struct SkillProgressRow: View {
    let info: SkillProgressInfo
    let onTap: () -> Void
    var onQuickDone: (() -> Void)?
    var onToggleMastered: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    // Track if "Next up" badge should display (hide immediately when mastered)
    private var showNextUpBadge: Bool {
        info.isNextUp && info.status != .mastered
    }

    // Track which priority badge to show
    private var priorityBadge: (label: String, color: Color)? {
        if info.isInRegression {
            return (Strings.Training.refresherNeeded, .otisDanger)
        }
        if info.isDueForReview {
            return (Strings.Training.dueForReview, .otisWarning)
        }
        if showNextUpBadge {
            return (Strings.Training.Progression.nextUp, .otisAccent)
        }
        return nil
    }

    // Whether confidence indicator is currently visible
    // Confidence only shows for phases where reliability matters (proofing+)
    private var isConfidenceVisible: Bool {
        guard let confidence = info.confidenceScore,
              let phase = info.learningPhase,
              !info.isLocked,
              info.status != .mastered else {
            return false
        }
        return phase.shouldShowConfidence && confidence > 0
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                statusIndicator

                // Icon
                Image(systemName: info.skill.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(info.isLocked ? .secondary : iconColor)
                    .frame(width: 28)

                // Name and details
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(info.skill.name)
                            .font(.body)
                            .fontWeight(priorityBadge != nil ? .semibold : .regular)
                            .foregroundStyle(info.isLocked ? .secondary : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)

                        // Priority badge (regression > due for review > next up)
                        if let badge = priorityBadge {
                            Text(badge.label)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badge.color)
                                .clipShape(Capsule())
                                .fixedSize()
                        }
                    }

                    // Subtitle based on status
                    subtitleView
                }

                Spacer(minLength: 8)

                // Confidence score - only show for phases where reliability matters
                // Early phases (luring, addingCue) are about learning the behavior, not reliability
                // Showing 100% confidence with 1 rep is misleading
                if let confidence = info.confidenceScore,
                   let phase = info.learningPhase,
                   !info.isLocked,
                   info.status != .mastered,
                   phase.shouldShowConfidence {
                    confidenceIndicator(confidence)
                }

                // Session count badge (if any sessions and not mastered, and confidence not visible)
                // Show session count when: no confidence score OR phase doesn't show confidence
                if info.sessionCount > 0 && !info.isLocked && info.status != .mastered && !isConfidenceVisible {
                    Text("\(info.sessionCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                }

                // Mastered checkmark (only for mastered skills)
                if info.status == .mastered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.otisSuccess)
                }

                // Chevron (only for non-mastered, unlocked skills)
                if !info.isLocked && info.status != .mastered {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(info.isLocked)
        .opacity(info.isLocked ? 0.6 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(rowBackground)
        )
        // Swipe actions for unlocked skills
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !info.isLocked, let onQuickDone = onQuickDone {
                Button {
                    onQuickDone()
                } label: {
                    Label(Strings.Training.quickDone, systemImage: "checkmark")
                }
                .tint(.otisAccent)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !info.isLocked, info.status != .mastered, let onToggleMastered = onToggleMastered {
                Button {
                    onToggleMastered()
                } label: {
                    Label(Strings.Training.markMastered, systemImage: "star.fill")
                }
                .tint(Color.otisSuccess)
            }
        }
    }

    // MARK: - Confidence Indicator

    @ViewBuilder
    private func confidenceIndicator(_ confidence: Double) -> some View {
        let percentage = Int(confidence * 100)
        let color: Color = confidence >= 0.8 ? .otisSuccess : (confidence >= 0.5 ? .otisWarning : .otisDanger)

        HStack(spacing: 4) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                    .frame(width: 20, height: 20)

                Circle()
                    .trim(from: 0, to: confidence)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 20, height: 20)
            }

            Text("\(percentage)%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 24, height: 24)

            Image(systemName: statusIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(statusColor)
        }
    }

    private var statusIcon: String {
        if info.isLocked {
            return "lock.fill"
        }
        // Use learning phase icon if available
        if let phase = info.learningPhase {
            return phase.icon
        }
        return info.status.statusIndicatorIcon
    }

    // phaseIcon and phaseColor are now available via SkillLearningPhase.icon and .color

    private var statusColor: Color {
        if info.isLocked {
            return .secondary
        }
        // Use learning phase color if available
        if let phase = info.learningPhase {
            return phase.color
        }
        return info.status.color
    }

    private var iconColor: Color {
        info.status.skillIconColor
    }

    // MARK: - Subtitle View

    @ViewBuilder
    private var subtitleView: some View {
        if info.isLocked {
            if !info.missingRequirements.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                    Text(Strings.Training.Progression.masteredSkillsRequired(info.missingRequirements.map { $0.name }.joined(separator: ", ")))
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
            }
        } else {
            HStack(spacing: 6) {
                // Show learning phase if available, otherwise fall back to simple status
                if let phase = info.learningPhase {
                    Text(phase.label)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                } else {
                    Text(info.status.label)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }

                if let method = info.skill.method {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    HStack(spacing: 3) {
                        Image(systemName: method.icon)
                            .font(.system(size: 9))
                        Text(method.label)
                            .font(.caption2)
                    }
                    .foregroundStyle(method == .operant ? Color.purple : Color.blue)
                }

                // Inline proofing indicator (compact 3-bar)
                if let levels = info.proofingLevels,
                   info.learningPhase == .proofing || info.learningPhase == .generalizing {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    InlineProofingIndicator(levels: levels)
                }

                // Context count for generalizing
                if !info.practicedContexts.isEmpty && info.learningPhase == .generalizing {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("\(info.practicedContexts.count) contexts")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Background

    private var rowBackground: Color {
        // Regression gets highest priority highlight
        if info.isInRegression {
            return colorScheme == .dark
                ? Color.otisDanger.opacity(0.15)
                : Color.otisDanger.opacity(0.08)
        }
        // Due for review gets warning highlight
        if info.isDueForReview {
            return colorScheme == .dark
                ? Color.otisWarning.opacity(0.12)
                : Color.otisWarning.opacity(0.06)
        }
        // Next up highlight
        if info.isNextUp {
            return colorScheme == .dark
                ? Color.otisAccent.opacity(0.15)
                : Color.otisAccent.opacity(0.08)
        }
        // Mastered highlight
        if info.status == .mastered || info.learningPhase == .maintaining {
            return colorScheme == .dark
                ? Color.otisSuccess.opacity(0.1)
                : Color.otisSuccess.opacity(0.05)
        }
        return .clear
    }
}


// MARK: - Preview

#Preview {
    let skill = Skill(
        id: "sit",
        icon: "arrow.down.to.line",
        category: .basicCommands,
        sortOrder: 7,
        requires: ["luring"],
        method: .classical,
        durationMinutes: 3,
        sessionsPerDay: 3,
        steps: nil,
        phases: nil
    )

    ScrollView {
        VStack(spacing: 8) {
            SkillProgressRow(
                info: SkillProgressInfo(
                    skill: skill,
                    status: .notStarted,
                    sessionCount: 0,
                    isLocked: false,
                    isNextUp: true,
                    missingRequirements: []
                ),
                onTap: {},
                onQuickDone: { print("Quick done!") }
            )

            SkillProgressRow(
                info: SkillProgressInfo(
                    skill: skill,
                    status: .practicing,
                    sessionCount: 5,
                    isLocked: false,
                    isNextUp: false,
                    missingRequirements: []
                ),
                onTap: {},
                onQuickDone: { print("Quick done!") },
                onToggleMastered: { print("Marked as mastered!") }
            )

            SkillProgressRow(
                info: SkillProgressInfo(
                    skill: skill,
                    status: .mastered,
                    sessionCount: 12,
                    isLocked: false,
                    isNextUp: false,
                    missingRequirements: []
                ),
                onTap: {}
            )

            SkillProgressRow(
                info: SkillProgressInfo(
                    skill: skill,
                    status: .notStarted,
                    sessionCount: 0,
                    isLocked: true,
                    isNextUp: false,
                    missingRequirements: [skill]
                ),
                onTap: {}
            )
        }
        .padding()
    }
}
