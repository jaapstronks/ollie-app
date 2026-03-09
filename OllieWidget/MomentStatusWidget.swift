//
//  MomentStatusWidget.swift
//  OllieWidget
//
//  Large widget showing latest moment on one side and current status on the other
//

import WidgetKit
import OtisShared
import SwiftUI
import UIKit

// MARK: - Timeline Provider

struct MomentStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> MomentStatusEntry {
        MomentStatusEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MomentStatusEntry) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let entry = MomentStatusEntry(date: Date(), data: data)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MomentStatusEntry>) -> Void) {
        let data = WidgetDataReader.read() ?? .placeholder
        let currentDate = Date()
        var entries: [MomentStatusEntry] = []

        // Create entries for next hour, updating every minute for accurate timers
        for minuteOffset in stride(from: 0, to: 60, by: 1) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = MomentStatusEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct MomentStatusEntry: TimelineEntry {
    let date: Date
    let data: WidgetData

    var minutesSinceLastEvent: Int {
        guard let lastEventTime = data.lastEventTime else { return 0 }
        return Int(date.timeIntervalSince(lastEventTime) / 60)
    }

    var minutesSinceSleepStart: Int {
        guard let sleepStart = data.sleepStartTime else { return 0 }
        return Int(date.timeIntervalSince(sleepStart) / 60)
    }

    var minutesSinceWake: Int {
        guard let wakeTime = data.lastWakeTime else { return 0 }
        return Int(date.timeIntervalSince(wakeTime) / 60)
    }

    var minutesUntilExpectedWake: Int? {
        guard let expectedWake = data.expectedWakeTime else { return nil }
        let minutes = Int(expectedWake.timeIntervalSince(date) / 60)
        return minutes > 0 ? minutes : nil
    }

    var expectedWakeTimeFormatted: String? {
        guard let expectedWake = data.expectedWakeTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: expectedWake)
    }

    var suggestedNapTime: Date? {
        // Suggest nap if awake for more than 45 minutes
        guard !data.isCurrentlySleeping,
              let wakeTime = data.lastWakeTime,
              minutesSinceWake >= 45 else { return nil }

        // Suggest nap time based on max awake duration (60 min default)
        let maxAwakeMinutes = 60
        return wakeTime.addingTimeInterval(Double(maxAwakeMinutes) * 60)
    }

    var isNapSuggestionOverdue: Bool {
        guard let napTime = suggestedNapTime else { return false }
        return date > napTime
    }

    /// Load thumbnail image from shared container
    var thumbnailImage: UIImage? {
        guard let thumbnailName = data.lastEventThumbnailName else { return nil }

        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier) else {
            return nil
        }

        let thumbnailURL = containerURL
            .appendingPathComponent("WidgetThumbnails", isDirectory: true)
            .appendingPathComponent(thumbnailName)

        guard let imageData = try? Data(contentsOf: thumbnailURL) else {
            return nil
        }

        return UIImage(data: imageData)
    }
}

// MARK: - Widget Views

