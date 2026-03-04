//
//  SkillCard.swift
//  Otis-app
//
//  Expandable card displaying a training skill with quick actions
//

import SwiftUI
import OtisShared

/// Card showing a training skill with expandable actions
struct SkillCard: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let isLocked: Bool
    let missingRequirements: [Skill]
    let recentSessions: [PuppyEvent]
    let onStartTraining: () -> Void
    let onQuickLog: () -> Void
    let onViewInfo: () -> Void
    let onToggleMastered: () -> Void

    @State private var isExpanded: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Main card header (tappable to expand)
            Button {
                guard !isLocked else { return }
                withAnimation(reduceMotion ? nil : TrainingAnimations.cardToggle) {
                    isExpanded.toggle()
                }
                HapticFeedback.light()
            } label: {
                cardHeader
            }
            .buttonStyle(.plain)
            .disabled(isLocked)

            // Expanded actions section
            if isExpanded && !isLocked {
                ExpandedSkillActions(
                    skill: skill,
                    status: status,
                    recentSessions: recentSessions,
                    onStartTraining: onStartTraining,
                    onQuickLog: onQuickLog,
                    onViewInfo: onViewInfo,
                    onToggleMastered: onToggleMastered
                )
            }
        }
        .glassStatusCard(tintColor: cardTintColor)
        .opacity(isLocked ? 0.6 : 1.0)
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        HStack(spacing: 12) {
            // Icon with optional recency badge
            SkillIconWithBadge(
                icon: skill.icon,
                isLocked: isLocked,
                recentSessions: recentSessions
            )

            // Name and status
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(isLocked ? .secondary : .primary)

                // Status or locked indicator
                if isLocked {
                    lockedIndicator
                } else {
                    statusRow
                }
            }

            Spacer()

            // Chevron or lock icon
            trailingIcon
        }
        .padding()
        .contentShape(Rectangle())
    }

    // MARK: - Status Row

    private var statusRow: some View {
        HStack(spacing: 6) {
            StatusBadge(status: status)

            if let method = skill.method {
                Text("•")
                    .foregroundStyle(.tertiary)
                MethodBadge(method: method, fontSize: .caption2)
            }

            if sessionCount > 0 {
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(Strings.Training.sessionCount(sessionCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Locked Indicator

    private var lockedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            Text(Strings.Training.locked)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Trailing Icon

    @ViewBuilder
    private var trailingIcon: some View {
        if !isLocked {
            Image(systemName: "chevron.down")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        } else {
            Image(systemName: "lock.fill")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Computed Properties

    private var cardTintColor: Color? {
        if isLocked { return nil }
        switch status {
        case .notStarted: return nil
        case .started: return Color.otisInfo
        case .practicing: return Color.otisWarning
        case .mastered: return Color.otisSuccess
        }
    }
}

// MARK: - Preview

private let previewSkill = Skill(
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

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SkillCard(
                skill: previewSkill,
                status: .practicing,
                sessionCount: 6,
                isLocked: false,
                missingRequirements: [],
                recentSessions: [
                    PuppyEvent(time: Date().addingTimeInterval(-86400), type: .training, exercise: "sit", durationMin: 5)
                ],
                onStartTraining: {},
                onQuickLog: {},
                onViewInfo: {},
                onToggleMastered: {}
            )

            SkillCard(
                skill: previewSkill,
                status: .started,
                sessionCount: 2,
                isLocked: false,
                missingRequirements: [],
                recentSessions: [
                    PuppyEvent(time: Date().addingTimeInterval(-86400 * 5), type: .training, exercise: "sit", durationMin: 3)
                ],
                onStartTraining: {},
                onQuickLog: {},
                onViewInfo: {},
                onToggleMastered: {}
            )

            SkillCard(
                skill: previewSkill,
                status: .notStarted,
                sessionCount: 0,
                isLocked: true,
                missingRequirements: [],
                recentSessions: [],
                onStartTraining: {},
                onQuickLog: {},
                onViewInfo: {},
                onToggleMastered: {}
            )
        }
        .padding()
    }
}
