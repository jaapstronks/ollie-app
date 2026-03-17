//
//  AIInstructions.swift
//  Ollie-app
//
//  System instructions and output format specifications for each AI surface.
//  Surface-specific instructions are in AIInstructions+<Surface>.swift extensions.
//  Broker models are in AIBrokerModels.swift.
//

import Foundation

// MARK: - AI Instructions

/// Generates system instructions and output format specs for AI surfaces.
enum AIInstructions {

    // MARK: - Shared Language Guidance

    /// Guidance for responding in the profile's preferred language.
    /// The locale is set by the profile owner and shared across all household members.
    static let languageGuidance = """

    LANGUAGE:
    The request includes a "locale" field indicating the profile's language preference.
    You MUST respond in the language that matches the locale:
    - "nl" or "nl_NL" → Respond in Dutch
    - "de" or "de_DE" → Respond in German
    - "es" or "es_ES" → Respond in Spanish
    - "fr" or "fr_FR" → Respond in French
    - "it" or "it_IT" → Respond in Italian
    - "sv" or "sv_SE" → Respond in Swedish
    - "pl" or "pl_PL" → Respond in Polish
    - "pt" or "pt_BR" or "pt_PT" → Respond in Portuguese
    - "en" or any other → Respond in English

    All user-facing text in your response (headlines, assessments, advice, suggestions,
    encouragement messages, etc.) must be in the profile's language. JSON keys remain in English.

    """

    // MARK: - Shared Lifecycle Guidance

    /// Guidance for lifecycle-appropriate terminology and tone.
    static let lifecycleGuidance = """

    LIFECYCLE-AWARE COMMUNICATION:
    Check the "dog_identity" context for these fields:
    - "usesPuppyTerminology": If true, use "puppy". If false, use "dog".
    - "lifecyclePhase": Determines overall tone and focus:
      • "puppy" (0-8 months): Focus on foundations, socialization, potty training
      • "teenage" (8-18 months): Focus on behavior maintenance, exercise, adventures
      • "adult" (18mo-7yr): Focus on routine, health, enrichment
      • "senior" (7yr+): Focus on comfort, wellness monitoring, gentle activity

    TERMINOLOGY RULES:
    - Never say "puppy" when usesPuppyTerminology is false
    - Use the dog's pseudonym when possible for a personal touch
    - Adjust expectations and advice to match lifecyclePhase

    PRONOUN USAGE:
    Check "pronouns" in dog_identity for proper pronouns:
    - "subject": he/she/they - use for "he needs a walk" or "she's doing great"
    - "object": him/her/them - use for "take him outside" or "reward her"
    - "possessive": his/her/their - use for "his training" or "her progress"
    - "reflexive": himself/herself/themselves - use for "by himself" or "settle herself"
    Always use these pronouns instead of "it" to personalize communication.

    """

    // MARK: - Shared Sentiment Guidance

    /// Guidance for using user sentiment data across all surfaces.
    static let sentimentGuidance = """

    USER SENTIMENT:
    If sentiment data is provided, use it to focus your advice:
    - "strugglingAreas": Focus your guidance here. The user said this isn't going well.
    - "mutedAreas": Do NOT give tips about these. The user said it's going great.
    - "primaryFocus" or "detectedPriorityFocus": This is what needs attention most. Prioritize it.
    - "rootCauseDependencies": These show that one problem causes another. Fix the root cause first.
    - If an area is struggling, don't over-explain why - just help with practical tips.

    ROOT CAUSE ANALYSIS (critical - apply this logic):
    When multiple areas are struggling, address foundational issues FIRST:

    CRATE TRAINING → is foundational for:
      • Potty training (puppies won't soil their sleeping space, enables supervision)
      • Nipping/biting (provides timeout option, ensures adequate rest)
      • Separation anxiety (builds comfort with alone time gradually)
      • Chewing/destruction (safe confinement when unsupervised)
      • Sleep enforcement (place to enforce naps)
    If ANY of these are struggling and crate training isn't solid, suggest crate training first.

    SLEEP (18-20 hours/day) → is foundational for:
      • Nipping/biting (overtired puppies bite much more)
      • Barking (overtired = more reactive)
      • Training focus (tired puppies can't concentrate)
      • Chewing (bored/tired puppies chew)
      • General behavior (most "difficult" behavior is actually overtiredness)
    If behavior issues exist and sleep isn't 5/5, suggest more sleep first.

    FOOD MOTIVATION → is critical for:
      • All skills training (hungry = motivated)
      • Recall reliability
      • Engagement during walks
    If training is struggling:
      • Pup may not be hungry enough to work for food
      • Fresh meat diets can reduce kibble motivation
      • Solution: kibble-based diet, smaller meals, train before meals

    PRIORITY ORDER when multiple issues:
    1. Crate training (enables everything else)
    2. Sleep (prevents behavior issues)
    3. Potty training (high daily impact)
    4. Skills training (enables other behaviors)
    5. Specific behavior issues (nipping, jumping, etc.)

    NEVER DO:
    - Don't give tips for muted areas (score 5)
    - Don't lecture about why something matters - just give the practical tip
    - Don't suggest addressing multiple root causes at once - pick the highest priority
    - Don't be generic - reference the specific area they're struggling with

    """

