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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header card
                    headerCard

                    // Description
                    Text(skill.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // How to train
                    howToSection

                    // Common mistakes (if available)
                    if !skill.mistakes.isEmpty {
                        mistakesSection
                    }

                    // Done when
                    doneWhenSection

                    // Tips
                    if !skill.tips.isEmpty {
                        tipsSection
                    }

                    // Recent sessions
                    if !recentSessions.isEmpty {
                        recentSessionsSection
                    }

                    // Action buttons
                    actionButtons
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

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            // Skill icon
            ZStack {
                Circle()
                    .fill(Color.otisAccent.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.otisAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Status badge
                HStack(spacing: 6) {
                    Image(systemName: status.icon)
                        .font(.caption2)
                    Text(status.label)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(status.color)

                // Method and recommendation
                HStack(spacing: 8) {
                    if let method = skill.method {
                        HStack(spacing: 4) {
                            Image(systemName: method.icon)
                                .font(.caption2)
                            Text(method.label)
                                .font(.caption)
                        }
                        .foregroundStyle(method == .operant ? Color.purple : Color.blue)
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

                // Session count
                if sessionCount > 0 {
                    Text(Strings.Training.sessionCount(sessionCount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .glassStatusCard(tintColor: status == .mastered ? .otisSuccess : nil)
    }

    // MARK: - How To Section

    private var howToSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.howTo, icon: "list.number")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(skill.howTo.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.otisAccent)
                            .frame(width: 24, alignment: .leading)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Mistakes Section

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.commonMistakes, icon: "exclamationmark.triangle")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(skill.mistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.8))
                        Text(mistake)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red.opacity(0.08))
            )
        }
    }

    // MARK: - Done When Section

    private var doneWhenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.doneWhen, icon: "checkmark.circle")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.otisSuccess)
                Text(skill.doneWhen)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.tips, icon: "lightbulb")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(skill.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(Color.otisWarning)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.recentSessions, icon: "clock")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(recentSessions.prefix(5)) { session in
                    HStack(spacing: 12) {
                        Text(session.time.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let duration = session.durationMin {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text("\(duration) min")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let result = session.result, !result.isEmpty {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(result)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action: Start training
            Button {
                HapticFeedback.medium()
                onDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onStartTraining()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text(Strings.TrainingSession.startTraining)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.otisAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // Secondary actions row
            HStack(spacing: 12) {
                // Log session
                Button {
                    HapticFeedback.light()
                    onDismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onLogSession()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text(Strings.Training.logSession)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.otisAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.otisAccent, lineWidth: 1.5)
                    )
                }

                // Toggle mastered
                if status == .practicing || status == .mastered {
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
                        .foregroundStyle(status == .mastered ? Color.otisSuccess : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
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
