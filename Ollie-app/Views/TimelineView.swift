//
//  TimelineView.swift
//  Ollie-app
//

import SwiftUI
import OllieShared
import TipKit

/// Main timeline view showing today's events
struct TimelineView: View {
    @ObservedObject var viewModel: TimelineViewModel
    /// Weather service passed down but not observed here to avoid full view redraws
    /// Weather-dependent sections use their own observation via WeatherSectionContainer
    let weatherService: WeatherService
    @StateObject private var mediaCaptureViewModel = MediaCaptureViewModel(mediaStore: MediaStore())
    @State private var selectedPhotoEvent: PuppyEvent?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var spotStore: SpotStore
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 0) {
            // Date navigation header
            DateHeader(
                title: viewModel.dateTitle,
                canGoForward: viewModel.canGoForward,
                onPrevious: {
                    HapticFeedback.selection()
                    viewModel.goToPreviousDay()
                },
                onNext: {
                    HapticFeedback.selection()
                    viewModel.goToNextDay()
                },
                onToday: viewModel.goToToday
            )

            // Trial banner (show during last 7 days of free period)
            if viewModel.shouldShowTrialBanner {
                TrialBanner(
                    daysRemaining: viewModel.freeDaysRemaining,
                    onTap: { viewModel.sheetCoordinator.presentSheet(.olliePlus) }
                )
            }

            // Weather section container (isolates weather observation to avoid full view redraws)
            WeatherSectionContainer(
                weatherService: weatherService,
                isToday: Calendar.current.isDateInToday(viewModel.currentDate),
                predictedPottyTime: viewModel.predictedNextPlasTime
            )

            // Daily digest summary
            DigestCard(
                digest: viewModel.dailyDigest,
                puppyName: viewModel.puppyName
            )

            // Scheduled events section (owns weather observation via @ObservedObject)
            ScheduledEventsSection(
                viewModel: viewModel,
                weatherService: weatherService
            )

            // V3: Potty status hero card with smart predictions
            PottyStatusCard(
                prediction: viewModel.pottyPrediction,
                puppyName: viewModel.puppyName
            )

            // Sleep status card
            SleepStatusCard(sleepState: viewModel.currentSleepState)

            // Streak card (outdoor potty streak)
            StreakCard(streakInfo: viewModel.streakInfo)

            // Event list with pull-to-refresh
            if viewModel.events.isEmpty {
                ScrollView {
                    EmptyTimelineView()
                }
                .refreshable {
                    viewModel.loadEvents()
                }
            } else {
                EventList(
                    timelineItems: viewModel.timelineItems,
                    events: viewModel.events,
                    onDelete: viewModel.deleteEvent,
                    onRefresh: viewModel.loadEvents,
                    onTapPhoto: { event in
                        selectedPhotoEvent = event
                    }
                )
            }

            Spacer()

            // Quick log bar (V3: smart contextual icons)
            QuickLogBar(
                context: viewModel.quickLogContext,
                canLogEvents: viewModel.canLogEvents,
                onPottyTap: viewModel.showPottySheet,
                onQuickLog: { type in viewModel.quickLog(type: type) },
                onShowAllEvents: viewModel.showAllEvents,
                onCameraTap: viewModel.openCamera
            )
        }
        // Swipe gestures for day navigation
        .dayNavigation(
            canGoForward: viewModel.canGoForward,
            onPreviousDay: viewModel.goToPreviousDay,
            onNextDay: viewModel.goToNextDay
        )
        // All sheets from shared modifier
        .timelineSheetHandling(
            viewModel: viewModel,
            mediaCaptureViewModel: mediaCaptureViewModel,
            selectedPhotoEvent: $selectedPhotoEvent,
            reduceMotion: reduceMotion,
            spotStore: spotStore,
            locationManager: locationManager
        )
        .task {
            // Fetch weather on appear
            await weatherService.fetchForecasts()
        }
    }
}

// MARK: - Undo Banner

struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .foregroundColor(.white)

            Spacer()

            Button(Strings.Common.undo) {
                onUndo()
            }
            .fontWeight(.semibold)
            .foregroundColor(.yellow)
            .frame(minWidth: 44, minHeight: 44)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(LayoutConstants.cornerRadiusM)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Timeline.eventDeleted)
        .accessibilityHint(Strings.Timeline.undoAccessibility)
    }
}

// MARK: - Subviews