    // MARK: - System Instructions

    /// Get system instruction for legacy AINudgeSurface type.
    static func systemInstruction(for surface: AINudgeSurface) -> String {
        switch surface {
        case .insightBundle:
            return insightBundleSystemInstruction
        case .notificationPolicy:
            return notificationPolicySystemInstruction
        }
    }

    /// Get output format for legacy AINudgeSurface type.
    static func outputFormat(for surface: AINudgeSurface) -> String {
        switch surface {
        case .insightBundle:
            return insightBundleOutputFormat
        case .notificationPolicy:
            return notificationPolicyOutputFormat
        }
    }

    /// Get the system instruction for a surface type.
    static func systemInstruction(for surface: AISurface) -> String {
        switch surface {
        case .insightBundle:
            return insightBundleSystemInstruction

        case .notificationPolicy:
            return notificationPolicySystemInstruction

        case .trainingGuidance:
            return trainingGuidanceSystemInstruction

        case .pottyAnalysis:
            return pottyAnalysisSystemInstruction

        case .socializationGuidance:
            return socializationGuidanceSystemInstruction

        case .healthInsights:
            return healthInsightsSystemInstruction

        case .morningBriefing:
            return morningBriefingSystemInstruction
        }
    }

    /// Get the output format specification for a surface type.
    static func outputFormat(for surface: AISurface) -> String {
        switch surface {
        case .insightBundle:
            return insightBundleOutputFormat

        case .notificationPolicy:
            return notificationPolicyOutputFormat

        case .trainingGuidance:
            return trainingGuidanceOutputFormat

        case .pottyAnalysis:
            return pottyAnalysisOutputFormat

        case .socializationGuidance:
            return socializationGuidanceOutputFormat

        case .healthInsights:
            return healthInsightsOutputFormat

        case .morningBriefing:
            return morningBriefingOutputFormat
        }
    }
}

// MARK: - Request Building Helper

extension AIInstructions {

    /// Build a complete request payload for the broker.
    static func buildBrokerRequest(
        surface: AISurface,
        context: AIContextPayload,
        providerPolicy: AIVendorPolicy,
        shadowMode: Bool,
        surfacePayload: (any Encodable)? = nil
    ) -> AIBrokerRequest {
        // Convert surfacePayload to AnyCodable if it's also Codable & Sendable
        let wrappedPayload: AnyCodable?
        if let payload = surfacePayload {
            // Try to encode via JSONEncoder to get the data
            if let data = try? JSONEncoder().encode(AnyEncodableWrapper(payload)) {
                wrappedPayload = AnyCodable(data: data)
            } else {
                wrappedPayload = nil
            }
        } else {
            wrappedPayload = nil
        }

        return AIBrokerRequest(
            surface: surface,
            profileId: context.profileId,
            locale: context.locale,
            policyVersion: "v2",
            promptVersion: context.promptVersion,
            providerPolicy: providerPolicy,
            shadowMode: shadowMode,
            systemInstruction: systemInstruction(for: surface),
            outputFormat: outputFormat(for: surface),
            context: context.components,
            surfacePayload: wrappedPayload
        )
    }
}
