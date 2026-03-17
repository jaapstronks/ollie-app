//
//  MaintenanceSkillsSection.swift
//  Ollie-app
//
//  Section showing skills in maintenance mode with refresh status
//  Designed for teenage+ dogs who have learned core skills
//

import SwiftUI
import OtisShared

/// Section showing skills in simplified maintenance mode
struct MaintenanceSkillsSection: View {
    var skillProgressStore: SkillProgressStore
    let trainingStore: TrainingPlanStore
    let onSkillTap: (Skill) -> Void
    let onRefresh: (Skill, SkillProgress) -> Void
    let onShowRefresher: (Skill) -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Skills in maintenance mode sorted by urgency
    private var maintenanceSkills: [(skill: Skill, progress: SkillProgress)] {
        let progressList = skillProgressStore.allProgress.filter { $0.isInMaintenanceMode }

        return progressList.compactMap { progress -> (Skill, SkillProgress)? in
            guard let skillInfo = trainingStore.allSkillsWithStatus.first(where: { $0.skill.id == progress.skillId }) else {
                return nil
            }
            return (skillInfo.skill, progress)
        }.sorted { lhs, rhs in
            // Sort by urgency: overdue first, then due, then practiced recently
            if lhs.1.isMaintenanceOverdue != rhs.1.isMaintenanceOverdue {
                return lhs.1.isMaintenanceOverdue
            }
            if lhs.1.needsMaintenanceRefresh != rhs.1.needsMaintenanceRefresh {
                return lhs.1.needsMaintenanceRefresh
            }
            // Sort by days since last practice (most recent last)
            let lhsDays = lhs.1.daysSinceLastPractice ?? Int.max
            let rhsDays = rhs.1.daysSinceLastPractice ?? Int.max
            return lhsDays > rhsDays
        }
    }

    /// Count of skills needing refresh
    private var dueCount: Int {
        maintenanceSkills.filter { $0.progress.needsMaintenanceRefresh || $0.progress.isMaintenanceOverdue }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label {
                    Text(Strings.Training.skillsInMaintenance)
                        .font(.headline)
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise")
                        .foregroundStyle(.indigo)
                }

                Spacer()

                if dueCount > 0 {
                    Text(Strings.Training.skillsDueBadge(dueCount))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange))
                }
            }

            if maintenanceSkills.isEmpty {
                // Empty state
                emptyState
            } else {
                // Skill cards
                VStack(spacing: 8) {
                    ForEach(maintenanceSkills, id: \.skill.id) { item in
                        MaintenanceSkillCard(
                            skill: item.skill,
                            progress: item.progress,
                            onRefresh: {
                                if item.progress.needsMaintenanceRefresh || item.progress.isMaintenanceOverdue {
                                    onShowRefresher(item.skill)
                                } else {
                                    onRefresh(item.skill, item.progress)
                                }
                            },
                            onTap: {
                                onSkillTap(item.skill)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(Strings.Training.noMaintenanceSkills)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(Strings.Training.noMaintenanceSkillsDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MaintenanceSkillsSection(
            skillProgressStore: SkillProgressStore(),
            trainingStore: TrainingPlanStore(),
            onSkillTap: { _ in },
            onRefresh: { _, _ in },
            onShowRefresher: { _ in }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
