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
    @State private var showMonthRecapSheet = false

    // First-visit tip tracking
    @AppStorage("hasSeenTodayTip") private var hasSeenTodayTip = false

    // Crate training mastery (hides potty reminders when mastered)
    @AppStorage(UserPreferences.Key.crateTrainingMastered.rawValue) private var crateTrainingMastered = false

    @EnvironmentObject private var atmosphereProvider: AtmosphereProvider
    @EnvironmentObject private var foodRecallService: FoodRecallService
    @EnvironmentObject private var eventStore: EventStore
    @EnvironmentObject private var milestoneStore: MilestoneStore

    // Trial touchpoint state
    @ObservedObject private var trialManager = TrialManager.shared

    // Appointment nudge dismissals (per-milestone labelKey)
    @AppStorage("appointmentNudgeDismissals") private var appointmentNudgeDismissalsData: Data = Data()

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

    /// Whether to show the potty status card based on crate training mastery and urgency
    /// - If crate training is mastered, don't show (puppy can hold it)
    /// - If not mastered, only show when < 30 minutes remaining or already urgent/overdue
    private var shouldShowPottyStatusCard: Bool {
        // Don't show if crate training is mastered
        if crateTrainingMastered {
            return false
        }

        // Check minutes remaining based on urgency level
        switch viewModel.pottyPrediction.urgency {
        case .soon, .overdue, .postAccident:
            // Always show when urgent
            return true
        case .attention(let minutesRemaining):
            // Attention is 10-20 min, always < 30
            return minutesRemaining < 30
        case .normal(let minutesRemaining):
            // Only show if < 30 minutes remaining
            return minutesRemaining < 30
        case .justWent, .unknown, .coverageGap:
            // Don't show for these states
            return false
        }
    }

    // MARK: - Appointment Nudge

    /// Decoded dismissals dictionary from AppStorage
    private var appointmentNudgeDismissals: [String: Date] {
        guard !appointmentNudgeDismissalsData.isEmpty else { return [:] }
        return (try? JSONDecoder().decode([String: Date].self, from: appointmentNudgeDismissalsData)) ?? [:]
    }

    /// Top appointment nudge candidate (if any)
    private var appointmentNudgeCandidate: AppointmentNudgeCandidate? {
        guard let birthDate = viewModel.profileStore.profile?.birthDate else { return nil }

        return AppointmentNudgeCalculations.topNudgeCandidate(
            milestones: milestoneStore.milestones,
            appointments: appointmentStore.appointments,
            birthDate: birthDate,
            dismissals: appointmentNudgeDismissals
        )
    }

    /// Whether to show the nap context message for the appointment nudge
    private var shouldShowAppointmentNudgeNapContext: Bool {
        PuppyContextUtility.shouldShowNapContextMessage(
            sleepState: viewModel.currentSleepState,
            events: viewModel.events
        )
    }

    /// Dismiss the appointment nudge for a milestone
    private func dismissAppointmentNudge(for labelKey: String) {
        var dismissals = appointmentNudgeDismissals
        dismissals[labelKey] = Date()
        if let encoded = try? JSONEncoder().encode(dismissals) {
            appointmentNudgeDismissalsData = encoded
        }
    }

    /// Create appointment prefill from nudge candidate
    private func createAppointmentPrefill(for candidate: AppointmentNudgeCandidate) -> AppointmentPrefill? {
        guard let birthDate = viewModel.profileStore.profile?.birthDate else { return nil }

        return AppointmentPrefill(
            appointmentType: candidate.appointmentType,
            title: candidate.milestone.localizedLabel,
            notes: nil,
            linkedMilestoneID: candidate.milestone.id,
            suggestedDate: AppointmentNudgeCalculations.suggestedAppointmentDate(for: candidate, birthDate: birthDate)
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
                    if viewModel.isShowingToday {
                        AIHealthInsightsCard()
                            .animatedAppear(delay: 0.14)
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
        .sheet(isPresented: $showMonthRecapSheet) {
            MonthRecapSheet(
                viewModel: MonthRecapViewModel(
                    eventStore: eventStore,
                    profileStore: viewModel.profileStore
                ),
                onDismiss: { showMonthRecapSheet = false }
            )
        }
    }

    // MARK: - Status Cards Section

    @ViewBuilder
    private var statusCardsSection: some View {
        TodayStatusCardsSection(
            viewModel: viewModel,
            weatherService: weatherService,
            appointmentNudgeCandidate: appointmentNudgeCandidate,
            crateTrainingMastered: crateTrainingMastered,
            shouldShowPottyStatusCard: shouldShowPottyStatusCard,
            shouldShowCrateNudge: shouldShowCrateNudge,
            shouldShowWalkTargetNudge: shouldShowWalkTargetNudge,
            shouldShowAppointmentNudgeNapContext: shouldShowAppointmentNudgeNapContext,
            onNavigateToTrain: onNavigateToTrain,
            onDismissCrateNudge: { dismissedCrateNudgeDate = Date() },
            onDismissWalkTargetNudge: { dismissedWalkTargetNudgeDate = Date() },
            onDismissAppointmentNudge: { dismissAppointmentNudge(for: $0) },
            onCreateAppointmentPrefill: { createAppointmentPrefill(for: $0) },
            onShowMonthRecap: { showMonthRecapSheet = true }
        )
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
    let milestoneStore = MilestoneStore()
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
    .environmentObject(milestoneStore)
    .environmentObject(eventStore)
}
