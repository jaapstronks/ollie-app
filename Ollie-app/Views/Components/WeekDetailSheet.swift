//
//  WeekDetailSheet.swift
//  Ollie-app
//
//  Detailed view of socialization progress for a specific week

import SwiftUI
import OllieShared

/// Category progress for the week detail view
struct CategoryWeekProgress: Identifiable {
    let id: String
    let category: SocializationCategory
    let count: Int
    let total: Int
}

/// Sheet showing detailed breakdown of a week's socialization progress
struct WeekDetailSheet: View {
    let weekProgress: WeeklyProgress
    let categoryProgress: [CategoryWeekProgress]
    let focusSuggestions: [String]
    let onLogExposure: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Week summary header
                    summaryHeader

                    // Category breakdown
                    categoryBreakdown

                    // Focus suggestions
                    if !focusSuggestions.isEmpty {
                        suggestionsSection
                    }

                    // Log exposure button
                    Button {
                        onLogExposure()
                        dismiss()
                    } label: {
                        Label(Strings.Socialization.logExposure, systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ollieAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(Strings.Health.weekNumber(weekProgress.weekNumber))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Summary Header

    @ViewBuilder
    private var summaryHeader: some View {
        VStack(spacing: 16) {
            // Date range
            HStack {
                Text(weekProgress.startDate, style: .date)
                Text("–")
                Text(weekProgress.endDate, style: .date)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Stats grid
            HStack(spacing: 24) {
                statItem(
                    value: "\(weekProgress.exposureCount)",
                    label: Strings.ThisWeek.exposures,
                    icon: "sparkles"
                )

                statItem(
                    value: "\(weekProgress.categoriesWithExposures)/\(weekProgress.totalCategories)",
                    label: Strings.ThisWeek.categories,
                    icon: "square.grid.2x2"
                )

                statItem(
                    value: "\(Int(weekProgress.positiveReactionRate * 100))%",
                    label: Strings.WeekDetail.positiveRate,
                    icon: "heart.fill"
                )
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Strings.WeekDetail.weeklyGoal)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(weekProgress.isComplete ? Strings.Socialization.complete : Strings.WeekDetail.inProgress)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(weekProgress.isComplete ? Color.ollieSuccess : Color.ollieAccent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(weekProgress.isComplete ? Color.ollieSuccess : Color.ollieAccent)
                            .frame(width: geo.size.width * weekProgress.overallProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .glassCard(tint: .accent)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.ollieAccent)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Category Breakdown

    @ViewBuilder
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.WeekDetail.categoryBreakdown)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(categoryProgress.sorted(by: { $0.category.localizedDisplayName < $1.category.localizedDisplayName })) { progress in
                    categoryRow(category: progress.category, count: progress.count, total: progress.total)
                }
            }
            .padding()
            .glassCard(tint: .accent)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func categoryRow(category: SocializationCategory, count: Int, total: Int) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: category.icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Category name
            Text(category.localizedDisplayName)
                .font(.subheadline)

            Spacer()

            // Progress
            HStack(spacing: 8) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressColor(count: count, total: total))
                            .frame(width: geo.size.width * min(1.0, Double(count) / Double(max(1, total))), height: 4)
                    }
                }
                .frame(width: 60, height: 4)

                // Count
                Text("\(count)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)

                // Status indicator
                if count >= total {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ollieSuccess)
                } else if count == 0 {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ollieWarning)
                }
            }
        }
    }

    private func progressColor(count: Int, total: Int) -> Color {
        let progress = Double(count) / Double(max(1, total))
        if progress >= 1.0 {
            return .ollieSuccess
        } else if progress >= 0.5 {
            return .ollieAccent
        } else if count > 0 {
            return .ollieInfo
        } else {
            return .ollieWarning
        }
    }

    // MARK: - Suggestions

    @ViewBuilder
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(Strings.ThisWeek.focusOn)
                    .font(.headline)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(focusSuggestions, id: \.self) { suggestion in
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle")
                            .font(.caption)
                            .foregroundStyle(Color.ollieAccent)

                        Text(suggestion)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .glassCard(tint: .accent)
            .padding(.horizontal)
        }
    }
}

// MARK: - Strings Extension

extension Strings {
    enum WeekDetail {
        static let positiveRate = String(localized: "positive")
        static let weeklyGoal = String(localized: "Weekly Goal")
        static let inProgress = String(localized: "In progress")
        static let categoryBreakdown = String(localized: "Category Breakdown")
    }
}

// MARK: - Preview

#Preview {
    let start = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
    let end = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

    let weekProgress = WeeklyProgress(
        weekNumber: 10,
        startDate: start,
        endDate: end,
        exposureCount: 35,
        categoriesWithExposures: 6,
        positiveReactionRate: 0.85,
        totalCategories: 9
    )

    let categories: [CategoryWeekProgress] = []

    return WeekDetailSheet(
        weekProgress: weekProgress,
        categoryProgress: categories,
        focusSuggestions: ["Vehicles: trucks, motorcycles", "Environments: pet store, outdoor café"],
        onLogExposure: {}
    )
}
