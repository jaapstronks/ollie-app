//
//  CrateTrainingSection.swift
//  Otis-app
//
//  Expandable section explaining crate training benefits and tips
//

import SwiftUI
import OtisShared

/// Section showing crate training guidance with nap statistics
struct CrateTrainingSection: View {
    @ObservedObject var eventStore: EventStore

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    var body: some View {
        VStack(spacing: 0) {
            // Header (tappable to expand)
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticFeedback.light()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundStyle(.indigo)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Training.CrateTraining.sectionTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if !isExpanded {
                            Text(Strings.Training.CrateTraining.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Crate percentage badge
                    if crateNapStats.total > 0 {
                        Text("\(crateNapStats.percentage)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.indigo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.indigo.opacity(0.15))
                            )
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                expandedContent
            }
        }
        .glassStatusCard(tintColor: .indigo.opacity(0.2))
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal)

            // Stats card
            statsCard

            // Benefits section
            VStack(alignment: .leading, spacing: 10) {
                Label(Strings.Training.CrateTraining.benefitsTitle, systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    InfoListRow.benefit(Strings.Training.CrateTraining.benefitPotty, icon: "drop.fill")
                    InfoListRow.benefit(Strings.Training.CrateTraining.benefitSelfSoothe, icon: "moon.zzz.fill")
                    InfoListRow.benefit(Strings.Training.CrateTraining.benefitSeparation, icon: "heart.fill")
                    InfoListRow.benefit(Strings.Training.CrateTraining.benefitSafeSpace, icon: "shield.fill")
                    InfoListRow.benefit(Strings.Training.CrateTraining.benefitLongerNaps, icon: "clock.fill")
                }
                .padding(.horizontal)
            }

            Divider()
                .padding(.horizontal)

            // Tips section
            VStack(alignment: .leading, spacing: 10) {
                Label(Strings.Training.CrateTraining.tipsTitle, systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    InfoListRow.bullet(Strings.Training.CrateTraining.tipCozy, color: .indigo)
                    InfoListRow.bullet(Strings.Training.CrateTraining.tipMeals, color: .indigo)
                    InfoListRow.bullet(Strings.Training.CrateTraining.tipTired, color: .indigo)
                    InfoListRow.bullet(Strings.Training.CrateTraining.tipStayClose, color: .indigo)
                    InfoListRow.bullet(Strings.Training.CrateTraining.tipNoCrying, color: .indigo)
                    InfoListRow.bullet(Strings.Training.CrateTraining.tipShortFirst, color: .indigo)
                }
                .padding(.horizontal)
            }

            // Encouragement
            Text(Strings.Training.CrateTraining.encouragement)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    private var statsCard: some View {
        HStack(spacing: 16) {
            // Crate icon
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "house.fill")
                    .font(.title3)
                    .foregroundStyle(.indigo)
            }

            VStack(alignment: .leading, spacing: 2) {
                if crateNapStats.total > 0 {
                    Text(Strings.Training.CrateTraining.crateNapPercentage(crateNapStats.percentage))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.indigo.opacity(0.15))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.indigo)
                                .frame(width: geometry.size.width * CGFloat(crateNapStats.percentage) / 100, height: 6)
                        }
                    }
                    .frame(height: 6)
                } else {
                    Text(Strings.Training.CrateTraining.noNapsYet)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CrateTrainingSection(eventStore: EventStore())
        }
        .padding()
    }
}
