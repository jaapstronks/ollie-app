//
//  VerticalTimelineView.swift
//  Ollie-app
//
//  Vertical day-planner style timeline with 24-hour grid, dual-track layout,
//  daylight gradient, and appointment support

import SwiftUI
import OllieShared

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

    /// Grid calculator for Y positioning
    private var calculator: TimelineGridCalculator {
        TimelineGridCalculator(for: viewModel.currentDate)
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

            if viewModel.events.isEmpty && (viewModel.appointmentStore?.todaysAppointments.isEmpty ?? true) {
                EmptyTimelineCard()
            } else {
                timelineContent
            }
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width - LayoutConstants.timelineTimeColumnWidth - 16

                    ZStack(alignment: .topLeading) {
                        // Layer 1: Daylight gradient background
                        DaylightGradientView(
                            sunrise: weatherService?.sunrise,
                            sunset: weatherService?.sunset,
                            calculator: calculator
                        )

                        // Layer 2: Hour grid lines
                        HourGridLayer(calculator: calculator)

                        // Layer 3: Walk track items (right side, 45% width)
                        walkTrackItems(availableWidth: availableWidth)

                        // Layer 4: Main track items (full width)
                        mainTrackItems(availableWidth: availableWidth)

                        // Layer 5: Current time indicator (for today only)
                        if viewModel.isShowingToday {
                            currentTimeIndicator
                                .id("current-time")
                        }
                    }
                }
                .frame(height: calculator.totalHeight)
            }
            .onAppear {
                // Auto-scroll to current time on appear (for today)
                if viewModel.isShowingToday {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToCurrentTime(proxy: proxy)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM)
                .fill(cardBackground)
        )
    }

    // MARK: - Walk Track Items

    @ViewBuilder
    private func walkTrackItems(availableWidth: CGFloat) -> some View {
        let walkItems = viewModel.verticalTimelineItems.filter { $0.track == .walk }
        let walkWidth = availableWidth * LayoutConstants.timelineWalkTrackWidthRatio
        let xOffset = LayoutConstants.timelineTimeColumnWidth + (availableWidth - walkWidth)

        ForEach(walkItems) { item in
            let yPos = calculator.yPosition(for: item.startTime)
            let height = itemHeight(for: item)

            TimelineBlock(item: item, height: height, isWalkTrack: true) {
                handleItemTap(item)
            }
            .frame(width: walkWidth)
            .position(x: xOffset + walkWidth / 2, y: yPos + height / 2)
            .contextMenu {
                contextMenuItems(for: item)
            }
        }
    }

    // MARK: - Main Track Items

    @ViewBuilder
    private func mainTrackItems(availableWidth: CGFloat) -> some View {
        let mainItems = viewModel.verticalTimelineItems.filter { $0.track == .main }
        let xOffset = LayoutConstants.timelineTimeColumnWidth + 8

        ForEach(mainItems) { item in
            let yPos = calculator.yPosition(for: item.startTime)

            Group {
                if item.hasDuration {
                    let height = itemHeight(for: item)

                    if item.isAppointment {
                        appointmentView(for: item, height: height)
                    } else {
                        // Duration blocks (sleep)
                        TimelineBlock(item: item, height: height, isWalkTrack: false) {
                            handleItemTap(item)
                        }
                        .contextMenu {
                            contextMenuItems(for: item)
                        }
                    }
                } else {
                    // Point events
                    TimelineEventMarker(item: item) {
                        handleItemTap(item)
                    }
                    .contextMenu {
                        contextMenuItems(for: item)
                    }
                }
            }
            .frame(width: availableWidth)
            .position(x: xOffset + availableWidth / 2, y: yPos + LayoutConstants.timelineEventMarkerHeight / 2)
        }
    }

    // MARK: - Appointment View

    @ViewBuilder
    private func appointmentView(for item: VerticalTimelineItem, height: CGFloat) -> some View {
        if case .appointmentItem(let appointment) = item.type {
            TimelineAppointmentMarker(
                appointment: appointment,
                height: height
            ) {
                onAppointmentTap?(appointment)
            }
        }
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let now = Date()
        let yPos = calculator.yPosition(for: now)

        return HStack(spacing: 0) {
            // Time label
            Text(now.timeString)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.ollieDanger)
                )

            // Red line extending to the right
            Rectangle()
                .fill(Color.ollieDanger)
                .frame(height: 2)
        }
        .offset(y: yPos)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for item: VerticalTimelineItem) -> some View {
        Button {
            if let event = eventForItem(item) {
                onEditEvent(event)
            }
        } label: {
            Label(Strings.Common.edit, systemImage: "pencil")
        }

        Button(role: .destructive) {
            HapticFeedback.warning()
            if let event = eventForItem(item) {
                onDeleteEvent(event)
            }
        } label: {
            Label(Strings.Common.delete, systemImage: "trash")
        }
    }

    // MARK: - Helpers

    private func itemHeight(for item: VerticalTimelineItem) -> CGFloat {
        guard let endTime = item.endTime else {
            // Ongoing items - calculate from now
            if item.isOngoing {
                let height = calculator.blockHeight(from: item.startTime, to: Date())
                return max(height, LayoutConstants.timelineMinBlockHeight)
            }
            return LayoutConstants.timelineEventMarkerHeight
        }

        let height = calculator.blockHeight(from: item.startTime, to: endTime)
        return max(height, LayoutConstants.timelineMinBlockHeight)
    }

    private func handleItemTap(_ item: VerticalTimelineItem) {
        HapticFeedback.selection()

        // If item has photo, trigger photo viewer
        if item.photoThumbnail != nil, let event = eventForItem(item) {
            onPhotoTap?(event)
            return
        }

        // For appointments, use appointment tap handler
        if case .appointmentItem(let appointment) = item.type {
            onAppointmentTap?(appointment)
            return
        }

        // Otherwise, edit the event
        if let event = eventForItem(item) {
            onEditEvent(event)
        }
    }

    private func eventForItem(_ item: VerticalTimelineItem) -> PuppyEvent? {
        switch item.type {
        case .sleepSession(let session):
            return viewModel.events.first { $0.id == session.startEventId }
        case .walkEvent(let event):
            return event
        case .pointEvent(let event):
            return event
        case .appointmentItem:
            return nil
        }
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // Calculate a good scroll position (show some context before current time)
        let scrollToHour = max(currentHour - 2, 0)
        let yOffset = calculator.yPosition(forHour: scrollToHour)

        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo("current-time", anchor: .center)
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.ollieCardDark : Color.ollieCardLight
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return ScrollView {
        VerticalTimelineView(
            viewModel: viewModel,
            onEditEvent: { _ in },
            onDeleteEvent: { _ in }
        )
        .padding()
    }
    .background(Color(.systemGray6))
}
