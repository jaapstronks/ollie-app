//
//  UpcomingEventsCard.swift
//  Otis-app
//

import SwiftUI
import OtisShared

// MARK: - Actionable Event Card

/// Prominent card that appears when a meal or walk is actionable (within 10 min or overdue)
struct ActionableEventCard: View {
    let actionableItem: ActionableItem
    let onLogEvent: (EventType, Date?) -> Void
    var onNavigateToSocialization: (() -> Void)?

    @EnvironmentObject private var socializationStore: SocializationStore
    @AppStorage(UserPreferences.Key.temperatureUnit.rawValue) private var temperatureUnitRaw = TemperatureUnit.celsius.rawValue
    @State private var showWalkTips = false

    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius
    }

    /// Suggested items to watch for during walks (max 2)
    private var walkTips: [SocializationItem] {
        socializationStore.suggestedWalkItems(limit: 2)
    }

    var body: some View {
        VStack(spacing: 12) {
            StatusCardHeader(
                iconName: iconName,
                iconColor: indicatorColor,
                tintColor: indicatorColor,
                title: mainText,
                titleColor: textColor,
                subtitle: subtitleText,
                iconSize: 40
            ) { EmptyView() }

            // Weather + Action row
            if actionableItem.item.itemType == .walk, let weatherIcon = actionableItem.item.weatherIcon {
                // Side by side layout for walks with weather
                HStack(spacing: 12) {
                    weatherBadge(icon: weatherIcon)
                    Spacer()
                    Button {
                        onLogEvent(actionableItem.item.itemType.eventType, actionableItem.item.targetTime)
                    } label: {
                        Label(buttonText, systemImage: buttonIcon)
                    }
                    .buttonStyle(.glassPill(tint: buttonTint))
                }
            } else {
                // Centered button for meals or walks without weather
                Button {
                    onLogEvent(actionableItem.item.itemType.eventType, actionableItem.item.targetTime)
                } label: {
                    Label(buttonText, systemImage: buttonIcon)
                }
                .buttonStyle(.glassPill(tint: buttonTint))
            }

            // Walk tips section (only for walks with socialization items)
            if actionableItem.item.itemType == .walk && !walkTips.isEmpty {
                walkTipsSection
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassStatusCard(tintColor: indicatorColor)
    }

    // MARK: - Walk Tips Section

    @ViewBuilder
    private var walkTipsSection: some View {
        VStack(spacing: 8) {
            // Toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showWalkTips.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "eye")
                        .font(.caption)
                    Text(Strings.Socialization.watchFor)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: showWalkTips ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.secondary.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Expanded tips
            if showWalkTips {
                VStack(spacing: 6) {
                    ForEach(walkTips) { item in
                        HStack(spacing: 8) {
                            if let category = socializationStore.category(forItemId: item.id) {
                                Image(systemName: category.icon)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16)
                            }
                            Text(item.localizedDisplayName)
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                    }

                    // Link to full socialization view
                    if let onNavigate = onNavigateToSocialization {
                        Button {
                            onNavigate()
                        } label: {
                            HStack(spacing: 4) {
                                Text(Strings.Socialization.seeAll)
                                    .font(.caption)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundStyle(Color.otisAccent)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Weather Badge

    @ViewBuilder
    private func weatherBadge(icon: String) -> some View {
        let item = actionableItem.item

        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .symbolRenderingMode(.multicolor)

            if let temp = item.temperature {
                Text(temperatureUnit.format(Double(temp)))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            if item.rainWarning {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                    Text(Strings.Weather.rainExpected)
                        .font(.caption)
                }
                .foregroundStyle(Color.otisDanger)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemBackground))
        .clipShape(Capsule())
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
        case .overdue:
            // Show "Time for a walk" instead of "Walk overdue by X min"
            switch actionableItem.item.itemType {
            case .walk: return Strings.Actionable.timeForWalk
            case .meal: return Strings.Actionable.timeForMeal
            }
        }
    }

    private var subtitleText: String? {
        switch actionableItem.state {
        case .overdue:
            // Show "Was scheduled at <time>" for overdue items
            return Strings.Actionable.wasScheduledAt(time: actionableItem.item.timeString)
        default:
            // Show detail like "2/9 walks today" or "110g"
            return actionableItem.item.detail
        }
    }

    private var indicatorColor: Color {
        switch actionableItem.state {
        case .approaching: return .otisInfo
        case .due: return .otisSuccess
        case .overdue: return .otisWarning
        }
    }

    private var textColor: Color {
        switch actionableItem.state {
        case .approaching: return .primary
        case .due: return .primary
        case .overdue: return .otisWarning
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

    /// Pre-computed separated items (optional, to avoid redundant calculation when passed from parent)
    var precomputedSeparated: (actionable: [ActionableItem], upcoming: [UpcomingItem])?

    /// Whether puppy is sleeping (passed in to avoid redundant state access)
    var isSleeping: Bool = false

    /// Navigation callback for socialization (Train tab)
    var onNavigateToSocialization: (() -> Void)?

    var body: some View {
        // Use precomputed values if available, otherwise compute here
        let separated = precomputedSeparated ?? viewModel.separatedUpcomingItems(forecasts: weatherService.forecasts)

        // Actionable events (within 10 min or overdue - shown prominently)
        // HIDE when puppy is sleeping - the sleep card will mention pending activities
        if !isSleeping {
            ForEach(separated.actionable) { actionableItem in
                ActionableEventCard(
                    actionableItem: actionableItem,
                    onLogEvent: { eventType, suggestedTime in
                        viewModel.quickLog(type: eventType, suggestedTime: suggestedTime)
                    },
                    onNavigateToSocialization: onNavigateToSocialization
                )
            }
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
    @AppStorage(UserPreferences.Key.temperatureUnit.rawValue) private var temperatureUnitRaw = TemperatureUnit.celsius.rawValue

    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRaw) ?? .celsius
    }

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
            .cornerRadius(LayoutConstants.cornerRadiusM)
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

            // Icon with approaching indicator - color based on item type
            ZStack(alignment: .topTrailing) {
                Image(systemName: item.icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor(for: item.itemType))
                    .frame(width: 20)

                // Dot for items approaching (within 30 min)
                if item.minutesUntil <= 30 && item.minutesUntil > 10 {
                    Circle()
                        .fill(iconColor(for: item.itemType))
                        .frame(width: 6, height: 6)
                        .offset(x: 2, y: -2)
                }
            }

            // Label (re-localized to current locale)
            Text(item.localizedLabel)
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
                        Text(temperatureUnit.format(Double(temp)))
                            .font(.caption2)
                    }
                }
                .foregroundStyle(item.rainWarning ? Color.otisDanger : Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// Returns the appropriate color for an item type
    private func iconColor(for itemType: UpcomingItemType) -> Color {
        switch itemType {
        case .walk:
            return .otisSuccess // Green for outdoor activities
        case .meal:
            return .otisAccent  // Gold for meals
        }
    }
}

// MARK: - Upcoming Items Calculation
// Note: UpcomingCalculations has been moved to Calculations/UpcomingItemsCalculations.swift

// MARK: - Previews

#Preview("Actionable - Approaching (sunny)") {
    VStack {
        ActionableEventCard(
            actionableItem: ActionableItem(
                item: UpcomingItem(
                    icon: "figure.walk",
                    label: "Afternoon walk",
                    detail: "2/9 walks",
                    targetTime: Date().addingTimeInterval(8 * 60),
                    itemType: .walk,
                    weatherIcon: "sun.max.fill",
                    temperature: 18
                ),
                state: .approaching(minutesUntil: 8)
            ),
            onLogEvent: { _, _ in }
        )
        Spacer()
    }
    .padding()
    .environmentObject(SocializationStore())
}

#Preview("Actionable - Due (meal)") {
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
    .environmentObject(SocializationStore())
}

#Preview("Actionable - Due (walk, cloudy)") {
    VStack {
        ActionableEventCard(
            actionableItem: ActionableItem(
                item: UpcomingItem(
                    icon: "figure.walk",
                    label: "Afternoon walk",
                    detail: "2/9 walks",
                    targetTime: Date(),
                    itemType: .walk,
                    weatherIcon: "cloud.fill",
                    temperature: 14
                ),
                state: .due
            ),
            onLogEvent: { _, _ in }
        )
        Spacer()
    }
    .padding()
    .environmentObject(SocializationStore())
}

#Preview("Actionable - Overdue (rainy)") {
    VStack {
        ActionableEventCard(
            actionableItem: ActionableItem(
                item: UpcomingItem(
                    icon: "figure.walk",
                    label: "Morning walk",
                    detail: "1/9 walks",
                    targetTime: Date().addingTimeInterval(-25 * 60),
                    itemType: .walk,
                    weatherIcon: "cloud.rain.fill",
                    temperature: 8,
                    rainWarning: true
                ),
                state: .overdue(minutesOverdue: 25)
            ),
            onLogEvent: { _, _ in }
        )
        Spacer()
    }
    .padding()
    .environmentObject(SocializationStore())
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
