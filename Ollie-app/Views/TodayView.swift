//
//  TodayView.swift
//  Ollie-app
//
//  The "Vandaag" (Today) tab - the daily hub showing everything needed right now
//  Combines the web app's "home" and "dag" views into a single scrollable view

import SwiftUI
import OllieShared
import TipKit

/// Main "Today" tab showing the daily hub
struct TodayView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var thisWeekViewModel: ThisWeekViewModel
    /// Weather service passed down but not observed here to avoid full view redraws
    /// Weather-dependent sections use their own observation via WeatherSectionContainer
    let weatherService: WeatherService
    let onSettingsTap: () -> Void
    var onNavigateToInsights: (() -> Void)?

    @State private var selectedPhotoEvent: PuppyEvent?

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar with date and settings gear
            todayNavBar

            // Trial banner (show during last 7 days of free period)
            if viewModel.shouldShowTrialBanner {
                TrialBanner(
                    daysRemaining: viewModel.freeDaysRemaining,
                    onTap: { viewModel.sheetCoordinator.presentSheet(.olliePlus) }
                )
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Weather section container (isolates weather observation)
                    WeatherSectionContainer(
                        weatherService: weatherService,
                        isToday: Calendar.current.isDateInToday(viewModel.currentDate),
                        predictedPottyTime: viewModel.predictedNextPlasTime
                    )
                    .animatedAppear(delay: 0)

                    // Status cards section (only for today)
                    if viewModel.isShowingToday {
                        statusCardsSection
                            .animatedAppear(delay: 0.05)
                    }

                    // This Week card (socialization + milestones)
                    if viewModel.isShowingToday {
                        ThisWeekCard(
                            viewModel: thisWeekViewModel,
                            onNavigateToInsights: onNavigateToInsights
                        )
                        .animatedAppear(delay: 0.10)
                    }

                    // Walk suggestions (socialization items to watch for)
                    if viewModel.isShowingToday {
                        WalkSuggestionsCard()
                            .animatedAppear(delay: 0.15)
                    }

                    // Combined potty progress card (streak + poop count)
                    if viewModel.isShowingToday {
                        PottyProgressSummaryCard(
                            streakInfo: viewModel.streakInfo,
                            poopStatus: viewModel.poopStatus
                        )
                        .animatedAppear(delay: 0.20)
                    }

                    // Timeline section
                    timelineSection
                        .animatedAppear(delay: 0.25)
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
            }
            .refreshable {
                viewModel.loadEvents()
            }
        }
        // Swipe gestures for day navigation
        .dayNavigation(
            canGoForward: viewModel.canGoForward,
            onPreviousDay: viewModel.goToPreviousDay,
            onNextDay: viewModel.goToNextDay
        )
        .task {
            await weatherService.fetchForecasts()
        }
        // Celebration overlay for milestone moments
        .celebration(style: viewModel.celebrationStyle, trigger: $viewModel.showCelebration)
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

            // Date title with subtle day counter (tappable to go to today)
            Button {
                viewModel.goToToday()
            } label: {
                VStack(spacing: 2) {
                    Text(viewModel.dateTitle)
                        .font(.headline)

                    // Subtle day counter - only show when viewing today
                    if viewModel.isShowingToday, let dayNumber = viewModel.dailyDigest.dayNumber {
                        Text("Day \(dayNumber) with \(viewModel.puppyName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Strings.Timeline.dateLabel(date: viewModel.dateTitle))
            .accessibilityHint(Strings.Timeline.goToTodayHint)
            .accessibilityAddTraits(.isHeader)

            Spacer()

            // Next day button (when not showing today)
            if !viewModel.isShowingToday {
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

            // Settings gear (always visible)
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
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Status Cards Section

    @ViewBuilder
    private var statusCardsSection: some View {
        VStack(spacing: 12) {
            // Use combined state to determine which cards to show
            let combinedState = viewModel.combinedSleepPottyState
            let isSleeping = combinedState.isSleeping

            // Compute upcoming items ONCE for both sleep card and scheduled events section
            // This avoids redundant calculation when puppy is sleeping
            let separated = viewModel.separatedUpcomingItems(forecasts: weatherService.forecasts)
            let pendingActionable = isSleeping ? separated.actionable.first : nil

            // Post-wake potty prompt (highest priority - shows at top)
            if case .justWokeNeedsPotty(let wokeAt, let minutesSinceWake, let overdueBy) = combinedState {
                PostWakePottyCard(
                    wokeAt: wokeAt,
                    minutesSinceWake: minutesSinceWake,
                    pottyWasOverdueBy: overdueBy,
                    onLogPotty: { viewModel.sheetCoordinator.presentSheet(.potty) }
                )
            }

            // Combined sleep + potty card (when sleeping and potty is urgent)
            if case .sleepingPottyUrgent(let since, let duration, let urgency, let overdue) = combinedState {
                CombinedSleepPottyCard(
                    sleepingSince: since,
                    sleepDurationMin: duration,
                    pottyUrgency: urgency,
                    minutesOverdue: overdue,
                    onWakeUp: {
                        viewModel.sheetCoordinator.presentSheet(.endSleep(since))
                    }
                )
            }

            // Normal potty card (hide when combined card is showing or just woke)
            if !combinedState.shouldHidePottyCard {
                PottyStatusCard(
                    prediction: viewModel.pottyPrediction,
                    puppyName: viewModel.puppyName,
                    onLogPotty: { viewModel.sheetCoordinator.presentSheet(.potty) }
                )
            }

            // Sleep status card (hide when combined card is showing)
            if !combinedState.shouldHideSleepCard {
                SleepStatusCard(
                    sleepState: viewModel.currentSleepState,
                    pendingActionable: pendingActionable,
                    onWakeUp: {
                        // Use EndSleepSheet for time-adjustable wake up
                        if case .sleeping(let since, _) = viewModel.currentSleepState {
                            viewModel.sheetCoordinator.presentSheet(.endSleep(since))
                        } else {
                            viewModel.quickLog(type: .ontwaken)
                        }
                    },
                    onStartNap: { viewModel.quickLog(type: .slapen) }
                )
            }

            // Medication reminders
            ForEach(viewModel.pendingMedications) { pending in
                MedicationReminderCard(
                    medication: pending.medication,
                    time: pending.time,
                    scheduledDate: pending.scheduledDate,
                    isOverdue: pending.isOverdue,
                    onComplete: { medicationName in
                        viewModel.completeMedication(pending, medicationName: medicationName)
                    }
                )
            }

            // Actionable & Upcoming events (pass precomputed values)
            ScheduledEventsSection(
                viewModel: viewModel,
                weatherService: weatherService,
                precomputedSeparated: separated,
                isSleeping: isSleeping
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
    let milestoneStore = MilestoneStore()
    let socializationStore = SocializationStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let thisWeekViewModel = ThisWeekViewModel(
        profileStore: profileStore,
        milestoneStore: milestoneStore,
        socializationStore: socializationStore
    )
    let weatherService = WeatherService()

    return TodayView(
        viewModel: viewModel,
        thisWeekViewModel: thisWeekViewModel,
        weatherService: weatherService,
        onSettingsTap: { print("Settings tapped") },
        onNavigateToInsights: { print("Navigate to Insights") }
    )
}
