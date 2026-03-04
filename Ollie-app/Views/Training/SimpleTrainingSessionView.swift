//
//  SimpleTrainingSessionView.swift
//  Otis-app
//
//  Full-screen training session without clicker - for skills like handling
//

import SwiftUI
import Combine
import OtisShared

/// Full-screen training session view for non-clicker skills (like handling)
struct SimpleTrainingSessionView: View {
    let skill: Skill
    let phase: SkillPhase?  // Optional phase for focused step display
    let onComplete: (TrainingSessionData) -> Void
    let onCancel: () -> Void

    @State private var startTime = Date()
    @State private var elapsedSeconds: Int = 0
    @State private var showExitConfirmation = false
    @State private var instructionsExpanded = true

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// Steps to display - either phase-specific or all steps
    private var displaySteps: [(index: Int, text: String)] {
        if let phase = phase {
            return phase.howToStepIndices.compactMap { idx in
                guard idx < skill.howTo.count else { return nil }
                return (idx, skill.howTo[idx])
            }
        } else {
            return skill.howTo.enumerated().map { ($0.offset, $0.element) }
        }
    }

    /// Tips to display - either phase-specific or all tips
    private var displayTips: [String] {
        if let phase = phase, let tipIndices = phase.tipIndices {
            return tipIndices.compactMap { idx in
                guard idx < skill.tips.count else { return nil }
                return skill.tips[idx]
            }
        } else {
            return skill.tips
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Collapsible instructions
                    instructionsSection

                    // Timer display (prominent)
                    timerDisplay
                        .padding(.top, 24)

                    // Progress indicator
                    progressRing
                        .padding(.vertical, 24)

                    // Tips reminder
                    tipsSection
                }
                .padding()
            }

            // Bottom action
            bottomSection
        }
        .background(Color(.systemBackground))
        .onAppear {
            startTime = Date()
        }
        .onReceive(timer) { _ in
            elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        }
        .confirmationDialog(
            Strings.TrainingSession.exitConfirmationTitle,
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.TrainingSession.exitWithoutSaving, role: .destructive) {
                onCancel()
            }
            Button(Strings.TrainingSession.saveAndExit) {
                completeSession()
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        } message: {
            Text(Strings.TrainingSession.exitConfirmationMessage)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Exit button
            Button {
                if elapsedSeconds > 10 {
                    showExitConfirmation = true
                } else {
                    onCancel()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    )
            }

            Spacer()

            // Skill name and phase
            VStack(spacing: 2) {
                Text(skill.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                if let phase = phase {
                    Text(phase.name(for: skill.id))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(Strings.TrainingSession.practice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Timer badge
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.caption)
                Text(formattedTime)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)
            .frame(width: 72, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with toggle
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    instructionsExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.otisWarning)
                    // Show phase name if available, otherwise generic "How to train"
                    if let phase = phase {
                        Text(phase.name(for: skill.id))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    } else {
                        Text(Strings.Training.howTo)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Image(systemName: instructionsExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }

            // Expandable content
            if instructionsExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(displaySteps, id: \.index) { step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(step.index + 1).")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.otisAccent)
                                .frame(width: 24, alignment: .leading)
                            Text(step.text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(formattedTime)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .spring(duration: 0.3), value: elapsedSeconds)

            Text(Strings.TrainingSession.elapsed)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        let recommendedSeconds = (skill.durationMinutes ?? 2) * 60
        let progress = min(Double(elapsedSeconds) / Double(recommendedSeconds), 1.0)

        return ZStack {
            // Background ring
            Circle()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), lineWidth: 12)
                .frame(width: 160, height: 160)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress >= 1.0 ? Color.otisSuccess : Color.otisAccent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: progress)

            // Center content
            VStack(spacing: 4) {
                if progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.otisSuccess)
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                Text("\(skill.durationMinutes ?? 2) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Tips Section

    @ViewBuilder
    private var tipsSection: some View {
        if !displayTips.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundStyle(Color.otisSuccess)
                    Text(Strings.Training.tips)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(displayTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.otisWarning)
                            Text(tip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.otisSuccess.opacity(0.1) : Color.otisSuccess.opacity(0.05))
            )
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                completeSession()
            } label: {
                Text(Strings.TrainingSession.endSession)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.otisAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func completeSession() {
        let sessionData = TrainingSessionData(
            skill: skill,
            startTime: startTime,
            endTime: Date(),
            clickCount: 0
        )
        HapticFeedback.success()
        onComplete(sessionData)
    }
}

// MARK: - Preview

#Preview("Without Phase") {
    let handlingSkill = Skill(
        id: "handling",
        icon: "hands.sparkles.fill",
        category: .care,
        sortOrder: 2,
        requires: [],
        method: nil,
        durationMinutes: 2,
        sessionsPerDay: 2,
        steps: nil,
        phases: nil
    )

    SimpleTrainingSessionView(
        skill: handlingSkill,
        phase: nil,
        onComplete: { _ in },
        onCancel: {}
    )
}

#Preview("With Phase") {
    let collarLeashSkill = Skill(
        id: "collarLeash",
        icon: "dog.fill",
        category: .safety,
        sortOrder: 3,
        requires: [],
        method: nil,
        durationMinutes: 5,
        sessionsPerDay: 2,
        steps: nil,
        phases: [
            SkillPhase(id: "introduction", howToStepIndices: [0, 1], tipIndices: [0]),
            SkillPhase(id: "buildDuration", howToStepIndices: [2], tipIndices: [1]),
            SkillPhase(id: "leashWork", howToStepIndices: [3, 4], tipIndices: [2, 3])
        ]
    )

    SimpleTrainingSessionView(
        skill: collarLeashSkill,
        phase: SkillPhase(id: "introduction", howToStepIndices: [0, 1], tipIndices: [0]),
        onComplete: { _ in },
        onCancel: {}
    )
}
