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
    @Bindable var viewModel: TimelineViewModel
    var memoriesViewModel: MemoriesViewModel
    var appointmentStore: AppointmentStore
    @Bindable var statusViewModel: TodayStatusViewModel
    /// Weather service passed down but not observed here to avoid full view redraws
    /// Weather-dependent sections use their own observation via WeatherSectionContainer
    let weatherService: WeatherService
    let onSettingsTap: () -> Void
    var onNavigateToAppointments: (() -> Void)?
    var onNavigateToTrain: (() -> Void)?
    var onAddDog: (() -> Void)?
    var onNavigateToDiary: (() -> Void)?

    @State private var selectedPhotoEvent: PuppyEvent?
    @State private var showProfilePicker = false

    // First-visit tip tracking
    @AppStorage("hasSeenTodayTip") private var hasSeenTodayTip = false

    @Environment(AtmosphereProvider.self) private var atmosphereProvider
    @Environment(FoodRecallService.self) private var foodRecallService
    @Environment(EventStore.self) private var eventStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(ContactStore.self) private var contactStore

    // Trial touchpoint state (using direct access to singleton, not injected)
    private let trialManager = TrialManager.shared

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

                    // Morning briefing (AI-powered daily guidance)
                    // Debug: always render but let the card handle visibility
                    MorningBriefingCard()
                        .padding(.horizontal)
                        .animatedAppear(delay: 0.04)
                        .onAppear {
                            print("[TodayView] MorningBriefingCard appeared, isShowingToday=\(viewModel.isShowingToday), shouldShowAIInsights=\(FirstWeekExperienceService.shared.shouldShowAIInsights)")
                        }

                    // Status cards section (only for today)
                    if viewModel.isShowingToday {
                        statusCardsSection
                            .animatedAppear(delay: 0.05)
                    }

                    // Sentiment check-in (daily question about how things are going)
                    if viewModel.isShowingToday, let profile = viewModel.profileStore.profile {
                        SentimentCheckInContainer(
                            sentimentStore: SentimentStore.shared,
                            profile: profile,
                            events: eventStore.events
                        )
                        .animatedAppear(delay: 0.06)

                        // Tips for struggling areas
                        SentimentTipsContainer(
                            sentimentStore: SentimentStore.shared,
                            onInfoSheet: { sheetType in
                                // Handle info sheet presentation
                                switch sheetType {
                                case .crateTraining:
                                    viewModel.sheetCoordinator.presentSheet(.crateTrainingGuide)
                                case .pottyTraining:
                                    viewModel.sheetCoordinator.presentSheet(.pottyTrainingGuide)
                                default:
                                    break
                                }
                            }
                        )
                        .animatedAppear(delay: 0.07)
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

                    // AI Health Insights (personalized wellness observations)
                    // First week: only show after 15+ events over 3+ days
                    if viewModel.isShowingToday,
                       FirstWeekExperienceService.shared.shouldShowAIInsights {
                        AIHealthInsightsCard()
                            .animatedAppear(delay: 0.14)
                    }

                    // Vet visit tips (when appointment is within 3 days)
                    if viewModel.isShowingToday, let upcomingVetAppointment = statusViewModel.upcomingVetAppointment {
                        VetVisitTipsCard(
                            appointment: upcomingVetAppointment,
                            tipCount: statusViewModel.vetVisitTips.count,
                            onTap: { statusViewModel.showVetTipsSheet = true }
                        )
                        .animatedAppear(delay: 0.15)
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
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.3))
                        onAddDog?()
                    }
                },
                onManageProfiles: onSettingsTap
            )
        }
        .sheet(isPresented: $statusViewModel.showMonthRecapSheet) {
            MonthRecapSheet(
                viewModel: MonthRecapViewModel(
                    eventStore: eventStore,
                    profileStore: viewModel.profileStore
                ),
                onDismiss: { statusViewModel.showMonthRecapSheet = false }
            )
        }
        .sheet(isPresented: $statusViewModel.showYearRecapSheet) {
            YearRecapView(
                viewModel: YearRecapViewModel(
                    eventStore: eventStore,
                    profileStore: viewModel.profileStore,
                    weightStore: weightStore
                ),
                onDismiss: { statusViewModel.showYearRecapSheet = false }
            )
        }
        .sheet(isPresented: $statusViewModel.showVetTipsSheet) {
            if let appointment = statusViewModel.upcomingVetAppointment {
                VetVisitTipsSheet(
                    appointment: appointment,
                    tips: statusViewModel.vetVisitTips,
                    onPrepareSummary: {
                        statusViewModel.showVetTipsSheet = false
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.3))
                            statusViewModel.showVisitSummary = true
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $statusViewModel.showVisitSummary) {
            VisitSummaryView()
                .environment(viewModel.profileStore)
        }
    }

    // MARK: - Status Cards Section

    @ViewBuilder
    private var statusCardsSection: some View {
        TodayStatusCardsSection(
            viewModel: viewModel,
            weatherService: weatherService,
            config: StatusCardsConfig(
                appointmentNudgeCandidate: statusViewModel.appointmentNudgeCandidate,
                crateTrainingMastered: statusViewModel.crateTrainingMastered,
                shouldShowPottyStatusCard: statusViewModel.shouldShowPottyStatusCard,
                shouldShowCrateNudge: statusViewModel.shouldShowCrateNudge,
                shouldShowWalkTargetNudge: statusViewModel.shouldShowWalkTargetNudge,
                shouldShowAppointmentNudgeNapContext: statusViewModel.shouldShowAppointmentNudgeNapContext,
                overdueGroomingActivities: statusViewModel.overdueGroomingActivities,
                mostRecentMoment: statusViewModel.mostRecentMoment,
                shouldShowRecentMomentCard: statusViewModel.shouldShowRecentMomentCard
            ),
            callbacks: StatusCardsCallbacks(
                nudge: .init(
                    onDismissCrateNudge: { statusViewModel.dismissCrateNudge() },
                    onDismissWalkTargetNudge: { statusViewModel.dismissWalkTargetNudge() },
                    onDismissGroomingNudge: { statusViewModel.dismissGroomingNudge() },
                    onDismissAppointmentNudge: { statusViewModel.dismissAppointmentNudge(for: $0) },
                    onMarkAppointmentDone: { candidate in
                        statusViewModel.milestoneToComplete = candidate.milestone
                    },
                    onCreateAppointmentPrefill: { statusViewModel.createAppointmentPrefill(for: $0) },
                    onMarkGroomingComplete: { activity in
                        statusViewModel.markGroomingComplete(activity)
                    },
                    onViewAllGrooming: {
                        viewModel.sheetCoordinator.presentSheet(.groomingQuickLog())
                    }
                ),
                recap: .init(
                    onShowMonthRecap: { statusViewModel.showMonthRecapSheet = true },
                    onShowYearRecap: { statusViewModel.showYearRecapSheet = true }
                ),
                firstWeek: .init(
                    onAddPhoto: {
                        viewModel.sheetCoordinator.presentSheet(.momentSourcePicker)
                    },
                    onInviteFamily: {
                        viewModel.sheetCoordinator.presentSheet(.settings)
                    }
                ),
                recentMoment: .init(
                    onNavigateToDiary: { onNavigateToDiary?() },
                    onDismiss: { statusViewModel.dismissRecentMomentCard() }
                ),
                onNavigateToTrain: onNavigateToTrain
            )
        )
        .sheet(item: $statusViewModel.milestoneToComplete) { milestone in
            MilestoneCompletionSheet(
                milestone: milestone,
                onDismiss: { statusViewModel.milestoneToComplete = nil },
                onComplete: { notes, photoID, linkedContactID, completionDate in
                    statusViewModel.completeMilestone(
                        milestone,
                        notes: notes,
                        photoID: photoID,
                        linkedContactID: linkedContactID,
                        completionDate: completionDate
                    )
                }
            )
            .environment(contactStore)
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

}

// MARK: - Empty Timeline Card

struct EmptyTimelineCard: View {
    private let quickLogBarTip = QuickLogBarTip()

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Strings.Timeline.noEvents)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(Strings.Timeline.tapToLog)
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
    let milestoneStore = MilestoneStore()
    let routineStore = RoutineStore()
    let trainingMasteryStore = TrainingMasteryStore.shared
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let memoriesViewModel = MemoriesViewModel(eventStore: eventStore)
    let statusViewModel = TodayStatusViewModel(
        timelineViewModel: viewModel,
        eventStore: eventStore,
        routineStore: routineStore,
        milestoneStore: milestoneStore,
        appointmentStore: appointmentStore,
        trainingMasteryStore: trainingMasteryStore
    )
    let weatherService = WeatherService()
    let atmosphereProvider = AtmosphereProvider()
    let foodRecallService = FoodRecallService()

    TodayView(
        viewModel: viewModel,
        memoriesViewModel: memoriesViewModel,
        appointmentStore: appointmentStore,
        statusViewModel: statusViewModel,
        weatherService: weatherService,
        onSettingsTap: { print("Settings tapped") },
        onNavigateToAppointments: { print("Navigate to Appointments") },
        onNavigateToTrain: { print("Navigate to Train") },
        onAddDog: { print("Add dog") },
        onNavigateToDiary: { print("Navigate to Diary") }
    )
    .environment(atmosphereProvider)
    .environment(foodRecallService)
    .environment(SocializationStore())
    .environment(milestoneStore)
    .environment(eventStore)
}
