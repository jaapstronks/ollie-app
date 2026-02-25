//
//  TrainingSessionView.swift
//  Ollie-app
//
//  Full-screen training session with clicker, timer, and instructions
//

import Combine
import SwiftUI

/// Data captured during a training session
struct TrainingSessionData {
    let skill: Skill
    let startTime: Date
    let endTime: Date
    let clickCount: Int

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
}

/// Full-screen training session view
struct TrainingSessionView: View {
    let skill: Skill
    let onComplete: (TrainingSessionData) -> Void
    let onCancel: () -> Void

    @State private var startTime = Date()
    @State private var elapsedSeconds: Int = 0
    @State private var clickCount: Int = 0
    @State private var showExitConfirmation = false
    @State private var showInstructions = true

    @AppStorage("trainingSession.soundEnabled") private var soundEnabled = true
    @AppStorage("trainingSession.vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("trainingSession.instructionsExpanded") private var instructionsExpanded = true

    @Environment(\.colorScheme) private var colorScheme

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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

                    // Counter display
                    counterDisplay
                        .padding(.top, 8)

                    // Clicker button
                    ClickerButton(
                        clickCount: $clickCount,
                        soundEnabled: soundEnabled,
                        vibrationEnabled: vibrationEnabled
                    )
                    .padding(.vertical, 16)

                    // Toggles
                    togglesSection
                }
                .padding()
            }

            // Bottom action
            bottomSection
        }
        .background(Color(.systemBackground))
        .onAppear {
            startTime = Date()
            AudioService.shared.prepareClickSound()
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
                if clickCount > 0 || elapsedSeconds > 10 {
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

            // Skill name
            VStack(spacing: 2) {
                Text(skill.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(Strings.TrainingSession.clicker)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Timer
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    instructionsExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.ollieWarning)
                    Text(Strings.Training.howTo)
                        .font(.subheadline)
                        .fontWeight(.medium)
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
                    ForEach(Array(skill.howTo.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(width: 20, alignment: .leading)
                            Text(step)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    // MARK: - Counter Display

    private var counterDisplay: some View {
        VStack(spacing: 4) {
            Text("\(clickCount)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: clickCount)

            Text(Strings.TrainingSession.clicks)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Toggles Section

    private var togglesSection: some View {
        HStack(spacing: 24) {
            // Sound toggle
            Toggle(isOn: $soundEnabled) {
                Label(Strings.TrainingSession.sound, systemImage: "speaker.wave.2.fill")
                    .font(.subheadline)
            }
            .toggleStyle(.button)
            .tint(soundEnabled ? .ollieAccent : .secondary)

            // Vibration toggle
            Toggle(isOn: $vibrationEnabled) {
                Label(Strings.TrainingSession.vibration, systemImage: "iphone.radiowaves.left.and.right")
                    .font(.subheadline)
            }
            .toggleStyle(.button)
            .tint(vibrationEnabled ? .ollieAccent : .secondary)
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
                    .background(Color.ollieAccent)
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
            clickCount: clickCount
        )
        HapticFeedback.success()
        onComplete(sessionData)
    }
}

// MARK: - Preview

private let previewSkillForSession = Skill(
    id: "sit",
    icon: "arrow.down.to.line",
    category: .basicCommands,
    week: 2,
    priority: 1,
    requires: ["luring"]
)

#Preview {
    TrainingSessionView(
        skill: previewSkillForSession,
        onComplete: { _ in },
        onCancel: {}
    )
}
