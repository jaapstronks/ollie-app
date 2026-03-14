//
//  TrainTabView.swift
//  Otis-app
//
//  Combined training tab with Potty Progress, Socialization, and Skills sections

import OtisShared
import SwiftUI

/// Train tab - unified view with potty progress, socialization checklist, and skills tracker
struct TrainTabView: View {
    @Bindable var viewModel: TimelineViewModel
    let onSettingsTap: () -> Void

    @Environment(EventStore.self) var eventStore
    @Environment(SocializationStore.self) var socializationStore
    @Environment(ProfileStore.self) var profileStore
    @Environment(SkillProgressStore.self) var skillProgressStore

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Sheet state for training guides
    @State private var showPottyGuide = false
    @State private var showCrateGuide = false
    @State private var showLeashGuide = false

    // First-visit tip tracking
    @AppStorage("hasSeenTrainTip") private var hasSeenTrainTip = false

    // Training mastery state
    @Environment(TrainingMasteryStore.self) var trainingMasteryStore

    @State private var showPottyMasteryConfirmation = false
    @State private var showLeashMasteryConfirmation = false

    // Convenience accessors for training mastery
    private var crateTrainingMastered: Bool { trainingMasteryStore.crateTrainingMastered }
    private var pottyTrainingMastered: Bool { trainingMasteryStore.pottyTrainingMastered }
    private var leashTrainingMastered: Bool { trainingMasteryStore.leashTrainingMastered }

