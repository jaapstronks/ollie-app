//
//  SentimentTipProvider.swift
//  Ollie-app
//
//  Provides rotating tips for categories where the user is struggling.
//  Also identifies root causes and suggests foundational improvements.
//

import Foundation

// MARK: - Tip Provider

struct SentimentTipProvider {

    // MARK: - Root Cause Analysis

    /// Analyze struggling categories and identify which one to focus on first.
    /// Returns the category that should be addressed first (root cause) and why.
    static func identifyPrimaryFocus(
        strugglingCategories: [SentimentCategory],
        checkIns: [SentimentCategory: SentimentCheckIn]
    ) -> (category: SentimentCategory, reason: String)? {
        guard !strugglingCategories.isEmpty else { return nil }

        // Priority order: foundational categories first
        let priorityOrder: [SentimentCategory] = [
            .benchTraining,   // Most foundational - enables many others
            .sleeping,        // Critical for behavior
            .pottyTraining,   // High daily impact
            .skillsTraining,  // Enables other behaviors
            .nipping,
            .chewing,
            .separationAnxiety,
            .jumping,
            .leashBehavior,
            .barking,
            .handlingTolerance,
            .carTravel,
            .resourceGuarding,
            .walks
        ]

        // Check if any struggling category has unsolved dependencies
        for category in strugglingCategories {
            let dependencies = category.rootCauseDependencies
            for dep in dependencies {
                if let depCheckIn = checkIns[dep], depCheckIn.isStruggling {
                    // Dependency is also struggling - suggest fixing that first
                    return (dep, rootCauseExplanation(for: category, dependsOn: dep))
                }
            }
        }

        // No dependency issues - return lowest-scoring in priority order
        let sorted = strugglingCategories.sorted { cat1, cat2 in
            let idx1 = priorityOrder.firstIndex(of: cat1) ?? 999
            let idx2 = priorityOrder.firstIndex(of: cat2) ?? 999
            if idx1 == idx2 {
                // Same priority - pick lower score
                let score1 = checkIns[cat1]?.score ?? 5
                let score2 = checkIns[cat2]?.score ?? 5
                return score1 < score2
            }
            return idx1 < idx2
        }

        if let primary = sorted.first {
            return (primary, "This is a good area to focus on right now.")
        }

        return nil
    }

    /// Get explanation for why a dependency should be fixed first.
    private static func rootCauseExplanation(for category: SentimentCategory, dependsOn: SentimentCategory) -> String {
        switch (category, dependsOn) {
        case (.pottyTraining, .benchTraining):
            return Strings.Sentiment.rootCausePottyCrate
        case (.nipping, .sleeping):
            return Strings.Sentiment.rootCauseNippingSleep
        case (.nipping, .benchTraining):
            return Strings.Sentiment.rootCauseNippingCrate
        case (.separationAnxiety, .benchTraining):
            return Strings.Sentiment.rootCauseSeparationCrate
        case (.chewing, .sleeping):
            return Strings.Sentiment.rootCauseChewingSleep
        case (.chewing, .benchTraining):
            return Strings.Sentiment.rootCauseChewingCrate
        case (.barking, .sleeping):
            return Strings.Sentiment.rootCauseBarkingSleep
        default:
            return "Improving \(dependsOn.displayName.lowercased()) will help with \(category.displayName.lowercased())."
        }
    }

    // MARK: - Tip Rotation

    /// Get the tip of the day for a struggling category.
    /// Rotates through available tips based on date.
    static func tipOfTheDay(for category: SentimentCategory) -> SentimentTip? {
        let tips = tips(for: category)
        guard !tips.isEmpty else { return nil }

        // Use day of year to rotate tips
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % tips.count
        return tips[index]
    }

    /// Get all tips for a category.
    static func tips(for category: SentimentCategory) -> [SentimentTip] {
        switch category {
        case .benchTraining:
            return crateTips
        case .pottyTraining:
            return pottyTips
        case .sleeping:
            return sleepTips
        case .nipping:
            return nippingTips
        case .skillsTraining:
            return trainingTips
        case .chewing:
            return chewingTips
        case .separationAnxiety:
            return separationTips
        case .barking:
            return barkingTips
        case .jumping:
            return jumpingTips
        case .leashBehavior:
            return leashTips
        default:
            return []
        }
    }

    // MARK: - Tips by Category