struct MomentStatusWidgetEntryView: View {
    var entry: MomentStatusProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemLarge:
            largeWidget
        case .systemMedium:
            mediumWidget
        default:
            largeWidget
        }
    }

    // MARK: - Large Widget

    private var largeWidget: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            // Main content - two columns
            HStack(spacing: 0) {
                // Left: Latest moment
                latestMomentPanel
                    .frame(maxWidth: .infinity)

                // Divider
                RoundedRectangle(cornerRadius: 1)
                    .fill(.primary.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // Right: Current status
                currentStatusPanel
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 0)

            // Bottom action hint
            bottomHintView
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 0) {
            // Left: Latest moment (compact)
            latestMomentCompact
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(.primary.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 16)

            // Right: Current status (compact)
            currentStatusCompact
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .containerBackground(for: .widget) {
            ContainerRelativeShape()
                .fill(backgroundGradient)
        }
    }

    // MARK: - Header

    private var headerView: some View {
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

            // Status badge
            if entry.data.isCurrentlySleeping {
                HStack(spacing: 4) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 10))
                    Text(String(localized: "Sleeping"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(WidgetColorPalette.sleepIconColor(colorScheme: colorScheme))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(WidgetColorPalette.sleepIconBackground(colorScheme: colorScheme), in: Capsule())
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 10))
                    Text(String(localized: "Awake"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.primary.opacity(0.06), in: Capsule())
            }
        }
    }

    // MARK: - Latest Moment Panel

    private var latestMomentPanel: some View {
        VStack(spacing: 10) {
            Text(String(localized: "MOMENT"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            if let eventType = entry.data.lastEventType, entry.data.lastEventHasMedia {
                // Show thumbnail if available, otherwise show event icon
                if let thumbnail = entry.thumbnailImage {
                    // Thumbnail with event type overlay
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Event type badge overlay
                        ZStack {
                            Circle()
                                .fill(eventIconBackground(for: eventType))
                                .frame(width: 24, height: 24)

                            Image(systemName: eventIcon(for: eventType))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(eventIconColor(for: eventType))
                        }
                        .offset(x: 4, y: 4)
                    }
                } else {
                    // Event icon (no thumbnail available)
                    ZStack {
                        Circle()
                            .fill(eventIconBackground(for: eventType))
                            .frame(width: 56, height: 56)

                        Image(systemName: eventIcon(for: eventType))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(eventIconColor(for: eventType))
                    }
                }

                // Event type label
                Text(eventLabel(for: eventType))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                // Time ago
                Text(DurationFormatter.format(entry.minutesSinceLastEvent, style: .compact, showZeroAsEmpty: true) + " " + String(localized: "ago"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                // Note preview if available (only show if no thumbnail, to save space)
                if entry.thumbnailImage == nil, let note = entry.data.lastEventNote, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            } else {
                // No moments with photos yet
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                Text(String(localized: "No moments yet"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(String(localized: "Add photos to events"))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }

    private var latestMomentCompact: some View {
        VStack(spacing: 6) {
            if let eventType = entry.data.lastEventType, entry.data.lastEventHasMedia, let thumbnail = entry.thumbnailImage {
                // Show thumbnail with event type badge
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Event type badge overlay
                    ZStack {
                        Circle()
                            .fill(eventIconBackground(for: eventType))
                            .frame(width: 20, height: 20)

                        Image(systemName: eventIcon(for: eventType))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(eventIconColor(for: eventType))
                    }
                    .offset(x: 3, y: 3)
                }

                Text(eventLabel(for: eventType))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(DurationFormatter.format(entry.minutesSinceLastEvent, style: .compact, showZeroAsEmpty: true) + " " + String(localized: "ago"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                // No moments with photos
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                Text(String(localized: "No moments"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Current Status Panel

    private var currentStatusPanel: some View {
        VStack(spacing: 10) {
            Text(String(localized: "STATUS"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            if entry.data.isCurrentlySleeping {
                sleepStatusView
            } else {
                awakeStatusView
            }
        }
        .padding(.vertical, 8)
    }

    private var currentStatusCompact: some View {
        VStack(spacing: 6) {
            if entry.data.isCurrentlySleeping {
                ZStack {
                    Circle()
                        .fill(WidgetColorPalette.sleepIconBackground(colorScheme: colorScheme))
                        .frame(width: 44, height: 44)

                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(WidgetColorPalette.sleepIconColor(colorScheme: colorScheme))
                }

                Text(DurationFormatter.format(entry.minutesSinceSleepStart, style: .compact, showZeroAsEmpty: true))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if let wakeTime = entry.expectedWakeTimeFormatted {
                    Text(String(localized: "Wake ~\(wakeTime)"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } else {
                ZStack {
                    Circle()
                        .fill(awakeIconBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(awakeIconColor)
                }

                Text(DurationFormatter.format(entry.minutesSinceWake, style: .compact, showZeroAsEmpty: true))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if entry.minutesSinceWake >= 45 {
                    Text(String(localized: "Nap time?"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text(String(localized: "awake"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Sleep Status View

    private var sleepStatusView: some View {
        VStack(spacing: 8) {
            // Sleep icon
            ZStack {
                Circle()
                    .fill(WidgetColorPalette.sleepIconBackground(colorScheme: colorScheme))
                    .frame(width: 56, height: 56)

                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(WidgetColorPalette.sleepIconColor(colorScheme: colorScheme))
            }

            // Duration sleeping
            Text(DurationFormatter.format(entry.minutesSinceSleepStart, style: .compact, showZeroAsEmpty: true))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "asleep"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            // Expected wake time
            if let wakeTime = entry.expectedWakeTimeFormatted {
                VStack(spacing: 2) {
                    Text(String(localized: "Expected wake"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("~\(wakeTime)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    if let remaining = entry.minutesUntilExpectedWake {
                        Text(String(localized: "in \(DurationFormatter.format(remaining, style: .compact, showZeroAsEmpty: true))"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Awake Status View

    private var awakeStatusView: some View {
        VStack(spacing: 8) {
            // Awake icon
            ZStack {
                Circle()
                    .fill(awakeIconBackground)
                    .frame(width: 56, height: 56)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(awakeIconColor)
            }

            // Duration awake
            Text(DurationFormatter.format(entry.minutesSinceWake, style: .compact, showZeroAsEmpty: true))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(String(localized: "awake"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            // Nap suggestion
            if entry.minutesSinceWake >= 45 {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: entry.isNapSuggestionOverdue ? "exclamationmark.triangle.fill" : "moon.fill")
                            .font(.system(size: 12))
                        Text(entry.isNapSuggestionOverdue ? String(localized: "Nap overdue") : String(localized: "Time for a nap"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(entry.isNapSuggestionOverdue ? .orange : .indigo)

                    if let avgNap = entry.data.averageNapDurationMin {
                        Text(String(localized: "Avg nap: \(avgNap) min"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background((entry.isNapSuggestionOverdue ? Color.orange : Color.indigo).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Bottom Hint

    private var bottomHintView: some View {
        Group {
            if entry.data.isCurrentlySleeping {
                // When sleeping, show potty timer as secondary info
                if let lastPlasTime = entry.data.lastPlasTime {
                    let minutesSincePlas = Int(entry.date.timeIntervalSince(lastPlasTime) / 60)
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(WidgetColorPalette.pottyIconColor(minutes: minutesSincePlas, colorScheme: colorScheme))
                        Text(String(localized: "Potty break needed when awake"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("(\(DurationFormatter.format(minutesSincePlas, style: .compact, showZeroAsEmpty: true)))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WidgetColorPalette.pottyIconColor(minutes: minutesSincePlas, colorScheme: colorScheme))
                    }
                    .opacity(minutesSincePlas > 60 ? 1 : 0.7)
                }
            } else {
                // When awake, show streak info
                HStack(spacing: 6) {
                    Image(systemName: WidgetColorPalette.streakIcon(streak: entry.data.currentStreak))
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetColorPalette.streakIconColor(streak: entry.data.currentStreak, colorScheme: colorScheme))
                    Text(String(localized: "Outdoor streak: \(entry.data.currentStreak)"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: LinearGradient {
        WidgetColorPalette.backgroundGradient(
            isCurrentlySleeping: entry.data.isCurrentlySleeping,
            minutesSinceLastPlas: entry.data.lastPlasTime.map { Int(entry.date.timeIntervalSince($0) / 60) } ?? 0,
            colorScheme: colorScheme
        )
    }

    // MARK: - Awake Colors

    private var awakeIconColor: Color {
        let isDark = colorScheme == .dark
        if entry.minutesSinceWake >= 60 {
            return isDark
                ? Color(red: 1.0, green: 0.70, blue: 0.30)
                : Color(red: 0.90, green: 0.55, blue: 0.15)
        }
        return isDark
            ? Color(red: 1.0, green: 0.85, blue: 0.40)
            : Color(red: 0.95, green: 0.70, blue: 0.20)
    }

    private var awakeIconBackground: Color {
        let isDark = colorScheme == .dark
        if entry.minutesSinceWake >= 60 {
            return isDark
                ? Color(red: 0.50, green: 0.40, blue: 0.18).opacity(0.7)
                : Color(red: 1.0, green: 0.88, blue: 0.70).opacity(0.6)
        }
        return isDark
            ? Color(red: 0.50, green: 0.45, blue: 0.20).opacity(0.7)
            : Color(red: 1.0, green: 0.95, blue: 0.75).opacity(0.6)
    }

    // MARK: - Event Type Helpers

    private func eventIcon(for type: String) -> String {
        switch type {
        case "eten": return "fork.knife"
        case "drinken": return "drop.fill"
        case "plassen": return "drop.fill"
        case "poepen": return "circle.inset.filled"
        case "slapen": return "moon.zzz.fill"
        case "ontwaken": return "sun.max.fill"
        case "uitlaten": return "figure.walk"
        case "tuin": return "leaf.fill"
        case "training": return "graduationcap.fill"
        case "bench": return "house.fill"
        case "sociaal": return "dog.fill"
        case "milestone": return "star.fill"
        case "gedrag": return "note.text"
        case "gewicht": return "scalemass.fill"
        case "moment": return "camera.fill"
        case "medicatie": return "pills.fill"
        default: return "pawprint.fill"
        }
    }

    private func eventLabel(for type: String) -> String {
        switch type {
        case "eten": return String(localized: "Meal")
        case "drinken": return String(localized: "Water")
        case "plassen": return String(localized: "Potty")
        case "poepen": return String(localized: "Poop")
        case "slapen": return String(localized: "Sleep")
        case "ontwaken": return String(localized: "Wake up")
        case "uitlaten": return String(localized: "Walk")
        case "tuin": return String(localized: "Garden")
        case "training": return String(localized: "Training")
        case "bench": return String(localized: "Crate")
        case "sociaal": return String(localized: "Social")
        case "milestone": return String(localized: "Milestone")
        case "gedrag": return String(localized: "Behavior")
        case "gewicht": return String(localized: "Weight")
        case "moment": return String(localized: "Moment")
        case "medicatie": return String(localized: "Medication")
        default: return String(localized: "Event")
        }
    }

    private func eventIconColor(for type: String) -> Color {
        let isDark = colorScheme == .dark
        switch type {
        case "plassen", "drinken":
            return isDark ? Color(red: 0.45, green: 0.75, blue: 0.95) : Color(red: 0.20, green: 0.55, blue: 0.80)
        case "poepen":
            return isDark ? Color(red: 0.75, green: 0.60, blue: 0.45) : Color(red: 0.55, green: 0.40, blue: 0.25)
        case "eten":
            return isDark ? Color(red: 1.0, green: 0.70, blue: 0.40) : Color(red: 0.90, green: 0.55, blue: 0.20)
        case "slapen":
            return WidgetColorPalette.sleepIconColor(colorScheme: colorScheme)
        case "ontwaken":
            return awakeIconColor
        case "uitlaten", "tuin":
            return isDark ? Color(red: 0.45, green: 0.85, blue: 0.55) : Color(red: 0.25, green: 0.65, blue: 0.35)
        case "training":
            return isDark ? Color(red: 0.70, green: 0.55, blue: 0.95) : Color(red: 0.50, green: 0.35, blue: 0.80)
        case "sociaal":
            return isDark ? Color(red: 0.95, green: 0.65, blue: 0.75) : Color(red: 0.85, green: 0.45, blue: 0.55)
        case "milestone":
            return isDark ? Color(red: 1.0, green: 0.85, blue: 0.30) : Color(red: 0.90, green: 0.70, blue: 0.15)
        default:
            return isDark ? Color(red: 0.65, green: 0.65, blue: 0.70) : Color(red: 0.45, green: 0.45, blue: 0.50)
        }
    }

    private func eventIconBackground(for type: String) -> Color {
        eventIconColor(for: type).opacity(colorScheme == .dark ? 0.25 : 0.18)
    }
}

// MARK: - Widget Configuration

struct MomentStatusWidget: Widget {
    let kind: String = "MomentStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MomentStatusProvider()) { entry in
            MomentStatusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Moment & Status"))
        .description(String(localized: "See your latest photo moment and current sleep/awake status with predictions."))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    MomentStatusWidget()
} timeline: {
    // Awake state
    MomentStatusEntry(date: .now, data: .placeholder)

    // Sleeping state
    MomentStatusEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-70 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 5,
        bestStreak: 12,
        todayPottyCount: 3,
        todayOutdoorCount: 3,
        isCurrentlySleeping: true,
        sleepStartTime: Date().addingTimeInterval(-25 * 60),
        lastWakeTime: nil,
        expectedWakeTime: Date().addingTimeInterval(20 * 60),
        averageNapDurationMin: 45,
        lastMealTime: Date().addingTimeInterval(-2 * 60 * 60),
        nextScheduledMealTime: Date().addingTimeInterval(30 * 60),
        mealsLoggedToday: 2,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-1 * 60 * 60),
        nextScheduledWalkTime: nil,
        lastEventType: "slapen",
        lastEventTime: Date().addingTimeInterval(-25 * 60),
        lastEventNote: nil,
        lastEventLocation: nil,
        lastEventHasMedia: false,
        puppyName: "Max",
        lastUpdated: Date()
    ))

    // Long awake - nap suggestion
    MomentStatusEntry(date: .now, data: WidgetData(
        lastPlasTime: Date().addingTimeInterval(-30 * 60),
        lastPlasLocation: "buiten",
        currentStreak: 8,
        bestStreak: 12,
        todayPottyCount: 5,
        todayOutdoorCount: 5,
        isCurrentlySleeping: false,
        sleepStartTime: nil,
        lastWakeTime: Date().addingTimeInterval(-55 * 60),
        expectedWakeTime: nil,
        averageNapDurationMin: 40,
        lastMealTime: Date().addingTimeInterval(-1 * 60 * 60),
        nextScheduledMealTime: Date().addingTimeInterval(2 * 60 * 60),
        mealsLoggedToday: 2,
        mealsExpectedToday: 3,
        lastWalkTime: Date().addingTimeInterval(-30 * 60),
        nextScheduledWalkTime: nil,
        lastEventType: "uitlaten",
        lastEventTime: Date().addingTimeInterval(-30 * 60),
        lastEventNote: "Morning walk at the park",
        lastEventLocation: nil,
        lastEventHasMedia: true,
        puppyName: "Max",
        lastUpdated: Date()
    ))
}

#Preview(as: .systemMedium) {
    MomentStatusWidget()
} timeline: {
    MomentStatusEntry(date: .now, data: .placeholder)
}