struct DateHeader: View {
    let title: String
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Strings.Timeline.previousDay)

            Spacer()

            Button(action: onToday) {
                Text(title)
                    .font(.headline)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Timeline.dateLabel(date: title))
            .accessibilityHint(Strings.Timeline.goToTodayHint)
            .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .opacity(canGoForward ? 1 : 0.3)
            .disabled(!canGoForward)
            .accessibilityLabel(Strings.Timeline.nextDay)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// TimelineItem enum moved to TimelineViewModel for pre-computation

struct EventList: View {
    /// Pre-computed timeline items from ViewModel (avoids O(n²) computation on every render)
    let timelineItems: [TimelineItem]
    /// Raw events for deletion operations
    let events: [PuppyEvent]
    let onDelete: (PuppyEvent) -> Void
    let onDeleteSession: ((SleepSession) -> Void)?
    let onRefresh: () -> Void
    let onTapPhoto: (PuppyEvent) -> Void

    private let swipeToDeleteTip = SwipeToDeleteTip()

    init(
        timelineItems: [TimelineItem],
        events: [PuppyEvent],
        onDelete: @escaping (PuppyEvent) -> Void,
        onRefresh: @escaping () -> Void,
        onTapPhoto: @escaping (PuppyEvent) -> Void,
        onDeleteSession: ((SleepSession) -> Void)? = nil
    ) {
        self.timelineItems = timelineItems
        self.events = events
        self.onDelete = onDelete
        self.onDeleteSession = onDeleteSession
        self.onRefresh = onRefresh
        self.onTapPhoto = onTapPhoto
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                // Tip for swipe-to-delete (shown once at top of list)
                TipView(swipeToDeleteTip)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                ForEach(timelineItems) { item in
                    switch item {
                    case .event(let event):
                        EventRow(event: event)
                            .id(event.id)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                if event.photo != nil {
                                    onTapPhoto(event)
                                }
                            }

                    case .sleepSession(let session, let note):
                        SleepSessionRow(
                            session: session,
                            note: note,
                            onEditStart: {},
                            onEditEnd: {},
                            onDelete: {
                                if let deleteSession = onDeleteSession {
                                    deleteSession(session)
                                } else {
                                    // Fallback: delete individual events
                                    if let sleepEvent = events.first(where: { $0.id == session.startEventId }) {
                                        onDelete(sleepEvent)
                                    }
                                    if let endId = session.endEventId,
                                       let wakeEvent = events.first(where: { $0.id == endId }) {
                                        onDelete(wakeEvent)
                                    }
                                }
                            }
                        )
                        .id(session.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let item = timelineItems[index]
                        HapticFeedback.warning()
                        switch item {
                        case .event(let event):
                            onDelete(event)
                        case .sleepSession(let session, _):
                            // Delete both sleep and wake events
                            if let sleepEvent = events.first(where: { $0.id == session.startEventId }) {
                                onDelete(sleepEvent)
                            }
                            if let endId = session.endEventId,
                               let wakeEvent = events.first(where: { $0.id == endId }) {
                                onDelete(wakeEvent)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                onRefresh()
            }
            .onChange(of: events.count) { _, _ in
                // Scroll to latest item
                if let lastItem = timelineItems.last {
                    withAnimation {
                        proxy.scrollTo(lastItem.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct EmptyTimelineView: View {
    private let quickLogBarTip = QuickLogBarTip()

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Animated paw prints
            ZStack {
                // Background paw (slightly offset)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.ollieAccent.opacity(0.2))
                    .offset(x: 15, y: -10)
                    .rotationEffect(.degrees(-15))

                // Main paw with animation
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.ollieAccent, Color.ollieAccent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.7)

                // Small accent paw
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.ollieSuccess.opacity(0.5))
                    .offset(x: -25, y: 20)
                    .rotationEffect(.degrees(20))
            }
            .padding(.bottom, 8)
            .onAppear {
                guard !reduceMotion else {
                    isAnimating = true
                    return
                }
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }

            VStack(spacing: 8) {
                Text(Strings.Timeline.noEvents)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(Strings.Timeline.tapToLog)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Tip for using the quick log bar
            TipView(quickLogBarTip)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Timeline.noEvents)
        .accessibilityHint(Strings.Timeline.tapToLog)
    }
}

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let weatherService = WeatherService()
    return TimelineView(viewModel: viewModel, weatherService: weatherService)
}
