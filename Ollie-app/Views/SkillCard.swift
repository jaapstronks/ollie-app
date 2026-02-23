//
//  SkillCard.swift
//  Ollie-app
//
//  Card displaying a training skill with Start Training and Info buttons
//

import SwiftUI
import OllieShared

/// Card showing a training skill with quick actions
struct SkillCard: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let isLocked: Bool
    let missingRequirements: [Skill]
    let recentSessions: [PuppyEvent]
    let onStartTraining: () -> Void
    let onViewInfo: () -> Void
    let onToggleMastered: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: 12) {
                // Icon
                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isLocked ? .secondary : Color.ollieAccent)
                    .frame(width: 36)

                // Name, status, and last session
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(isLocked ? .secondary : .primary)

                    // Status or locked indicator
                    if isLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                            Text(Strings.Training.locked)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 6) {
                            // Status badge
                            statusBadge

                            // Session count
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

                // Action buttons (only if not locked)
                if !isLocked {
                    HStack(spacing: 8) {
                        // Info button
                        Button {
                            HapticFeedback.light()
                            onViewInfo()
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // Start training button
                        Button {
                            HapticFeedback.medium()
                            onStartTraining()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.ollieAccent)
                            .clipShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                } else {
                    // Lock icon for locked skills
                    Image(systemName: "lock.fill")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()

            // Last session info (if has sessions and not locked)
            if !isLocked && !recentSessions.isEmpty {
                lastSessionRow
            }
        }
        .glassStatusCard(tintColor: cardTintColor)
        .opacity(isLocked ? 0.6 : 1.0)
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

    // MARK: - Last Session Row

    @ViewBuilder
    private var lastSessionRow: some View {
        if let lastSession = recentSessions.first {
            VStack(spacing: 0) {
                Divider()
                    .padding(.horizontal)

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(Strings.TrainingSession.lastSession(date: lastSession.time.formatted(date: .abbreviated, time: .omitted)))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Mark mastered button (contextual)
                    if status == .practicing || status == .mastered {
                        Button {
                            HapticFeedback.medium()
                            onToggleMastered()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: status == .mastered ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.caption2)
                                Text(status == .mastered ? Strings.Training.unmarkMastered : Strings.Training.markMastered)
                                    .font(.caption2)
                            }
                            .foregroundStyle(status == .mastered ? Color.ollieSuccess : .secondary)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Computed Properties

    private var cardTintColor: Color? {
        if isLocked {
            return nil
        }
        switch status {
        case .notStarted: return nil
        case .started: return Color.ollieInfo
        case .practicing: return Color.ollieWarning
        case .mastered: return Color.ollieSuccess
        }
    }
}

// MARK: - Locked Skill Card

/// Simpler card for locked skills showing requirements
struct LockedSkillCard: View {
    let skill: Skill
    let missingRequirements: [Skill]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text(Strings.Training.locked)
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            }

            // Requirements
            if !missingRequirements.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.Training.requires)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    HStack(spacing: 8) {
                        ForEach(missingRequirements) { req in
                            HStack(spacing: 4) {
                                Image(systemName: req.icon)
                                    .font(.caption)
                                Text(req.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .glassStatusCard()
        .opacity(0.6)
    }
}

// MARK: - Scale Button Style

/// A button style that provides scale feedback without blocking scroll gestures
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

private let previewSkill = Skill(
    id: "sit",
    icon: "arrow.down.to.line",
    category: .basicCommands,
    week: 2,
    priority: 1,
    requires: ["luring"]
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
                onViewInfo: {},
                onToggleMastered: {}
            )

            SkillCard(
                skill: previewSkill,
                status: .notStarted,
                sessionCount: 0,
                isLocked: false,
                missingRequirements: [],
                recentSessions: [],
                onStartTraining: {},
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
                onViewInfo: {},
                onToggleMastered: {}
            )
        }
        .padding()
    }
}
