//
//  VisualTimelineView.swift
//  Ollie-app
//
//  Container view for the visual timeline mode

import SwiftUI
import OllieShared

/// Container view for the visual timeline display
struct VisualTimelineView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @State private var selectedBlock: ActivityBlock?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary stats row
                TimelineSummaryRow(
                    summary: viewModel.activityBlockSummary,
                    onStatTap: { statType in
                        // Could filter timeline or show detail
                        HapticFeedback.selection()
                    }
                )

                // Timeline bar
                TimelineBarView(
                    blocks: viewModel.activityBlocks,
                    startTime: viewModel.timelineStartTime,
                    endTime: viewModel.timelineEndTime,
                    isToday: Calendar.current.isDateInToday(viewModel.currentDate),
                    onBlockTap: { block in
                        HapticFeedback.selection()
                        selectedBlock = block
                    }
                )

                // Legend
                legendView

                // Quick stats cards
                if !viewModel.activityBlocks.isEmpty {
                    quickStatsSection
                }

                // Empty state
                if viewModel.activityBlocks.isEmpty {
                    emptyStateView
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedBlock) { block in
            TimelineBlockDetailView(
                block: block,
                events: viewModel.events
            )
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: .ollieSleep, label: Strings.VisualTimeline.legendSleep)
            legendItem(color: .ollieSuccess, label: Strings.VisualTimeline.legendWalk)
            legendItem(color: .ollieSuccess, label: Strings.VisualTimeline.legendPotty, shape: .tick)
            legendItem(color: .ollieAccent, label: Strings.VisualTimeline.legendMeal, shape: .dot)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }

    private enum LegendShape {
        case bar
        case tick
        case dot
    }

    private func legendItem(color: Color, label: String, shape: LegendShape = .bar) -> some View {
        HStack(spacing: 4) {
            switch shape {
            case .bar:
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 16, height: 8)
            case .tick:
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: 10)
            case .dot:
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }

            Text(label)
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Sleep insight card
                if viewModel.activityBlockSummary.totalSleepMinutes > 0 {
                    insightCard(
                        icon: "moon.zzz.fill",
                        color: .ollieSleep,
                        title: Strings.VisualTimeline.sleepToday,
                        value: viewModel.activityBlockSummary.sleepString
                    )
                }

                // Walk insight card
                if viewModel.activityBlockSummary.walkCount > 0 {
                    insightCard(
                        icon: "figure.walk",
                        color: .ollieSuccess,
                        title: Strings.VisualTimeline.walksToday,
                        value: "\(viewModel.activityBlockSummary.walkCount)"
                    )
                }
            }

            // Potty success card (only show if there were potty events)
            if viewModel.activityBlockSummary.totalPottyCount > 0 {
                pottySuccessCard
            }
        }
        .padding(.horizontal)
    }

    private func insightCard(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                .fill(cardBackground)
        )
    }

    private var pottySuccessCard: some View {
        HStack(spacing: 12) {
            // Success indicator
            ZStack {
                Circle()
                    .fill(pottySuccessColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: pottySuccessIcon)
                    .font(.title3)
                    .foregroundStyle(pottySuccessColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.VisualTimeline.pottyScore)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text("\(viewModel.activityBlockSummary.outdoorPottyCount)")
                        .font(.headline)
                        .foregroundStyle(Color.ollieSuccess)

                    Text(Strings.VisualTimeline.outdoor)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if viewModel.activityBlockSummary.indoorPottyCount > 0 {
                        Text("/")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(viewModel.activityBlockSummary.indoorPottyCount)")
                            .font(.headline)
                            .foregroundStyle(Color.ollieDanger)

                        Text(Strings.VisualTimeline.indoor)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Percentage
            if viewModel.activityBlockSummary.totalPottyCount > 1 {
                Text("\(Int(viewModel.activityBlockSummary.pottySuccessRate * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(pottySuccessColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                .fill(cardBackground)
        )
    }

    private var pottySuccessColor: Color {
        let rate = viewModel.activityBlockSummary.pottySuccessRate
        if rate >= 1.0 {
            return .ollieSuccess
        } else if rate >= 0.8 {
            return .ollieWarning
        } else {
            return .ollieDanger
        }
    }

    private var pottySuccessIcon: String {
        let rate = viewModel.activityBlockSummary.pottySuccessRate
        if rate >= 1.0 {
            return "checkmark.circle.fill"
        } else if rate >= 0.8 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(Strings.VisualTimeline.noActivity)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(Strings.VisualTimeline.noActivityHint)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Helpers

    private var cardBackground: Color {
        colorScheme == .dark ? Color.ollieCardDark : Color.ollieCardLight
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return NavigationStack {
        VisualTimelineView(viewModel: viewModel)
    }
}
