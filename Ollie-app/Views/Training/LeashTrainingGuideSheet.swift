//
//  LeashTrainingGuideSheet.swift
//  Ollie-app
//
//  Personalized leash training guide with sentiment-based progress tracking

import SwiftUI
import OtisShared

/// Personalized leash training guide sheet
struct LeashTrainingGuideSheet: View {
    let recentSentimentAverage: Double?
    let sentimentTrend: SentimentTrend?
    let ageInWeeks: Int

    // Injected from parent
    let shouldShowReactivationPrompt: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject var trainingMasteryStore: TrainingMasteryStore

    @State private var showMasteryConfirmation = false

    // Convenience accessors
    private var isMastered: Bool { trainingMasteryStore.leashTrainingMastered }
    private var masteredTimestamp: Double {
        trainingMasteryStore.leashMasteredDate?.timeIntervalSince1970 ?? 0
    }

    /// Determine which age phase the puppy is in
    private var agePhase: AgePhase {
        switch ageInWeeks {
        case ..<14: return .early
        case 14..<20: return .middle
        default: return .adolescent
        }
    }

    private enum AgePhase {
        case early      // 8-14 weeks
        case middle     // 14-20 weeks
        case adolescent // 20+ weeks
    }

    /// Whether user has meaningful data
    private var hasData: Bool {
        recentSentimentAverage != nil
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
                        masteredSection
                    } else {
                        // Progress section
                        if hasData {
                            progressSection
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
            .navigationTitle(Strings.Leash.guideSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                Strings.Leash.markMastered,
                isPresented: $showMasteryConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Leash.markMastered) {
                    markAsMastered()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            } message: {
                Text(Strings.Leash.markMasteredDescription)
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

                Text(Strings.Leash.masteredCelebration)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Strings.Leash.masteredDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !masteredDateFormatted.isEmpty {
                    Text(Strings.Leash.masteredOn(date: masteredDateFormatted))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 20)

            // Reactivation prompt
            if shouldShowReactivationPrompt {
                reactivationPromptCard
            }

            Divider()

            // Key principles reminder
            principlesSection

            Divider()

            // Always-available reactivate link
            Button {
                reactivateTracking()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                    Text(Strings.Leash.reactivateLink)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    // MARK: - Progress Section

    @ViewBuilder
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Leash.currentProgress)
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                // Average rating
                if let avg = recentSentimentAverage {
                    statCard(
                        title: Strings.Leash.averageRating(avg),
                        icon: "star.fill",
                        color: ratingColor(avg)
                    )
                }

                // Trend indicator
                if let trend = sentimentTrend {
                    statCard(
                        title: trend.label,
                        icon: trend.icon,
                        color: trendColor(trend)
                    )
                }
            }
        }
        .padding()
        .glassStatusCard(tintColor: .otisAccent.opacity(0.15))
    }