    private static let crateTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipCrateWhiningTitle,
            body: Strings.Sentiment.tipCrateWhiningBody,
            actionLabel: Strings.Sentiment.learnMore,
            infoSheetType: .crateTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipCrateLocationTitle,
            body: Strings.Sentiment.tipCrateLocationBody,
            actionLabel: nil,
            infoSheetType: .crateTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipCrateCoverTitle,
            body: Strings.Sentiment.tipCrateCoverBody,
            actionLabel: nil,
            infoSheetType: .crateTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipCratePositiveTitle,
            body: Strings.Sentiment.tipCratePositiveBody,
            actionLabel: nil,
            infoSheetType: .crateTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipCrateBenefitsTitle,
            body: Strings.Sentiment.tipCrateBenefitsBody,
            actionLabel: Strings.Sentiment.learnMore,
            infoSheetType: .crateTraining
        )
    ]

    private static let pottyTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipPottyScheduleTitle,
            body: Strings.Sentiment.tipPottyScheduleBody,
            actionLabel: nil,
            infoSheetType: .pottyTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipPottyCrateTitle,
            body: Strings.Sentiment.tipPottyCrateBody,
            actionLabel: Strings.Sentiment.learnMore,
            infoSheetType: .crateTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipPottyAccidentTitle,
            body: Strings.Sentiment.tipPottyAccidentBody,
            actionLabel: nil,
            infoSheetType: .pottyTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipPottyRewardTitle,
            body: Strings.Sentiment.tipPottyRewardBody,
            actionLabel: nil,
            infoSheetType: .pottyTraining
        )
    ]

    private static let sleepTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipSleepAmountTitle,
            body: Strings.Sentiment.tipSleepAmountBody,
            actionLabel: nil,
            infoSheetType: .sleepEnforcement
        ),
        SentimentTip(
            title: Strings.Sentiment.tipSleepEnforceTitle,
            body: Strings.Sentiment.tipSleepEnforceBody,
            actionLabel: Strings.Sentiment.learnMore,
            infoSheetType: .crateTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipSleepOvertiredTitle,
            body: Strings.Sentiment.tipSleepOvertiredBody,
            actionLabel: nil,
            infoSheetType: .sleepEnforcement
        )
    ]

    private static let nippingTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipNippingSleepTitle,
            body: Strings.Sentiment.tipNippingSleepBody,
            actionLabel: nil,
            infoSheetType: .nippingManagement
        ),
        SentimentTip(
            title: Strings.Sentiment.tipNippingTimeoutTitle,
            body: Strings.Sentiment.tipNippingTimeoutBody,
            actionLabel: Strings.Sentiment.learnMore,
            infoSheetType: .crateTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipNippingRedirectTitle,
            body: Strings.Sentiment.tipNippingRedirectBody,
            actionLabel: nil,
            infoSheetType: .nippingManagement
        ),
        SentimentTip(
            title: Strings.Sentiment.tipNippingNormalTitle,
            body: Strings.Sentiment.tipNippingNormalBody,
            actionLabel: nil,
            infoSheetType: .nippingManagement
        )
    ]

    private static let trainingTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipTrainingHungryTitle,
            body: Strings.Sentiment.tipTrainingHungryBody,
            actionLabel: nil,
            infoSheetType: .foodMotivation
        ),
        SentimentTip(
            title: Strings.Sentiment.tipTrainingShortTitle,
            body: Strings.Sentiment.tipTrainingShortBody,
            actionLabel: nil,
            infoSheetType: nil
        ),
        SentimentTip(
            title: Strings.Sentiment.tipTrainingKibbleTitle,
            body: Strings.Sentiment.tipTrainingKibbleBody,
            actionLabel: nil,
            infoSheetType: .foodMotivation
        )
    ]

    private static let chewingTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipChewingBoredTitle,
            body: Strings.Sentiment.tipChewingBoredBody,
            actionLabel: nil,
            infoSheetType: nil
        ),
        SentimentTip(
            title: Strings.Sentiment.tipChewingTeethingTitle,
            body: Strings.Sentiment.tipChewingTeethingBody,
            actionLabel: nil,
            infoSheetType: nil
        )
    ]

    private static let separationTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipSeparationCrateTitle,
            body: Strings.Sentiment.tipSeparationCrateBody,
            actionLabel: Strings.Sentiment.learnMore,
            infoSheetType: .crateTraining
        ),
        SentimentTip(
            title: Strings.Sentiment.tipSeparationGradualTitle,
            body: Strings.Sentiment.tipSeparationGradualBody,
            actionLabel: nil,
            infoSheetType: nil
        )
    ]

    private static let barkingTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipBarkingTiredTitle,
            body: Strings.Sentiment.tipBarkingTiredBody,
            actionLabel: nil,
            infoSheetType: .sleepEnforcement
        ),
        SentimentTip(
            title: Strings.Sentiment.tipBarkingAlertTitle,
            body: Strings.Sentiment.tipBarkingAlertBody,
            actionLabel: nil,
            infoSheetType: nil
        )
    ]

    private static let jumpingTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipJumpingSitTitle,
            body: Strings.Sentiment.tipJumpingSitBody,
            actionLabel: nil,
            infoSheetType: nil
        ),
        SentimentTip(
            title: Strings.Sentiment.tipJumpingIgnoreTitle,
            body: Strings.Sentiment.tipJumpingIgnoreBody,
            actionLabel: nil,
            infoSheetType: nil
        )
    ]

    private static let leashTips: [SentimentTip] = [
        SentimentTip(
            title: Strings.Sentiment.tipLeashEngagementTitle,
            body: Strings.Sentiment.tipLeashEngagementBody,
            actionLabel: nil,
            infoSheetType: nil
        ),
        SentimentTip(
            title: Strings.Sentiment.tipLeashStopTitle,
            body: Strings.Sentiment.tipLeashStopBody,
            actionLabel: nil,
            infoSheetType: nil
        )
    ]
}

// MARK: - Sentiment Tip Model

/// A tip for a sentiment category (renamed to avoid conflict with TipKit's Tip protocol)
struct SentimentTip: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let actionLabel: String?
    let infoSheetType: InfoSheetType?
}

// MARK: - Info Sheet Types

enum InfoSheetType: String, Identifiable {
    case crateTraining
    case pottyTraining
    case sleepEnforcement
    case nippingManagement
    case foodMotivation

    var id: String { rawValue }
}
