//
//  VerticalTimelineView.swift
//  Ollie-app
//
//  Vertical day-planner style timeline - fresh implementation
//  Building step by step for clarity and correctness

import SwiftUI
import OllieShared
import Combine

/// Vertical day-planner style timeline with hour markers, duration blocks, and point events
struct VerticalTimelineView: View {
    @ObservedObject var viewModel: TimelineViewModel
    let onEditEvent: (PuppyEvent) -> Void
    let onDeleteEvent: (PuppyEvent) -> Void
    var onPhotoTap: ((PuppyEvent) -> Void)?
    var onAppointmentTap: ((DogAppointment) -> Void)?

    /// Optional WeatherService for sunrise/sunset data
    var weatherService: WeatherService?

    @Environment(\.colorScheme) private var colorScheme

    /// Height per hour in points
    private let hourHeight: CGFloat = LayoutConstants.timelineHourHeight

    /// Height of hour labels (used for top padding to prevent clipping)
    private let labelHeight: CGFloat = 14

    /// Width of the time column on the left
    private let timeColumnWidth: CGFloat = LayoutConstants.timelineTimeColumnWidth

    /// Height of point event cards (pill-shaped, same height as icon)
    private let pointEventCardHeight: CGFloat = 28

    /// Vertical spacing between stacked point event cards
    private let pointEventSpacing: CGFloat = 4

    /// Hours to display (0 to max hour, reverse order)
    /// For today: shows up to current hour + 1
    /// For past days: shows full day (0-23)
    private var hoursToShow: [Int] {
        let calendar = Calendar.current

        // Check if viewing today or a past date
        let isToday = calendar.isDateInToday(viewModel.currentDate)

        let maxHour: Int
        if isToday {
            let currentHour = calendar.component(.hour, from: Date())
            maxHour = min(currentHour + 1, 23) // Cap at 23
        } else {
            maxHour = 23 // Show full day for past dates
        }

        // Return hours from maxHour down to 0
        return Array((0...maxHour).reversed())
    }

    /// Total height of the grid (hours + top padding for label)
    private var totalGridHeight: CGFloat {
        CGFloat(hoursToShow.count) * hourHeight + (labelHeight / 2)
    }

    /// Duration items (naps and walks) from the view model
    private var durationItems: [VerticalTimelineItem] {
        viewModel.verticalTimelineItems.filter { $0.hasDuration && $0.isActivityBlock }
    }

