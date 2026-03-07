//
//  PottyTrainingGuideSheet.swift
//  Otis-app
//
//  Personalized potty training guide with stats and age-based tips
//

import SwiftUI
import OtisShared

/// Personalized potty training guide sheet
struct PottyTrainingGuideSheet: View {
    let streakInfo: StreakInfo
    let patternAnalysis: PatternAnalysis
    let outdoorPercentage: Int
    let ageInWeeks: Int

    // Injected from parent (TimelineViewModel)
    let shouldShowIncidentMessage: Bool
    let shouldShowReactivationPrompt: Bool
    let incidentCount: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Mastery state
    @AppStorage(UserPreferences.Key.pottyTrainingMastered.rawValue) private var isMastered = false
    @AppStorage(UserPreferences.Key.pottyTrainingMasteredDate.rawValue) private var masteredTimestamp: Double = 0

    @State private var showMasteryConfirmation = false

    /// Determine which age phase the puppy is in
    private var agePhase: AgePhase {
        switch ageInWeeks {
        case ..<12: return .early
        case 12..<16: return .middle
        default: return .older
        }
    }

    private enum AgePhase {
        case early   // 8-12 weeks
        case middle  // 12-16 weeks
        case older   // 16+ weeks
    }

    /// Top pattern triggers for display
    private var topTriggers: [PatternTrigger] {
        patternAnalysis.triggers
            .filter { $0.hasData }
            .sorted { $0.successRate > $1.successRate }
            .prefix(3)
            .map { $0 }
    }

    /// Whether user has meaningful data
    private var hasData: Bool {
        outdoorPercentage > 0 || streakInfo.currentStreak > 0 || !topTriggers.isEmpty
    }

    /// Formatted mastered date
    private var masteredDateFormatted: String {
        guard masteredTimestamp > 0 else { return "" }
        let date = Date(timeIntervalSince1970: masteredTimestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isMastered {
                        // Mastered state
                        masteredSection
                    } else {
                        // AI Potty Analysis (personalized insights)
                        AIPottyAnalysisCard()

                        // Stats section
                        if hasData {
                            statsSection
                        } else {
                            getStartedSection
                        }

                        // Key principles (always show)
                        principlesSection

                        // Age-based tips
                        ageBasedTipsSection

                        // Common mistakes
                        commonMistakesSection

                        // Mark as mastered button
                        markAsMasteredButton
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
            .navigationTitle(Strings.Training.Guides.pottyGuideTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                Strings.Training.PottyTraining.markMastered,
                isPresented: $showMasteryConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Training.PottyTraining.markMastered) {
                    markAsMastered()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            } message: {
                Text(Strings.Training.PottyTraining.markMasteredDescription)
            }
        }
    }

    // MARK: - Mastered Section

    @ViewBuilder
    private var masteredSection: some View {
        VStack(spacing: 24) {
            // Celebration header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                }

                Text(Strings.Training.PottyTraining.masteredCelebration)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Strings.Training.PottyTraining.masteredDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !masteredDateFormatted.isEmpty {
                    Text(Strings.Training.PottyTraining.masteredOn(date: masteredDateFormatted))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 20)

            // Incident message (gentle, not patronizing)
            if shouldShowIncidentMessage {
                incidentMessageCard
            }

            // Reactivation prompt (3+ incidents)
            if shouldShowReactivationPrompt {
                reactivationPromptCard
            }

            Divider()

            // Key principles reminder (collapsed)
            principlesSection

            Divider()

            // Always-available reactivate link
            Button {
                reactivateTracking()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                    Text(Strings.Training.PottyTraining.reactivateLink)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    // MARK: - Incident Message Card (gentle tone)

    @ViewBuilder
    private var incidentMessageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.orange)
                Text(Strings.Training.PottyTraining.incidentHappened)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text(Strings.Training.PottyTraining.incidentMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                acknowledgeIncident()
            } label: {
                Text(Strings.Common.gotIt)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.08))
        )
    }

    // MARK: - Reactivation Prompt Card

