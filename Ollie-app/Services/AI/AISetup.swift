//
//  AISetup.swift
//  Ollie-app
//
//  App initialization for AI services.
//  Call `AI.setup()` during app launch to wire up data providers.
//

import Foundation
import OtisShared

extension AI {

    // MARK: - Setup

    /// Initialize AI services with required data providers.
    /// Call this during app launch after stores are initialized.
    ///
    /// Example usage in OtisApp.swift:
    /// ```swift
    /// .task {
    ///     // ... other initialization ...
    ///     AI.setup(
    ///         skillProgressStore: skillProgressStore,
    ///         regressionLogStore: regressionLogStore,
    ///         socializationStore: socializationStore
    ///     )
    /// }
    /// ```
    @MainActor
    static func setup(
        skillProgressStore: SkillProgressStore?,
        regressionLogStore: RegressionLogStore? = nil,
        socializationStore: SocializationStore?
    ) {
        // Register skill progress provider
        if let skillStore = skillProgressStore {
            orchestrator.registerSkillProgressProvider { [weak skillStore] in
                skillStore?.skillProgress ?? []
            }
        }

        // Register regression log provider
        if let regressionStore = regressionLogStore {
            orchestrator.registerRegressionLogProvider { [weak regressionStore] in
                regressionStore?.regressionLogs ?? []
            }
        } else {
            // Fallback to empty if no regression store provided
            orchestrator.registerRegressionLogProvider {
                []
            }
        }

        // Register socialization progress provider
        if let socStore = socializationStore {
            orchestrator.registerSocializationProgressProvider { [weak socStore] profile in
                guard let socStore else { return nil }

                // Calculate overall progress
                var totalItems = 0
                var completedItems = 0
                var lowExposureCategories: [String] = []

                for category in socStore.categories {
                    let (completed, total) = socStore.categoryProgress(for: category.id)
                    totalItems += total
                    completedItems += completed

                    // Mark categories with < 25% progress as low exposure
                    let progress = total > 0 ? Double(completed) / Double(total) : 0
                    if progress < 0.25 && total > 0 {
                        lowExposureCategories.append(category.id)
                    }
                }

                let overallProgress = totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0

                // Count exposures this week
                let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                var exposuresThisWeek = 0
                for category in socStore.categories {
                    for item in category.items {
                        let exposures = socStore.getExposures(for: item.id)
                        exposuresThisWeek += exposures.filter { $0.date >= weekStart }.count
                    }
                }

                // Count completed categories
                let completedCategories = socStore.categories.filter { category in
                    let (completed, total) = socStore.categoryProgress(for: category.id)
                    return total > 0 && completed == total
                }.count

                return SocializationProgress(
                    overallProgress: overallProgress,
                    exposuresThisWeek: exposuresThisWeek,
                    lowExposureCategories: lowExposureCategories,
                    completedCategories: completedCategories
                )
            }
        }
    }
}

// MARK: - Integration with Legacy System

extension AI {

    /// Bridge to existing AINudgeOrchestrator for backwards compatibility.
    /// Use this during migration to route calls through either system.
    @MainActor
    static func legacyOrchestrator() -> AINudgeOrchestrator {
        .shared
    }

    /// Check if new AI system should be used for a given surface.
    /// During migration, some surfaces may still use the legacy system.
    @MainActor
    static func useNewSystem(for surface: AISurface) -> Bool {
        switch surface {
        // New surfaces always use new system
        case .trainingGuidance, .pottyAnalysis, .socializationGuidance, .healthInsights:
            return true

        // Legacy surfaces can be migrated gradually
        case .insightBundle, .notificationPolicy:
            // TODO: Set to true once broker supports new request format
            return false
        }
    }
}

// MARK: - Convenience for Views

extension AI {

    /// Get cached training guidance if available (for UI display).
    @MainActor
    static func cachedTrainingGuidance(profileId: UUID) -> TrainingGuidanceResponse? {
        orchestrator.cachedResult(
            surface: .trainingGuidance,
            profileId: profileId,
            responseType: TrainingGuidanceResponse.self
        )
    }

    /// Get cached potty analysis if available (for UI display).
    @MainActor
    static func cachedPottyAnalysis(profileId: UUID) -> PottyAnalysisResponse? {
        orchestrator.cachedResult(
            surface: .pottyAnalysis,
            profileId: profileId,
            responseType: PottyAnalysisResponse.self
        )
    }

    /// Get cached socialization guidance if available (for UI display).
    @MainActor
    static func cachedSocializationGuidance(profileId: UUID) -> SocializationGuidanceResponse? {
        orchestrator.cachedResult(
            surface: .socializationGuidance,
            profileId: profileId,
            responseType: SocializationGuidanceResponse.self
        )
    }
}
