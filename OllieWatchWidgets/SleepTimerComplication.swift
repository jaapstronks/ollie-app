//
//  SleepTimerComplication.swift
//  OllieWatchWidgets
//
//  Watch complication showing sleep/awake timer with state indicator

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct SleepTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepTimerEntry {
        SleepTimerEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepTimerEntry) -> Void) {
        let data = WatchWidgetDataReader.read() ?? .placeholder
        let entry = SleepTimerEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepTimerEntry>) -> Void) {
        let data = WatchWidgetDataReader.read() ?? .placeholder
        let currentDate = Date()
        var entries: [SleepTimerEntry] = []

        // Create entries every minute for the next 15 minutes
        for minuteOffset in 0..<15 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SleepTimerEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        // Refresh timeline after 15 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct SleepTimerEntry: TimelineEntry {
    let date: Date
    let data: WatchWidgetData

    var isSleeping: Bool {
        data.isCurrentlySleeping
    }

    var minutesSinceSleep: Int {
        guard let sleepStart = data.sleepStartTime else { return 0 }
        return max(0, Int(date.timeIntervalSince(sleepStart) / 60))
    }

    var minutesSinceWake: Int {
        guard let wakeTime = data.lastWakeTime else { return 0 }
        return max(0, Int(date.timeIntervalSince(wakeTime) / 60))
    }

    var sleepState: SleepState {
        if isSleeping {
            return .sleeping(minutes: minutesSinceSleep)
        } else if data.lastWakeTime != nil {
            return .awake(minutes: minutesSinceWake)
        } else {
            return .unknown
        }
    }
}

// MARK: - Sleep State

enum SleepState {
    case sleeping(minutes: Int)
    case awake(minutes: Int)
    case unknown

    var color: Color {
        switch self {
        case .sleeping: return .purple
        case .awake: return .cyan
        case .unknown: return .gray
        }
    }