    @ViewBuilder
    private func statCard(title: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.backgroundOpacity(colorScheme: colorScheme))
        )
    }

    private func ratingColor(_ avg: Double) -> Color {
        switch avg {
        case 4.5...: return .otisSuccess
        case 3.5...: return .otisAccent
        case 2.5...: return .otisWarning
        default: return .otisDanger
        }
    }

    private func trendColor(_ trend: SentimentTrend) -> Color {
        switch trend {
        case .improving: return .otisSuccess
        case .stable: return .otisAccent
        case .declining: return .otisWarning
        }
    }

    // MARK: - Get Started Section

    @ViewBuilder
    private var getStartedSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "link")
                .font(.system(size: 40))
                .foregroundStyle(Color.otisAccent)

            Text(Strings.Leash.noRatingsYet)
                .font(.headline)

            Text(Strings.Leash.rateAfterWalks)
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
            Label(Strings.Leash.keyPrinciples, systemImage: "lightbulb.fill")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                InfoListRow.principle(Strings.Leash.principle1, icon: "link.badge.plus")
                InfoListRow.principle(Strings.Leash.principle2, icon: "star.fill")
                InfoListRow.principle(Strings.Leash.principle3, icon: "hand.raised.fill")
                InfoListRow.principle(Strings.Leash.principle4, icon: "house.fill")
                InfoListRow.principle(Strings.Leash.principle5, icon: "carrot.fill")
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
        case .early: return Strings.Leash.earlyWeeks
        case .middle: return Strings.Leash.middleWeeks
        case .adolescent: return Strings.Leash.adolescent
        }
    }

    private var phaseTips: [String] {
        switch agePhase {
        case .early:
            return [
                Strings.Leash.earlyTip1,
                Strings.Leash.earlyTip2,
                Strings.Leash.earlyTip3,
                Strings.Leash.earlyTip4
            ]
        case .middle:
            return [
                Strings.Leash.middleTip1,
                Strings.Leash.middleTip2,
                Strings.Leash.middleTip3,
                Strings.Leash.middleTip4
            ]
        case .adolescent:
            return [
                Strings.Leash.adolescentTip1,
                Strings.Leash.adolescentTip2,
                Strings.Leash.adolescentTip3,
                Strings.Leash.adolescentTip4
            ]
        }
    }

    // MARK: - Common Mistakes Section

    @ViewBuilder
    private var commonMistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Leash.commonMistakes, systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                InfoListRow.warning(Strings.Leash.mistake1)
                InfoListRow.warning(Strings.Leash.mistake2)
                InfoListRow.warning(Strings.Leash.mistake3)
                InfoListRow.warning(Strings.Leash.mistake4)
            }
        }
        .padding()
        .glassStatusCard(tintColor: .otisWarning.opacity(0.1))
    }

    // MARK: - Reactivation Prompt Card

    @ViewBuilder
    private var reactivationPromptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .foregroundStyle(.indigo)
                Text(Strings.Leash.reactivationTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(Strings.Leash.reactivationMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    reactivateTracking()
                } label: {
                    Text(Strings.Leash.reactivateNow)
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
                    Text(Strings.Leash.notNow)
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
                    Text(Strings.Leash.markMastered)
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

            Text(Strings.Leash.markMasteredDescription)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Actions

    private func markAsMastered() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            trainingMasteryStore.markLeashMastered()
        }
        HapticFeedback.success()
    }

    private func reactivateTracking() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            trainingMasteryStore.reactivateLeashTraining()
        }
        // Clear dismissal states
        trainingMasteryStore.leashReactivationPromptDismissedDate = nil
        trainingMasteryStore.leashLastSentimentAcknowledgedDate = nil
        HapticFeedback.light()
    }

    private func dismissReactivationPrompt() {
        trainingMasteryStore.dismissLeashReactivationPrompt()
        HapticFeedback.selection()
    }
}

// MARK: - Preview

#Preview("With Data") {
    LeashTrainingGuideSheet(
        recentSentimentAverage: 3.8,
        sentimentTrend: .improving,
        ageInWeeks: 16,
        shouldShowReactivationPrompt: false
    )
    .environmentObject(TrainingMasteryStore.shared)
}

#Preview("New User") {
    LeashTrainingGuideSheet(
        recentSentimentAverage: nil,
        sentimentTrend: nil,
        ageInWeeks: 10,
        shouldShowReactivationPrompt: false
    )
    .environmentObject(TrainingMasteryStore.shared)
}

#Preview("Adolescent Puppy") {
    LeashTrainingGuideSheet(
        recentSentimentAverage: 4.2,
        sentimentTrend: .stable,
        ageInWeeks: 24,
        shouldShowReactivationPrompt: false
    )
    .environmentObject(TrainingMasteryStore.shared)
}

#Preview("With Reactivation Prompt") {
    LeashTrainingGuideSheet(
        recentSentimentAverage: 2.5,
        sentimentTrend: .declining,
        ageInWeeks: 20,
        shouldShowReactivationPrompt: true
    )
    .environmentObject(TrainingMasteryStore.shared)
}
