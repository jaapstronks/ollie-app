//
//  ExpandedSkillActions.swift
//  Otis-app
//
//  Expanded actions section for skill cards
//

import SwiftUI
import OtisShared

// MARK: - Expanded Skill Actions

/// The expanded section of a skill card showing last session, mistakes, and action buttons
struct ExpandedSkillActions: View {
    let skill: Skill
    let status: SkillStatus
    let recentSessions: [PuppyEvent]
    let onStartTraining: () -> Void
    let onQuickLog: () -> Void
    let onViewInfo: () -> Void
    let onToggleMastered: () -> Void

    @State private var showMistakes: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal)

            // Last session info
            if let lastSession = recentSessions.first {
                lastSessionRow(lastSession)
                Divider()
                    .padding(.horizontal)
            }

            // Session recommendation (if available)
            if let recommendation = skill.sessionRecommendation {
                recommendationRow(recommendation)
                Divider()
                    .padding(.horizontal)
            }

            // Common mistakes section (if available)
            if !skill.mistakes.isEmpty {
                mistakesSection
                Divider()
                    .padding(.horizontal)
            }

            // Action buttons row
            actionButtonsRow
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Last Session Row

    private func lastSessionRow(_ session: PuppyEvent) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(Strings.TrainingSession.lastSession(date: session.time.formatted(date: .abbreviated, time: .omitted)))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Mark mastered button (if practicing or mastered)
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
                    .foregroundStyle(status == .mastered ? Color.otisSuccess : .secondary)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Recommendation Row

    private func recommendationRow(_ recommendation: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.caption2)
                .foregroundStyle(.teal)

            Text(recommendation)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    // MARK: - Mistakes Section

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(reduceMotion ? nil : TrainingAnimations.quickToggle) {
                    showMistakes.toggle()
                }
                HapticFeedback.light()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text(Strings.Training.commonMistakes)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showMistakes ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showMistakes {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(skill.mistakes, id: \.self) { mistake in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.orange.opacity(0.7))

                            Text(mistake)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Action Buttons Row

    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            // Info button
            CircularIconButton(systemName: "info.circle") {
                onViewInfo()
            }

            // Log session button
            Button {
                HapticFeedback.medium()
                onQuickLog()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text(Strings.Training.logSession)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.otisAccent)
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())

            // Train in-app button
            Button {
                HapticFeedback.medium()
                onStartTraining()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text(Strings.Training.trainInApp)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.otisAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    Capsule()
                        .strokeBorder(Color.otisAccent, lineWidth: 1.5)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding()
    }
}

// MARK: - Skill Icon with Recency Badge

/// Skill icon with optional "overdue" badge showing when training is stale
struct SkillIconWithBadge: View {
    let icon: String
    let isLocked: Bool
    let recentSessions: [PuppyEvent]
    var overdueThresholdDays: Int = 3

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(isLocked ? .secondary : Color.otisAccent)
                .frame(width: 36)

            // Recency indicator badge (if has sessions and been a while)
            if let lastSession = recentSessions.first, !isLocked {
                let daysSince = Calendar.current.dateComponents([.day], from: lastSession.time, to: Date()).day ?? 0
                if daysSince >= overdueThresholdDays {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Color.otisWarning)
                        .clipShape(Circle())
                        .offset(x: 6, y: -4)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Expanded Actions") {
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

    VStack {
        ExpandedSkillActions(
            skill: skill,
            status: .practicing,
            recentSessions: [
                PuppyEvent(time: Date().addingTimeInterval(-86400), type: .training, exercise: "sit", durationMin: 5)
            ],
            onStartTraining: {},
            onQuickLog: {},
            onViewInfo: {},
            onToggleMastered: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
