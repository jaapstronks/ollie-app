//
//  StatusDashboardComponents.swift
//  OllieWidget
//
//  Reusable view components for the status dashboard widget
//

import SwiftUI
import WidgetKit
import OtisShared

// MARK: - Sleep Indicator

struct SleepIndicatorView: View {
    let minutesSinceSleepStart: Int
    let minutesSinceLastPlas: Int
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(WidgetColorPalette.sleepIconBackground(colorScheme: colorScheme))
                    .frame(width: 44, height: 44)

                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(WidgetColorPalette.sleepIconColor(colorScheme: colorScheme))
            }

            Text(DurationFormatter.format(minutesSinceSleepStart, style: .compact, showZeroAsEmpty: true))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "sleeping"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            // Potty warning while sleeping
            if minutesSinceLastPlas > 90 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                    Text(DurationFormatter.format(minutesSinceLastPlas, style: .compact, showZeroAsEmpty: true))
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(WidgetColorPalette.pottyUrgencyColor(minutes: minutesSinceLastPlas, colorScheme: colorScheme))
                .padding(.top, 2)
            }
        }
    }
}

struct SleepIndicatorLargeView: View {
    let minutesSinceSleepStart: Int
    let minutesSinceLastPlas: Int
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 16) {
            // Sleep duration
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(WidgetColorPalette.sleepIconBackground(colorScheme: colorScheme))
                        .frame(width: 64, height: 64)

                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(WidgetColorPalette.sleepIconColor(colorScheme: colorScheme))
                }

                Text(DurationFormatter.format(minutesSinceSleepStart, style: .compact, showZeroAsEmpty: true))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(String(localized: "asleep"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Potty alert if overdue while sleeping
            if minutesSinceLastPlas > 90 {
                let urgencyColor = WidgetColorPalette.pottyUrgencyColor(minutes: minutesSinceLastPlas, colorScheme: colorScheme)
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text(String(localized: "Potty break needed when awake"))
                        .font(.system(size: 12, weight: .semibold))
                    Text("(\(DurationFormatter.format(minutesSinceLastPlas, style: .compact, showZeroAsEmpty: true)))")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(urgencyColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(urgencyColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Potty Timer

struct PottyTimerView: View {
    let minutesSinceLastPlas: Int
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(WidgetColorPalette.pottyIconBackground(minutes: minutesSinceLastPlas, colorScheme: colorScheme))
                    .frame(width: 44, height: 44)

                Image(systemName: "drop.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(WidgetColorPalette.pottyIconColor(minutes: minutesSinceLastPlas, colorScheme: colorScheme))
            }

            Text(DurationFormatter.format(minutesSinceLastPlas, style: .compact, showZeroAsEmpty: true))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "since potty"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

struct PottyTimerLargeView: View {
    let minutesSinceLastPlas: Int
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(WidgetColorPalette.pottyIconBackground(minutes: minutesSinceLastPlas, colorScheme: colorScheme))
                    .frame(width: 52, height: 52)

                Image(systemName: "drop.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(WidgetColorPalette.pottyIconColor(minutes: minutesSinceLastPlas, colorScheme: colorScheme))
            }

            Text(DurationFormatter.format(minutesSinceLastPlas, style: .compact, showZeroAsEmpty: true))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "since potty"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Streak Display

struct StreakDisplayView: View {
    let streak: Int
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(WidgetColorPalette.streakIconBackground(streak: streak, colorScheme: colorScheme))
                    .frame(width: 52, height: 52)

                Image(systemName: WidgetColorPalette.streakIcon(streak: streak))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(WidgetColorPalette.streakIconColor(streak: streak, colorScheme: colorScheme))
            }

            Text("\(streak)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "streak"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Meal Status

struct MealStatusView: View {
    let minutesUntilNextMeal: Int?
    let isMealOverdue: Bool
    let mealsLoggedToday: Int
    let mealsExpectedToday: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "fork.knife")
                .font(.system(size: 12))
                .foregroundStyle(WidgetColorPalette.mealStatusColor(isOverdue: isMealOverdue))

            if let mins = minutesUntilNextMeal {
                Text(String(localized: "in \(DurationFormatter.format(mins, style: .compact, showZeroAsEmpty: true))"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            } else if isMealOverdue {
                Text(String(localized: "overdue"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            } else {
                Text("\(mealsLoggedToday)/\(mealsExpectedToday)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CompactMealStatusView: View {
    let mealsLoggedToday: Int
    let mealsExpectedToday: Int
    let isOverdue: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "fork.knife")
                .font(.system(size: 10))
            Text("\(mealsLoggedToday)/\(mealsExpectedToday)")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(WidgetColorPalette.mealStatusColor(isOverdue: isOverdue))
    }
}

struct MealCardView: View {
    let minutesUntilNextMeal: Int?
    let isMealOverdue: Bool
    let mealsLoggedToday: Int
    let mealsExpectedToday: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetColorPalette.mealStatusColor(isOverdue: isMealOverdue))

                if let mins = minutesUntilNextMeal {
                    Text(String(localized: "in \(DurationFormatter.format(mins, style: .compact, showZeroAsEmpty: true))"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                } else if isMealOverdue {
                    Text(String(localized: "Overdue"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text(String(localized: "Done"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.green)
                }
            }

            Text("\(mealsLoggedToday)/\(mealsExpectedToday) \(String(localized: "meals"))")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Walk Status

struct WalkStatusView: View {
    let minutesUntilNextWalk: Int?
    let isWalkOverdue: Bool
    let minutesSinceLastWalk: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.walk")
                .font(.system(size: 12))
                .foregroundStyle(WidgetColorPalette.walkStatusColor(isOverdue: isWalkOverdue))

            if let mins = minutesUntilNextWalk {
                Text(String(localized: "in \(DurationFormatter.format(mins, style: .compact, showZeroAsEmpty: true))"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            } else if isWalkOverdue {
                Text(String(localized: "overdue"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            } else {
                Text(DurationFormatter.format(minutesSinceLastWalk, style: .compact, showZeroAsEmpty: true) + " " + String(localized: "ago"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CompactWalkStatusView: View {
    let minutesSinceLastWalk: Int
    let isOverdue: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.walk")
                .font(.system(size: 10))
            if minutesSinceLastWalk > 0 {
                Text(DurationFormatter.format(minutesSinceLastWalk, style: .compact, showZeroAsEmpty: true))
                    .font(.system(size: 10, weight: .medium))
            } else {
                Text("--")
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .foregroundStyle(WidgetColorPalette.walkStatusColor(isOverdue: isOverdue))
    }
}

struct WalkCardView: View {
    let minutesUntilNextWalk: Int?
    let isWalkOverdue: Bool
    let minutesSinceLastWalk: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetColorPalette.walkStatusColor(isOverdue: isWalkOverdue))

                if let mins = minutesUntilNextWalk {
                    Text(String(localized: "in \(DurationFormatter.format(mins, style: .compact, showZeroAsEmpty: true))"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                } else if isWalkOverdue {
                    Text(String(localized: "Overdue"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text(DurationFormatter.format(minutesSinceLastWalk, style: .compact, showZeroAsEmpty: true) + " " + String(localized: "ago"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }

            Text(String(localized: "last walk"))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}
