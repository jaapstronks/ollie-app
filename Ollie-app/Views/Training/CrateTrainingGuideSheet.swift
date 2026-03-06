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
    @ObservedObject var eventStore: EventStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Mastery state
    @AppStorage(UserPreferences.Key.crateTrainingMastered.rawValue) private var isMastered = false
    @AppStorage(UserPreferences.Key.crateTrainingMasteredDate.rawValue) private var masteredTimestamp: Double = 0

    @State private var showMasteryConfirmation = false

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
                benefitRow(text: Strings.Training.CrateTraining.benefitPotty, icon: "drop.fill")
                benefitRow(text: Strings.Training.CrateTraining.benefitSelfSoothe, icon: "moon.zzz.fill")
                benefitRow(text: Strings.Training.CrateTraining.benefitSeparation, icon: "heart.fill")
                benefitRow(text: Strings.Training.CrateTraining.benefitSafeSpace, icon: "shield.fill")
                benefitRow(text: Strings.Training.CrateTraining.benefitLongerNaps, icon: "clock.fill")
            }
        }
        .padding()
        .glassStatusCard(tintColor: nil)
    }

    @ViewBuilder
    private func benefitRow(text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.indigo)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Tips Section

    @ViewBuilder
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Strings.Training.CrateTraining.tipsTitle, systemImage: "lightbulb.fill")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                tipRow(text: Strings.Training.CrateTraining.tipCozy)
                tipRow(text: Strings.Training.CrateTraining.tipMeals)
                tipRow(text: Strings.Training.CrateTraining.tipTired)
                tipRow(text: Strings.Training.CrateTraining.tipStayClose)
                tipRow(text: Strings.Training.CrateTraining.tipNoCrying)
                tipRow(text: Strings.Training.CrateTraining.tipShortFirst)
            }
        }
        .padding()
        .glassStatusCard(tintColor: .indigo.opacity(0.1))
    }

    @ViewBuilder
    private func tipRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(.indigo.opacity(0.6))
                .frame(width: 16)
                .padding(.top, 6)

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
    CrateTrainingGuideSheet(eventStore: EventStore())
}

#Preview("No Data") {
    CrateTrainingGuideSheet(eventStore: EventStore())
}
