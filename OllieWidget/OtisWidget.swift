//
//  OtisWidget.swift
//  OtisWidget
//
//  Potty timer widget showing time since last plas event

import WidgetKit
import OtisShared
import SwiftUI

// MARK: - Shared Widget Data

/// Widget data shared between app and widgets via App Groups
struct WidgetData: Codable {
    // MARK: - Potty Data
    let lastPlasTime: Date?
    let lastPlasLocation: String?  // "buiten" or "binnen"
    let currentStreak: Int
    let bestStreak: Int
    let todayPottyCount: Int
    let todayOutdoorCount: Int

    // MARK: - Sleep Data
    let isCurrentlySleeping: Bool
    let sleepStartTime: Date?  // When current sleep started (if sleeping)
    let lastWakeTime: Date?    // When puppy last woke up (for awake timer)
    let expectedWakeTime: Date?  // Predicted wake time based on average nap duration
    let averageNapDurationMin: Int?  // Average nap duration for predictions

    // MARK: - Meal Data
    let lastMealTime: Date?
    let nextScheduledMealTime: Date?  // Next meal target time today
    let mealsLoggedToday: Int
    let mealsExpectedToday: Int

    // MARK: - Walk Data
    let lastWalkTime: Date?
    let nextScheduledWalkTime: Date?  // Next walk target time today

    // MARK: - Latest Event Data
    let lastEventType: String?  // EventType.rawValue
    let lastEventTime: Date?
    let lastEventNote: String?
    let lastEventLocation: String?  // For potty events
    let lastEventHasMedia: Bool
    let lastEventThumbnailName: String?  // Filename of thumbnail in shared container

    // MARK: - Meta
    let puppyName: String
    let lastUpdated: Date