    /// Point events (pee, poo, meals, etc.) from the view model
    private var pointItems: [VerticalTimelineItem] {
        viewModel.verticalTimelineItems.filter { !$0.hasDuration }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text(Strings.VerticalTimeline.sectionTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            if viewModel.timelineDisplayEvents.isEmpty && (viewModel.appointmentStore?.todaysAppointments.isEmpty ?? true) {
                EmptyTimelineCard()
            } else {
                timelineContent
            }
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Hour grid (bottom layer)
                hourGrid
                    .padding(.top, labelHeight / 2)
                    .zIndex(0)

                // Current time indicator
                currentTimeIndicator
                    .zIndex(1)

                // Duration blocks (naps and walks) - full width
                durationBlocksLayer
                    .zIndex(2)

                // Point events with stems (top layer - always on top)
                pointEventsLayer
                    .zIndex(3)
            }
            .frame(height: totalGridHeight)
        }
    }

    // MARK: - Hour Grid

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(hoursToShow, id: \.self) { hour in
                HourRow(hour: hour, labelHeight: labelHeight)
                    .frame(height: hourHeight)
            }
        }
    }

    // MARK: - Duration Blocks Layer

    private var durationBlocksLayer: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - timeColumnWidth - 16  // 16 for padding

            ForEach(durationItems) { item in
                let position = calculateBlockPosition(for: item)

                DurationBlockView(
                    item: item,
                    onTap: {
                        handleItemTap(item)
                    }
                )
                .frame(width: contentWidth, height: position.height)
                .offset(x: timeColumnWidth + 8, y: position.yOffset)
            }
        }
    }

    // MARK: - Point Events Layer

    private var pointEventsLayer: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width - timeColumnWidth - 16
            let cardWidth = contentWidth * 0.6  // 60% width for cards
            let stemAnchorX = contentWidth * 0.5  // Middle of timeline for stem anchor

            // Calculate positions with collision detection
            let layoutItems = calculatePointEventLayout(
                items: pointItems,
                cardWidth: cardWidth,
                contentWidth: contentWidth
            )

            ForEach(layoutItems, id: \.item.id) { layoutItem in
                PointEventWithStem(
                    item: layoutItem.item,
                    anchorY: layoutItem.anchorY,
                    cardY: layoutItem.cardY,
                    cardWidth: cardWidth,
                    stemAnchorX: stemAnchorX,
                    timeColumnWidth: timeColumnWidth,
                    contentWidth: contentWidth,
                    onTap: { handleItemTap(layoutItem.item) }
                )
            }
        }
    }

    // MARK: - Point Event Layout Calculation

    private struct PointEventLayoutItem {
        let item: VerticalTimelineItem
        let anchorY: CGFloat  // True timestamp position on timeline
        let cardY: CGFloat    // Actual card position (may be offset for collision)
    }

    private func calculatePointEventLayout(
        items: [VerticalTimelineItem],
        cardWidth: CGFloat,
        contentWidth: CGFloat
    ) -> [PointEventLayoutItem] {
        // Sort by time descending (most recent first = smaller Y values at top)
        // This gives recent events priority placement; older events get pushed down on collision
        let sortedItems = items.sorted { $0.startTime > $1.startTime }

        var layoutItems: [PointEventLayoutItem] = []

        for item in sortedItems {
            let anchorY = calculateYPosition(for: item.startTime)

            // Check for collisions with already-placed cards
            var cardY = anchorY - (pointEventCardHeight / 2)  // Center card on anchor

            // Ensure card doesn't go above the timeline top
            cardY = max(cardY, 0)

            // Check collisions with existing cards and offset if needed
            // Keep checking until we find a non-colliding position
            var hasCollision = true
            while hasCollision {
                hasCollision = false
                for existingItem in layoutItems {
                    let existingTop = existingItem.cardY
                    let existingBottom = existingItem.cardY + pointEventCardHeight

                    let newTop = cardY
                    let newBottom = cardY + pointEventCardHeight

                    // Check if they overlap (with spacing)
                    if newTop < existingBottom + pointEventSpacing && newBottom > existingTop - pointEventSpacing {
                        // Collision detected - move this card below the existing one
                        cardY = existingBottom + pointEventSpacing
                        hasCollision = true
                        break  // Re-check all items at new position
                    }
                }
            }

            layoutItems.append(PointEventLayoutItem(
                item: item,
                anchorY: anchorY,
                cardY: cardY
            ))
        }

        return layoutItems
    }

    // MARK: - Y Position Calculation

    private func calculateYPosition(for time: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        guard let rowIndex = hoursToShow.firstIndex(of: hour) else {
            // Time is beyond displayed hours
            return labelHeight / 2
        }

        let minuteProgress = CGFloat(minute) / 60.0
        return (labelHeight / 2) + (CGFloat(rowIndex) * hourHeight) - (minuteProgress * hourHeight)
    }

    // MARK: - Block Position Calculation

    private struct BlockPosition {
        let yOffset: CGFloat
        let height: CGFloat
    }

    /// Minimum height for duration blocks to ensure text is readable
    private let minBlockHeight: CGFloat = 44

    private func calculateBlockPosition(for item: VerticalTimelineItem) -> BlockPosition {
        let calendar = Calendar.current

        // Get start time - clamp to midnight if it started the previous day
        let dayStart = calendar.startOfDay(for: viewModel.currentDate)
        let effectiveStartTime = max(item.startTime, dayStart)

        // Get end time - use now if ongoing, otherwise the actual end time
        // For ongoing items, extend 5 minutes into the future so the block
        // visually extends above the current time indicator
        let effectiveEndTime: Date
        if item.isOngoing {
            effectiveEndTime = Date().addingTimeInterval(5 * 60)  // +5 minutes
        } else {
            effectiveEndTime = item.endTime ?? item.startTime
        }

        let yTop = calculateYPosition(for: effectiveEndTime)
        let yBottom = calculateYPosition(for: effectiveStartTime)

        let naturalHeight = yBottom - yTop

        // If the block is too short, extend it upward (toward later times)
        // This keeps the bottom anchored at the start time
        if naturalHeight < minBlockHeight {
            let adjustedYTop = yBottom - minBlockHeight
            return BlockPosition(yOffset: max(adjustedYTop, 0), height: minBlockHeight)
        }

        return BlockPosition(yOffset: yTop, height: naturalHeight)
    }

    // MARK: - Item Tap Handler

    private func handleItemTap(_ item: VerticalTimelineItem) {
        switch item.type {
        case .sleepSession(let session):
            // Find the sleep event to edit
            if var sleepEvent = viewModel.events.first(where: { $0.id == session.startEventId }) {
                // If session has ended, populate the duration so edit sheet shows it
                if !session.isOngoing {
                    sleepEvent.durationMin = session.durationMinutes
                }
                onEditEvent(sleepEvent)
            }
        case .walkEvent(let event):
            onEditEvent(event)
        case .pointEvent(let event):
            onEditEvent(event)
        case .appointmentItem(let appointment):
            onAppointmentTap?(appointment)
        }
    }

    // MARK: - Current Time Indicator

    @ViewBuilder
    private var currentTimeIndicator: some View {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        // Calculate Y position
        // First, find which row the current hour is in
        if let rowIndex = hoursToShow.firstIndex(of: hour) {
            // Position within that hour (0.0 at top of hour, 1.0 at bottom)
            let minuteProgress = CGFloat(minute) / 60.0

            // Y position: top padding + row offset - progress within hour (subtract because reverse chronological)
            let yPosition = (labelHeight / 2) + (CGFloat(rowIndex) * hourHeight) - (minuteProgress * hourHeight)

            HStack(spacing: 0) {
                // Time label
                Text(now.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.ollieDanger))

                // Red line extending to the right
                Rectangle()
                    .fill(Color.ollieDanger)
                    .frame(height: 2)
            }
            .offset(y: yPosition)
        }
    }
}

