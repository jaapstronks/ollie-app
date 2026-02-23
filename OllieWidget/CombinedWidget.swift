//
//  CombinedWidget.swift
//  OllieWidget
//
//  Combined widget showing potty timer and streak together

import WidgetKit
import OllieShared
import SwiftUI

// MARK: - Timeline Provider

struct CombinedProvider: TimelineProvider {
    func placeholder(in context: Context) -> CombinedEntry {
        CombinedEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CombinedEntry) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let entry = CombinedEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CombinedEntry>) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let currentDate = Date()
        var entries: [CombinedEntry] = []

        // Create entries for next hour, updating every 5 minutes
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = CombinedEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct CombinedEntry: TimelineEntry {
    let date: Date
    let data: WidgetData

    var minutesSinceLastPlas: Int {
        guard let lastPlasTime = data.lastPlasTime else { return 0 }
        return Int(date.timeIntervalSince(lastPlasTime) / 60)
    }
}

// MARK: - Widget Views

struct CombinedWidgetEntryView: View {
    var entry: CombinedProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        default:
            mediumWidget
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 0) {
            // Left side: Potty timer
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(pottyIconBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: "drop.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(pottyIconColor)
                }

                Text(timeText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(String(localized: "since potty"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(.primary.opacity(0.12))
                .frame(width: 1)
                .padding(.vertical, 16)

            // Right side: Streak
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(streakIconBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: streakIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(streakIconColor)
                }

                Text("\(entry.data.currentStreak)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(String(localized: "outdoor streak"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(spacing: 16) {
            // Header with puppy name
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(entry.data.puppyName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text(String(localized: "today"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.primary.opacity(0.06), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Main stats row
            HStack(spacing: 0) {
                // Potty timer
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(pottyIconBackground)
                            .frame(width: 56, height: 56)

                        Image(systemName: "drop.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(pottyIconColor)
                    }

                    Text(timeText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(String(localized: "since potty"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Streak
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(streakIconBackground)
                            .frame(width: 56, height: 56)

                        Image(systemName: streakIcon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(streakIconColor)
                    }

                    Text("\(entry.data.currentStreak)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(String(localized: "outdoor streak"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Today's summary cards
            HStack(spacing: 12) {
                StatCard(value: entry.data.todayPottyCount, label: String(localized: "potty"), icon: "drop.fill")
                StatCard(value: entry.data.todayOutdoorCount, label: String(localized: "outdoor"), icon: "leaf.fill")
                StatCard(value: entry.data.bestStreak, label: String(localized: "record"), icon: "trophy.fill")
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)

            // Warning message if needed
            if entry.minutesSinceLastPlas > 90 {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 12))
                    Text(String(localized: "Time for a potty break!"))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.15), in: Capsule())
                .padding(.bottom, 12)
            }
        }
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Helpers

    private var timeText: String {
        let minutes = entry.minutesSinceLastPlas
        if minutes == 0 {
            return "-- min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
    }

    private var streakIcon: String {
        let streak = entry.data.currentStreak
        if streak == 0 {
            return "xmark.circle.fill"
        } else if streak < 3 {
            return "star.fill"
        } else if streak < 10 {
            return "flame.fill"
        } else {
            return "trophy.fill"
        }
    }

    private var streakIconColor: Color {
        let streak = entry.data.currentStreak
        let isDark = colorScheme == .dark

        if streak == 0 {
            return isDark
                ? Color(red: 0.90, green: 0.55, blue: 0.55)
                : Color(red: 0.70, green: 0.35, blue: 0.35)
        } else if streak < 3 {
            return isDark
                ? Color(red: 0.50, green: 0.85, blue: 0.65)
                : Color(red: 0.30, green: 0.60, blue: 0.45)
        } else if streak < 10 {
            return isDark
                ? Color(red: 1.0, green: 0.70, blue: 0.30)
                : Color(red: 0.90, green: 0.55, blue: 0.15)
        } else {
            return isDark
                ? Color(red: 1.0, green: 0.80, blue: 0.25)
                : Color(red: 0.85, green: 0.65, blue: 0.10)
        }
    }

    private var streakIconBackground: Color {
        let streak = entry.data.currentStreak
        let isDark = colorScheme == .dark

        if streak == 0 {
            return isDark
                ? Color(red: 0.45, green: 0.25, blue: 0.25).opacity(0.7)
                : Color(red: 0.90, green: 0.80, blue: 0.80).opacity(0.6)
        } else if streak < 3 {
            return isDark
                ? Color(red: 0.20, green: 0.40, blue: 0.30).opacity(0.7)
                : Color(red: 0.75, green: 0.90, blue: 0.82).opacity(0.6)
        } else if streak < 10 {
            return isDark
                ? Color(red: 0.50, green: 0.40, blue: 0.18).opacity(0.7)
                : Color(red: 1.0, green: 0.88, blue: 0.70).opacity(0.6)
        } else {
            return isDark
                ? Color(red: 0.50, green: 0.45, blue: 0.15).opacity(0.7)
                : Color(red: 1.0, green: 0.92, blue: 0.60).opacity(0.6)
        }
    }

    private var pottyIconColor: Color {
        let minutes = entry.minutesSinceLastPlas
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark
                ? Color(red: 1.0, green: 0.55, blue: 0.50)
                : Color(red: 0.85, green: 0.30, blue: 0.25)
        } else if minutes > 90 {
            return isDark
                ? Color(red: 1.0, green: 0.75, blue: 0.30)
                : Color(red: 0.90, green: 0.60, blue: 0.10)
        } else {
            return isDark
                ? Color(red: 0.45, green: 0.85, blue: 0.65)
                : Color(red: 0.25, green: 0.65, blue: 0.45)
        }
    }

    private var pottyIconBackground: Color {
        let minutes = entry.minutesSinceLastPlas
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark
                ? Color(red: 0.55, green: 0.25, blue: 0.22).opacity(0.7)
                : Color(red: 0.95, green: 0.75, blue: 0.70).opacity(0.6)
        } else if minutes > 90 {
            return isDark
                ? Color(red: 0.55, green: 0.45, blue: 0.20).opacity(0.7)
                : Color(red: 1.0, green: 0.88, blue: 0.65).opacity(0.6)
        } else {
            return isDark
                ? Color(red: 0.20, green: 0.45, blue: 0.35).opacity(0.7)
                : Color(red: 0.70, green: 0.88, blue: 0.78).opacity(0.6)
        }
    }

    private var backgroundGradient: LinearGradient {
        let minutes = entry.minutesSinceLastPlas
        let isDark = colorScheme == .dark

        if minutes > 120 {
            // Urgent - red/coral
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.35, green: 0.15, blue: 0.15), Color(red: 0.40, green: 0.18, blue: 0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.98, green: 0.92, blue: 0.90), Color(red: 0.95, green: 0.85, blue: 0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else if minutes > 90 {
            // Warning - amber
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.35, green: 0.28, blue: 0.12), Color(red: 0.38, green: 0.30, blue: 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 1.0, green: 0.96, blue: 0.88), Color(red: 1.0, green: 0.92, blue: 0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            // Good - mint/sage
            if isDark {
                return LinearGradient(
                    colors: [Color(red: 0.12, green: 0.22, blue: 0.18), Color(red: 0.14, green: 0.25, blue: 0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.92, green: 0.97, blue: 0.94), Color(red: 0.85, green: 0.94, blue: 0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Stat Card Component

private struct StatCard: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Widget Configuration

struct CombinedWidget: Widget {
    let kind: String = "CombinedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CombinedProvider()) { entry in
            CombinedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Ollie Overview"))
        .description(String(localized: "Potty timer and streak in one widget."))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    CombinedWidget()
} timeline: {
    CombinedEntry(date: .now, data: .placeholder)
    CombinedEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-95 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 7,
        bestStreak: 15,
        todayPottyCount: 6,
        todayOutdoorCount: 5,
        isCurrentlySleeping: false,
        sleepStartTime: nil,
        lastMealTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledMealTime: Date().addingTimeInterval(1 * 60 * 60),
        mealsLoggedToday: 2,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-1 * 60 * 60),
        nextScheduledWalkTime: Date().addingTimeInterval(30 * 60),
        puppyName: "Ollie",
        lastUpdated: Date()
    ))
}

#Preview(as: .systemLarge) {
    CombinedWidget()
} timeline: {
    CombinedEntry(date: .now, data: .placeholder)
}
