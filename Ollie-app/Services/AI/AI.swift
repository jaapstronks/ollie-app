//
//  AI.swift
//  Ollie-app
//
//  Central export for AI services.
//  Import this file to access all AI functionality.
//

import Foundation
import OtisShared

// MARK: - AI Namespace

/// Namespace for AI-related types and services.
enum AI {

    // MARK: - Shared Instances

    /// The shared orchestrator for making AI requests.
    @MainActor
    static var orchestrator: AIOrchestrator { .shared }

    /// Context builder for constructing AI request payloads.
    @MainActor
    static func contextBuilder() -> AIContextBuilder {
        AIContextBuilder()
    }

    // MARK: - Quick Access

    /// Check if AI features are available for a profile.
    @MainActor
    static func isAvailable(for profile: PuppyProfile) -> Bool {
        // PERFORMANCE: Check debug toggle to disable AI cards
        guard !PerformanceDebug.disableAICards else { return false }
        guard AINudgeRollout.isEnabled else { return false }
        guard SubscriptionManager.shared.hasAccess(to: .aiNudges) else { return false }
        let bucket = abs(profile.id.uuidString.hashValue) % 100
        return bucket < AINudgeRollout.rolloutPercentage
    }

    // MARK: - Surface Shortcuts

    /// Request insight bundle (daily status, activity ordering).
    @MainActor
    static func requestInsightBundle(
        profile: PuppyProfile,
        events: [PuppyEvent],
        prediction: PottyPrediction?,
        sleepState: SleepState,
        actionableItems: [ActionableItem],
        upcomingItems: [UpcomingItem]
    ) async -> AIResult<InsightBundleResponse> {
        let payload = InsightBundlePayload.build(
            baselineTitle: prediction.map { PredictionCalculations.displayText(for: $0, puppyName: profile.name) } ?? "",
            baselineSubtitle: prediction.flatMap { PredictionCalculations.subtitleText(for: $0) },
            prediction: prediction,
            sleepState: sleepState,
            actionableItems: actionableItems,
            upcomingItems: upcomingItems
        )

        return await orchestrator.request(
            surface: .insightBundle,
            profile: profile,
            recentEvents: events,
            prediction: prediction,
            sleepState: sleepState,
            surfacePayload: payload,
            responseType: InsightBundleResponse.self
        )
    }

    /// Request notification policy adjustments.
    @MainActor
    static func requestNotificationPolicy(
        profile: PuppyProfile,
        events: [PuppyEvent]
    ) async -> AIResult<NotificationPolicyResponse> {
        let payload = NotificationPolicyPayload.build(from: events)

        return await orchestrator.request(
            surface: .notificationPolicy,
            profile: profile,
            recentEvents: events,
            surfacePayload: payload,
            responseType: NotificationPolicyResponse.self
        )
    }

    /// Request training guidance.
    @MainActor
    static func requestTrainingGuidance(
        profile: PuppyProfile,
        events: [PuppyEvent],
        sessionContext: TrainingGuidancePayload.SessionContext? = nil,
        userQuestion: String? = nil
    ) async -> AIResult<TrainingGuidanceResponse> {
        let payload = TrainingGuidancePayload(
            sessionContext: sessionContext,
            userQuestion: userQuestion
        )

        return await orchestrator.request(
            surface: .trainingGuidance,
            profile: profile,
            recentEvents: events,
            surfacePayload: payload,
            responseType: TrainingGuidanceResponse.self
        )
    }

    /// Request potty analysis.
    @MainActor
    static func requestPottyAnalysis(
        profile: PuppyProfile,
        events: [PuppyEvent],
        prediction: PottyPrediction?,
        gapStats: GapStats?
    ) async -> AIResult<PottyAnalysisResponse> {
        return await orchestrator.request(
            surface: .pottyAnalysis,
            profile: profile,
            recentEvents: events,
            prediction: prediction,
            gapStats: gapStats,
            responseType: PottyAnalysisResponse.self
        )
    }

    /// Request socialization guidance.
    @MainActor
    static func requestSocializationGuidance(
        profile: PuppyProfile,
        events: [PuppyEvent]
    ) async -> AIResult<SocializationGuidanceResponse> {
        return await orchestrator.request(
            surface: .socializationGuidance,
            profile: profile,
            recentEvents: events,
            responseType: SocializationGuidanceResponse.self
        )
    }