    @ViewBuilder
    private var reactivationPromptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .foregroundStyle(.indigo)
                Text(Strings.Training.PottyTraining.reactivationTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(Strings.Training.PottyTraining.reactivationMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    reactivateTracking()
                } label: {
                    Text(Strings.Training.PottyTraining.reactivateNow)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.indigo))
                }
                .buttonStyle(.plain)

                Button {
                    dismissReactivationPrompt()
                } label: {
                    Text(Strings.Training.PottyTraining.notNow)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.indigo.opacity(colorScheme == .dark ? 0.15 : 0.08))
        )
    }

    // MARK: - Mark as Mastered Button

    @ViewBuilder
    private var markAsMasteredButton: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.top, 8)

            Button {
                showMasteryConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text(Strings.Training.PottyTraining.markMastered)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(colorScheme == .dark ? 0.15 : 0.1))
                )
            }
            .buttonStyle(.plain)

            Text(Strings.Training.PottyTraining.markMasteredDescription)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Actions

    private func markAsMastered() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isMastered = true
            masteredTimestamp = Date().timeIntervalSince1970
        }
        HapticFeedback.success()
    }

    private func reactivateTracking() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isMastered = false
            masteredTimestamp = 0
        }
        // Clear dismissal states
        UserDefaults.standard.removeObject(forKey: UserPreferences.Key.pottyReactivationPromptDismissedDate.rawValue)
        UserDefaults.standard.removeObject(forKey: UserPreferences.Key.pottyLastIncidentAcknowledgedDate.rawValue)
        HapticFeedback.light()
    }

    private func acknowledgeIncident() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: UserPreferences.Key.pottyLastIncidentAcknowledgedDate.rawValue)
        HapticFeedback.selection()
    }

    private func dismissReactivationPrompt() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: UserPreferences.Key.pottyReactivationPromptDismissedDate.rawValue)
        HapticFeedback.selection()
    }

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Training.Guides.currentProgress)
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                // Outdoor rate
                statCard(
                    title: Strings.Training.Guides.outdoorRate,
                    value: "\(outdoorPercentage)%",
                    icon: "target",
                    color: percentageColor
                )

                // Current streak
                statCard(
                    title: Strings.Training.Guides.outdoorStreak,
                    value: "\(streakInfo.currentStreak)",
                    icon: StreakCalculations.iconName(for: streakInfo.currentStreak),
                    color: StreakCalculations.iconColor(for: streakInfo.currentStreak)
                )
            }

            // Top triggers (if available)
            if !topTriggers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Train.topTriggers)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ForEach(topTriggers) { trigger in
                            triggerBadge(trigger)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .glassStatusCard(tintColor: .otisAccent.opacity(0.15))
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.backgroundOpacity(colorScheme: colorScheme))
        )
    }

    @ViewBuilder
    private func triggerBadge(_ trigger: PatternTrigger) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trigger.iconName)
                .font(.caption2)
                .foregroundStyle(trigger.iconColor)

            Text("\(trigger.successRate)%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(trigger.iconColor.badgeOpacity(colorScheme: colorScheme))
        )
    }

    private var percentageColor: Color {
        switch outdoorPercentage {
        case 90...: return .otisSuccess
        case 70...: return .otisAccent
        case 50...: return .otisWarning
        default: return .otisDanger
        }
    }

    // MARK: - Get Started Section

    @ViewBuilder
    private var getStartedSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundStyle(Color.otisAccent)

            Text(Strings.Training.Guides.getStarted)
                .font(.headline)

            Text(Strings.Training.Guides.pottySubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassStatusCard(tintColor: .otisAccent.opacity(0.15))
    }

    // MARK: - Principles Section

    @ViewBuilder
    private var principlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.Guides.keyPrinciples, systemImage: "lightbulb.fill")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                InfoListRow.principle(Strings.Training.Guides.principleTiming, icon: "clock.fill")
                InfoListRow.principle(Strings.Training.Guides.principleReward, icon: "star.fill")
                InfoListRow.principle(Strings.Training.Guides.principleSupervise, icon: "eye.fill")
                InfoListRow.principle(Strings.Training.Guides.principlePatience, icon: "heart.fill")
            }
        }
        .padding()
        .glassStatusCard(tintColor: nil)
    }

    // MARK: - Age-Based Tips Section

    @ViewBuilder
    private var ageBasedTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.Guides.tipsForYourPuppy, systemImage: "pawprint.fill")
                .font(.headline)
                .fontWeight(.semibold)

            // Show phase header
            Text(phaseTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.otisAccent)
                .padding(.top, 4)

            VStack(spacing: 8) {
                ForEach(phaseTips, id: \.self) { tip in
                    InfoListRow.tip(tip)
                }
            }
        }
        .padding()
        .glassStatusCard(tintColor: .otisAccent.opacity(0.1))
    }

    private var phaseTitle: String {
        switch agePhase {
        case .early: return Strings.Training.Guides.earlyWeeks
        case .middle: return Strings.Training.Guides.middleWeeks
        case .older: return Strings.Training.Guides.olderPuppy
        }
    }

    private var phaseTips: [String] {
        switch agePhase {
        case .early:
            return [
                Strings.Training.Guides.earlyTip1,
                Strings.Training.Guides.earlyTip2,
                Strings.Training.Guides.earlyTip3,
                Strings.Training.Guides.earlyTip4
            ]
        case .middle:
            return [
                Strings.Training.Guides.middleTip1,
                Strings.Training.Guides.middleTip2,
                Strings.Training.Guides.middleTip3,
                Strings.Training.Guides.middleTip4
            ]
        case .older:
            return [
                Strings.Training.Guides.olderTip1,
                Strings.Training.Guides.olderTip2,
                Strings.Training.Guides.olderTip3,
                Strings.Training.Guides.olderTip4
            ]
        }
    }

    // MARK: - Common Mistakes Section

    @ViewBuilder
    private var commonMistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.Guides.commonMistakes, systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                InfoListRow.warning(Strings.Training.Guides.pottyMistake1)
                InfoListRow.warning(Strings.Training.Guides.pottyMistake2)
                InfoListRow.warning(Strings.Training.Guides.pottyMistake3)
                InfoListRow.warning(Strings.Training.Guides.pottyMistake4)
            }
        }
        .padding()
        .glassStatusCard(tintColor: .otisWarning.opacity(0.1))
    }
}

