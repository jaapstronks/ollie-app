//
//  SocializationWeekTimeline.swift
//  Ollie-app
//
//  Week-by-week progress timeline for the socialization window

import SwiftUI
import OllieShared

/// Horizontal timeline showing week-by-week socialization progress
struct SocializationWeekTimeline: View {
    let weeklyProgress: [WeeklyProgress]
    let currentWeek: Int
    let onWeekTap: ((Int) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(
        weeklyProgress: [WeeklyProgress],
        currentWeek: Int,
        onWeekTap: ((Int) -> Void)? = nil
    ) {
        self.weeklyProgress = weeklyProgress
        self.currentWeek = currentWeek
        self.onWeekTap = onWeekTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(Strings.Socialization.socializationWindowTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Weeks remaining badge
                if let weeksRemaining = weeksRemaining, weeksRemaining > 0 {
                    Text(Strings.Socialization.weeksRemaining(weeksRemaining))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .clipShape(Capsule())
                }
            }

            // Week timeline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(weeklyProgress) { week in
                        WeekProgressNode(
                            week: week,
                            isCurrent: week.weekNumber == currentWeek,
                            onTap: onWeekTap != nil ? { onWeekTap?(week.weekNumber) } : nil
                        )
                    }
                }
                .padding(.horizontal, 4)
            }

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .ollieSuccess, label: Strings.Socialization.complete)
                legendItem(color: .ollieAccent, label: Strings.Socialization.current)
                legendItem(color: .secondary.opacity(0.3), label: Strings.Socialization.upcoming)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .glassCard(tint: .accent)
    }

    private var weeksRemaining: Int? {
        guard currentWeek <= SocializationWindow.endWeek else { return nil }
        return SocializationWindow.endWeek - currentWeek
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Week Progress Node

struct WeekProgressNode: View {
    let week: WeeklyProgress
    let isCurrent: Bool
    let onTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.light()
            onTap?()
        } label: {
            VStack(spacing: 4) {
                // Week number
                Text("\(week.weekNumber)")
                    .font(.caption2)
                    .fontWeight(isCurrent ? .bold : .regular)
                    .foregroundStyle(isCurrent ? .primary : .secondary)

                // Progress circle
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(backgroundColor, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    // Progress ring
                    if week.exposureCount > 0 {
                        Circle()
                            .trim(from: 0, to: week.overallProgress)
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                    }

                    // Center indicator
                    if week.isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.ollieSuccess)
                            .clipShape(Circle())
                    } else if isCurrent {
                        Circle()
                            .fill(Color.ollieAccent)
                            .frame(width: 12, height: 12)
                    } else if week.isPast && week.exposureCount == 0 {
                        // Missed week indicator
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.ollieWarning)
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                // Exposure count (only if has exposures)
                if week.exposureCount > 0 {
                    Text("\(week.exposureCount)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                } else {
                    Text(" ")
                        .font(.system(size: 9))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var backgroundColor: Color {
        if week.isComplete {
            return .ollieSuccess
        } else if isCurrent {
            return .ollieAccent
        } else if week.isPast {
            return week.exposureCount > 0 ? .ollieInfo.opacity(0.5) : .ollieWarning.opacity(0.3)
        } else {
            return .secondary.opacity(0.2)
        }
    }

    private var progressColor: Color {
        if week.isComplete {
            return .ollieSuccess
        } else if isCurrent {
            return .ollieAccent
        } else {
            return .ollieInfo
        }
    }
}

// MARK: - Compact Timeline (for ThisWeekCard)

struct SocializationWeekTimelineCompact: View {
    let weeklyProgress: [WeeklyProgress]
    let currentWeek: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(weeklyProgress) { week in
                CompactWeekDot(
                    isComplete: week.isComplete,
                    isCurrent: week.weekNumber == currentWeek,
                    hasProgress: week.exposureCount > 0,
                    isPast: week.isPast
                )
            }
        }
    }
}

struct CompactWeekDot: View {
    let isComplete: Bool
    let isCurrent: Bool
    let hasProgress: Bool
    let isPast: Bool

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: isCurrent ? 10 : 6, height: isCurrent ? 10 : 6)
            .overlay {
                if isCurrent {
                    Circle()
                        .stroke(Color.ollieAccent, lineWidth: 2)
                        .frame(width: 14, height: 14)
                }
            }
    }

    private var dotColor: Color {
        if isComplete {
            return .ollieSuccess
        } else if isCurrent {
            return .ollieAccent
        } else if isPast {
            return hasProgress ? .ollieInfo.opacity(0.5) : .ollieWarning.opacity(0.3)
        } else {
            return .secondary.opacity(0.2)
        }
    }
}

// MARK: - Preview

#Preview {
    let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -10, to: Date())!

    // Create sample weekly progress
    let weeklyProgress = SocializationWindow.allWeeks.map { weekNumber -> WeeklyProgress in
        let start = Calendar.current.date(byAdding: .weekOfYear, value: weekNumber, to: birthDate)!
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!

        var exposures = 0
        var positiveRate = 0.0

        if weekNumber < 10 {
            exposures = Int.random(in: 30...50)
            positiveRate = Double.random(in: 0.7...0.95)
        } else if weekNumber == 10 {
            exposures = Int.random(in: 15...25)
            positiveRate = Double.random(in: 0.6...0.85)
        }

        return WeeklyProgress(
            weekNumber: weekNumber,
            startDate: start,
            endDate: end,
            exposureCount: exposures,
            categoriesWithExposures: exposures > 0 ? Int.random(in: 4...7) : 0,
            positiveReactionRate: positiveRate,
            totalCategories: 7
        )
    }

    ScrollView {
        VStack(spacing: 20) {
            SocializationWeekTimeline(
                weeklyProgress: weeklyProgress,
                currentWeek: 10
            )

            SocializationWeekTimelineCompact(
                weeklyProgress: weeklyProgress,
                currentWeek: 10
            )
            .padding()
        }
        .padding()
    }
}
