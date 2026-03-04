//
//  SkillProgressRow.swift
//  Otis-app
//
//  Unified row component showing skill status in the all-skills list
//

import SwiftUI
import OtisShared

/// Data structure for displaying a skill with its status
struct SkillProgressInfo {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let isLocked: Bool
    let isNextUp: Bool
    let missingRequirements: [Skill]
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
                            .fontWeight(showNextUpBadge ? .semibold : .regular)
                            .foregroundStyle(info.isLocked ? .secondary : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)

                        if showNextUpBadge {
                            Text(Strings.Training.Progression.nextUp)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.otisAccent)
                                .clipShape(Capsule())
                                .fixedSize()
                        }
                    }

                    // Subtitle based on status
                    subtitleView
                }

                Spacer(minLength: 8)

                // Session count badge (if any sessions and not mastered)
                if info.sessionCount > 0 && !info.isLocked && info.status != .mastered {
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
        info.isLocked ? "lock.fill" : info.status.statusIndicatorIcon
    }

    private var statusColor: Color {
        info.isLocked ? .secondary : info.status.color
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
                Text(info.status.label)
                    .font(.caption)
                    .foregroundStyle(statusColor)

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
            }
        }
    }

    // MARK: - Background

    private var rowBackground: Color {
        if info.isNextUp {
            return colorScheme == .dark
                ? Color.otisAccent.opacity(0.15)
                : Color.otisAccent.opacity(0.08)
        }
        if info.status == .mastered {
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
