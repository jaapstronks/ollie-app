//
//  UpcomingEventsCard.swift
//  Ollie-app
//

import SwiftUI

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

    var actionLabel: String {
        switch self {
        case .meal: return Strings.Common.log
        case .walk: return Strings.Common.log
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
    let isOverdue: Bool
    let itemType: UpcomingItemType
    let weatherIcon: String?     // SF Symbol name (sun.max.fill, cloud.rain.fill, etc.)
    let temperature: Int?        // Temperature in °C
    let rainWarning: Bool        // Highlight if >60% rain probability

    init(
        icon: String,
        label: String,
        detail: String?,
        targetTime: Date,
        isOverdue: Bool,
        itemType: UpcomingItemType,
        weatherIcon: String? = nil,
        temperature: Int? = nil,
        rainWarning: Bool = false
    ) {
        self.icon = icon
        self.label = label
        self.detail = detail
        self.targetTime = targetTime
        self.isOverdue = isOverdue
        self.itemType = itemType
        self.weatherIcon = weatherIcon
        self.temperature = temperature
        self.rainWarning = rainWarning
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: targetTime)
    }
}

/// Card showing upcoming meals and walks for today
struct UpcomingEventsCard: View {
    let items: [UpcomingItem]
    let isToday: Bool
    /// Callback with event type and optional suggested time (for overdue items, use scheduled time)
    let onLogEvent: (EventType, Date?) -> Void

    var body: some View {
        if !isToday || items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(Strings.Upcoming.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }

                // Next item (highlighted)
                if let nextItem = items.first {
                    nextItemCard(nextItem)
                }

                // Later items (collapsed)
                if items.count > 1 {
                    laterItemsList(Array(items.dropFirst()))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    @ViewBuilder
    private func nextItemCard(_ item: UpcomingItem) -> some View {
        HStack(spacing: 12) {
            // Time with overdue indicator
            HStack(spacing: 4) {
                if item.isOverdue {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Text(item.timeString)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(item.isOverdue ? .orange : .secondary)
            }
            .frame(minWidth: 50, alignment: .leading)

            // Event icon
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)

            // Label and detail
            VStack(alignment: .leading, spacing: 2) {
                Text(item.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if let detail = item.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Weather info for walks
            if item.itemType == .walk, let weatherIcon = item.weatherIcon {
                HStack(spacing: 2) {
                    Image(systemName: weatherIcon)
                        .font(.caption)
                    if let temp = item.temperature {
                        Text("\(temp)°")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(item.rainWarning ? .red : .secondary)
            }

            // Action button - for overdue items show "Log now" text
            Button {
                // For overdue items, suggest using the scheduled time as default
                onLogEvent(item.itemType.eventType, item.isOverdue ? item.targetTime : nil)
            } label: {
                if item.isOverdue {
                    Text(Strings.Upcoming.logNow)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(16)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func laterItemsList(_ items: [UpcomingItem]) -> some View {
        DisclosureGroup {
            VStack(spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 8) {
                        // Time with overdue indicator
                        HStack(spacing: 2) {
                            if item.isOverdue {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            Text(item.timeString)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(item.isOverdue ? .orange : .secondary)
                        }
                        .frame(minWidth: 44, alignment: .leading)

                        Image(systemName: item.icon)
                            .font(.subheadline)
                            .foregroundColor(.accentColor)

                        Text(item.label)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        // Weather info for walks
                        if item.itemType == .walk, let weatherIcon = item.weatherIcon {
                            HStack(spacing: 2) {
                                Image(systemName: weatherIcon)
                                    .font(.caption2)
                                if let temp = item.temperature {
                                    Text("\(temp)°")
                                        .font(.caption2)
                                }
                            }
                            .foregroundColor(item.rainWarning ? .red : .secondary)
                        }

                        Spacer()

                        // Compact action button
                        Button {
                            onLogEvent(item.itemType.eventType, item.isOverdue ? item.targetTime : nil)
                        } label: {
                            if item.isOverdue {
                                Text(Strings.Upcoming.logNow)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Text(Strings.Upcoming.laterToday(items.count))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Upcoming Items Calculation

struct UpcomingCalculations {
    /// Calculate upcoming meals and walks for today
    /// Uses smart walk suggestions based on actual walk times instead of fixed schedule
    static func calculateUpcoming(
        events: [PuppyEvent],
        mealSchedule: MealSchedule?,
        walkSchedule: WalkSchedule?,
        forecasts: [HourForecast] = [],
        date: Date = Date()
    ) -> [UpcomingItem] {
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDateInToday(date)

        guard isToday else { return [] }

        var items: [UpcomingItem] = []

        // Calculate upcoming meals (unchanged - uses fixed schedule)
        if let schedule = mealSchedule {
            let mealsToday = events.filter { $0.type == .eten }
            let mealCount = mealsToday.count

            for (index, portion) in schedule.portions.enumerated() {
                // Skip meals already eaten
                if index < mealCount { continue }

                // Parse target time
                if let targetTime = portion.targetTime,
                   let scheduledTime = parseTime(targetTime, on: date) {
                    let isOverdue = scheduledTime < now
                    items.append(UpcomingItem(
                        icon: "fork.knife",
                        label: portion.label,
                        detail: portion.amount,
                        targetTime: scheduledTime,
                        isOverdue: isOverdue,
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

                items.append(UpcomingItem(
                    icon: "figure.walk",
                    label: suggestion.label,
                    detail: progressDetail,
                    targetTime: suggestion.suggestedTime,
                    isOverdue: suggestion.isOverdue,
                    itemType: .walk,
                    weatherIcon: forecast?.icon,
                    temperature: forecast.map { Int($0.temperature) },
                    rainWarning: forecast?.rainWarning ?? false
                ))
            }
        }

        // Sort by target time
        return items.sorted { $0.targetTime < $1.targetTime }
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

#Preview {
    VStack {
        UpcomingEventsCard(
            items: [
                UpcomingItem(
                    icon: "fork.knife",
                    label: "Lunch",
                    detail: "110g",
                    targetTime: Date().addingTimeInterval(-1800), // Overdue
                    isOverdue: true,
                    itemType: .meal
                ),
                UpcomingItem(
                    icon: "figure.walk",
                    label: "Afternoon walk",
                    detail: nil,
                    targetTime: Date().addingTimeInterval(7200),
                    isOverdue: false,
                    itemType: .walk,
                    weatherIcon: "cloud.rain.fill",
                    temperature: 12,
                    rainWarning: true
                ),
                UpcomingItem(
                    icon: "fork.knife",
                    label: "Dinner",
                    detail: "80g",
                    targetTime: Date().addingTimeInterval(14400),
                    isOverdue: false,
                    itemType: .meal
                )
            ],
            isToday: true,
            onLogEvent: { eventType, suggestedTime in
                print("Log event: \(eventType), suggested time: \(suggestedTime?.description ?? "now")")
            }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
