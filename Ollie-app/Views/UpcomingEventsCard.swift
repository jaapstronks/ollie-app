//
//  UpcomingEventsCard.swift
//  Ollie-app
//

import SwiftUI

// MARK: - Types

/// Type of upcoming item for action handling
enum UpcomingItemType {
    case meal
    case walk

    var eventType: EventType {
        switch self {
        case .meal: return .eten
        case .walk: return .uitlaten
        }
    }
}

/// Represents an upcoming scheduled item (meal or walk)
struct UpcomingItem: Identifiable {
    let id = UUID()
    let icon: String             // SF Symbol name
    let label: String
    let detail: String?
    let targetTime: Date
    let itemType: UpcomingItemType
    let weatherIcon: String?     // SF Symbol name (sun.max.fill, cloud.rain.fill, etc.)
    let temperature: Int?        // Temperature in °C
    let rainWarning: Bool        // Highlight if >60% rain probability

    init(
        icon: String,
        label: String,
        detail: String?,
        targetTime: Date,
        itemType: UpcomingItemType,
        weatherIcon: String? = nil,
        temperature: Int? = nil,
        rainWarning: Bool = false
    ) {
        self.icon = icon
        self.label = label
        self.detail = detail
        self.targetTime = targetTime
        self.itemType = itemType
        self.weatherIcon = weatherIcon
        self.temperature = temperature
        self.rainWarning = rainWarning
    }

    var timeString: String {
        targetTime.timeString
    }

    /// Minutes until target time (negative if past)
    var minutesUntil: Int {
        Int(targetTime.timeIntervalSince(Date()) / 60)
    }
}

/// State of an actionable item
enum ActionableItemState {
    case approaching(minutesUntil: Int)  // 1-10 min before
    case due                              // at scheduled time (0 min or just past)
    case overdue(minutesOverdue: Int)     // past scheduled time
}

/// An item that requires action (within 10 min or overdue)
struct ActionableItem: Identifiable {
    let id = UUID()
    let item: UpcomingItem
    let state: ActionableItemState
}

// MARK: - Actionable Event Card

/// Prominent card that appears when a meal or walk is actionable (within 10 min or overdue)
struct ActionableEventCard: View {
    let actionableItem: ActionableItem
    let onLogEvent: (EventType, Date?) -> Void

    var body: some View {
        VStack(spacing: 12) {
            StatusCardHeader(
                iconName: iconName,
                iconColor: indicatorColor,
                tintColor: indicatorColor,
                title: mainText,
                titleColor: textColor,
                subtitle: subtitleText,
                statusLabel: statusLabel,
                iconSize: 40
            )

            // Action button
            Button {
                onLogEvent(actionableItem.item.itemType.eventType, actionableItem.item.targetTime)
            } label: {
                Label(buttonText, systemImage: buttonIcon)
            }
            .buttonStyle(.glassPill(tint: buttonTint))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassStatusCard(tintColor: indicatorColor)
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch actionableItem.item.itemType {
        case .walk: return "figure.walk"
        case .meal: return "fork.knife"
        }
    }

    private var mainText: String {
        switch actionableItem.state {
        case .approaching(let minutes):
            switch actionableItem.item.itemType {
            case .walk: return Strings.Actionable.walkInMinutes(minutes)
            case .meal: return Strings.Actionable.mealInMinutes(minutes)
            }
        case .due:
            switch actionableItem.item.itemType {
            case .walk: return Strings.Actionable.timeForWalk
            case .meal: return Strings.Actionable.timeForMeal
            }
        case .overdue(let minutes):
            switch actionableItem.item.itemType {
            case .walk: return Strings.Actionable.walkOverdue(minutes)
            case .meal: return Strings.Actionable.mealOverdue(minutes)
            }
        }
    }

    private var subtitleText: String? {
        // Show detail like "2/9 walks today" or "110g"
        actionableItem.item.detail
    }

    private var statusLabel: String {
        switch actionableItem.state {
        case .approaching: return Strings.Actionable.approaching
        case .due: return Strings.Actionable.due
        case .overdue: return Strings.Actionable.overdueLabel
        }
    }

    private var indicatorColor: Color {
        switch actionableItem.state {
        case .approaching: return .blue
        case .due: return .green
        case .overdue: return .orange
        }
    }

    private var textColor: Color {
        switch actionableItem.state {
        case .approaching: return .primary
        case .due: return .primary
        case .overdue: return .orange
        }
    }

    private var buttonText: String {
        switch actionableItem.state {
        case .approaching: return Strings.Actionable.startEarly
        case .due: return Strings.Actionable.start
        case .overdue: return Strings.Upcoming.logNow
        }
    }

    private var buttonIcon: String {
        switch actionableItem.item.itemType {
        case .walk: return "figure.walk"
        case .meal: return "fork.knife"
        }
    }

    private var buttonTint: GlassTint {
        switch actionableItem.state {
        case .approaching: return .accent
        case .due: return .success
        case .overdue: return .warning
        }
    }
}

// MARK: - Scheduled Events Section

/// Wrapper view for actionable and upcoming events
/// Separates items that need action now vs items coming later
struct ScheduledEventsSection: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var weatherService: WeatherService

