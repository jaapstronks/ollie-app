//
//  SkillInfoSheet.swift
//  Ollie-app
//
//  Info sheet for viewing skill details without starting a session
//

import SwiftUI
import OllieShared

/// Sheet showing skill details without starting a training session
struct SkillInfoSheet: View {
    let skill: Skill
    let status: SkillStatus
    let sessionCount: Int
    let recentSessions: [PuppyEvent]
    let onStartTraining: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Skill header card
                    headerCard

                    // Description
                    Text(skill.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // How to train
                    howToSection

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

                    // Start training button
                    startTrainingButton
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
                    .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.ollieAccent)
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
        .glassStatusCard(tintColor: status == .mastered ? .ollieSuccess : nil)
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
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .leading)
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Done When Section

    private var doneWhenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(Strings.Training.doneWhen, icon: "checkmark.circle")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.ollieSuccess)
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
                            .foregroundStyle(Color.ollieWarning)
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

    // MARK: - Start Training Button

    private var startTrainingButton: some View {
        Button {
            HapticFeedback.selection()
            onDismiss()
            // Small delay to allow sheet to dismiss before starting training
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
            .background(Color.ollieAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

private let previewSkillForInfo = Skill(
    id: "sit",
    icon: "arrow.down.to.line",
    category: .basicCommands,
    week: 2,
    priority: 1,
    requires: ["luring"]
)

#Preview {
    SkillInfoSheet(
        skill: previewSkillForInfo,
        status: .practicing,
        sessionCount: 6,
        recentSessions: [],
        onStartTraining: {},
        onDismiss: {}
    )
}
