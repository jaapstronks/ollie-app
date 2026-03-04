//
//  NextUpCard.swift
//  Otis-app
//
//  Prominent card showing the next skill to learn in linear progression
//

import SwiftUI

/// Prominent card for the next skill in the training progression
struct NextUpCard: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let onStartTraining: () -> Void
    let onViewInfo: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Text(Strings.Training.Progression.nextUp)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                Spacer()

                // Session count badge
                if sessionCount > 0 {
                    Text(Strings.Training.sessionCount(sessionCount))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                        .accessibilityLabel(Strings.Training.sessionCount(sessionCount))
                }
            }

            // Skill info
            HStack(spacing: 16) {
                // Icon
                IconCircle(systemName: skill.icon)

                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    // Method and recommendation
                    HStack(spacing: 8) {
                        if let method = skill.method {
                            MethodBadge(method: method)
                        }

                        if let recommendation = skill.sessionRecommendation {
                            if skill.method != nil {
                                Text("•")
                                    .foregroundStyle(.tertiary)
                            }
                            Text(recommendation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }

            // Description
            Text(skill.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Action buttons
            HStack(spacing: 12) {
                // Info button
                Button {
                    HapticFeedback.light()
                    onViewInfo()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.Training.Progression.viewSkillDetails)

                // Start training button
                Button {
                    HapticFeedback.medium()
                    onStartTraining()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                        Text(sessionCount > 0 ? Strings.Training.Progression.continueTraining : Strings.Training.Progression.startTraining)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.otisAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .glassStatusCard(tintColor: Color.otisAccent)
    }
}

// MARK: - Preview

private let previewSkill = Skill(
    id: "clicker",
    icon: "bell.fill",
    category: .foundations,
    sortOrder: 1,
    requires: [],
    method: nil,
    durationMinutes: 3,
    sessionsPerDay: 3,
    steps: nil,
    phases: nil
)

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            NextUpCard(
                skill: previewSkill,
                status: .notStarted,
                sessionCount: 0,
                onStartTraining: {},
                onViewInfo: {}
            )

            NextUpCard(
                skill: previewSkill,
                status: .started,
                sessionCount: 3,
                onStartTraining: {},
                onViewInfo: {}
            )
        }
        .padding()
    }
}
