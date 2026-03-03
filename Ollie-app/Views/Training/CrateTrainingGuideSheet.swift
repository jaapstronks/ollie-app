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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
        }
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