    var icon: String {
        switch self {
        case .sleeping: return "moon.zzz.fill"
        case .awake: return "sun.max.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var label: String {
        switch self {
        case .sleeping: return "sleeping"
        case .awake: return "awake"
        case .unknown: return "unknown"
        }
    }

    var minutes: Int {
        switch self {
        case .sleeping(let m), .awake(let m): return m
        case .unknown: return 0
        }
    }

    /// Gauge value for circular complication (normalized 0-1)
    /// For sleeping: fills up over 2 hours
    /// For awake: fills up over 4 hours
    var gaugeValue: Double {
        switch self {
        case .sleeping(let m):
            return min(1.0, Double(m) / 120.0)  // Full at 2 hours
        case .awake(let m):
            return min(1.0, Double(m) / 240.0)  // Full at 4 hours
        case .unknown:
            return 0.0
        }
    }
}

// MARK: - Complication Views

struct SleepTimerComplicationView: View {
    var entry: SleepTimerEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        case .accessoryCorner:
            cornerView
        default:
            circularView
        }
    }

    // MARK: - Circular Complication

    private var circularView: some View {
        ZStack {
            // Background gauge showing duration
            Gauge(value: entry.sleepState.gaugeValue) {
                EmptyView()
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(stateGradient)

            VStack(spacing: 0) {
                Image(systemName: entry.sleepState.icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(stateColor)
                Text(compactTimeText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(stateColor)
            }
        }
    }

    // MARK: - Rectangular Complication

    private var rectangularView: some View {
        HStack(spacing: 8) {
            // Left: Icon with state indicator
            ZStack {
                Circle()
                    .fill(stateColor.opacity(0.3))
                    .frame(width: 32, height: 32)

                Image(systemName: entry.sleepState.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(stateColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(timeText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(stateColor)

                Text(entry.sleepState.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Inline Complication

    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: entry.sleepState.icon)
            Text("\(timeText) \(entry.sleepState.label)")
        }
    }

    // MARK: - Corner Complication (watchOS specific)

    @ViewBuilder
    private var cornerView: some View {
        #if os(watchOS)
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 0) {
                Image(systemName: entry.sleepState.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(stateColor)
            }
        }
        .widgetLabel {
            ProgressView(value: entry.sleepState.gaugeValue) {
                Text(compactTimeText)
            }
            .tint(stateColor)
        }
        #else
        EmptyView()
        #endif
    }

    // MARK: - Helpers

    private var timeText: String {
        let minutes = entry.sleepState.minutes
        if minutes == 0 {
            return "--"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
    }

    private var compactTimeText: String {
        let minutes = entry.sleepState.minutes
        if minutes == 0 {
            return "--"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours):\(String(format: "%02d", mins))"
        }
    }

    private var stateColor: Color {
        if renderingMode == .fullColor {
            return entry.sleepState.color
        } else if renderingMode == .accented {
            return .accentColor
        } else {
            return .primary
        }
    }

    private var stateGradient: Gradient {
        if renderingMode == .fullColor {
            return Gradient(colors: [entry.sleepState.color, entry.sleepState.color.opacity(0.7)])
        } else if renderingMode == .accented {
            return Gradient(colors: [.accentColor, .accentColor.opacity(0.7)])
        } else {
            return Gradient(colors: [.primary, .primary.opacity(0.7)])
        }
    }
}

// MARK: - Widget Configuration

struct SleepTimerComplication: Widget {
    let kind: String = "SleepTimerComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepTimerProvider()) { entry in
            SleepTimerComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sleep Timer")
        .description("Shows sleep duration when sleeping, awake time when awake.")
        #if os(watchOS)
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
        #endif
    }
}

// MARK: - Previews

#if os(watchOS)
#Preview(as: .accessoryCircular) {
    SleepTimerComplication()
} timeline: {
    // Sleeping state
    SleepTimerEntry(date: .now, data: WatchWidgetData(
        lastPlasTime: Date().addingTimeInterval(-45 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 3,
        bestStreak: 12,
        todayPottyCount: 4,
        todayOutdoorCount: 3,
        isCurrentlySleeping: true,
        sleepStartTime: Date().addingTimeInterval(-75 * 60),
        lastWakeTime: nil,
        lastMealTime: nil,
        nextScheduledMealTime: nil,
        mealsLoggedToday: 0,
        mealsExpectedToday: 3,
        lastWalkTime: nil,
        nextScheduledWalkTime: nil,
        puppyName: "Ollie",
        lastUpdated: Date()
    ))
    // Awake state
    SleepTimerEntry(date: .now, data: WatchWidgetData(
        lastPlasTime: Date().addingTimeInterval(-45 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 3,
        bestStreak: 12,
        todayPottyCount: 4,
        todayOutdoorCount: 3,
        isCurrentlySleeping: false,
        sleepStartTime: nil,
        lastWakeTime: Date().addingTimeInterval(-90 * 60),
        lastMealTime: nil,
        nextScheduledMealTime: nil,
        mealsLoggedToday: 0,
        mealsExpectedToday: 3,
        lastWalkTime: nil,
        nextScheduledWalkTime: nil,
        puppyName: "Ollie",
        lastUpdated: Date()
    ))
}

#Preview(as: .accessoryRectangular) {
    SleepTimerComplication()
} timeline: {
    // Sleeping state
    SleepTimerEntry(date: .now, data: WatchWidgetData(
        lastPlasTime: Date().addingTimeInterval(-45 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 3,
        bestStreak: 12,
        todayPottyCount: 4,
        todayOutdoorCount: 3,
        isCurrentlySleeping: true,
        sleepStartTime: Date().addingTimeInterval(-45 * 60),
        lastWakeTime: nil,
        lastMealTime: nil,
        nextScheduledMealTime: nil,
        mealsLoggedToday: 0,
        mealsExpectedToday: 3,
        lastWalkTime: nil,
        nextScheduledWalkTime: nil,
        puppyName: "Ollie",
        lastUpdated: Date()
    ))
}

#Preview(as: .accessoryCorner) {
    SleepTimerComplication()
} timeline: {
    SleepTimerEntry(date: .now, data: .placeholder)
}

#Preview(as: .accessoryInline) {
    SleepTimerComplication()
} timeline: {
    SleepTimerEntry(date: .now, data: .placeholder)
}
#endif
