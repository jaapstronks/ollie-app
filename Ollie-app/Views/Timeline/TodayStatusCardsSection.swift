//
//  TodayStatusCardsSection.swift
//  Otis-app
//
//  Status cards section for TodayView - shows potty, sleep, nudges, and scheduled items
//

import OtisShared
import SwiftUI

/// Status cards section showing current puppy state and actionable items
struct TodayStatusCardsSection: View {
    @Bindable var viewModel: TimelineViewModel
    let weatherService: WeatherService
    let appointmentNudgeCandidate: AppointmentNudgeCandidate?
    let crateTrainingMastered: Bool
    let shouldShowPottyStatusCard: Bool
    let shouldShowCrateNudge: Bool
    let shouldShowWalkTargetNudge: Bool
    let shouldShowAppointmentNudgeNapContext: Bool
    let overdueGroomingActivities: [GroomingActivity]
    var onNavigateToTrain: (() -> Void)?

    // Nudge dismissal callbacks
    var onDismissCrateNudge: () -> Void
    var onDismissWalkTargetNudge: () -> Void
    var onDismissGroomingNudge: () -> Void
    var onDismissAppointmentNudge: (String) -> Void
    var onMarkAppointmentDone: (AppointmentNudgeCandidate) -> Void
    var onCreateAppointmentPrefill: (AppointmentNudgeCandidate) -> AppointmentPrefill?
    var onMarkGroomingComplete: (GroomingActivity) -> Void
    var onViewAllGrooming: () -> Void

    // Recap callbacks
    var onShowMonthRecap: () -> Void
    var onShowYearRecap: () -> Void

    // First week prompt callbacks
    var onAddPhoto: () -> Void
    var onInviteFamily: () -> Void

    @ObservedObject private var trialManager = TrialManager.shared
    @ObservedObject private var firstWeekService = FirstWeekExperienceService.shared
    @Environment(ContactStore.self) private var contactStore

    var body: some View {
        VStack(spacing: 12) {
            // PERFORMANCE: Use cached values instead of computing on every render
            let combinedState = viewModel.cachedCombinedState
            let isSleeping = combinedState.isSleeping
            let separated = viewModel.cachedSeparatedItems
            let pendingActionable = isSleeping ? separated.actionable.first : nil
            let aiRecommendation = viewModel.aiLoggingRecommendations.first

            // First run welcome card
            firstRunCard(combinedState)

            // First week summary card
            firstWeekCard(combinedState)

            // Trial touchpoint card
            trialTouchpointCard(combinedState)

            // Weekly walk summary card
            weeklyWalkSummaryCard(combinedState)

            // Monthly recap tease card
            monthRecapTeaseCard(combinedState)

            // Year in review tease card (Dec 15 - Jan 15)
            yearRecapTeaseCard(combinedState)

            // Recent moments carousel - disabled for performance
            // recentMomentsCarousel(combinedState)

            // Stale logging banner
            staleLoggingBanner(combinedState)

            // Post-wake potty prompt
            postWakePottyCard(combinedState)

            // Assumed overnight sleep card
            assumedOvernightSleepCard(combinedState)

            // Combined sleep + potty card
            combinedSleepPottyCard(combinedState, pendingActionable: pendingActionable)

            // Normal potty card
            normalPottyCard(combinedState)

            // Sleep status card
            sleepStatusCard(combinedState, pendingActionable: pendingActionable)

            // Crate nudge card
            crateNudgeCard(combinedState)

            // Walk target nudge card
            walkTargetNudgeCard(combinedState)

            // Grooming nudge card
            groomingNudgeCard(combinedState)

            // Appointment nudge card
            appointmentNudgeCard(combinedState)

            // AI recommendation card
            aiRecommendationCard(aiRecommendation, combinedState: combinedState)

            // First-week photo prompt card (Day 2+)
            photoPromptCard(combinedState)

            // First-week family invite prompt card (Day 3+)
            familyInvitePromptCard(combinedState)

            // Health check-in card (for dogs with conditions or seniors)
            healthCheckInCard(combinedState)

            // Symptom trend card (for dogs with conditions)
            symptomTrendCard(combinedState)

            // Senior wellness quick card (for senior dogs)
            seniorWellnessQuickCard(combinedState)

            // Medications and scheduled events
            medicationsAndScheduledEvents(combinedState, separated: separated, isSleeping: isSleeping)
        }
    }
}

// MARK: - Card Builders

private extension TodayStatusCardsSection {

