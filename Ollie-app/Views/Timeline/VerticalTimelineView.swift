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
    @Bindable var viewModel: TimelineViewModel
    let onEditEvent: (PuppyEvent) -> Void
    let onDeleteEvent: (PuppyEvent) -> Void
    var onPhotoTap: ((PuppyEvent) -> Void)?
    var onAppointmentTap: ((DogAppointment) -> Void)?

    /// Optional WeatherService for sunrise/sunset data
    var weatherService: WeatherService?

    // Note: Event attribution now uses CloudKit record IDs via UserIdentityStore
    // instead of profile-embedded HouseholdMembers

    @Environment(\.colorScheme) private var colorScheme

    /// Expanded training sessions (by session ID)
    @State private var expandedTrainingSessions: Set<UUID> = []

    /// Cached hours array to avoid recomputation on every access
    /// Updated via .onChange when currentDate changes
    @State private var cachedHoursToShow: [Int] = []

    /// Cached hour index lookup for O(1) position calculation instead of O(n) firstIndex
    @State private var hourIndexLookup: [Int: Int] = [:]

    /// Cached filtered items to avoid repeated filtering on every render
    @State private var cachedDurationItems: [VerticalTimelineItem] = []
    @State private var cachedPointItems: [VerticalTimelineItem] = []
    @State private var cachedTrainingSessionItems: [VerticalTimelineItem] = []

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

    /// Hours to display - uses cached value for performance
    /// PERF: Cached to avoid recomputation on every access (was called 4+ times per render)
    private var hoursToShow: [Int] {
        cachedHoursToShow
    }

    /// Computes the hours array - called once when date changes
    private func computeHoursToShow() -> [Int] {
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

    /// Updates the cached hours and lookup dictionary
    private func updateHoursCache() {
        let hours = computeHoursToShow()
        cachedHoursToShow = hours
        // Build O(1) lookup dictionary for hour -> index
        hourIndexLookup = Dictionary(uniqueKeysWithValues: hours.enumerated().map { ($1, $0) })
    }

    /// Total height of the grid (hours + top padding for label)
    private var totalGridHeight: CGFloat {
        CGFloat(cachedHoursToShow.count) * hourHeight + (labelHeight / 2)
    }

    /// Duration items (naps and walks) from the view model - uses cached value
    private var durationItems: [VerticalTimelineItem] {
        cachedDurationItems
    }

    /// Point events (pee, poo, meals, etc.) from the view model - uses cached value
    private var pointItems: [VerticalTimelineItem] {
        cachedPointItems
    }

    /// Training session items (grouped training events) - uses cached value
    private var trainingSessionItems: [VerticalTimelineItem] {
        cachedTrainingSessionItems
    }

    /// Updates the cached filtered item arrays
    private func updateFilteredItemsCache() {
        let allItems = viewModel.verticalTimelineItems
        cachedDurationItems = allItems.filter { $0.hasDuration && $0.isActivityBlock }
        cachedPointItems = allItems.filter { !$0.hasDuration && !$0.isTrainingSession }
        cachedTrainingSessionItems = allItems.filter { $0.isTrainingSession }
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
        .onAppear {
            updateHoursCache()
            updateFilteredItemsCache()
        }
        .onChange(of: viewModel.currentDate) { _, _ in
            updateHoursCache()
            updateFilteredItemsCache()
        }
        .onChange(of: viewModel.cachedVerticalTimelineItems) { _, _ in
            updateFilteredItemsCache()
        }
    }

    // MARK: - Timeline Content

    /// PERF: Single GeometryReader instead of 3 separate ones (each GeometryReader = layout pass)
    private var timelineContent: some View {
        ScrollView {
            GeometryReader { geometry in
                let contentWidth = timelineContentWidth(for: geometry.size.width)

                ZStack(alignment: .topLeading) {
                    // Hour grid (bottom layer)
                    hourGrid
                        .padding(.top, labelHeight / 2)
                        .zIndex(0)

                    // Current time indicator
                    currentTimeIndicator
                        .zIndex(1)

                    // Duration blocks (naps and walks) - full width
                    durationBlocksContent(contentWidth: contentWidth)
                        .zIndex(2)

                    // Training sessions layer
                    trainingSessionsContent(contentWidth: contentWidth)
                        .zIndex(3)

                    // Point events with stems (top layer - always on top)
                    pointEventsContent(contentWidth: contentWidth)
                        .zIndex(4)
                }
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

    // MARK: - Duration Blocks Content

    @ViewBuilder
    private func durationBlocksContent(contentWidth: CGFloat) -> some View {
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

    // MARK: - Training Sessions Content

    @ViewBuilder
    private func trainingSessionsContent(contentWidth: CGFloat) -> some View {
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

    // MARK: - Point Events Content

    @ViewBuilder
    private func pointEventsContent(contentWidth: CGFloat) -> some View {
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
                onTap: { handleItemTap(layoutItem.item) }
            )
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

        // Track occupied Y ranges for O(n) collision detection instead of O(n²)
        // Each range is (top, bottom) of an occupied area
        var occupiedRanges: [(top: CGFloat, bottom: CGFloat)] = []

        for item in sortedItems {
            let anchorY = calculateYPosition(for: item.startTime)

            // Check for collisions with already-placed cards
            var cardY = anchorY - (pointEventCardHeight / 2)  // Center card on anchor

            // Ensure card doesn't go above the timeline top
            cardY = max(cardY, 0)

            // Find placement using sorted occupied ranges
            // Check against occupied ranges and find the next available slot
            for range in occupiedRanges {
                let cardTop = cardY
                let cardBottom = cardY + pointEventCardHeight

                // Check if they overlap
                if cardTop < range.bottom + pointEventSpacing && cardBottom > range.top - pointEventSpacing {
                    // Collision - move below this range
                    cardY = range.bottom + pointEventSpacing
                }
            }

            // Add this card's range to occupied list (keep sorted by top position)
            let newRange = (top: cardY, bottom: cardY + pointEventCardHeight)
            // Insert in sorted order for efficient future checks
            if let insertIndex = occupiedRanges.firstIndex(where: { $0.top > newRange.top }) {
                occupiedRanges.insert(newRange, at: insertIndex)
            } else {
                occupiedRanges.append(newRange)
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

    /// PERF: Uses O(1) dictionary lookup instead of O(n) firstIndex search
    private func calculateYPosition(for time: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        guard let rowIndex = hourIndexLookup[hour] else {
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
            // Walk events with photos: show photo viewer
            if event.photo != nil, let onPhotoTap = onPhotoTap {
                onPhotoTap(event)
            } else {
                onEditEvent(event)
            }
        case .pointEvent(let event):
            // Events with photos (especially moments): show photo viewer instead of edit
            if event.photo != nil, let onPhotoTap = onPhotoTap {
                onPhotoTap(event)
            } else {
                onEditEvent(event)
            }
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
        // PERF: Use O(1) dictionary lookup instead of O(n) firstIndex
        if let rowIndex = hourIndexLookup[hour] {
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
