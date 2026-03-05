//
//  VerticalTimelineView.swift
//  Otis-app
//
//  Vertical day-planner style timeline - fresh implementation
//  Building step by step for clarity and correctness

import SwiftUI
import OtisShared
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

    /// Household members for event attribution display
    private var householdMembers: HouseholdMembers? {
        viewModel.profileStore.profile?.householdMembers
    }

    @Environment(\.colorScheme) private var colorScheme

    /// Expanded training sessions (by session ID)
    @State private var expandedTrainingSessions: Set<UUID> = []

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

    /// Horizontal inset between time column and timeline content
    private let timelineHorizontalInset: CGFloat = 8

    /// Prevent cards from collapsing in split-view widths
    private let minimumTimelineContentWidth: CGFloat = 220

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

    /// Point events (pee, poo, meals, etc.) from the view model - excludes training sessions
    private var pointItems: [VerticalTimelineItem] {
        viewModel.verticalTimelineItems.filter { !$0.hasDuration && !$0.isTrainingSession }
    }

    /// Training session items (grouped training events)
    private var trainingSessionItems: [VerticalTimelineItem] {
        viewModel.verticalTimelineItems.filter { $0.isTrainingSession }
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

                // Training sessions layer
                trainingSessionsLayer
                    .zIndex(3)

                // Point events with stems (top layer - always on top)
                pointEventsLayer
                    .zIndex(4)
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
            let contentWidth = timelineContentWidth(for: geometry.size.width)

            ForEach(durationItems) { item in
                let position = calculateBlockPosition(for: item)

                DurationBlockView(
                    item: item,
                    onTap: {
                        handleItemTap(item)
                    }
                )
                .frame(width: contentWidth, height: position.height)
                .offset(x: timeColumnWidth + timelineHorizontalInset, y: position.yOffset)
            }
        }
    }

    // MARK: - Training Sessions Layer

    private var trainingSessionsLayer: some View {
        GeometryReader { geometry in
            let contentWidth = timelineContentWidth(for: geometry.size.width)
            let cardWidth = max(contentWidth * 0.7, 180)  // Keep cards usable on narrow split widths

            ForEach(trainingSessionItems) { item in
                if case .trainingSession(let session) = item.type {
                    let anchorY = calculateYPosition(for: item.startTime)
                    let isExpanded = expandedTrainingSessions.contains(session.id)

                    TrainingSessionCardWithStem(
                        session: session,
                        anchorY: anchorY,
                        cardWidth: cardWidth,
                        timeColumnWidth: timeColumnWidth,
                        contentWidth: contentWidth,
                        isExpanded: isExpanded,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedTrainingSessions.contains(session.id) {
                                    expandedTrainingSessions.remove(session.id)
                                } else {
                                    expandedTrainingSessions.insert(session.id)
                                }
                            }
                        },
                        onEventTap: { event in
                            onEditEvent(event)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Point Events Layer

    private var pointEventsLayer: some View {
        GeometryReader { geometry in
            let contentWidth = timelineContentWidth(for: geometry.size.width)
            let cardWidth = max(contentWidth * 0.6, 170)  // Keep cards readable on narrow split widths
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
                    householdMembers: householdMembers,
                    onTap: { handleItemTap(layoutItem.item) }
                )
            }
        }
    }

    private func timelineContentWidth(for totalWidth: CGFloat) -> CGFloat {
        max(totalWidth - timeColumnWidth - (timelineHorizontalInset * 2), minimumTimelineContentWidth)
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
        case .trainingSession:
            // Training sessions handle their own tap (expand/collapse)
            // Individual event taps are handled by TrainingSessionCardWithStem
            break
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
                    .background(Capsule().fill(Color.otisDanger))

                // Red line extending to the right
                Rectangle()
                    .fill(Color.otisDanger)
                    .frame(height: 2)
            }
            .offset(y: yPosition)
        }
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
