//
//  TodayView.swift
//  Otis-app
//
//  The "Vandaag" (Today) tab - the daily hub showing everything needed right now
//  Combines the web app's "home" and "dag" views into a single scrollable view

import SwiftUI
import OtisShared
import TipKit

/// Main "Today" tab showing the daily hub
struct TodayView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var memoriesViewModel: MemoriesViewModel
    @ObservedObject var appointmentStore: AppointmentStore
    /// Weather service passed down but not observed here to avoid full view redraws
    /// Weather-dependent sections use their own observation via WeatherSectionContainer
    let weatherService: WeatherService
    let onSettingsTap: () -> Void
    var onNavigateToAppointments: (() -> Void)?
    var onNavigateToTrain: (() -> Void)?
    var onAddDog: (() -> Void)?

    @State private var selectedPhotoEvent: PuppyEvent?
    @State private var showProfilePicker = false
    @State private var dismissedCrateNudgeDate: Date?
    @State private var dismissedWalkTargetNudgeDate: Date?

    // First-visit tip tracking
    @AppStorage("hasSeenTodayTip") private var hasSeenTodayTip = false

    @EnvironmentObject private var atmosphereProvider: AtmosphereProvider
    @EnvironmentObject private var foodRecallService: FoodRecallService
    @EnvironmentObject private var eventStore: EventStore

    /// Whether to show the crate nudge card
    private var shouldShowCrateNudge: Bool {
        // Check if dismissed today
        if let dismissedDate = dismissedCrateNudgeDate,
           Calendar.current.isDateInToday(dismissedDate) {
            return false
        }

        return NudgeCalculations.shouldShowCrateNudge(
            sleepState: viewModel.currentSleepState,
            todayEvents: viewModel.events,
            allEvents: eventStore.events
        )
    }

    /// Whether to show the walk target nudge card
    private var shouldShowWalkTargetNudge: Bool {
        NudgeCalculations.shouldShowWalkTargetNudge(
            walkStats: viewModel.walkStats,
            dismissedDate: dismissedWalkTargetNudgeDate
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar with date and settings gear
            todayNavBar

            // Trial banner (show during last 7 days of free period)
            if viewModel.shouldShowTrialBanner {
                TrialBanner(
                    daysRemaining: viewModel.freeDaysRemaining,
                    onTap: { viewModel.sheetCoordinator.presentSheet(.otisPlus) }
                )
            }

            // Food recall alert (if any matching recalls)
            if viewModel.isShowingToday && !foodRecallService.unacknowledgedRecalls.isEmpty {
                RecallAlertCard(foodRecallService: foodRecallService)
                    .padding(.horizontal)
            }

            // Partner activity summary (handoff card)
            if viewModel.isShowingToday, let partnerSummary = viewModel.partnerActivitySummary {
                PartnerActivitySummaryCard(
                    summary: partnerSummary,
                    householdMembers: viewModel.householdMembersContainer,
                    onDismiss: { viewModel.dismissPartnerActivitySummary() }
                )
                .padding(.horizontal)
            }

            ScrollView {
                VStack(spacing: 16) {
                    // First-visit tip (only show on today, not past dates)
                    if viewModel.isShowingToday && !hasSeenTodayTip {
                        FeatureTipCard(
                            tip: .todayIntro,
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    hasSeenTodayTip = true
                                }
                            }
                        )
                    }

                    // Status cards section (only for today)
                    if viewModel.isShowingToday {
                        statusCardsSection
                            .animatedAppear(delay: 0.05)
                    }

                    // Memories card ("On This Day")
                    if viewModel.isShowingToday {
                        MemoriesCard(
                            viewModel: memoriesViewModel,
                            onMemoryTap: { event in
                                // Navigate to the date of the memory
                                viewModel.goToDate(event.time)
                            }
                        )
                        .animatedAppear(delay: 0.08)
                    }

                    // Today's scheduled appointments
                    if viewModel.isShowingToday {
                        TodaysScheduleCard(
                            appointmentStore: appointmentStore,
                            onViewAll: onNavigateToAppointments
                        )
                        .animatedAppear(delay: 0.10)
                    }

                    // Combined potty progress card (streak + poop count)
                    if viewModel.isShowingToday {
                        PottyProgressSummaryCard(
                            streakInfo: viewModel.streakInfo,
                            poopStatus: viewModel.poopStatus
                        )
                        .animatedAppear(delay: 0.12)
                    }

                    // Timeline section
                    timelineSection
                        .animatedAppear(delay: 0.15)
                }
                .padding()
                .padding(.bottom, 84) // Space for FAB
                .adaptiveContainer()
            }
            .refreshable {
                viewModel.loadEvents()
            }
        }
        .atmosphereBackground()
        .task {
            await weatherService.fetchForecasts()
        }
        // Sync puppy sleep state to atmosphere provider
        .onChange(of: viewModel.currentSleepState.isSleeping) { _, isSleeping in
            atmosphereProvider.updatePuppyState(isSleeping: isSleeping)
        }
        .onAppear {
            // Initial sync of sleep state
            atmosphereProvider.updatePuppyState(isSleeping: viewModel.currentSleepState.isSleeping)
        }
    }

    // MARK: - Nav Bar

    @ViewBuilder
    private var todayNavBar: some View {
        HStack(spacing: 12) {
            // Date title with subtle day counter
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.dateTitle)
                    .font(.headline)

                // Subtle day counter
                if let dayNumber = viewModel.dailyDigest.dayNumber {
                    Text(Strings.Timeline.dayWithPuppyName(day: dayNumber, name: viewModel.puppyName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 44)
            .accessibilityLabel(Strings.Timeline.dateLabel(date: viewModel.dateTitle))
            .accessibilityAddTraits(.isHeader)

            Spacer()

            // Profile photo button
            // - Tap: Opens full settings hub (consistent with other tabs)
            // - Long press/context menu: Quick actions like profile switching
            ProfilePhotoButton(
                profile: viewModel.profileStore.profile,
                action: {
                    onSettingsTap()
                }
            )
            .contextMenu {
                Button {
                    onSettingsTap()
                } label: {
                    Label(Strings.Tabs.settings, systemImage: "gearshape")
                }

                if viewModel.profileStore.profiles.count > 1 {
                    Button {
                        showProfilePicker = true
                    } label: {
                        Label(Strings.Profile.switchProfile, systemImage: "arrow.left.arrow.right")
                    }
                }
            }
        }
        .padding()
        .atmosphereNavBar()
        .sheet(isPresented: $showProfilePicker) {
            ProfilePickerSheet(
                profileStore: viewModel.profileStore,
                isPresented: $showProfilePicker,
                onAddDog: {
                    // Dismiss profile picker first, then trigger onboarding
                    showProfilePicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onAddDog?()
                    }
                },
                onManageProfiles: onSettingsTap
            )
        }
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
            let aiRecommendation = viewModel.aiLoggingRecommendations.first

            // First run welcome card (highest priority for new users)
            if case .firstRun(let puppyName) = combinedState {
                FirstRunWelcomeCard(
                    puppyName: puppyName,
                    onSleeping: { viewModel.firstRunPuppyIsSleeping() },
                    onAwake: { viewModel.firstRunPuppyIsAwake() }
                )
            }

            // First week summary card (days 1-7)
            if viewModel.shouldShowFirstWeekCard,
               !combinedState.shouldShowFirstRunCard,
               let stats = viewModel.firstWeekStats {
                FirstWeekCard(
                    stats: stats,
                    isCollapsed: viewModel.isFirstWeekCardCollapsed,
                    onToggle: { viewModel.toggleFirstWeekCard() }
                )
                .animatedAppear(delay: 0.03)
            }

            // Stale logging banner (replaces misleading status cards)
            if case .staleLogging = combinedState {
                StaleLoggingBanner(
                    onStartFresh: { viewModel.startFreshAfterLoggingGap() }
                )
            }

            // Post-wake potty prompt (highest priority - shows at top)
            if case .justWokeNeedsPotty(let wokeAt, let minutesSinceWake, let overdueBy) = combinedState {
                PostWakePottyCard(
                    wokeAt: wokeAt,
                    minutesSinceWake: minutesSinceWake,
                    pottyWasOverdueBy: overdueBy,
                    onLogPotty: { viewModel.sheetCoordinator.presentSheet(.potty(preselected: .plassen)) }
                )
            }

            // Assumed overnight sleep card (when user likely forgot to log sleep)
            if case .assumedOvernightSleep(let suggestedStart, let minutesSleeping, _) = combinedState {
                AssumedOvernightSleepCard(
                    suggestedSleepStart: suggestedStart,
                    minutesSleeping: minutesSleeping,
                    puppyName: viewModel.puppyName,
                    onConfirmSleeping: { sleepStart in
                        viewModel.confirmAssumedOvernightSleep(sleepStartTime: sleepStart)
                    },
                    onConfirmAwake: { sleepStart, wakeTime in
                        viewModel.confirmAssumedOvernightSleepAndWakeUp(sleepStartTime: sleepStart, wakeTime: wakeTime)
                    },
                    onDismiss: {
                        viewModel.dismissAssumedOvernightSleep()
                    }
                )
            }

            // Combined sleep + potty card (when sleeping and potty is urgent)
            if case .sleepingPottyUrgent(let since, let duration, let urgency, let overdue) = combinedState {
                CombinedSleepPottyCard(
                    sleepingSince: since,
                    sleepDurationMin: duration,
                    pottyUrgency: urgency,
                    minutesOverdue: overdue,
                    pendingActionable: pendingActionable,
                    onWakeUp: {
                        viewModel.sheetCoordinator.presentSheet(.endSleep(since))
                    }
                )
            }

            // Normal potty card (hide when combined card is showing or just woke)
            if !combinedState.shouldHidePottyCard {
                let aiStatusCopy = viewModel.aiEnhancedPottyStatusCopy
                PottyStatusCard(
                    prediction: viewModel.pottyPrediction,
                    puppyName: viewModel.puppyName,
                    titleOverride: aiStatusCopy.title,
                    subtitleOverride: aiStatusCopy.subtitle,
                    onLogPotty: { viewModel.sheetCoordinator.presentSheet(.potty(preselected: .plassen)) }
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
                    onStartNap: { viewModel.sheetCoordinator.presentSheet(.startActivity(.nap)) }
                )
            }

            // Crate nudge card (contextual suggestion for crate naps)
            if shouldShowCrateNudge && !combinedState.shouldShowFirstRunCard {
                CrateNudgeCard(
                    puppyName: viewModel.puppyName,
                    onStartCrateNap: {
                        // Start a crate nap via the sheet with crate preselected
                        viewModel.sheetCoordinator.presentSheet(.startActivity(.nap, preselectedLocation: .crate))
                    },
                    onDismiss: {
                        // Dismiss for the rest of today
                        dismissedCrateNudgeDate = Date()
                    }
                )
                .animatedAppear(delay: 0.02)
            }

            // Walk target nudge card (contextual suggestion to adjust walk schedule)
            if shouldShowWalkTargetNudge && !combinedState.shouldShowFirstRunCard,
               let stats = viewModel.walkStats {
                WalkTargetNudgeCard(
                    actualAverage: stats.averageWalksPerDay,
                    scheduledTarget: stats.scheduledWalksPerDay,
                    onAdjust: {
                        viewModel.sheetCoordinator.presentSheet(.walkScheduleEditor)
                    },
                    onDismiss: {
                        // Dismiss for 7 days
                        dismissedWalkTargetNudgeDate = Date()
                    }
                )
                .animatedAppear(delay: 0.025)
            }

            // Subtle AI recommendation card (confirm before applying reminder changes)
            if let recommendation = aiRecommendation, !combinedState.shouldShowFirstRunCard {
                aiRecommendationCard(recommendation)
                    .animatedAppear(delay: 0.03)
            }

            // Hide scheduled events and medications during first run to avoid confusing "missed" reminders
            if !combinedState.shouldShowFirstRunCard {
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
                    isSleeping: isSleeping,
                    onNavigateToSocialization: onNavigateToTrain
                )
            }
        }
    }

    // MARK: - Timeline Section

    @ViewBuilder
    private var timelineSection: some View {
        RecentActivityPreview(
            events: viewModel.events,
            onViewFullTimeline: {
                viewModel.sheetCoordinator.presentSheet(.fullTimeline)
            },
            onEditEvent: { event in
                viewModel.editEvent(event)
            },
            onDeleteEvent: { event in
                viewModel.deleteEvent(event)
            }
        )
    }

    @ViewBuilder
    private func aiRecommendationCard(_ recommendation: AILoggingCategoryRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.AINudges.recommendationTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(Strings.AINudges.recommendationBody(category: localizedCategoryName(recommendation.category)))
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                Button(Strings.AINudges.keepCurrent) {
                    viewModel.dismissAILoggingRecommendation(recommendation)
                }
                .buttonStyle(.glassPillCompact(tint: .custom(.otisMuted)))

                Button(Strings.AINudges.reduceReminders) {
                    viewModel.applyAILoggingRecommendation(recommendation)
                }
                .buttonStyle(.glassPillCompact(tint: .custom(.otisAccent)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground).opacity(0.6))
        .cornerRadius(LayoutConstants.cornerRadiusM)
    }

    private func localizedCategoryName(_ category: AILoggingCategory) -> String {
        switch category {
        case .potty:
            return Strings.AINudges.categoryPotty
        case .walk:
            return Strings.AINudges.categoryWalk
        case .meal:
            return Strings.AINudges.categoryMeal
        case .training:
            return Strings.AINudges.categoryTraining
        case .socialization:
            return Strings.AINudges.categorySocialization
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
                .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Timeline.noEvents)
        .accessibilityHint(Strings.Timeline.tapToLog)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let appointmentStore = AppointmentStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let memoriesViewModel = MemoriesViewModel(eventStore: eventStore)
    let weatherService = WeatherService()
    let atmosphereProvider = AtmosphereProvider()
    let foodRecallService = FoodRecallService()

    return TodayView(
        viewModel: viewModel,
        memoriesViewModel: memoriesViewModel,
        appointmentStore: appointmentStore,
        weatherService: weatherService,
        onSettingsTap: { print("Settings tapped") },
        onNavigateToAppointments: { print("Navigate to Appointments") },
        onNavigateToTrain: { print("Navigate to Train") },
        onAddDog: { print("Add dog") }
    )
    .environmentObject(atmosphereProvider)
    .environmentObject(foodRecallService)
    .environmentObject(SocializationStore())
}
