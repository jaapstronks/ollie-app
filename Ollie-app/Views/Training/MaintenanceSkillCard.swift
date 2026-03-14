//
//  MaintenanceSkillCard.swift
//  Ollie-app
//
//  Simplified card for skills in maintenance mode
//  Shows last practiced date and refresh action
//

import SwiftUI
import OtisShared

/// Card for a skill in maintenance mode showing status and refresh action
struct MaintenanceSkillCard: View {
    let skill: Skill
    let progress: SkillProgress
    let onRefresh: () -> Void
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var daysSinceLastPractice: Int? {
        progress.daysSinceLastPractice
    }

    private var statusText: String {
        guard let days = daysSinceLastPractice else {
            return Strings.Training.neverPracticed
        }
        if days == 0 {
            return Strings.Training.practicedToday
        }
        return Strings.Training.daysAgo(days)
    }

    private var needsRefresh: Bool {
        progress.needsMaintenanceRefresh
    }

    private var isOverdue: Bool {
        progress.isMaintenanceOverdue
    }

    private var statusColor: Color {
        if isOverdue {
            return .orange
        } else if needsRefresh {
            return .yellow
        }
        return .otisSuccess
    }

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        HStack(spacing: 12) {
            skillIcon
            skillInfo
            Spacer()
            actionButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(cardBackground)
        .overlay(cardBorder)
    }

    private var skillIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: skill.icon)
                .font(.system(size: 18))
                .foregroundStyle(statusColor)
        }
    }

    private var skillInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(skill.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            statusBadges
        }
    }

    private var statusBadges: some View {
        HStack(spacing: 6) {
            if isOverdue {
                Text(Strings.Training.refreshOverdue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
            } else if needsRefresh {
                Text(Strings.Training.refreshDue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.yellow)
            }

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if needsRefresh || isOverdue {
            refreshButton
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.otisSuccess)
        }
    }

    private var refreshButton: some View {
        Button {
            HapticFeedback.light()
            onRefresh()
        } label: {
            Text(Strings.Training.refreshNow)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(refreshButtonBackground)
        }
        .buttonStyle(.plain)
    }

    private var refreshButtonBackground: some View {
        Capsule()
            .fill(isOverdue ? Color.orange : Color.otisAccent)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(borderColor, lineWidth: 1)
    }

    private var borderColor: Color {
        if isOverdue {
            return Color.orange.opacity(0.3)
        } else if needsRefresh {
            return Color.yellow.opacity(0.3)
        }
        return Color.clear
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        MaintenanceSkillCard(
            skill: Skill(
                id: "sit",
                icon: "arrow.down.to.line",
                category: .basicCommands,
                sortOrder: 1,
                requires: [],
                method: .classical,
                durationMinutes: 3,
                sessionsPerDay: 3,
                steps: nil,
                phases: nil
            ),
            progress: SkillProgress(
                skillId: "sit",
                phase: .maintaining,
                lastPracticedAt: Date().addingTimeInterval(-3 * 24 * 60 * 60),
                isInMaintenanceMode: true
            ),
            onRefresh: {},
            onTap: {}
        )

        MaintenanceSkillCard(
            skill: Skill(
                id: "come",
                icon: "figure.walk",
                category: .basicCommands,
                sortOrder: 2,
                requires: [],
                method: .classical,
                durationMinutes: 5,
                sessionsPerDay: 3,
                steps: nil,
                phases: nil
            ),
            progress: SkillProgress(
                skillId: "come",
                phase: .maintaining,
                lastPracticedAt: Date().addingTimeInterval(-10 * 24 * 60 * 60),
                isInMaintenanceMode: true
            ),
            onRefresh: {},
            onTap: {}
        )

        MaintenanceSkillCard(
            skill: Skill(
                id: "stay",
                icon: "hand.raised.fill",
                category: .basicCommands,
                sortOrder: 3,
                requires: [],
                method: .classical,
                durationMinutes: 3,
                sessionsPerDay: 3,
                steps: nil,
                phases: nil
            ),
            progress: SkillProgress(
                skillId: "stay",
                phase: .maintaining,
                lastPracticedAt: Date().addingTimeInterval(-18 * 24 * 60 * 60),
                isInMaintenanceMode: true
            ),
            onRefresh: {},
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
