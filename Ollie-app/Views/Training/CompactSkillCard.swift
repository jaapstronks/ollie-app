//
//  CompactSkillCard.swift
//  Otis-app
//
//  Simple row for skill in list - no inline expansion, taps open sheet
//

import SwiftUI

/// Compact skill row that opens detail sheet on tap
struct CompactSkillCard: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let isLocked: Bool
    let missingRequirements: [Skill]
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            guard !isLocked else { return }
            HapticFeedback.light()
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: skill.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isLocked ? Color.secondary.opacity(0.5) : Color.otisAccent)
                    .frame(width: 32)

                // Name and status
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(isLocked ? .secondary : .primary)

                    if isLocked {
                        // Show requirement
                        if !missingRequirements.isEmpty {
                            let names = missingRequirements.map { $0.name }.joined(separator: ", ")
                            Text(Strings.Training.Progression.masteredSkillsRequired(names))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } else {
                        // Status and session count
                        HStack(spacing: 6) {
                            statusBadge

                            if sessionCount > 0 {
                                Text("•")
                                    .foregroundStyle(.tertiary)
                                Text(Strings.Training.sessionCount(sessionCount))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                // Chevron or lock
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .glassStatusCard(tintColor: cardTintColor)
        .opacity(isLocked ? 0.6 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isLocked ? "" : Strings.Training.Progression.viewSkillDetails)
    }

    private var accessibilityLabel: String {
        if isLocked {
            let requiresNames = missingRequirements.map { $0.name }.joined(separator: ", ")
            return Strings.Training.Progression.skillLockedAccessibility(name: skill.name, requires: requiresNames)
        }
        return Strings.Training.Progression.skillStatusAccessibility(name: skill.name, status: status.label, sessions: sessionCount)
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(status.color)
    }

    // MARK: - Computed Properties

    private var cardTintColor: Color? {
        if isLocked {
            return nil
        }
        switch status {
        case .notStarted: return nil
        case .started: return Color.otisInfo
        case .practicing: return Color.otisWarning
        case .mastered: return Color.otisSuccess
        }
    }
}

// MARK: - Mastered Skill Card (simplified)

/// Even simpler card for mastered skills
struct MasteredSkillCard: View {
    let skill: Skill
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: skill.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.otisSuccess)
                    .frame(width: 28)

                Text(skill.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(Color.otisSuccess)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Training.Progression.skillStatusAccessibility(name: skill.name, status: Strings.Training.statusMastered, sessions: 0))
        .accessibilityHint(Strings.Training.Progression.viewSkillDetails)
    }
}

// MARK: - Locked Skill Card (simplified)

/// Simple locked skill indicator
struct LockedSkillRow: View {
    let skill: Skill
    let missingRequirements: [Skill]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: skill.icon)
                .font(.system(size: 16))
                .foregroundStyle(.tertiary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !missingRequirements.isEmpty {
                    let names = missingRequirements.map { $0.name }.joined(separator: ", ")
                    Text(Strings.Training.Progression.masteredSkillsRequired(names))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .opacity(0.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Training.Progression.skillLockedAccessibility(
            name: skill.name,
            requires: missingRequirements.map { $0.name }.joined(separator: ", ")
        ))
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
        VStack(spacing: 12) {
            CompactSkillCard(
                skill: previewSkill,
                status: .practicing,
                sessionCount: 5,
                isLocked: false,
                missingRequirements: [],
                onTap: {}
            )

            CompactSkillCard(
                skill: previewSkill,
                status: .notStarted,
                sessionCount: 0,
                isLocked: true,
                missingRequirements: [previewSkill],
                onTap: {}
            )

            MasteredSkillCard(skill: previewSkill, onTap: {})

            LockedSkillRow(skill: previewSkill, missingRequirements: [previewSkill])
        }
        .padding()
    }
}