    /// Request health insights.
    @MainActor
    static func requestHealthInsights(
        profile: PuppyProfile,
        events: [PuppyEvent]
    ) async -> AIResult<HealthInsightsResponse> {
        return await orchestrator.request(
            surface: .healthInsights,
            profile: profile,
            recentEvents: events,
            responseType: HealthInsightsResponse.self
        )
    }

    /// Request morning briefing - synthesized daily guidance from all sources.
    @MainActor
    static func requestMorningBriefing(
        profile: PuppyProfile,
        events: [PuppyEvent]
    ) async -> AIResult<MorningBriefingResponse> {
        return await orchestrator.request(
            surface: .morningBriefing,
            profile: profile,
            recentEvents: events,
            responseType: MorningBriefingResponse.self
        )
    }

    // MARK: - Cache Access

    /// Get cached morning briefing if available.
    @MainActor
    static func cachedMorningBriefing(profileId: UUID) -> MorningBriefingResponse? {
        orchestrator.cachedResponse(surface: .morningBriefing, profileId: profileId)
    }
}

// MARK: - Usage Examples

/*

 USAGE GUIDE
 ===========

 The AI system is built on modular context components that are assembled
 based on each surface's requirements. This ensures efficient, focused
 context for each type of AI request.

 ## Basic Usage

 ```swift
 // Check availability
 guard AI.isAvailable(for: profile) else {
     // Use fallback behavior
     return
 }

 // Request insights
 let result = await AI.requestInsightBundle(
     profile: profile,
     events: recentEvents,
     prediction: pottyPrediction,
     sleepState: currentSleepState,
     actionableItems: actionable,
     upcomingItems: upcoming
 )

 switch result {
 case .success(let response):
     let (title, subtitle) = response.applyDailyStatus(
         baselineTitle: baselineTitle,
         baselineSubtitle: baselineSubtitle,
         shadowMode: AINudgeRollout.isShadowMode
     )
     // Use enhanced title/subtitle

 case .shadow(let response):
     // Log for validation but don't apply
     Analytics.log("shadow_ai_response", data: response)

 case .fallback(let reason):
     // Use baseline behavior
     print("AI fallback: \(reason.description)")
 }
 ```

 ## Adding a New AI Surface

 1. Add case to `AISurface` enum in `AISurfaces.swift`
 2. Define required/optional context components
 3. Add response type conforming to `AISurfaceResponse`
 4. Add system instruction and output format in `AIInstructions.swift`
 5. Add convenience method in `AI.swift` namespace

 ## Adding a New Context Component

 1. Create struct conforming to `AIContextComponent` in `AIContextComponents.swift`
 2. Add key to `AIContextComponentKey` enum
 3. Add build case in `AIContextBuilder.buildComponent()`
 4. Register any required data providers at app startup

 ## Registering Data Providers

 At app launch, register providers for data that needs to be fetched:

 ```swift
 // In AppDelegate or similar
 AI.orchestrator.registerSkillProgressProvider {
     SkillProgressStore.shared.fetchAll()
 }

 AI.orchestrator.registerSocializationProgressProvider { profile in
     SocializationStore.shared.calculateProgress(for: profile)
 }
 ```

 ## Context Component Reference

 | Component        | Key                | Tokens | Description                         |
 |------------------|-------------------|--------|-------------------------------------|
 | DogIdentityContext| dog_identity      | ~50    | Age, size, pseudonym, life stage   |
 | HouseholdContext  | household         | ~30    | Member count, roles                 |
 | PottyPatternsContext| potty_patterns  | ~120   | Gaps, streaks, success rate        |
 | SleepContext      | sleep             | ~60    | Sleep state, nap tracking          |
 | FeedingContext    | feeding           | ~50    | Meal tracking, water               |
 | ExerciseContext   | exercise          | ~60    | Walks, yard visits, limits         |
 | TrainingProgressContext| training     | ~200   | Skills summary, pace warnings      |
 | TrainingDetailContext| training_detail | ~400   | Full skill details, sessions       |
 | SocializationContext| socialization   | ~100   | Window status, exposure counts     |
 | RecentEventsSummary| recent_events    | ~80    | Event counts, logging patterns     |
 | HealthContext     | health            | ~70    | Weight, medications, notes         |

 */
