//
//  CrateTrainingGuideSheet.swift
//  Otis-app
//
//  Personalized crate training guide with stats and tips
//  Refactored from CrateTrainingSection for sheet presentation
//

import SwiftUI
import OtisShared

/// Personalized crate training guide sheet
struct CrateTrainingGuideSheet: View {
    var eventStore: EventStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Training mastery state
    @EnvironmentObject var trainingMasteryStore: TrainingMasteryStore

    @State private var showMasteryConfirmation = false

    // Convenience accessors
    private var isMastered: Bool { trainingMasteryStore.crateTrainingMastered }
    private var masteredTimestamp: Double {
        trainingMasteryStore.crateMasteredDate?.timeIntervalSince1970 ?? 0
    }

    /// Calculate percentage of recent naps taken in crate
    private var crateNapStats: (percentage: Int, total: Int) {
        let recentNaps = eventStore.events
            .sleeps()
            .lastDays(14)

        guard !recentNaps.isEmpty else { return (0, 0) }

        let crateNaps = recentNaps.filter { $0.napLocation == .crate }
        let percentage = Int((Double(crateNaps.count) / Double(recentNaps.count)) * 100)

        return (percentage, recentNaps.count)
    }

    /// Whether user has meaningful data
    private var hasData: Bool {
        crateNapStats.total > 0
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
                        // Stats section
                        statsSection

                        // Benefits section
                        benefitsSection

                        // Tips section
                        tipsSection

                        // Encouragement
                        Text(Strings.Training.CrateTraining.encouragement)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Mark as mastered button
                        markAsMasteredButton
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
            .navigationTitle(Strings.Training.Guides.crateGuideTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                Strings.Training.CrateTraining.markMastered,
                isPresented: $showMasteryConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Training.CrateTraining.markMastered) {
                    markAsMastered()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            } message: {
                Text(Strings.Training.CrateTraining.markMasteredDescription)
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

                Text(Strings.Training.CrateTraining.masteredCelebration)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Strings.Training.CrateTraining.masteredDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !masteredDateFormatted.isEmpty {
                    Text(Strings.Training.CrateTraining.masteredOn(date: masteredDateFormatted))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 20)

            Divider()

            // Benefits reminder (collapsed)
            benefitsSection

            Divider()

            // Reactivate button
            Button {
                reactivateTracking()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                    Text(Strings.Training.CrateTraining.reactivateTracking)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
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
                    Text(Strings.Training.CrateTraining.markMastered)
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

            Text(Strings.Training.CrateTraining.markMasteredDescription)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Actions

    private func markAsMastered() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            trainingMasteryStore.markCrateMastered()
        }
        HapticFeedback.success()
    }

    private func reactivateTracking() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            trainingMasteryStore.reactivateCrateTraining()
        }
        HapticFeedback.light()
    }

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Training.Guides.crateProgress)
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                // Crate icon
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if hasData {
                        Text(Strings.Training.CrateTraining.crateNapPercentage(crateNapStats.percentage))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.indigo.opacity(0.15))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.indigo)
                                    .frame(width: geometry.size.width * CGFloat(crateNapStats.percentage) / 100, height: 8)
                            }
                        }
                        .frame(height: 8)

                        // Personalized message
                        Text(Strings.Training.Guides.crateUsageMessage(percentage: crateNapStats.percentage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(Strings.Training.CrateTraining.noNapsYet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(Strings.Training.Guides.getStarted)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .glassStatusCard(tintColor: .indigo.opacity(0.15))
    }

    // MARK: - Benefits Section

    @ViewBuilder
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.CrateTraining.benefitsTitle, systemImage: "checkmark.seal.fill")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                InfoListRow.benefit(Strings.Training.CrateTraining.benefitPotty, icon: "drop.fill")
                InfoListRow.benefit(Strings.Training.CrateTraining.benefitSelfSoothe, icon: "moon.zzz.fill")
                InfoListRow.benefit(Strings.Training.CrateTraining.benefitSeparation, icon: "heart.fill")
                InfoListRow.benefit(Strings.Training.CrateTraining.benefitSafeSpace, icon: "shield.fill")
                InfoListRow.benefit(Strings.Training.CrateTraining.benefitLongerNaps, icon: "clock.fill")
            }
        }
        .padding()
        .glassStatusCard(tintColor: nil)
    }

    // MARK: - Tips Section

    @ViewBuilder
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.CrateTraining.tipsTitle, systemImage: "lightbulb.fill")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                InfoListRow.bullet(Strings.Training.CrateTraining.tipCozy, color: .indigo)
                InfoListRow.bullet(Strings.Training.CrateTraining.tipMeals, color: .indigo)
                InfoListRow.bullet(Strings.Training.CrateTraining.tipTired, color: .indigo)
                InfoListRow.bullet(Strings.Training.CrateTraining.tipStayClose, color: .indigo)
                InfoListRow.bullet(Strings.Training.CrateTraining.tipNoCrying, color: .indigo)
                InfoListRow.bullet(Strings.Training.CrateTraining.tipShortFirst, color: .indigo)
            }
        }
        .padding()
        .glassStatusCard(tintColor: .indigo.opacity(0.1))
    }
}

// MARK: - Preview

#Preview("With Data") {
    CrateTrainingGuideSheet(eventStore: EventStore())
}

#Preview("No Data") {
    CrateTrainingGuideSheet(eventStore: EventStore())
}