    /// Calculate crate nap percentage for guide entry card
    private var crateNapPercentage: Int {
        let recentNaps = eventStore.events
            .sleeps()
            .lastDays(14)

        guard !recentNaps.isEmpty else { return 0 }

        let crateNaps = recentNaps.filter { $0.napLocation == .crate }
        return Int((Double(crateNaps.count) / Double(recentNaps.count)) * 100)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // First-visit tip
                    if !hasSeenTrainTip {
                        FeatureTipCard(
                            tip: .trainIntro,
                            onDismiss: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    hasSeenTrainTip = true
                                }
                            }
                        )
                    }

                    // AI Training Guidance (shows suggestions from AI)
                    AITrainingGuidanceCard()
                        .animatedAppear(delay: 0)

                    // Regression alert (highest priority)
                    if !skillProgressStore.skillsNeedingWork.isEmpty {
                        regressionAlertSection
                    }

                    // Due for review card
                    if !skillProgressStore.skillsDueForReview.isEmpty && skillProgressStore.skillsNeedingWork.isEmpty {
                        dueForReviewSection
                    }

                    // Section 1: Training Guides (non-mastered only in normal position)
                    if pottyTrainingMastered || crateTrainingMastered || leashTrainingMastered {
                        // Only show non-mastered guides in normal position
                        nonMasteredGuidesSection
                            .animatedAppear(delay: 0)
                    } else {
                        guidesSection
                            .animatedAppear(delay: 0)
                    }

                    // Section 2: Skills
                    skillsSection
                        .animatedAppear(delay: 0.05)

                    // Section 3: Socialization
                    socializationSection
                        .animatedAppear(delay: 0.10)

                    // Section 4: Behavior Support (shows for teenage+ or when incidents logged)
                    behaviorSupportSection
                        .animatedAppear(delay: 0.15)

                    // Section 5: Mastered guides (at bottom)
                    if pottyTrainingMastered || crateTrainingMastered || leashTrainingMastered {
                        masteredGuidesSection
                            .animatedAppear(delay: 0.20)
                    }
                }
                .padding()
                .adaptiveContainer()
            }
            .navigationTitle(Strings.Tabs.train)
            .navigationBarTitleDisplayMode(.inline)
            .profileToolbar(profile: profileStore.profile, action: onSettingsTap)
            // Training guide sheets
            .sheet(isPresented: $showPottyGuide) {
                PottyTrainingGuideSheet(
                    viewModel: PottyTrainingGuideViewModel(
                        streakInfo: viewModel.streakInfo,
                        patternAnalysis: viewModel.patternAnalysis,
                        outdoorPercentage: viewModel.outdoorPercentage,
                        ageInWeeks: profileStore.profile?.ageInWeeks ?? 12,
                        shouldShowIncidentMessage: viewModel.shouldShowPottyIncidentMessage,
                        shouldShowReactivationPrompt: viewModel.shouldShowPottyReactivationPrompt,
                        incidentCount: viewModel.incidentsSincePottyMastery.count
                    )
                )
            }
            .sheet(isPresented: $showCrateGuide) {
                CrateTrainingGuideSheet(eventStore: eventStore)
            }
            .sheet(isPresented: $showLeashGuide) {
                LeashTrainingGuideSheet(
                    recentSentimentAverage: viewModel.leashRecentSentimentAverage,
                    sentimentTrend: viewModel.leashSentimentTrend,
                    ageInWeeks: profileStore.profile?.ageInWeeks ?? 12,
                    shouldShowReactivationPrompt: viewModel.shouldShowLeashReactivationPrompt
                )
            }
            .confirmationDialog(
                Strings.Training.PottyTraining.markMastered,
                isPresented: $showPottyMasteryConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Training.PottyTraining.markMastered) {
                    markPottyAsMastered()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            } message: {
                Text(Strings.Training.PottyTraining.markMasteredDescription)
            }
            .confirmationDialog(
                Strings.Leash.markMastered,
                isPresented: $showLeashMasteryConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Leash.markMastered) {
                    markLeashAsMastered()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            } message: {
                Text(Strings.Leash.markMasteredDescription)
            }
        }
    }

    // MARK: - Potty Mastery Actions

    private func markPottyAsMastered() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            trainingMasteryStore.markPottyMastered()
        }
        HapticFeedback.success()
    }

    private func dismissPottyMasteryPrompt() {
        withAnimation(.easeOut(duration: 0.2)) {
            trainingMasteryStore.dismissPottyMasteryPrompt()
        }
        HapticFeedback.light()
    }

    // MARK: - Leash Mastery Actions

    private func markLeashAsMastered() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            trainingMasteryStore.markLeashMastered()
        }
        HapticFeedback.success()
    }

    private func dismissLeashMasteryPrompt() {
        withAnimation(.easeOut(duration: 0.2)) {
            trainingMasteryStore.dismissLeashMasteryPrompt()
        }
        HapticFeedback.light()
    }

    // MARK: - Training Guides Section

    @ViewBuilder
    private var guidesSection: some View {
        VStack(spacing: 10) {
            // Potty Training Guide - shown with mastered badge if mastered, hidden when at 100% for 4+ days (unless mastered)
            if pottyTrainingMastered || viewModel.shouldShowPottyTrainingGuide {
                TrainingGuideEntryCard(
                    icon: "target",
                    title: Strings.Training.Guides.pottyTitle,
                    subtitle: pottyTrainingMastered
                        ? Strings.Training.PottyTraining.masteredDescription
                        : Strings.Training.Guides.pottySubtitle,
                    statValue: pottyTrainingMastered ? nil : (viewModel.outdoorPercentage > 0 ? "\(viewModel.outdoorPercentage)%" : nil),
                    tintColor: .otisSuccess,
                    isMastered: pottyTrainingMastered
                ) {
                    showPottyGuide = true
                }
            }

            // Potty Mastery Prompt - shows when at 100% for multiple days, dismissible
            if viewModel.shouldShowPottyMasteryPrompt {
                PottyMasteryPromptCard(
                    consecutiveDays: viewModel.consecutivePerfectDays,
                    onMarkMastered: {
                        showPottyMasteryConfirmation = true
                    },
                    onDismiss: {
                        dismissPottyMasteryPrompt()
                    }
                )
            }

            // Crate Training Guide
            TrainingGuideEntryCard(
                icon: "house.fill",
                title: Strings.Training.Guides.crateTitle,
                subtitle: crateTrainingMastered
                    ? Strings.Training.CrateTraining.masteredDescription
                    : Strings.Training.Guides.crateSubtitle,
                statValue: crateTrainingMastered ? nil : (crateNapPercentage > 0 ? "\(crateNapPercentage)%" : nil),
                tintColor: .indigo,
                isMastered: crateTrainingMastered
            ) {
                showCrateGuide = true
            }

            // Leash Training Guide (shown for puppies 10+ weeks)
            if viewModel.shouldShowLeashTrainingGuide {
                LeashProgressCard(
                    recentAverage: viewModel.leashRecentSentimentAverage,
                    trend: viewModel.leashSentimentTrend,
                    isMastered: leashTrainingMastered,
                    onTap: { showLeashGuide = true }
                )
            }

            // Leash Mastery Prompt
            if viewModel.shouldShowLeashMasteryPrompt {
                LeashMasteryPromptCard(
                    weeksAtHighRating: 2,
                    onMarkMastered: {
                        showLeashMasteryConfirmation = true
                    },
                    onDismiss: {
                        dismissLeashMasteryPrompt()
                    }
                )
            }
        }
    }

    // MARK: - Non-Mastered Guides Section (only shows guides that are not mastered)

    @ViewBuilder
    private var nonMasteredGuidesSection: some View {
        VStack(spacing: 10) {
            // Potty Mastery Prompt - shows when at 100% for multiple days, dismissible
            if viewModel.shouldShowPottyMasteryPrompt {
                PottyMasteryPromptCard(
                    consecutiveDays: viewModel.consecutivePerfectDays,
                    onMarkMastered: {
                        showPottyMasteryConfirmation = true
                    },
                    onDismiss: {
                        dismissPottyMasteryPrompt()
                    }
                )
            }

            // Show potty guide in normal position only if not mastered
            if !pottyTrainingMastered && viewModel.shouldShowPottyTrainingGuide {
                TrainingGuideEntryCard(
                    icon: "target",
                    title: Strings.Training.Guides.pottyTitle,
                    subtitle: Strings.Training.Guides.pottySubtitle,
                    statValue: viewModel.outdoorPercentage > 0 ? "\(viewModel.outdoorPercentage)%" : nil,
                    tintColor: .otisSuccess,
                    isMastered: false
                ) {
                    showPottyGuide = true
                }
            }

            // Show crate guide in normal position only if not mastered
            if !crateTrainingMastered {
                TrainingGuideEntryCard(
                    icon: "house.fill",
                    title: Strings.Training.Guides.crateTitle,
                    subtitle: Strings.Training.Guides.crateSubtitle,
                    statValue: crateNapPercentage > 0 ? "\(crateNapPercentage)%" : nil,
                    tintColor: .indigo,
                    isMastered: false
                ) {
                    showCrateGuide = true
                }
            }

            // Leash Mastery Prompt (only in non-mastered section)
            if viewModel.shouldShowLeashMasteryPrompt {
                LeashMasteryPromptCard(
                    weeksAtHighRating: 2,
                    onMarkMastered: {
                        showLeashMasteryConfirmation = true
                    },
                    onDismiss: {
                        dismissLeashMasteryPrompt()
                    }
                )
            }

            // Show leash guide in normal position only if not mastered and visible
            if !leashTrainingMastered && viewModel.shouldShowLeashTrainingGuide {
                LeashProgressCard(
                    recentAverage: viewModel.leashRecentSentimentAverage,
                    trend: viewModel.leashSentimentTrend,
                    isMastered: false,
                    onTap: { showLeashGuide = true }
                )
            }
        }
    }

    // MARK: - Mastered Guides Section (below socialization)

    @ViewBuilder
    private var masteredGuidesSection: some View {
        VStack(spacing: 10) {
            // Show mastered potty guide at bottom
            if pottyTrainingMastered {
                TrainingGuideEntryCard(
                    icon: "target",
                    title: Strings.Training.Guides.pottyTitle,
                    subtitle: Strings.Training.PottyTraining.masteredDescription,
                    statValue: nil,
                    tintColor: .otisSuccess,
                    isMastered: true
                ) {
                    showPottyGuide = true
                }
            }

            // Show mastered crate guide at bottom
            if crateTrainingMastered {
                TrainingGuideEntryCard(
                    icon: "house.fill",
                    title: Strings.Training.Guides.crateTitle,
                    subtitle: Strings.Training.CrateTraining.masteredDescription,
                    statValue: nil,
                    tintColor: .indigo,
                    isMastered: true
                ) {
                    showCrateGuide = true
                }
            }

            // Show mastered leash guide at bottom
            if leashTrainingMastered {
                LeashProgressCard(
                    recentAverage: nil,
                    trend: nil,
                    isMastered: true,
                    onTap: { showLeashGuide = true }
                )
            }
        }
    }

    // MARK: - Socialization Section

    @ViewBuilder
    private var socializationSection: some View {
        SocializationJourneyCard()
    }

    // MARK: - Behavior Support Section

    /// Whether to show behavior support card
    /// Shows for teenage+ dogs OR if any behavior incidents exist in last 30 days
    private var shouldShowBehaviorSupport: Bool {
        guard let profile = profileStore.profile else { return false }
        let isTeenageOrOlder = profile.lifecyclePhase != .puppy
        let hasRecentIncidents = eventStore.events
            .filter { $0.isBehaviorIncident }
            .thisMonth()
            .isEmpty == false
        return isTeenageOrOlder || hasRecentIncidents
    }

    @ViewBuilder
    private var behaviorSupportSection: some View {
        if shouldShowBehaviorSupport {
            BehaviorSupportCard()
        }
    }

    // MARK: - Skills Section

    @ViewBuilder
    private var skillsSection: some View {
        SkillsPreviewCard(eventStore: eventStore, skillProgressStore: skillProgressStore)
    }

    // MARK: - Alert Sections

    /// Convert SkillProgress to SkillProgressInfo for RegressionAlertBanner
    private var skillsNeedingWorkInfo: [SkillProgressInfo] {
        let trainingStore = TrainingPlanStore()
        return skillProgressStore.skillsNeedingWork.compactMap { progress in
            guard let skill = trainingStore.trainingPlan?.skills.first(where: { $0.id == progress.skillId }) else {
                return nil
            }
            return SkillProgressInfo(
                skill: skill,
                status: .practicing,
                sessionCount: 0,
                isLocked: false,
                isNextUp: false,
                missingRequirements: [],
                learningPhase: progress.phase,
                confidenceScore: progress.confidenceScore,
                isDueForReview: false,
                daysUntilReview: nil
            )
        }
    }

    @ViewBuilder
    private var regressionAlertSection: some View {
        RegressionAlertBanner(
            skillsNeedingWork: skillsNeedingWorkInfo,
            onTapSkill: { _ in
                // Navigate handled by sheet presentation in skillsSection
            },
            onDismiss: nil // Don't allow dismiss - this is important
        )
    }

    @ViewBuilder
    private var dueForReviewSection: some View {
        let count = skillProgressStore.skillsDueForReview.count
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.title3)
                .foregroundStyle(.indigo)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.indigo.opacity(colorScheme == .dark ? 0.2 : 0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Training.dueForReview)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(Strings.Training.dueForReviewCount(count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.indigo.opacity(colorScheme == .dark ? 0.08 : 0.05))
        )
    }
}

