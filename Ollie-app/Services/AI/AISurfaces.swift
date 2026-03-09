//
//  AISurfaces.swift
//  Ollie-app
//
//  Defines AI surfaces (function call types) and their required context.
//  Each surface specifies which context components it needs, enabling
//  efficient, focused context assembly.
//

import Foundation

// MARK: - AI Surface Definition

/// Defines an AI surface (type of function call) with its required context and instructions.
enum AISurface: String, Codable, CaseIterable, Sendable {
    /// Daily insights: status copy, activity ordering, logging recommendations
    case insightBundle = "insight_bundle"

    /// Notification timing adjustments
    case notificationPolicy = "notification_policy"

    /// Training guidance: session planning, skill recommendations
    case trainingGuidance = "training_guidance"

    /// Potty training analysis and predictions
    case pottyAnalysis = "potty_analysis"

    /// Socialization planning and recommendations
    case socializationGuidance = "socialization_guidance"

    /// Health and wellness insights
    case healthInsights = "health_insights"

    // MARK: - Configuration

    /// Context components required for this surface
    var requiredComponents: Set<AIContextComponentKey> {
        switch self {
        case .insightBundle:
            return [.dogIdentity, .pottyPatterns, .sleep, .feeding, .exercise, .recentEvents]

        case .notificationPolicy:
            return [.dogIdentity, .pottyPatterns, .sleep, .exercise, .recentEvents]

        case .trainingGuidance:
            return [.dogIdentity, .training, .trainingDetail, .recentEvents]

        case .pottyAnalysis:
            return [.dogIdentity, .pottyPatterns, .sleep, .feeding, .recentEvents]

        case .socializationGuidance:
            return [.dogIdentity, .socialization, .recentEvents]

        case .healthInsights:
            return [.dogIdentity, .health, .feeding, .exercise, .sleep, .recentEvents]
        }
    }

    /// Optional components that enhance this surface if available
    var optionalComponents: Set<AIContextComponentKey> {
        switch self {
        case .insightBundle:
            return [.training, .socialization, .health, .household, .sentiment]

        case .notificationPolicy:
            return [.household, .sentiment]

        case .trainingGuidance:
            return [.household, .sentiment]

        case .pottyAnalysis:
            return [.household, .sentiment]

        case .socializationGuidance:
            return [.household, .sentiment]

        case .healthInsights:
            return [.household, .sentiment]
        }
    }

    /// Prompt version for tracking prompt iterations
    var promptVersion: String {
        switch self {
        case .insightBundle: return "insight_bundle_v3"
        case .notificationPolicy: return "notification_policy_v3"
        case .trainingGuidance: return "training_guidance_v1"
        case .pottyAnalysis: return "potty_analysis_v1"
        case .socializationGuidance: return "socialization_guidance_v1"
        case .healthInsights: return "health_insights_v1"
        }
    }

    /// Estimated total tokens for required context
    var estimatedRequiredTokens: Int {
        requiredComponents.reduce(0) { $0 + $1.estimatedTokens }
    }

    /// Maximum response tokens to request
    var maxResponseTokens: Int {
        switch self {
        case .insightBundle: return 500
        case .notificationPolicy: return 300
        case .trainingGuidance: return 600
        case .pottyAnalysis: return 400
        case .socializationGuidance: return 500
        case .healthInsights: return 400
        }
    }

    /// Cache duration in minutes
    var cacheDurationMinutes: Int {
        switch self {
        case .insightBundle: return 360  // 6 hours
        case .notificationPolicy: return 240  // 4 hours
        case .trainingGuidance: return 120  // 2 hours
        case .pottyAnalysis: return 60  // 1 hour
        case .socializationGuidance: return 360  // 6 hours
        case .healthInsights: return 720  // 12 hours
        }
    }

    /// Daily budget for this surface type
    var maxCallsPerDay: Int {
        switch self {
        case .insightBundle: return 4
        case .notificationPolicy: return 6
        case .trainingGuidance: return 6
        case .pottyAnalysis: return 4
        case .socializationGuidance: return 2
        case .healthInsights: return 2
        }
    }