// MARK: - Point Event with Stem

private struct PointEventWithStem: View {
    let item: VerticalTimelineItem
    let anchorY: CGFloat
    let cardY: CGFloat
    let cardWidth: CGFloat
    let stemAnchorX: CGFloat  // Not used anymore, kept for API compatibility
    let timeColumnWidth: CGFloat
    let contentWidth: CGFloat
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Icon size (must match PointEventCard)
    private let iconSize: CGFloat = 28

    /// X position for card's left edge
    private var cardLeftX: CGFloat {
        timeColumnWidth + contentWidth - cardWidth + 8
    }

    /// X position for icon center (where stem should connect)
    private var iconCenterX: CGFloat {
        cardLeftX + iconSize / 2
    }

    /// X position for anchor dot (just to the left of the icon)
    private var anchorX: CGFloat {
        cardLeftX - 12
    }

    /// Card vertical center
    private var cardCenterY: CGFloat {
        cardY + iconSize / 2
    }

    private var iconColor: Color {
        switch item.type {
        case .pointEvent(let event):
            return colorForEvent(event)
        default:
            return .ollieAccent
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Stem line (horizontal from anchor to icon center)
            StemLine(
                anchorX: anchorX,
                anchorY: anchorY,
                cardLeftX: iconCenterX,  // Connect to icon center, not card edge
                cardCenterY: cardCenterY,
                color: iconColor.opacity(0.3)
            )

            // Anchor dot at true timestamp position
            Circle()
                .fill(iconColor)
                .frame(width: 6, height: 6)
                .offset(x: anchorX - 3, y: anchorY - 3)

            // Event card (right-aligned, pill-shaped)
            PointEventCard(item: item, iconColor: iconColor, onTap: onTap)
                .frame(width: cardWidth, height: iconSize)
                .offset(x: cardLeftX, y: cardY)
        }
    }

    private func colorForEvent(_ event: PuppyEvent) -> Color {
        switch event.type {
        case .plassen, .poepen:
            return event.location == .buiten ? .ollieSuccess : .ollieDanger
        case .eten, .drinken:
            return .ollieAccent
        case .training:
            return .olliePurple
        case .sociaal:
            return .ollieSuccess
        case .tuin:
            return .ollieSuccess
        case .milestone:
            return .ollieRose
        case .gewicht:
            return .ollieHealth
        case .medicatie:
            return .ollieHealth
        case .coverageGap:
            return .secondary
        default:
            return .secondary
        }
    }
}

// MARK: - Stem Line

/// L-shaped stem connecting anchor point to card
private struct StemLine: View {
    let anchorX: CGFloat
    let anchorY: CGFloat
    let cardLeftX: CGFloat
    let cardCenterY: CGFloat
    let color: Color