// MARK: - Skills Preview Card

/// Compact preview of current week's training focus
private struct SkillsPreviewCard: View {
    var eventStore: EventStore
    var skillProgressStore: SkillProgressStore
    @State private var trainingStore = TrainingPlanStore()
    @Environment(ProfileStore.self) var profileStore

    @State private var showTodaysTraining = false

    @Environment(\.colorScheme) private var colorScheme

    /// Determine if user has any training progress
    private var hasStartedTraining: Bool {
        trainingStore.masteryProgress.mastered > 0 ||
        trainingStore.allSkillsWithStatus.contains { $0.sessionCount > 0 }
    }

    /// Count of urgent skills (regression + due for review)
    private var urgentCount: Int {
        skillProgressStore.skillsNeedingWork.count +
        skillProgressStore.skillsDueForReview.count
    }

    /// Generate session summary text
    private var sessionSummaryText: String {
        let plan = skillProgressStore.generateSessionPlan()
        let totalSkills = plan.allSkillsInOrder.count

        if plan.isEmpty {
            return Strings.Training.noSkillsDue
        }

        let focusCount = plan.primaryFocus.count
        let reviewCount = plan.maintenance.count

        if focusCount > 0 && reviewCount > 0 {
            return Strings.Train.focusAndReview(focus: focusCount, review: reviewCount)
        } else if focusCount > 0 {
            return Strings.Train.skillsToPractice(focusCount)
        } else {
            return Strings.Train.skillsToReview(totalSkills)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with title and progress ring
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .foregroundStyle(Color.otisAccent)
                            .accessibilityHidden(true)
                        Text(Strings.Train.skills)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .accessibilityAddTraits(.isHeader)
                    }

                    Text(Strings.Train.skillsDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if trainingStore.trainingPlan != nil {
                    ProgressRing(
                        completed: trainingStore.masteryProgress.mastered,
                        total: trainingStore.masteryProgress.total,
                        size: .compact
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Strings.Train.progressRingAccessibility)
                    .accessibilityValue(Strings.Train.progressValue(started: trainingStore.masteryProgress.mastered, total: trainingStore.masteryProgress.total))
                }
            }

            if trainingStore.trainingPlan != nil {
                // Primary CTA: Start Training button
                Button {
                    showTodaysTraining = true
                } label: {
                    HStack(spacing: 10) {
                        // Icon with optional badge
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "play.fill")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.otisAccent))

                            if urgentCount > 0 {
                                Circle()
                                    .fill(Color.otisDanger)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 2, y: -2)
                            }
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(hasStartedTraining ? Strings.Train.continueTraining : Strings.Training.startSession)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text(sessionSummaryText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
                    )
                }
                .buttonStyle(.plain)

                // Secondary: View all skills link (inline, subtle)
                NavigationLink {
                    TrainingView(eventStore: eventStore)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                        Text(Strings.Training.viewAllSkills)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.otisAccent)
                }
                .buttonStyle(.plain)
            } else {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
        .padding()
        .glassCard(tint: .accent)
        .onAppear {
            trainingStore.setEventStore(eventStore)
            trainingStore.setSkillProgressStore(skillProgressStore)
        }
        .sheet(isPresented: $showTodaysTraining) {
            TodaysTrainingView(
                skillProgressStore: skillProgressStore,
                eventStore: eventStore,
                trainingStore: trainingStore,
                puppyAgeWeeks: profileStore.profile?.ageInWeeks ?? 12,
                onDismiss: { showTodaysTraining = false }
            )
        }
    }

}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    return TrainTabView(
        viewModel: viewModel,
        onSettingsTap: { print("Settings tapped") }
    )
    .environment(eventStore)
    .environment(SocializationStore())
    .environment(profileStore)
}