    @ViewBuilder
    func firstRunCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if case .firstRun(let puppyName) = combinedState {
            FirstRunWelcomeCard(
                puppyName: puppyName,
                onSleeping: { viewModel.firstRunPuppyIsSleeping() },
                onAwake: { viewModel.firstRunPuppyIsAwake() }
            )
        }
    }

    @ViewBuilder
    func firstWeekCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if viewModel.shouldShowFirstWeekCard,
           !combinedState.shouldShowFirstRunCard,
           let stats = viewModel.firstWeekStats {
            FirstWeekCard(
                stats: stats,
                isCollapsed: viewModel.isFirstWeekCardCollapsed,
                onToggle: { viewModel.toggleFirstWeekCard() }
            )
            .animatedAppear(delay: 0.05)
        }
    }

    @ViewBuilder
    func trialTouchpointCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if let touchpoint = trialManager.currentTouchpoint(),
           touchpoint.showsInAppCard,
           !combinedState.shouldShowFirstRunCard {
            TrialTouchpointCard(
                touchpoint: touchpoint,
                puppyName: viewModel.puppyName,
                onDismiss: {
                    trialManager.markTouchpointShown(touchpoint)
                },
                onSubscribe: {
                    trialManager.markTouchpointShown(touchpoint)
                    viewModel.sheetCoordinator.presentSheet(.otisPlus)
                }
            )
            .animatedAppear(delay: 0.08)
        }
    }

    @ViewBuilder
    func weeklyWalkSummaryCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if !combinedState.shouldShowFirstRunCard,
           let profile = viewModel.profileStore.profile,
           profile.lifecyclePhase != .puppy,
           viewModel.cachedWeekWalkStats.count > 0 {
            WeeklyWalkSummaryCard(
                weekStats: viewModel.cachedWeekStats,
                totalWalks: viewModel.cachedWeekWalkStats.count,
                totalMinutes: viewModel.cachedWeekWalkStats.totalMinutes
            )
            .animatedAppear(delay: 0.1)
        }
    }

    @ViewBuilder
    func monthRecapTeaseCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if !combinedState.shouldShowFirstRunCard,
           MonthRecapViewModel.shouldShowRecapCard(),
           let profile = viewModel.profileStore.profile {
            let recapMonth = MonthRecapViewModel.recapMonth()
            let stats = MonthCalculations.calculateMonthStats(
                month: recapMonth,
                puppyName: profile.name,
                events: viewModel.eventStore.events
            )
            let photoEvents = MonthCalculations.photoEvents(for: recapMonth, from: viewModel.eventStore.events)

            if stats.hasData {
                MonthRecapTeaseCard(
                    puppyName: profile.name,
                    photoEvents: photoEvents,
                    stats: stats,
                    onTap: onShowMonthRecap
                )
                .animatedAppear(delay: 0.12)
            }
        }
    }

    @ViewBuilder
    func yearRecapTeaseCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if !combinedState.shouldShowFirstRunCard,
           YearRecapViewModel.shouldShowRecapCard(),
           let profile = viewModel.profileStore.profile {
            let recapYear = YearRecapViewModel.recapYear()
            let yearStats = YearCalculations.calculateStats(
                from: YearCalculations.eventsInYear(recapYear, from: viewModel.eventStore.events)
            )
            let photoEvents = YearCalculations.photoEvents(for: recapYear, from: viewModel.eventStore.events)

            if yearStats.totalWalks > 0 || yearStats.photoCount > 0 {
                YearRecapTeaseCard(
                    puppyName: profile.name,
                    year: recapYear,
                    photoEvents: photoEvents,
                    stats: yearStats,
                    onTap: onShowYearRecap
                )
                .animatedAppear(delay: 0.14)
            }
        }
    }

    @ViewBuilder
    func recentMomentsCarousel(_ combinedState: CombinedSleepPottyState) -> some View {
        if !combinedState.shouldShowFirstRunCard {
            let recentPhotos = viewModel.recentPhotoEvents
            if !recentPhotos.isEmpty {
                RecentMomentsCarousel(
                    photoEvents: recentPhotos,
                    onPhotoTap: { _, index in
                        viewModel.sheetCoordinator.presentMomentsLightbox(
                            events: recentPhotos,
                            startIndex: index
                        )
                    }
                )
                .animatedAppear(delay: 0.16)
            }
        }
    }

    @ViewBuilder
    func staleLoggingBanner(_ combinedState: CombinedSleepPottyState) -> some View {
        if case .staleLogging = combinedState {
            StaleLoggingBanner(
                onStartFresh: { viewModel.startFreshAfterLoggingGap() }
            )
        }
    }

    @ViewBuilder
    func postWakePottyCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if case .justWokeNeedsPotty(let wokeAt, let minutesSinceWake, let overdueBy) = combinedState {
            PostWakePottyCard(
                wokeAt: wokeAt,
                minutesSinceWake: minutesSinceWake,
                pottyWasOverdueBy: overdueBy,
                gender: viewModel.profileStore.profile?.gender ?? .unspecified,
                onLogPotty: { viewModel.sheetCoordinator.presentSheet(.potty(preselected: .plassen)) }
            )
        }
    }

    @ViewBuilder
    func assumedOvernightSleepCard(_ combinedState: CombinedSleepPottyState) -> some View {
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
    }

    @ViewBuilder
    func combinedSleepPottyCard(_ combinedState: CombinedSleepPottyState, pendingActionable: ActionableItem?) -> some View {
        if case .sleepingPottyUrgent(let since, let duration, let urgency, let overdue) = combinedState {
            CombinedSleepPottyCard(
                sleepingSince: since,
                sleepDurationMin: duration,
                pottyUrgency: urgency,
                minutesOverdue: overdue,
                pendingActionable: pendingActionable,
                gender: viewModel.profileStore.profile?.gender ?? .unspecified,
                onWakeUp: {
                    viewModel.sheetCoordinator.presentSheet(.endSleep(since))
                }
            )
        }
    }

    @ViewBuilder
    func normalPottyCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if !combinedState.shouldHidePottyCard && shouldShowPottyStatusCard {
            let aiStatusCopy = viewModel.aiEnhancedPottyStatusCopy
            PottyStatusCard(
                prediction: viewModel.pottyPrediction,
                puppyName: viewModel.puppyName,
                titleOverride: aiStatusCopy.title,
                subtitleOverride: aiStatusCopy.subtitle,
                onLogPotty: { viewModel.sheetCoordinator.presentSheet(.potty(preselected: .plassen)) }
            )
        }
    }

    @ViewBuilder
    func sleepStatusCard(_ combinedState: CombinedSleepPottyState, pendingActionable: ActionableItem?) -> some View {
        if !combinedState.shouldHideSleepCard {
            SleepStatusCard(
                sleepState: viewModel.currentSleepState,
                pendingActionable: pendingActionable,
                onWakeUp: {
                    if case .sleeping(let since, _) = viewModel.currentSleepState {
                        viewModel.sheetCoordinator.presentSheet(.endSleep(since))
                    } else {
                        viewModel.quickLog(type: .ontwaken)
                    }
                },
                onStartNap: { viewModel.sheetCoordinator.presentSheet(.startActivity(.nap)) }
            )
        }
    }

    @ViewBuilder
    func crateNudgeCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if shouldShowCrateNudge && !combinedState.shouldShowFirstRunCard {
            CrateNudgeCard(
                puppyName: viewModel.puppyName,
                onStartCrateNap: {
                    viewModel.sheetCoordinator.presentSheet(.startActivity(.nap, preselectedLocation: .crate))
                },
                onDismiss: onDismissCrateNudge
            )
            .animatedAppear(delay: 0.05)
        }
    }

    @ViewBuilder
    func walkTargetNudgeCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if shouldShowWalkTargetNudge && !combinedState.shouldShowFirstRunCard,
           let stats = viewModel.walkStats {
            WalkTargetNudgeCard(
                actualAverage: stats.averageWalksPerDay,
                scheduledTarget: stats.scheduledWalksPerDay,
                onAdjust: {
                    viewModel.sheetCoordinator.presentSheet(.walkScheduleEditor)
                },
                onDismiss: onDismissWalkTargetNudge
            )
            .visibleForNudge(.walks)
            .animatedAppear(delay: 0.08)
        }
    }

    @ViewBuilder
    func groomingNudgeCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if !overdueGroomingActivities.isEmpty && !combinedState.shouldShowFirstRunCard {
            GroomingNudgeCard(
                activities: overdueGroomingActivities,
                puppyName: viewModel.puppyName,
                onMarkComplete: { activity in
                    onMarkGroomingComplete(activity)
                },
                onDismiss: onDismissGroomingNudge,
                onViewAll: onViewAllGrooming
            )
            .visibleForNudge(.grooming)
            .animatedAppear(delay: 0.1)
        }
    }

    @ViewBuilder
    func appointmentNudgeCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if let candidate = appointmentNudgeCandidate, !combinedState.shouldShowFirstRunCard {
            AppointmentNudgeCard(
                candidate: candidate,
                puppyName: viewModel.puppyName,
                showNapContext: shouldShowAppointmentNudgeNapContext,
                vetContact: contactStore.vetContactWithPhone,
                onSchedule: {
                    if let prefill = onCreateAppointmentPrefill(candidate) {
                        viewModel.sheetCoordinator.presentSheet(.addAppointmentWithPrefill(prefill))
                    }
                },
                onAlreadyDone: {
                    onMarkAppointmentDone(candidate)
                },
                onDismiss: {
                    onDismissAppointmentNudge(candidate.milestone.labelKey)
                },
                onCallVet: ContactUtilities.callPhoneNumber
            )
            .visibleForNudge(.appointments)
            .animatedAppear(delay: 0.12)
        }
    }

    @ViewBuilder
    func aiRecommendationCard(_ recommendation: AILoggingCategoryRecommendation?, combinedState: CombinedSleepPottyState) -> some View {
        if let recommendation, !combinedState.shouldShowFirstRunCard {
            AIRecommendationCard(
                recommendation: recommendation,
                onKeepCurrent: { viewModel.dismissAILoggingRecommendation(recommendation) },
                onReduceReminders: { viewModel.applyAILoggingRecommendation(recommendation) }
            )
            .visibleForNudge(.training)
            .animatedAppear(delay: 0.14)
        }
    }

    @ViewBuilder
    func photoPromptCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if firstWeekService.shouldShowPhotoPrompt,
           !combinedState.shouldShowFirstRunCard {
            PhotoPromptCard(
                puppyName: viewModel.puppyName,
                onAddPhoto: onAddPhoto,
                onDismiss: {
                    firstWeekService.dismissPhotoPrompt()
                }
            )
            .animatedAppear(delay: 0.16)
        }
    }

    @ViewBuilder
    func familyInvitePromptCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if firstWeekService.shouldShowInvitePrompt,
           !combinedState.shouldShowFirstRunCard {
            FamilyInvitePromptCard(
                puppyName: viewModel.puppyName,
                onInvite: {
                    onInviteFamily()
                    firstWeekService.markFamilyInviteSent()
                },
                onDismiss: {
                    firstWeekService.dismissInvitePrompt()
                }
            )
            .animatedAppear(delay: 0.18)
        }
    }

    @ViewBuilder
    func healthCheckInCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if !combinedState.shouldShowFirstRunCard,
           let profile = viewModel.profileStore.profile,
           let nextCategory = HealthCheckInStore.shared.nextCategoryForCard(for: profile) {
            let contextSummary = HealthCheckInStore.shared.contextSummary(for: nextCategory, puppyName: profile.name)
            HealthCheckInCard(
                category: nextCategory,
                puppyName: profile.name,
                contextSummary: contextSummary,
                onSubmit: { score in
                    HealthCheckInStore.shared.recordCheckIn(
                        category: nextCategory,
                        score: score,
                        contextSummary: contextSummary
                    )
                },
                onDismiss: {
                    // User dismissed, we'll ask again in a few days
                }
            )
            .animatedAppear(delay: 0.2)
        }
    }

    @ViewBuilder
    func symptomTrendCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if !combinedState.shouldShowFirstRunCard,
           let profile = viewModel.profileStore.profile {
            let activeConditions = profile.healthConditions.filter { $0.status == .active }
            // Show trend card for first active condition with recent symptoms
            if let condition = activeConditions.first {
                let trendSummary = HealthSymptomStore.shared.trend(for: condition.id)
                if trendSummary.episodesThisWeek > 0 || trendSummary.episodesLastWeek > 0 {
                    SymptomTrendCard(
                        conditionName: condition.displayName,
                        conditionId: condition.id,
                        trendSummary: trendSummary,
                        onViewDetails: {
                            // Navigate to health detail view - could add navigation here
                        }
                    )
                    .animatedAppear(delay: 0.22)
                }
            }
        }
    }

    @ViewBuilder
    func seniorWellnessQuickCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if !combinedState.shouldShowFirstRunCard,
           let profile = viewModel.profileStore.profile,
           profile.lifecyclePhase == .senior {
            let wellnessStore = SeniorWellnessStore.shared

            // Show mobility quick check if not logged today
            if wellnessStore.latestMobility?.daysAgo ?? 1 > 0 {
                SeniorMobilityQuickCard(
                    puppyName: profile.name,
                    onRate: { score in
                        wellnessStore.recordMobility(score: score)
                    },
                    onDetailedLog: {
                        viewModel.sheetCoordinator.presentSheet(.seniorMobility)
                    }
                )
                .animatedAppear(delay: 0.24)
            }
        }
    }

    @ViewBuilder
    func medicationsAndScheduledEvents(
        _ combinedState: CombinedSleepPottyState,
        separated: (actionable: [ActionableItem], upcoming: [UpcomingItem]),
        isSleeping: Bool
    ) -> some View {
        if !combinedState.shouldShowFirstRunCard {
            // Medication reminders (filtered by nudge preferences)
            if NudgeCategory.medications.isEnabledForCurrentUser {
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
            }

            // Scheduled events section
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