    // MARK: - Backwards-compatible decoding
    // Handles cached data that may be missing newer fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastPlasTime = try container.decodeIfPresent(Date.self, forKey: .lastPlasTime)
        lastPlasLocation = try container.decodeIfPresent(String.self, forKey: .lastPlasLocation)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        bestStreak = try container.decode(Int.self, forKey: .bestStreak)
        todayPottyCount = try container.decode(Int.self, forKey: .todayPottyCount)
        todayOutdoorCount = try container.decode(Int.self, forKey: .todayOutdoorCount)
        isCurrentlySleeping = try container.decode(Bool.self, forKey: .isCurrentlySleeping)
        sleepStartTime = try container.decodeIfPresent(Date.self, forKey: .sleepStartTime)
        lastWakeTime = try container.decodeIfPresent(Date.self, forKey: .lastWakeTime)
        expectedWakeTime = try container.decodeIfPresent(Date.self, forKey: .expectedWakeTime)
        averageNapDurationMin = try container.decodeIfPresent(Int.self, forKey: .averageNapDurationMin)
        lastMealTime = try container.decodeIfPresent(Date.self, forKey: .lastMealTime)
        nextScheduledMealTime = try container.decodeIfPresent(Date.self, forKey: .nextScheduledMealTime)
        mealsLoggedToday = try container.decode(Int.self, forKey: .mealsLoggedToday)
        mealsExpectedToday = try container.decode(Int.self, forKey: .mealsExpectedToday)
        lastWalkTime = try container.decodeIfPresent(Date.self, forKey: .lastWalkTime)
        nextScheduledWalkTime = try container.decodeIfPresent(Date.self, forKey: .nextScheduledWalkTime)
        lastEventType = try container.decodeIfPresent(String.self, forKey: .lastEventType)
        lastEventTime = try container.decodeIfPresent(Date.self, forKey: .lastEventTime)
        lastEventNote = try container.decodeIfPresent(String.self, forKey: .lastEventNote)
        lastEventLocation = try container.decodeIfPresent(String.self, forKey: .lastEventLocation)
        lastEventHasMedia = try container.decodeIfPresent(Bool.self, forKey: .lastEventHasMedia) ?? false
        lastEventThumbnailName = try container.decodeIfPresent(String.self, forKey: .lastEventThumbnailName)
        puppyName = try container.decode(String.self, forKey: .puppyName)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    }

    // Memberwise initializer for creating new instances
    init(
        lastPlasTime: Date?,
        lastPlasLocation: String?,
        currentStreak: Int,
        bestStreak: Int,
        todayPottyCount: Int,
        todayOutdoorCount: Int,
        isCurrentlySleeping: Bool,
        sleepStartTime: Date?,
        lastWakeTime: Date?,
        expectedWakeTime: Date? = nil,
        averageNapDurationMin: Int? = nil,
        lastMealTime: Date?,
        nextScheduledMealTime: Date?,
        mealsLoggedToday: Int,
        mealsExpectedToday: Int,
        lastWalkTime: Date?,
        nextScheduledWalkTime: Date?,
        lastEventType: String? = nil,
        lastEventTime: Date? = nil,
        lastEventNote: String? = nil,
        lastEventLocation: String? = nil,
        lastEventHasMedia: Bool = false,
        lastEventThumbnailName: String? = nil,
        puppyName: String,
        lastUpdated: Date
    ) {
        self.lastPlasTime = lastPlasTime
        self.lastPlasLocation = lastPlasLocation
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.todayPottyCount = todayPottyCount
        self.todayOutdoorCount = todayOutdoorCount
        self.isCurrentlySleeping = isCurrentlySleeping
        self.sleepStartTime = sleepStartTime
        self.lastWakeTime = lastWakeTime
        self.expectedWakeTime = expectedWakeTime
        self.averageNapDurationMin = averageNapDurationMin
        self.lastMealTime = lastMealTime
        self.nextScheduledMealTime = nextScheduledMealTime
        self.mealsLoggedToday = mealsLoggedToday
        self.mealsExpectedToday = mealsExpectedToday
        self.lastWalkTime = lastWalkTime
        self.nextScheduledWalkTime = nextScheduledWalkTime
        self.lastEventType = lastEventType
        self.lastEventTime = lastEventTime
        self.lastEventNote = lastEventNote
        self.lastEventLocation = lastEventLocation
        self.lastEventHasMedia = lastEventHasMedia
        self.lastEventThumbnailName = lastEventThumbnailName
        self.puppyName = puppyName
        self.lastUpdated = lastUpdated
    }

    static var placeholder: WidgetData {
        WidgetData(
            lastPlasTime: Date().addingTimeInterval(-45 * 60),
            lastPlasLocation: "buiten",
            currentStreak: 3,
            bestStreak: 12,
            todayPottyCount: 4,
            todayOutdoorCount: 3,
            isCurrentlySleeping: false,
            sleepStartTime: nil,
            lastWakeTime: Date().addingTimeInterval(-90 * 60),
            expectedWakeTime: nil,
            averageNapDurationMin: 45,
            lastMealTime: Date().addingTimeInterval(-3 * 60 * 60),
            nextScheduledMealTime: Date().addingTimeInterval(1 * 60 * 60),
            mealsLoggedToday: 2,
            mealsExpectedToday: 3,
            lastWalkTime: Date().addingTimeInterval(-2 * 60 * 60),
            nextScheduledWalkTime: Date().addingTimeInterval(30 * 60),
            lastEventType: "plassen",
            lastEventTime: Date().addingTimeInterval(-45 * 60),
            lastEventNote: nil,
            lastEventLocation: "buiten",
            lastEventHasMedia: false,
            lastEventThumbnailName: nil,
            puppyName: "--",
            lastUpdated: Date()
        )
    }
}

/// Reads widget data from shared App Group UserDefaults
struct WidgetDataReader {
    static let suiteName = Constants.appGroupIdentifier
    static let dataKey = "widgetData"

    static func read() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName),
              let data = sharedDefaults.data(forKey: dataKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(WidgetData.self, from: data)
    }
}

// MARK: - Timeline Provider

struct PottyProvider: TimelineProvider {
    func placeholder(in context: Context) -> PottyEntry {
        PottyEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PottyEntry) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let entry = PottyEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PottyEntry>) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let currentDate = Date()
        var entries: [PottyEntry] = []

        // Create entries for next hour, updating every 5 minutes
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = PottyEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct PottyEntry: TimelineEntry {
    let date: Date
    let data: WidgetData

    var minutesSinceLastPlas: Int {
        guard let lastPlasTime = data.lastPlasTime else { return 0 }
        return Int(date.timeIntervalSince(lastPlasTime) / 60)
    }

    var wasOutdoor: Bool {
        data.lastPlasLocation == "buiten"
    }
}

