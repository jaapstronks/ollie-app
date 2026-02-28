//
//  ThisWeekCard.swift
//  Ollie-app
//
//  "This Week" summary card for Today view

import SwiftUI
import OllieShared

/// Card showing this week's focus: socialization progress and upcoming milestones
struct ThisWeekCard: View {
    @ObservedObject var viewModel: ThisWeekViewModel
    var onNavigateToInsights: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if viewModel.shouldShowCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header (tappable to navigate to Insights)
                Button {
                    Analytics.track(.thisWeekCardTapped)
                    onNavigateToInsights?()
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(Color.ollieAccent)
                        Text(Strings.ThisWeek.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Spacer()

                        // Age badge
                        Text(Strings.Health.weekNumber(viewModel.ageInWeeks))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())

                        // Navigation indicator
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                // Socialization mini-progress (if in window)
                if viewModel.showSocialization {
                    socializationSection
                }

                // Upcoming milestones
                if !viewModel.upcomingMilestones.isEmpty {
                    milestonesSection
                }
            }
            .padding()
            .glassCard(tint: .accent)
            .onAppear {
                Analytics.track(.thisWeekCardViewed)
            }
        }
    }

    // MARK: - Socialization Section

    @ViewBuilder
    private var socializationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Window status
            HStack(spacing: 8) {
                if viewModel.inSocializationWindow {
                    // Active window indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.ollieSuccess)
                            .frame(width: 6, height: 6)
                        Text(Strings.ThisWeek.socializationActive)
                            .font(.caption)
                            .foregroundStyle(Color.ollieSuccess)
                    }

                    if let weeks = viewModel.weeksRemaining {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(Strings.Socialization.weeksRemaining(weeks))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if viewModel.socializationWindowClosed {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.caption)
                        Text(Strings.ThisWeek.windowEnded)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // This week's progress
            if let progress = viewModel.currentWeekProgress {
                HStack(spacing: 16) {
                    // Exposure count
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(progress.exposureCount)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(Strings.ThisWeek.exposures)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Categories covered
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(progress.categoriesWithExposures)/\(progress.totalCategories)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(Strings.ThisWeek.categories)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Mini progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                            .frame(width: 40, height: 40)

                        Circle()
                            .trim(from: 0, to: progress.overallProgress)
                            .stroke(Color.ollieAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(progress.overallProgress * 100))%")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
            }

            // Focus categories
            if !viewModel.focusCategories.isEmpty && viewModel.inSocializationWindow {
                HStack(spacing: 4) {
                    Text(Strings.ThisWeek.focusOn)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.focusCategories, id: \.id) { category in
                        Text(category.localizedDisplayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.1 : 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Milestones Section

    @ViewBuilder
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.ThisWeek.upcoming)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            ForEach(viewModel.upcomingMilestones.prefix(2)) { milestone in
                HStack(spacing: 10) {
                    // Icon
                    Image(systemName: milestone.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ollieAccent)
                        .frame(width: 24, height: 24)
                        .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .clipShape(Circle())

                    // Label
                    Text(milestone.localizedLabel)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    // Days until
                    if let days = milestone.daysUntil(birthDate: viewModel.birthDate) {
                        if days == 0 {
                            Text(Strings.Health.today)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.ollieAccent)
                        } else if days < 0 {
                            Text(Strings.Health.daysAgo(abs(days)))
                                .font(.caption)
                                .foregroundStyle(Color.ollieWarning)
                        } else {
                            Text(Strings.Health.inDays(days))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let profileStore = ProfileStore()
    let milestoneStore = MilestoneStore()
    let socializationStore = SocializationStore()

    let viewModel = ThisWeekViewModel(
        profileStore: profileStore,
        milestoneStore: milestoneStore,
        socializationStore: socializationStore
    )

    return VStack {
        ThisWeekCard(viewModel: viewModel) {
            print("Navigate to Insights")
        }
    }
    .padding()
}
