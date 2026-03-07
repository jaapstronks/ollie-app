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
    @ObservedObject var viewModel: TimelineViewModel
    let weatherService: WeatherService
    let appointmentNudgeCandidate: AppointmentNudgeCandidate?
    let crateTrainingMastered: Bool
    let shouldShowPottyStatusCard: Bool
    let shouldShowCrateNudge: Bool
    let shouldShowWalkTargetNudge: Bool
    let shouldShowAppointmentNudgeNapContext: Bool
    var onNavigateToTrain: (() -> Void)?

    // Nudge dismissal callbacks
    var onDismissCrateNudge: () -> Void
    var onDismissWalkTargetNudge: () -> Void
    var onDismissAppointmentNudge: (String) -> Void
    var onCreateAppointmentPrefill: (AppointmentNudgeCandidate) -> AppointmentPrefill?

    // Month recap callback
    var onShowMonthRecap: () -> Void

    @ObservedObject private var trialManager = TrialManager.shared

    var body: some View {
        VStack(spacing: 12) {
            let combinedState = viewModel.combinedSleepPottyState
            let isSleeping = combinedState.isSleeping
            let separated = viewModel.separatedUpcomingItems(forecasts: weatherService.forecasts)
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

            // Appointment nudge card
            appointmentNudgeCard(combinedState)

            // AI recommendation card
            aiRecommendationCard(aiRecommendation, combinedState: combinedState)

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
            .animatedAppear(delay: 0.03)
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
            .animatedAppear(delay: 0.035)
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
            .animatedAppear(delay: 0.04)
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
                .animatedAppear(delay: 0.045)
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
                subjectPronoun: viewModel.profileStore.profile?.subjectPronoun ?? "they",
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
                subjectPronoun: viewModel.profileStore.profile?.subjectPronoun ?? "they",
                objectPronoun: viewModel.profileStore.profile?.objectPronoun ?? "them",
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
            .animatedAppear(delay: 0.02)
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
            .animatedAppear(delay: 0.025)
        }
    }

    @ViewBuilder
    func appointmentNudgeCard(_ combinedState: CombinedSleepPottyState) -> some View {
        if let candidate = appointmentNudgeCandidate, !combinedState.shouldShowFirstRunCard {
            AppointmentNudgeCard(
                candidate: candidate,
                puppyName: viewModel.puppyName,
                showNapContext: shouldShowAppointmentNudgeNapContext,
                onSchedule: {
                    if let prefill = onCreateAppointmentPrefill(candidate) {
                        viewModel.sheetCoordinator.presentSheet(.addAppointmentWithPrefill(prefill))
                    }
                },
                onDismiss: {
                    onDismissAppointmentNudge(candidate.milestone.labelKey)
                }
            )
            .animatedAppear(delay: 0.027)
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
            .animatedAppear(delay: 0.03)
        }
    }

    @ViewBuilder
    func medicationsAndScheduledEvents(
        _ combinedState: CombinedSleepPottyState,
        separated: (actionable: [ActionableItem], upcoming: [UpcomingItem]),
        isSleeping: Bool
    ) -> some View {
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

// MARK: - AI Recommendation Card

private struct AIRecommendationCard: View {
    let recommendation: AILoggingCategoryRecommendation
    let onKeepCurrent: () -> Void
    let onReduceReminders: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.AINudges.recommendationTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(Strings.AINudges.recommendationBody(category: localizedCategoryName(recommendation.category)))
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                Button(Strings.AINudges.keepCurrent, action: onKeepCurrent)
                    .buttonStyle(.glassPillCompact(tint: .custom(.otisMuted)))

                Button(Strings.AINudges.reduceReminders, action: onReduceReminders)
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
        case .potty: return Strings.AINudges.categoryPotty
        case .walk: return Strings.AINudges.categoryWalk
        case .meal: return Strings.AINudges.categoryMeal
        case .training: return Strings.AINudges.categoryTraining
        case .socialization: return Strings.AINudges.categorySocialization
        }
    }
}