    /// Minimum confidence threshold to apply results
    var confidenceThreshold: Double {
        switch self {
        case .insightBundle: return 0.65
        case .notificationPolicy: return 0.65
        case .trainingGuidance: return 0.60
        case .pottyAnalysis: return 0.70
        case .socializationGuidance: return 0.60
        case .healthInsights: return 0.70
        }
    }
}

// MARK: - Context Component Keys

/// Keys for context component types, used for selective inclusion.
enum AIContextComponentKey: String, Codable, Hashable, Sendable {
    case dogIdentity = "dog_identity"
    case household = "household"
    case pottyPatterns = "potty_patterns"
    case sleep = "sleep"
    case feeding = "feeding"
    case exercise = "exercise"
    case training = "training"
    case trainingDetail = "training_detail"
    case socialization = "socialization"
    case recentEvents = "recent_events"
    case health = "health"
    case sentiment = "sentiment"  // User sentiment ratings
    case behavior = "behavior"    // Behavior challenges and interventions

    /// Estimated tokens for this component
    var estimatedTokens: Int {
        switch self {
        case .dogIdentity: return 50
        case .household: return 30
        case .pottyPatterns: return 120
        case .sleep: return 60
        case .feeding: return 50
        case .exercise: return 60
        case .training: return 200
        case .trainingDetail: return 400
        case .socialization: return 100
        case .recentEvents: return 80
        case .health: return 70
        case .sentiment: return 60
        case .behavior: return 120
        }
    }
}

// MARK: - Response Type Definitions

/// Expected response structure for each surface type.
/// Broker uses these to validate LLM output.

protocol AISurfaceResponse: Codable, Sendable {
    var confidence: Double { get }
}

struct InsightBundleResponse: AISurfaceResponse {
    let confidence: Double
    let dailyStatusDecision: DailyStatusDecision?
    let walkOrderingDecision: WalkOrderingDecision?
    let loggingRecommendations: [LoggingRecommendation]

    struct DailyStatusDecision: Codable, Sendable {
        let headline: String
        let subtitle: String?
        let confidence: Double
    }

    struct WalkOrderingDecision: Codable, Sendable {
        let orderedIds: [String]
        let confidence: Double
    }

    struct LoggingRecommendation: Codable, Sendable, Identifiable {
        var id: String { category }
        let category: String
        let recommendation: String
        let confidence: Double
    }
}

struct NotificationPolicyResponse: AISurfaceResponse {
    let confidence: Double
    let validForMinutes: Int
    let pottyMinutesDelta: Int
    let walkMinutesDelta: Int
    let suppressPotty: Bool
    let suppressWalk: Bool
}

struct TrainingGuidanceResponse: AISurfaceResponse {
    let confidence: Double

    /// Suggested skill to focus on in next session
    let suggestedSkill: String?

    /// Why this skill is recommended
    let skillRationale: String?

    /// Session composition advice
    let sessionAdvice: String?

    /// Warning about pace or approach
    let paceGuidance: String?

    /// Skills to include in warm-up
    let warmupSkills: [String]?

    /// Context/location suggestions for generalization
    let contextSuggestions: [String]?

    /// Encouragement message based on recent progress
    let encouragementMessage: String?

    /// Type of encouragement: "celebration", "motivational", "supportive", "reminder"
    let encouragementType: String?

    /// Specific achievement to celebrate (if any)
    let recentAchievement: String?
}

struct PottyAnalysisResponse: AISurfaceResponse {
    let confidence: Double

    /// Current assessment of potty training progress
    let progressAssessment: String

    /// Predicted reliability percentage
    let predictedReliability: Double?

    /// Key insight about patterns
    let keyInsight: String?

    /// Actionable suggestion
    let suggestion: String?

    /// Risk factors to watch
    let riskFactors: [String]?
}

struct SocializationGuidanceResponse: AISurfaceResponse {
    let confidence: Double

    /// Overall socialization assessment
    let assessment: String

    /// Priority exposure category
    let priorityCategory: String?

    /// Specific exposure suggestion
    let exposureSuggestion: String?

    /// Window urgency message (if applicable)
    let windowUrgency: String?
}

struct HealthInsightsResponse: AISurfaceResponse {
    let confidence: Double

    /// Overall wellness assessment
    let wellnessAssessment: String

    /// Specific insights
    let insights: [String]

    /// Recommended actions
    let recommendations: [String]?
}