// MARK: - Widget Views

struct PottyWidgetEntryView: View {
    var entry: PottyProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryCircular:
            circularWidget
        case .accessoryInline:
            inlineWidget
        case .accessoryRectangular:
            rectangularWidget
        default:
            smallWidget
        }
    }

    // MARK: - Home Screen Widgets

    private var smallWidget: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(urgencyIconBackground)
                    .frame(width: 52, height: 52)

                Image(systemName: "drop.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(urgencyIconColor)
            }

            Text(timeText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.8)

            Text(String(localized: "since potty"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left: Icon with background
            ZStack {
                Circle()
                    .fill(urgencyIconBackground)
                    .frame(width: 64, height: 64)

                Image(systemName: "drop.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(urgencyIconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.data.puppyName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(timeText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(String(localized: "since last potty"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Right: Status indicator
            if entry.minutesSinceLastPlas > 90 {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.orange)
                    Text(String(localized: "Now"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                }
            } else if entry.minutesSinceLastPlas > 0 {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                    Text("OK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Lock Screen Widgets

    private var circularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14))
                Text(compactTimeText)
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }

    private var inlineWidget: some View {
        HStack(spacing: 4) {
            Image(systemName: "drop.fill")
            Text("\(timeText) \(String(localized: "since potty"))")
        }
    }

    private var rectangularWidget: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                    Text(timeText)
                        .fontWeight(.bold)
                }
                Text(String(localized: "since potty"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.data.currentStreak > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Text("\(entry.data.currentStreak)")
                            .fontWeight(.bold)
                        Image(systemName: "flame.fill")
                    }
                    Text("streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
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

    private var urgencyIconBackground: Color {
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

    private var urgencyIconColor: Color {
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

    private var urgencyGradient: [Color] {
        let minutes = entry.minutesSinceLastPlas
        let isDark = colorScheme == .dark

        if minutes > 120 {
            return isDark
                ? [Color(red: 0.35, green: 0.15, blue: 0.15), Color(red: 0.40, green: 0.18, blue: 0.16)]
                : [Color(red: 0.98, green: 0.92, blue: 0.90), Color(red: 0.95, green: 0.85, blue: 0.82)]
        } else if minutes > 90 {
            return isDark
                ? [Color(red: 0.35, green: 0.28, blue: 0.12), Color(red: 0.38, green: 0.30, blue: 0.10)]
                : [Color(red: 1.0, green: 0.96, blue: 0.88), Color(red: 1.0, green: 0.92, blue: 0.80)]
        } else {
            return isDark
                ? [Color(red: 0.12, green: 0.22, blue: 0.18), Color(red: 0.14, green: 0.25, blue: 0.20)]
                : [Color(red: 0.92, green: 0.97, blue: 0.94), Color(red: 0.85, green: 0.94, blue: 0.88)]
        }
    }
}

// MARK: - Widget Configuration

struct OtisWidget: Widget {
    let kind: String = "OtisWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PottyProvider()) { entry in
            PottyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Potty Timer"))
        .description(String(localized: "See how long since the last potty break."))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    OtisWidget()
} timeline: {
    PottyEntry(date: .now, data: .placeholder)
    PottyEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-95 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 5,
        bestStreak: 12,
        todayPottyCount: 6,
        todayOutdoorCount: 5,
        isCurrentlySleeping: false,
        sleepStartTime: nil,
        lastWakeTime: Date().addingTimeInterval(-95 * 60),
        lastMealTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledMealTime: Date().addingTimeInterval(1 * 60 * 60),
        mealsLoggedToday: 2,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-1 * 60 * 60),
        nextScheduledWalkTime: Date().addingTimeInterval(30 * 60),
        puppyName: "Max",
        lastUpdated: Date()
    ))
}

#Preview(as: .systemMedium) {
    OtisWidget()
} timeline: {
    PottyEntry(date: .now, data: .placeholder)
}

#Preview(as: .accessoryCircular) {
    OtisWidget()
} timeline: {
    PottyEntry(date: .now, data: .placeholder)
}

#Preview(as: .accessoryRectangular) {
    OtisWidget()
} timeline: {
    PottyEntry(date: .now, data: .placeholder)
}