    var body: some View {
        let separated = viewModel.separatedUpcomingItems(forecasts: weatherService.forecasts)

        // Actionable events (within 10 min or overdue - shown prominently)
        ForEach(separated.actionable) { actionableItem in
            ActionableEventCard(
                actionableItem: actionableItem,
                onLogEvent: { eventType, suggestedTime in
                    viewModel.quickLog(type: eventType, suggestedTime: suggestedTime)
                }
            )
        }

        // Upcoming events (more than 10 min away - compact list)
        UpcomingEventsCard(
            items: separated.upcoming,
            isToday: viewModel.isShowingToday
        )
    }
}

// MARK: - Upcoming Events Card (Simplified List)

/// Compact list showing upcoming meals and walks (more than 10 min away)
struct UpcomingEventsCard: View {
    let items: [UpcomingItem]
    let isToday: Bool

    @State private var isExpanded = false

    /// Number of items to show by default
    private let defaultVisibleCount = 3

    var body: some View {
        if !isToday || items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                Text(Strings.Upcoming.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                // Items list
                VStack(spacing: 6) {
                    ForEach(visibleItems) { item in
                        upcomingRow(item)
                    }
                }

                // Expand/collapse button if more than 3 items
                if items.count > defaultVisibleCount {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text(isExpanded ? Strings.Upcoming.showLess : Strings.Upcoming.showAll(items.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .cornerRadius(12)
        }
    }

    private var visibleItems: [UpcomingItem] {
        if isExpanded {
            return items
        } else {
            return Array(items.prefix(defaultVisibleCount))
        }
    }

    @ViewBuilder
    private func upcomingRow(_ item: UpcomingItem) -> some View {
        HStack(spacing: 10) {
            // Time
            Text(item.timeString)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(minWidth: 40, alignment: .leading)

            // Icon with approaching indicator
            ZStack(alignment: .topTrailing) {
                Image(systemName: item.icon)
                    .font(.subheadline)
                    .foregroundStyle(.accent)
                    .frame(width: 20)

                // Orange dot for items approaching (within 30 min)
                if item.minutesUntil <= 30 && item.minutesUntil > 10 {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                        .offset(x: 2, y: -2)
                }
            }

            // Label
            Text(item.label)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            // Detail (amount, progress)
            if let detail = item.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Weather for walks
            if item.itemType == .walk, let weatherIcon = item.weatherIcon {
                HStack(spacing: 2) {
                    Image(systemName: weatherIcon)
                        .font(.caption2)
                    if let temp = item.temperature {
                        Text("\(temp)°")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(item.rainWarning ? .red : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Upcoming Items Calculation

struct UpcomingCalculations {
    /// Threshold in minutes - items within this time become actionable
    static let actionableThresholdMinutes = 10

    /// Calculate upcoming meals and walks for today
    /// Returns separate actionable items (within 10 min or overdue) and upcoming items (>10 min away)
    static func calculateUpcoming(
        events: [PuppyEvent],
        mealSchedule: MealSchedule?,
        walkSchedule: WalkSchedule?,
        forecasts: [HourForecast] = [],
        date: Date = Date()
    ) -> (actionable: [ActionableItem], upcoming: [UpcomingItem]) {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)

        guard isToday else { return ([], []) }

        var allItems: [UpcomingItem] = []

        // Calculate upcoming meals
        if let schedule = mealSchedule {
            let mealsToday = events.meals()
            let mealCount = mealsToday.count

            for (index, portion) in schedule.portions.enumerated() {
                // Skip meals already eaten
                if index < mealCount { continue }

                // Parse target time
                if let targetTime = portion.targetTime,
                   let scheduledTime = parseTime(targetTime, on: date) {
                    allItems.append(UpcomingItem(
                        icon: "fork.knife",
                        label: portion.label,
                        detail: portion.amount,
                        targetTime: scheduledTime,
                        itemType: .meal
                    ))
                }
            }
        }

        // Calculate smart walk suggestion (only show ONE upcoming walk - the next suggested)
        if let schedule = walkSchedule {
            if let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
                events: events,
                walkSchedule: schedule,
                date: date
            ) {
                // Look up weather forecast for suggested walk time
                let forecast = forecasts.first {
                    calendar.isDate($0.time, equalTo: suggestion.suggestedTime, toGranularity: .hour)
                }

                // Build detail string showing progress
                let progressDetail = Strings.Walks.walksProgress(
                    completed: suggestion.walksCompletedToday,
                    total: suggestion.targetWalksPerDay
                )

                allItems.append(UpcomingItem(
                    icon: "figure.walk",
                    label: suggestion.label,
                    detail: progressDetail,
                    targetTime: suggestion.suggestedTime,
                    itemType: .walk,
                    weatherIcon: forecast?.icon,
                    temperature: forecast.map { Int($0.temperature) },
                    rainWarning: forecast?.rainWarning ?? false
                ))
            }
        }

        // Sort by target time
        allItems.sort { $0.targetTime < $1.targetTime }

        // Separate into actionable and upcoming
        var actionable: [ActionableItem] = []
        var upcoming: [UpcomingItem] = []

        for item in allItems {
            let minutesUntil = item.minutesUntil

            if minutesUntil < 0 {
                // Overdue
                actionable.append(ActionableItem(
                    item: item,
                    state: .overdue(minutesOverdue: abs(minutesUntil))
                ))
            } else if minutesUntil <= 5 {
                // Due now (within 5 min window)
                actionable.append(ActionableItem(
                    item: item,
                    state: .due
                ))
            } else if minutesUntil <= actionableThresholdMinutes {
                // Approaching (6-10 min)
                actionable.append(ActionableItem(
                    item: item,
                    state: .approaching(minutesUntil: minutesUntil)
                ))
            } else {
                // Future - goes to upcoming list
                upcoming.append(item)
            }
        }

        return (actionable, upcoming)
    }

    /// Legacy method for backwards compatibility - returns all items as UpcomingItem
    static func calculateUpcoming(
        events: [PuppyEvent],
        mealSchedule: MealSchedule?,
        walkSchedule: WalkSchedule?,
        forecasts: [HourForecast] = [],
        date: Date = Date()
    ) -> [UpcomingItem] {
        let (actionable, upcoming) = calculateUpcoming(
            events: events,
            mealSchedule: mealSchedule,
            walkSchedule: walkSchedule,
            forecasts: forecasts,
            date: date
        ) as (actionable: [ActionableItem], upcoming: [UpcomingItem])

        // Combine actionable items back as UpcomingItem for legacy callers
        let actionableAsUpcoming = actionable.map { $0.item }
        return actionableAsUpcoming + upcoming
    }

    /// Parse a time string (e.g., "08:00") into a Date for the given day
    private static func parseTime(_ timeString: String, on date: Date) -> Date? {
        let parts = timeString.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute

        return Calendar.current.date(from: components)
    }
}

// MARK: - Previews

#Preview("Actionable - Approaching") {
    VStack {
        ActionableEventCard(
            actionableItem: ActionableItem(
                item: UpcomingItem(
                    icon: "figure.walk",
                    label: "Afternoon walk",
                    detail: "2/9 walks",
                    targetTime: Date().addingTimeInterval(8 * 60),
                    itemType: .walk
                ),
                state: .approaching(minutesUntil: 8)
            ),
            onLogEvent: { _, _ in }
        )
        Spacer()
    }
    .padding()
}

#Preview("Actionable - Due") {
    VStack {
        ActionableEventCard(
            actionableItem: ActionableItem(
                item: UpcomingItem(
                    icon: "fork.knife",
                    label: "Lunch",
                    detail: "110g",
                    targetTime: Date(),
                    itemType: .meal
                ),
                state: .due
            ),
            onLogEvent: { _, _ in }
        )
        Spacer()
    }
    .padding()
}

#Preview("Actionable - Overdue") {
    VStack {
        ActionableEventCard(
            actionableItem: ActionableItem(
                item: UpcomingItem(
                    icon: "figure.walk",
                    label: "Morning walk",
                    detail: "1/9 walks",
                    targetTime: Date().addingTimeInterval(-25 * 60),
                    itemType: .walk
                ),
                state: .overdue(minutesOverdue: 25)
            ),
            onLogEvent: { _, _ in }
        )
        Spacer()
    }
    .padding()
}

#Preview("Upcoming List") {
    VStack {
        UpcomingEventsCard(
            items: [
                UpcomingItem(
                    icon: "figure.walk",
                    label: "Afternoon walk",
                    detail: "2/9 walks",
                    targetTime: Date().addingTimeInterval(90 * 60),
                    itemType: .walk,
                    weatherIcon: "sun.max.fill",
                    temperature: 18
                ),
                UpcomingItem(
                    icon: "fork.knife",
                    label: "Dinner",
                    detail: "80g",
                    targetTime: Date().addingTimeInterval(180 * 60),
                    itemType: .meal
                ),
                UpcomingItem(
                    icon: "figure.walk",
                    label: "Evening walk",
                    detail: "3/9 walks",
                    targetTime: Date().addingTimeInterval(240 * 60),
                    itemType: .walk,
                    weatherIcon: "cloud.fill",
                    temperature: 15
                ),
                UpcomingItem(
                    icon: "fork.knife",
                    label: "Late snack",
                    detail: "40g",
                    targetTime: Date().addingTimeInterval(300 * 60),
                    itemType: .meal
                )
            ],
            isToday: true
        )
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
