//
//  SkillDetailSheet.swift
//  Otis-app
//
//  Full sheet for viewing skill details and starting training
//

import SwiftUI
import OtisShared

/// Full detail sheet for a training skill
struct SkillDetailSheet: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let recentSessions: [PuppyEvent]
    let onStartTraining: () -> Void
    let onLogSession: () -> Void
    let onToggleMastered: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header card
                    SkillHeaderCard(
                        skill: skill,
                        status: status,
                        sessionCount: sessionCount
                    )

                    // Description
                    Text(skill.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // How to train
                    NumberedStepsSection(
                        title: Strings.Training.howTo,
                        icon: "list.number",
                        steps: skill.howTo
                    )

                    // Common mistakes (if available)
                    if !skill.mistakes.isEmpty {
                        BulletedListSection(
                            title: Strings.Training.commonMistakes,
                            headerIcon: "exclamationmark.triangle",
                            items: skill.mistakes,
                            bulletIcon: "xmark.circle.fill",
                            bulletColor: .red.opacity(0.8),
                            backgroundColor: .red.opacity(0.08)
                        )
                    }

                    // Done when
                    SingleItemSection(
                        title: Strings.Training.doneWhen,
                        headerIcon: "checkmark.circle",
                        text: skill.doneWhen,
                        bulletIcon: "checkmark.circle.fill",
                        bulletColor: .otisSuccess
                    )

                    // Tips
                    if !skill.tips.isEmpty {
                        BulletedListSection(
                            title: Strings.Training.tips,
                            headerIcon: "lightbulb",
                            items: skill.tips,
                            bulletIcon: "lightbulb.fill",
                            bulletColor: .otisWarning
                        )
                    }

                    // Recent sessions
                    if !recentSessions.isEmpty {
                        RecentSessionsSection(sessions: recentSessions)
                    }

                    // Action buttons
                    SkillActionButtons(
                        status: status,
                        onStartTraining: onStartTraining,
                        onLogSession: onLogSession,
                        onToggleMastered: onToggleMastered,
                        onDismiss: onDismiss
                    )
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle(skill.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        onDismiss()
                    }
                }
            }
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
    SkillDetailSheet(
        skill: previewSkill,
        status: .practicing,
        sessionCount: 6,
        recentSessions: [],
        onStartTraining: {},
        onLogSession: {},
        onToggleMastered: {},
        onDismiss: {}
    )
}
