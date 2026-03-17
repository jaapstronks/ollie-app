//
//  TheoryPageView.swift
//  Ollie-app
//
//  Individual theory page showing phase content.
//  Displays: phase name, subtitle, how-to steps, tips.
//

import SwiftUI
import OtisShared

/// Single theory page for a skill phase
struct TheoryPageView: View {
    let skill: Skill
    let phase: SkillPhase
    let phaseIndex: Int
    let totalPhases: Int

    @Environment(\.colorScheme) private var colorScheme

    private var phaseName: String {
        phase.name(for: skill.id)
    }

    private var phaseSubtitle: String {
        phase.subtitle(for: skill.id)
    }

    /// Get howTo steps for this phase
    private var howToSteps: [String] {
        phase.howToStepIndices.compactMap { index in
            guard index >= 0 && index < skill.howTo.count else { return nil }
            return skill.howTo[index]
        }
    }

    /// Get tips for this phase
    private var tips: [String] {
        guard let tipIndices = phase.tipIndices else { return [] }
        return tipIndices.compactMap { index in
            guard index >= 0 && index < skill.tips.count else { return nil }
            return skill.tips[index]
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Phase header
                VStack(alignment: .leading, spacing: 8) {
                    // Phase number badge
                    Text(Strings.Training.Matrix.phaseNumber(phaseIndex + 1))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.otisAccent)
                        )

                    Text(phaseName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if !phaseSubtitle.isEmpty {
                        Text(phaseSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // How to section
                if !howToSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Label(Strings.Training.howTo, systemImage: "list.number")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(howToSteps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    // Step number circle
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color.otisAccent))

                                    Text(step)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
                    )
                }

                // Tips section
                if !tips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(Strings.Training.tips, systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundStyle(.yellow)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)

                                    Text(tip)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.yellow.opacity(0.1))
                    )
                }

                Spacer(minLength: 100) // Space for bottom bar
            }
            .padding()
        }
        .textSelection(.enabled)
    }
}

// MARK: - Preview

#Preview {
    TheoryPageView(
        skill: Skill(
            id: "sit",
            icon: "figure.seated",
            category: .basicCommands,
            sortOrder: 5,
            requires: [],
            method: nil,
            durationMinutes: 5,
            sessionsPerDay: 2,
            steps: nil,
            phases: nil
        ),
        phase: SkillPhase(id: "lureToPosition", howToStepIndices: [0, 1, 2], tipIndices: [0, 1]),
        phaseIndex: 0,
        totalPhases: 4
    )
}
