//
//  TodayView.swift
//  Ollie-app
//
//  The "Vandaag" (Today) tab - the daily hub showing everything needed right now
//  Combines the web app's "home" and "dag" views into a single scrollable view

import SwiftUI
import TipKit

/// Main "Today" tab showing the daily hub
struct TodayView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var weatherService: WeatherService
    let onSettingsTap: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var selectedPhotoEvent: PuppyEvent?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar with date and settings gear
            todayNavBar

            // Trial banner (show during last 7 days of free period)
            if viewModel.shouldShowTrialBanner {
                TrialBanner(
                    daysRemaining: viewModel.freeDaysRemaining,
                    onTap: { viewModel.sheetCoordinator.presentSheet(.upgradePrompt) }
                )
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Weather section (only show for today)
                    if Calendar.current.isDateInToday(viewModel.currentDate) {
                        WeatherSection(
                            forecasts: weatherService.upcomingForecasts(hours: 6),
                            alert: weatherService.smartAlert(predictedPottyTime: viewModel.predictedNextPlasTime),
                            isLoading: weatherService.isLoading
                        )
                        .padding(.vertical, 8)
                    }

                    // Day hero - "Day X with Ollie" at top for context
                    DayHeroCard(
                        dayNumber: viewModel.dailyDigest.dayNumber,
                        puppyName: viewModel.puppyName
                    )

                    // Status cards section (only for today)
                    if viewModel.isShowingToday {
                        statusCardsSection
                    }

                    // Streak card (motivational - only if there's a streak)
                    StreakCard(streakInfo: viewModel.streakInfo)

                    // Timeline section
                    timelineSection
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .refreshable {
                viewModel.loadEvents()
            }
        }
        // Swipe gestures for day navigation
        .gesture(dayNavigationGesture)
        .task {
            await weatherService.fetchForecasts()
        }
    }

    // MARK: - Nav Bar

    @ViewBuilder
    private var todayNavBar: some View {
        HStack {
            // Previous day button
            Button {
                HapticFeedback.selection()
                viewModel.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Strings.Timeline.previousDay)

            Spacer()

            // Date title (tappable to go to today)
            Button {
                viewModel.goToToday()
            } label: {
                Text(viewModel.dateTitle)
                    .font(.headline)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Timeline.dateLabel(date: viewModel.dateTitle))
            .accessibilityHint(Strings.Timeline.goToTodayHint)
            .accessibilityAddTraits(.isHeader)

            Spacer()

            // Settings gear (when showing today) or next day button
            if viewModel.isShowingToday {
                Button {
                    onSettingsTap()
                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Strings.Tabs.settings)
                .accessibilityIdentifier("settings_button")
            } else {
                Button {
                    HapticFeedback.selection()
                    viewModel.goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .opacity(viewModel.canGoForward ? 1 : 0.3)
                .disabled(!viewModel.canGoForward)
                .accessibilityLabel(Strings.Timeline.nextDay)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Status Cards Section

    @ViewBuilder
    private var statusCardsSection: some View {
        VStack(spacing: 12) {
            // Potty status hero card
            PottyStatusCard(
                prediction: viewModel.pottyPrediction,
                puppyName: viewModel.puppyName
            )

            // Poop status tracker
            PoopStatusCard(status: viewModel.poopStatus)

            // Sleep status card
            SleepStatusCard(sleepState: viewModel.currentSleepState)

            // Medication reminders
            ForEach(viewModel.pendingMedications) { pending in
                MedicationReminderCard(
                    medication: pending.medication,
                    time: pending.time,
                    scheduledDate: pending.scheduledDate,
                    isOverdue: pending.isOverdue,
                    onComplete: { viewModel.completeMedication(pending) }
                )
            }

            // Upcoming events (meals & walks)
            UpcomingEventsCard(
                items: viewModel.upcomingItems(forecasts: weatherService.forecasts),
                isToday: viewModel.isShowingToday,
                onLogEvent: { eventType in
                    viewModel.quickLog(type: eventType)
                }
            )
        }
    }

    // MARK: - Timeline Section

    @ViewBuilder
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text("Timeline")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            if viewModel.events.isEmpty {
                EmptyTimelineCard()
            } else {
                // Event cards in timeline - wrapped in List for swipe actions
                List {
                    ForEach(viewModel.events) { event in
                        EventRow(event: event)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                if event.photo != nil {
                                    selectedPhotoEvent = event
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    HapticFeedback.warning()
                                    viewModel.deleteEvent(event)
                                } label: {
                                    Label(Strings.Common.delete, systemImage: "trash")
                                }

                                Button {
                                    viewModel.editEvent(event)
                                } label: {
                                    Label(Strings.Common.edit, systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(minHeight: CGFloat(viewModel.events.count * 80))
            }
        }
    }

    // MARK: - Gestures

    private var dayNavigationGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                if value.translation.width > threshold {
                    HapticFeedback.selection()
                    if reduceMotion {
                        viewModel.goToPreviousDay()
                    } else {
                        withAnimation {
                            viewModel.goToPreviousDay()
                        }
                    }
                } else if value.translation.width < -threshold && viewModel.canGoForward {
                    HapticFeedback.selection()
                    if reduceMotion {
                        viewModel.goToNextDay()
                    } else {
                        withAnimation {
                            viewModel.goToNextDay()
                        }
                    }
                }
                dragOffset = 0
            }
    }

}

// MARK: - Empty Timeline Card

struct EmptyTimelineCard: View {
    private let quickLogBarTip = QuickLogBarTip()

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(Strings.Timeline.noEvents)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(Strings.Timeline.tapToLog)
                .font(.subheadline)
                .foregroundColor(.secondary)

            TipView(quickLogBarTip)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let weatherService = WeatherService()

    return TodayView(
        viewModel: viewModel,
        weatherService: weatherService,
        onSettingsTap: { print("Settings tapped") }
    )
}