    var body: some View {
        Path { path in
            // Start at anchor point
            path.move(to: CGPoint(x: anchorX, y: anchorY))

            // If anchor and card are at different Y positions, draw L-shape
            // First go horizontally part way, then vertically, then horizontally to card
            let midX = anchorX + 8  // Small horizontal segment from anchor

            if abs(anchorY - cardCenterY) > 2 {
                // Draw to mid point at anchor height
                path.addLine(to: CGPoint(x: midX, y: anchorY))
                // Draw vertically to card height
                path.addLine(to: CGPoint(x: midX, y: cardCenterY))
            }

            // Draw horizontally to card
            path.addLine(to: CGPoint(x: cardLeftX, y: cardCenterY))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Point Event Card

/// Pill-shaped card with icon overlapping left edge
/// Height matches icon size (28pt) for compact stacking
private struct PointEventCard: View {
    let item: VerticalTimelineItem
    let iconColor: Color
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Icon size matches card height for perfect circle overlap
    private let iconSize: CGFloat = 28

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Icon circle (overlaps the left edge of the pill)
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: iconSize, height: iconSize)

                    Image(systemName: item.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                // Time and label on same line
                HStack(spacing: 4) {
                    Text(item.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(shortDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.leading, 6)
                .padding(.trailing, 12)
            }
            .frame(height: iconSize)
            .background(
                // Pill background that starts where icon ends
                Capsule()
                    .fill(cardBackground)
                    .padding(.leading, iconSize / 2)  // Start pill from icon center
            )
            .overlay(
                // Subtle border on pill portion
                Capsule()
                    .strokeBorder(iconColor.opacity(0.15), lineWidth: 0.5)
                    .padding(.leading, iconSize / 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var shortDescription: String {
        switch item.type {
        case .pointEvent(let event):
            switch event.type {
            case .plassen:
                return event.location == .buiten ? "Pee" : "Accident"
            case .poepen:
                return event.location == .buiten ? "Poo" : "Accident"
            case .eten:
                return "Meal"
            case .drinken:
                return "Water"
            case .training:
                return event.exercise ?? "Training"
            case .sociaal:
                return event.who ?? "Social"
            case .gewicht:
                if let kg = event.weightKg {
                    return String(format: "%.1f kg", kg)
                }
                return "Weighed"
            case .medicatie:
                return "Medication"
            default:
                return event.type.label
            }
        default:
            return item.description
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.95)
    }
}

// MARK: - Hour Row

private struct HourRow: View {
    let hour: Int
    let labelHeight: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Hour label column - vertically centered on the line
            Text(hourString)
                .font(.caption2)
                .foregroundStyle(labelColor)
                .frame(width: LayoutConstants.timelineTimeColumnWidth, height: labelHeight, alignment: .trailing)
                .padding(.trailing, 8)
                .offset(y: -labelHeight / 2) // Center label on the line

            // Line and content area
            VStack(spacing: 0) {
                // Horizontal line at the top of each hour
                Rectangle()
                    .fill(lineColor)
                    .frame(height: 1)

                Spacer()
            }
        }
    }

    private var hourString: String {
        String(format: "%d:00", hour)
    }

    /// Slightly more contrast than .tertiary for better accessibility
    private var labelColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.45)
            : Color.black.opacity(0.4)
    }

    private var lineColor: Color {
        // Very subtle hour lines
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }
}

// MARK: - Duration Block View

/// Compact block view for naps and walks using iOS 26 liquid glass design
/// Label positioned at bottom left with time next to title
private struct DurationBlockView: View {
    let item: VerticalTimelineItem
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var blockColor: Color {
        switch item.type {
        case .sleepSession:
            return .ollieSleep
        case .walkEvent:
            return .ollieSuccess
        default:
            return .secondary
        }
    }

    private var glassTint: GlassTint {
        switch item.type {
        case .sleepSession:
            return .sleep
        case .walkEvent:
            return .success
        default:
            return .none
        }
    }

    private var blockLabel: String {
        switch item.type {
        case .sleepSession:
            return Strings.VerticalTimeline.sleep
        case .walkEvent:
            return Strings.VerticalTimeline.walk
        default:
            return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            // Label at top left with duration next to it
            HStack(spacing: 6) {
                Text(blockLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(blockColor)

                // Duration next to label (if available)
                if let duration = item.durationString {
                    Text(duration)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if item.isOngoing {
                    // Live duration for ongoing activities
                    LiveDurationText(startTime: item.startTime, color: blockColor)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .liquidGlass(style: .card, tint: glassTint, cornerRadius: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Live Duration Text

/// Shows live-updating duration for ongoing activities
private struct LiveDurationText: View {
    let startTime: Date
    let color: Color

    @State private var now = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var durationString: String {
        let minutes = Int(now.timeIntervalSince(startTime) / 60)
        if minutes < 60 {
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

    var body: some View {
        Text(durationString)
            .font(.caption2)
            .foregroundStyle(color)
            .onReceive(timer) { _ in
                now = Date()
            }
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    ScrollView {
        VerticalTimelineView(
            viewModel: viewModel,
            onEditEvent: { _ in },
            onDeleteEvent: { _ in }
        )
        .padding()
    }
    .background(Color(.systemGray6))
}