// MARK: - Preview

#Preview("With Data") {
    PottyTrainingGuideSheet(
        streakInfo: StreakInfo(
            currentStreak: 5,
            bestStreak: 8,
            lastOutdoorTime: Date(),
            lastIndoorTime: nil
        ),
        patternAnalysis: PatternAnalysis(
            triggers: [
                PatternTrigger(id: "sleep", name: "After Sleep", iconName: "moon.zzz.fill", iconColor: .otisSleep, outdoorCount: 9, indoorCount: 1),
                PatternTrigger(id: "meal", name: "After Eating", iconName: "fork.knife", iconColor: .otisAccent, outdoorCount: 7, indoorCount: 2),
                PatternTrigger(id: "walk", name: "During Walk", iconName: "figure.walk", iconColor: .otisAccent, outdoorCount: 10, indoorCount: 0)
            ],
            periodDays: 7
        ),
        outdoorPercentage: 82,
        ageInWeeks: 10,
        shouldShowIncidentMessage: false,
        shouldShowReactivationPrompt: false,
        incidentCount: 0
    )
}

#Preview("New User") {
    PottyTrainingGuideSheet(
        streakInfo: .empty,
        patternAnalysis: .empty,
        outdoorPercentage: 0,
        ageInWeeks: 8,
        shouldShowIncidentMessage: false,
        shouldShowReactivationPrompt: false,
        incidentCount: 0
    )
}

#Preview("Older Puppy") {
    PottyTrainingGuideSheet(
        streakInfo: StreakInfo(
            currentStreak: 14,
            bestStreak: 14,
            lastOutdoorTime: Date(),
            lastIndoorTime: nil
        ),
        patternAnalysis: .empty,
        outdoorPercentage: 95,
        ageInWeeks: 20,
        shouldShowIncidentMessage: false,
        shouldShowReactivationPrompt: false,
        incidentCount: 0
    )
}

#Preview("Mastered with Incident") {
    PottyTrainingGuideSheet(
        streakInfo: .empty,
        patternAnalysis: .empty,
        outdoorPercentage: 100,
        ageInWeeks: 24,
        shouldShowIncidentMessage: true,
        shouldShowReactivationPrompt: false,
        incidentCount: 1
    )
}

#Preview("Mastered with Reactivation Prompt") {
    PottyTrainingGuideSheet(
        streakInfo: .empty,
        patternAnalysis: .empty,
        outdoorPercentage: 100,
        ageInWeeks: 24,
        shouldShowIncidentMessage: false,
        shouldShowReactivationPrompt: true,
        incidentCount: 3
    )
}
