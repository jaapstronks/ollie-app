//
//  SkillCard.swift
//  Ollie-app
//
//  Expandable card displaying a training skill and its progress
//

import SwiftUI

/// Expandable card showing a training skill with details
struct SkillCard: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let isLocked: Bool
    let missingRequirements: [Skill]
    let recentSessions: [PuppyEvent]
    let onLogSession: () -> Void
    let onToggleMastered: () -> Void

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header - always visible
            collapsedHeader

            // Expanded content
            if isExpanded && !isLocked {
                expandedContent
            }
        }
        .padding()
        .glassStatusCard(tintColor: cardTintColor)
        .opacity(isLocked ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    // MARK: - Collapsed Header

    @ViewBuilder
    private var collapsedHeader: some View {
        Button {
            if !isLocked {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Emoji
                Text(skill.emoji)
                    .font(.system(size: 28))
                    .frame(width: 36)

                // Name and status
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

                // Expand/collapse indicator or lock
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                } else {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
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

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.vertical, 8)

            // Description
            Text(skill.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // How to train
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Training.howTo)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(skill.howTo.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .frame(width: 20, alignment: .leading)
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Done when
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Training.doneWhen)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ollieSuccess)
                    Text(skill.doneWhen)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Tips
            if !skill.tips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Strings.Training.tips)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    ForEach(skill.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.ollieWarning)
                            Text(tip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Recent sessions
            if !recentSessions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Strings.Training.recentSessions)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    ForEach(recentSessions.prefix(3)) { session in
                        HStack(spacing: 8) {
                            Text(session.time.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let duration = session.durationMin {
                                Text("•")
                                    .foregroundStyle(.tertiary)
                                Text("\(duration) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let result = session.result, !result.isEmpty {
                                Text("•")
                                    .foregroundStyle(.tertiary)
                                Text(result)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                // Log session button
                Button {
                    HapticFeedback.selection()
                    onLogSession()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text(Strings.Training.logSession)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.ollieAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Mark mastered button
                Button {
                    HapticFeedback.medium()
                    onToggleMastered()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: status == .mastered ? "checkmark.circle.fill" : "checkmark.circle")
                        Text(status == .mastered ? Strings.Training.unmarkMastered : Strings.Training.markMastered)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(masterButtonBackground)
                    .foregroundStyle(status == .mastered ? .white : .ollieSuccess)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.ollieSuccess, lineWidth: status == .mastered ? 0 : 1)
                    )
                }
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

    @ViewBuilder
    private var masterButtonBackground: some View {
        if status == .mastered {
            Color.ollieSuccess
        } else {
            Color.ollieSuccess.opacity(colorScheme == .dark ? 0.15 : 0.1)
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
                Text(skill.emoji)
                    .font(.system(size: 28))
                    .frame(width: 36)
                    .grayscale(0.8)

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
                                Text(req.emoji)
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

// MARK: - Preview

#Preview {
    let skill = Skill(
        id: "zit",
        name: "Sit",
        emoji: "🐕",
        description: "The classic sit command. A building block for many other behaviors.",
        howTo: [
            "Hold treat above puppy's nose",
            "Move treat slowly back over their head",
            "Click and treat the moment bottom touches floor"
        ],
        doneWhen: "Your puppy sits on command with just the verbal cue.",
        tips: [
            "Don't push their bottom down",
            "Practice before meals for extra motivation"
        ],
        category: .basiscommandos,
        week: 2,
        priority: 1,
        requires: ["luring"]
    )

    return ScrollView {
        VStack(spacing: 16) {
            SkillCard(
                skill: skill,
                status: .practicing,
                sessionCount: 6,
                isLocked: false,
                missingRequirements: [],
                recentSessions: [],
                onLogSession: {},
                onToggleMastered: {}
            )

            SkillCard(
                skill: skill,
                status: .notStarted,
                sessionCount: 0,
                isLocked: true,
                missingRequirements: [],
                recentSessions: [],
                onLogSession: {},
                onToggleMastered: {}
            )
        }
        .padding()
    }
}
