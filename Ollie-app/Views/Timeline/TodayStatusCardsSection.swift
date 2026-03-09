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
    @EnvironmentObject private var contactStore: ContactStore

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

            // Year in review tease card (Dec 15 - Jan 15)
            yearRecapTeaseCard(combinedState)

            // Recent moments carousel
            recentMomentsCarousel(combinedState)

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
                .animatedAppear(delay: 0.05)
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
                .animatedAppear(delay: 0.06)
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
                usesPluralVerbForm: viewModel.profileStore.profile?.usesPluralVerbForm ?? true,
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
                usesPluralVerbForm: viewModel.profileStore.profile?.usesPluralVerbForm ?? true,
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
            .visibleForNudge(.walks)
            .animatedAppear(delay: 0.025)
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
            .animatedAppear(delay: 0.028)
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
                onCallVet: { phone in
                    callPhone(phone)
                }
            )
            .visibleForNudge(.appointments)
            .animatedAppear(delay: 0.027)
        }
    }

    /// Opens the phone dialer with the given number
    private func callPhone(_ phone: String) {
        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
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
            .animatedAppear(delay: 0.03)
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
            .animatedAppear(delay: 0.032)
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
            .animatedAppear(delay: 0.034)
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
            .animatedAppear(delay: 0.035)
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
                    .animatedAppear(delay: 0.04)
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
                .animatedAppear(delay: 0.045)
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

// MARK: - Senior Mobility Quick Card

private struct SeniorMobilityQuickCard: View {
    let puppyName: String
    let onRate: (Int) -> Void
    let onDetailedLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.blue)
                Text(Strings.SeniorWellness.howIsMobility(name: puppyName))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Quick 1-5 rating buttons
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        onRate(score)
                    } label: {
                        Text("\(score)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(colorForScore(score).opacity(0.2))
                            .foregroundStyle(colorForScore(score))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Add details button
            Button(action: onDetailedLog) {
                HStack {
                    Text("Add observations")
                        .font(.caption)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM))
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .gray
        }
    }
}
