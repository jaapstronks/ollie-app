//
//  PottyTimerComplication.swift
//  OllieWatchWidgets
//
//  Watch complication showing time since last potty break with urgency indicator

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct PottyTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PottyTimerEntry {
        PottyTimerEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PottyTimerEntry) -> Void) {
        let data = WatchWidgetDataReader.read() ?? .placeholder
        let entry = PottyTimerEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PottyTimerEntry>) -> Void) {
        let data = WatchWidgetDataReader.read() ?? .placeholder
        let currentDate = Date()
        var entries: [PottyTimerEntry] = []

        // Create entries every minute for the next 15 minutes
        // Watch complications need frequent updates for accurate time display
        for minuteOffset in 0..<15 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = PottyTimerEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        // Refresh timeline after 15 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct PottyTimerEntry: TimelineEntry {
    let date: Date
    let data: WatchWidgetData

    var minutesSinceLastPlas: Int {
        guard let lastPlasTime = data.lastPlasTime else { return 0 }
        return max(0, Int(date.timeIntervalSince(lastPlasTime) / 60))
    }

    var wasOutdoor: Bool {
        data.lastPlasLocation == "buiten"
    }

    var urgencyLevel: WatchUrgencyLevel {
        let minutes = minutesSinceLastPlas
        if minutes == 0 { return .unknown }
        if minutes < 60 { return .good }
        if minutes < 120 { return .attention }
        if minutes < 180 { return .warning }
        return .urgent
    }
}

// MARK: - Urgency Level

enum WatchUrgencyLevel {
    case good
    case attention
    case warning
    case urgent
    case unknown

    var color: Color {
        switch self {
        case .good: return .green
        case .attention: return .yellow
        case .warning: return .orange
        case .urgent: return .red
        case .unknown: return .gray
        }
    }

    var gaugeValue: Double {
        switch self {
        case .good: return 0.25
        case .attention: return 0.5
        case .warning: return 0.75
        case .urgent: return 1.0
        case .unknown: return 0.0
        }
    }
}

// MARK: - Complication Views

struct PottyTimerComplicationView: View {
    var entry: PottyTimerEntry
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
            // Background gauge showing urgency
            Gauge(value: entry.urgencyLevel.gaugeValue) {
                EmptyView()
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(urgencyGradient)

            VStack(spacing: 0) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(urgencyColor)
                Text(compactTimeText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(urgencyColor)
            }
        }
    }

    // MARK: - Rectangular Complication

    private var rectangularView: some View {
        HStack(spacing: 8) {
            // Left: Icon with urgency indicator
            ZStack {
                Circle()
                    .fill(urgencyColor.opacity(0.3))
                    .frame(width: 32, height: 32)

                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(urgencyColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(timeText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(urgencyColor)

                Text("since potty")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Streak indicator (if any)
            if entry.data.currentStreak > 0 {
                VStack(spacing: 1) {
                    Text("\(entry.data.currentStreak)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Inline Complication

    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "drop.fill")
            Text("\(timeText) since potty")
        }
    }

    // MARK: - Corner Complication (watchOS specific)

    @ViewBuilder
    private var cornerView: some View {
        #if os(watchOS)
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 0) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(urgencyColor)
            }
        }
        .widgetLabel {
            ProgressView(value: entry.urgencyLevel.gaugeValue) {
                Text(compactTimeText)
            }
            .tint(urgencyColor)
        }
        #else
        EmptyView()
        #endif
    }

    // MARK: - Helpers

    private var timeText: String {
        let minutes = entry.minutesSinceLastPlas
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
        let minutes = entry.minutesSinceLastPlas
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

    private var urgencyColor: Color {
        if renderingMode == .fullColor {
            return entry.urgencyLevel.color
        } else if renderingMode == .accented {
            return .accentColor
        } else {
            // .vibrant and any future modes
            return .primary
        }
    }

    private var urgencyGradient: Gradient {
        if renderingMode == .fullColor {
            return Gradient(colors: [entry.urgencyLevel.color, entry.urgencyLevel.color.opacity(0.7)])
        } else if renderingMode == .accented {
            return Gradient(colors: [.accentColor, .accentColor.opacity(0.7)])
        } else {
            // .vibrant and any future modes
            return Gradient(colors: [.primary, .primary.opacity(0.7)])
        }
    }
}

// MARK: - Widget Configuration

struct PottyTimerComplication: Widget {
    let kind: String = "PottyTimerComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PottyTimerProvider()) { entry in
            PottyTimerComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Potty Timer")
        .description("Time since last potty break with urgency indicator.")
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
    PottyTimerComplication()
} timeline: {
    PottyTimerEntry(date: .now, data: .placeholder)
    PottyTimerEntry(date: .now, data: WatchWidgetData(
        lastPlasTime: Date().addingTimeInterval(-95 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 5,
        bestStreak: 12,
        todayPottyCount: 6,
        todayOutdoorCount: 5,
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
    PottyTimerComplication()
} timeline: {
    PottyTimerEntry(date: .now, data: .placeholder)
}

#Preview(as: .accessoryCorner) {
    PottyTimerComplication()
} timeline: {
    PottyTimerEntry(date: .now, data: .placeholder)
}

#Preview(as: .accessoryInline) {
    PottyTimerComplication()
} timeline: {
    PottyTimerEntry(date: .now, data: .placeholder)
}
#endif
