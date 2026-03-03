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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
        }
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
                .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.08))
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
                .fill(trigger.iconColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
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
                principleRow(text: Strings.Training.Guides.principleTiming, icon: "clock.fill")
                principleRow(text: Strings.Training.Guides.principleReward, icon: "star.fill")
                principleRow(text: Strings.Training.Guides.principleSupervise, icon: "eye.fill")
                principleRow(text: Strings.Training.Guides.principlePatience, icon: "heart.fill")
            }
        }
        .padding()
        .glassStatusCard(tintColor: nil)
    }

    @ViewBuilder
    private func principleRow(text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.otisAccent)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
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
                    tipRow(text: tip)
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

    @ViewBuilder
    private func tipRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.otisSuccess)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
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
                mistakeRow(text: Strings.Training.Guides.pottyMistake1)
                mistakeRow(text: Strings.Training.Guides.pottyMistake2)
                mistakeRow(text: Strings.Training.Guides.pottyMistake3)
                mistakeRow(text: Strings.Training.Guides.pottyMistake4)
            }
        }
        .padding()
        .glassStatusCard(tintColor: .otisWarning.opacity(0.1))
    }

    @ViewBuilder
    private func mistakeRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.otisWarning)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
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
        ageInWeeks: 10
    )
}

#Preview("New User") {
    PottyTrainingGuideSheet(
        streakInfo: .empty,
        patternAnalysis: .empty,
        outdoorPercentage: 0,
        ageInWeeks: 8
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
        ageInWeeks: 20
    )
}
