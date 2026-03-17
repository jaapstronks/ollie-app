//
//  SkillRefresherSheet.swift
//  Ollie-app
//
//  Lightweight sheet for maintenance reviews of mastered skills
//  Shows the last phase content as a quick refresher
//

import SwiftUI
import OtisShared

/// Quick refresher sheet for mastered/maintaining skills
/// Shows the final phase instructions to help recall the full behavior
struct SkillRefresherSheet: View {
    let skill: Skill
    let onStartPractice: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Get the last phase (representing the complete behavior)
    private var lastPhase: SkillPhase? {
        skill.effectivePhases.last
    }

    /// Get how-to steps for the last phase
    private var refresherSteps: [String] {
        guard let phase = lastPhase else { return [] }
        let allSteps = skill.howTo
        return phase.howToStepIndices.compactMap { index in
            guard index < allSteps.count else { return nil }
            return allSteps[index]
        }
    }

    /// Get tips for the last phase
    private var refresherTips: [String] {
        guard let phase = lastPhase,
              let tipIndices = phase.tipIndices else { return [] }
        let allTips = skill.tips
        return tipIndices.compactMap { index in
            guard index < allTips.count else { return nil }
            return allTips[index]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Quick refresher steps
                    if !refresherSteps.isEmpty {
                        stepsSection
                    }

                    // Key tips
                    if !refresherTips.isEmpty {
                        tipsSection
                    }
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
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.otisSuccess.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: skill.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.otisSuccess)
            }

            VStack(spacing: 4) {
                Text(Strings.Training.quickRefresher)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(skill.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Steps Section

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.howTo, systemImage: "list.number")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(refresherSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.otisAccent))

                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.tips, systemImage: "lightbulb.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(refresherTips.prefix(2).enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.otisSuccess)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                HapticFeedback.medium()
                onDismiss()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.3))
                    onStartPractice()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text(Strings.Training.startPractice)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.otisAccent)
                )
            }
            .padding()
        }
        .background(.regularMaterial)
    }
}

// MARK: - Preview

#Preview {
    SkillRefresherSheet(
        skill: Skill(
            id: "sit",
            icon: "arrow.down.to.line",
            category: .basicCommands,
            sortOrder: 7,
            requires: [],
            method: .classical,
            durationMinutes: 3,
            sessionsPerDay: 3,
            steps: nil,
            phases: [
                SkillPhase(id: "lure", howToStepIndices: [0, 1, 2], tipIndices: [0, 1]),
                SkillPhase(id: "proof", howToStepIndices: [3, 4], tipIndices: [2, 3])
            ]
        ),
        onStartPractice: {},
        onDismiss: {}
    )
}
