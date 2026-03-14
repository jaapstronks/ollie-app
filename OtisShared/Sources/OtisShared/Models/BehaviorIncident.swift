//
//  BehaviorIncident.swift
//  OtisShared
//
//  Behavior incident tracking for teenage/adult dog retention
//  Helps owners understand and address behavioral challenges
//

import Foundation

// MARK: - Behavior Category

/// Categories of behavioral challenges commonly seen in dogs
public enum BehaviorCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case reactivity      // Lunging, barking at triggers (other dogs, people, vehicles)
    case anxiety         // Panting, pacing, destruction when alone or stressed
    case destructive     // Chewing, digging inappropriately
    case barking         // Excessive vocalization
    case guarding        // Resource guarding (food, toys, spaces)
    case jumping         // Jumping on people
    case pulling         // Leash pulling/lunging on walks
    case recall          // Not coming when called
    case mouthing        // Inappropriate mouthing/nipping
    case fearful         // Fear responses (cowering, hiding, trembling)

    public var id: String { rawValue }

    /// Localized label for the category
    public var label: String {
        switch self {
        case .reactivity: return Strings.Behavior.categoryReactivity
        case .anxiety: return Strings.Behavior.categoryAnxiety
        case .destructive: return Strings.Behavior.categoryDestructive
        case .barking: return Strings.Behavior.categoryBarking
        case .guarding: return Strings.Behavior.categoryGuarding
        case .jumping: return Strings.Behavior.categoryJumping
        case .pulling: return Strings.Behavior.categoryPulling
        case .recall: return Strings.Behavior.categoryRecall
        case .mouthing: return Strings.Behavior.categoryMouthing
        case .fearful: return Strings.Behavior.categoryFearful
        }
    }

    /// Short description of the behavior
    public var description: String {
        switch self {
        case .reactivity: return Strings.Behavior.descReactivity
        case .anxiety: return Strings.Behavior.descAnxiety
        case .destructive: return Strings.Behavior.descDestructive
        case .barking: return Strings.Behavior.descBarking
        case .guarding: return Strings.Behavior.descGuarding
        case .jumping: return Strings.Behavior.descJumping
        case .pulling: return Strings.Behavior.descPulling
        case .recall: return Strings.Behavior.descRecall
        case .mouthing: return Strings.Behavior.descMouthing
        case .fearful: return Strings.Behavior.descFearful
        }
    }

    /// SF Symbol icon for the category
    public var icon: String {
        switch self {
        case .reactivity: return "exclamationmark.triangle.fill"
        case .anxiety: return "heart.slash.fill"
        case .destructive: return "tornado"
        case .barking: return "speaker.wave.3.fill"
        case .guarding: return "shield.fill"
        case .jumping: return "arrow.up.circle.fill"
        case .pulling: return "arrow.left.arrow.right"
        case .recall: return "ear.trianglebadge.exclamationmark"
        case .mouthing: return "mouth.fill"
        case .fearful: return "cloud.rain.fill"
        }
    }

    /// Common triggers for this behavior category
    public var commonTriggers: [String] {
        switch self {
        case .reactivity:
            return [
                Strings.Behavior.triggerOtherDogs,
                Strings.Behavior.triggerStrangers,
                Strings.Behavior.triggerBicycles,
                Strings.Behavior.triggerVehicles,
                Strings.Behavior.triggerChildren
            ]
        case .anxiety:
            return [
                Strings.Behavior.triggerAlone,
                Strings.Behavior.triggerLoudNoises,
                Strings.Behavior.triggerNewEnvironment,
                Strings.Behavior.triggerCarRides,
                Strings.Behavior.triggerVetVisit
            ]
        case .destructive:
            return [
                Strings.Behavior.triggerBoredom,
                Strings.Behavior.triggerAlone,
                Strings.Behavior.triggerTeething,
                Strings.Behavior.triggerExcess
            ]
        case .barking:
            return [
                Strings.Behavior.triggerDoorbell,
                Strings.Behavior.triggerPassersby,
                Strings.Behavior.triggerOtherDogs,
                Strings.Behavior.triggerAttentionSeeking,
                Strings.Behavior.triggerAlone
            ]
        case .guarding:
            return [
                Strings.Behavior.triggerFood,
                Strings.Behavior.triggerToys,
                Strings.Behavior.triggerBed,
                Strings.Behavior.triggerOwner,
                Strings.Behavior.triggerHighValueTreats
            ]
        case .jumping:
            return [
                Strings.Behavior.triggerGreeting,
                Strings.Behavior.triggerExcitement,
                Strings.Behavior.triggerAttentionSeeking
            ]
        case .pulling:
            return [
                Strings.Behavior.triggerExcitement,
                Strings.Behavior.triggerOtherDogs,
                Strings.Behavior.triggerScents,
                Strings.Behavior.triggerSquirrels
            ]
        case .recall:
            return [
                Strings.Behavior.triggerDistractions,
                Strings.Behavior.triggerOtherDogs,
                Strings.Behavior.triggerScents,
                Strings.Behavior.triggerSquirrels
            ]
        case .mouthing:
            return [
                Strings.Behavior.triggerPlay,
                Strings.Behavior.triggerExcitement,
                Strings.Behavior.triggerTeething,
                Strings.Behavior.triggerOverstimulation
            ]
        case .fearful:
            return [
                Strings.Behavior.triggerLoudNoises,
                Strings.Behavior.triggerStrangers,
                Strings.Behavior.triggerNewEnvironment,
                Strings.Behavior.triggerOtherDogs,
                Strings.Behavior.triggerObjects
            ]
        }
    }
}

// MARK: - Behavior Intensity

/// Intensity scale for behavior incidents (1-5)
public enum BehaviorIntensity: Int, Codable, CaseIterable, Identifiable, Sendable {
    case mild = 1       // Brief, easily redirected
    case low = 2        // Noticeable but manageable
    case moderate = 3   // Required intervention
    case high = 4       // Difficult to manage
    case severe = 5     // Extreme, concerning

    public var id: Int { rawValue }

    /// Localized label
    public var label: String {
        switch self {
        case .mild: return Strings.Behavior.intensityMild
        case .low: return Strings.Behavior.intensityLow
        case .moderate: return Strings.Behavior.intensityModerate
        case .high: return Strings.Behavior.intensityHigh
        case .severe: return Strings.Behavior.intensitySevere
        }
    }

    /// Short description
    public var description: String {
        switch self {
        case .mild: return Strings.Behavior.intensityMildDesc
        case .low: return Strings.Behavior.intensityLowDesc
        case .moderate: return Strings.Behavior.intensityModerateDesc
        case .high: return Strings.Behavior.intensityHighDesc
        case .severe: return Strings.Behavior.intensitySevereDesc
        }
    }

    /// Color representation for UI
    public var colorName: String {
        switch self {
        case .mild: return "otisSuccess"
        case .low: return "otisInfo"
        case .moderate: return "otisAccent"
        case .high: return "otisWarning"
        case .severe: return "otisDestructive"
        }
    }
}

// MARK: - Behavior Outcome

/// What happened after the behavior incident
public enum BehaviorOutcome: String, Codable, CaseIterable, Identifiable, Sendable {
    case redirected      // Successfully redirected attention
    case escalated       // Behavior got worse
    case selfResolved    // Dog calmed on their own
    case removed         // Had to remove dog from situation
    case managed         // Managed but challenging

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .redirected: return Strings.Behavior.outcomeRedirected
        case .escalated: return Strings.Behavior.outcomeEscalated
        case .selfResolved: return Strings.Behavior.outcomeSelfResolved
        case .removed: return Strings.Behavior.outcomeRemoved
        case .managed: return Strings.Behavior.outcomeManaged
        }
    }
}

// MARK: - Behavior Intervention

/// An intervention or technique being used to address a behavior challenge
/// Could be trainer-recommended or self-directed
public struct BehaviorIntervention: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var category: BehaviorCategory
    public var notes: String?
    public var isActive: Bool
    public var createdAt: Date
    public var practicedDates: [Date]

    public init(
        id: UUID = UUID(),
        name: String,
        category: BehaviorCategory,
        notes: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        practicedDates: [Date] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.practicedDates = practicedDates
    }

    /// Mark the intervention as practiced today
    public mutating func markPracticed(on date: Date = Date()) {
        practicedDates.append(date)
    }

    /// Days since last practiced
    public var daysSinceLastPractice: Int? {
        // PERF: Use max() O(n) instead of sorted().last O(n log n)
        guard let lastPractice = practicedDates.max() else { return nil }
        return Date().daysSince(lastPractice)
    }

    /// Number of times practiced in the last 7 days
    public var practiceCountThisWeek: Int {
        practicedDates.filter { $0.isThisWeek }.count
    }
}

// MARK: - Common Intervention Templates

/// Pre-defined intervention templates for common behavior modification techniques
public enum InterventionTemplate: String, CaseIterable, Identifiable, Sendable {
    case counterConditioning
    case desensitization
    case batTraining
    case relaxationProtocol
    case managementOnly
    case avoidTriggers
    case shorterWalks
    case quieterRoutes
    case moreExercise
    case mentalEnrichment
    case tradeUpGame
    case leaveItCommand
    case positiveInterrupter
    case calmingSignals
    case thundershirt
    case medicationSupport
    case trainerSessions
    case custom

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .counterConditioning: return Strings.BehaviorSupport.interventionCounterConditioning
        case .desensitization: return Strings.BehaviorSupport.interventionDesensitization
        case .batTraining: return Strings.BehaviorSupport.interventionBAT
        case .relaxationProtocol: return Strings.BehaviorSupport.interventionRelaxation
        case .managementOnly: return Strings.BehaviorSupport.interventionManagement
        case .avoidTriggers: return Strings.BehaviorSupport.interventionAvoidTriggers
        case .shorterWalks: return Strings.BehaviorSupport.interventionShorterWalks
        case .quieterRoutes: return Strings.BehaviorSupport.interventionQuieterRoutes
        case .moreExercise: return Strings.BehaviorSupport.interventionMoreExercise
        case .mentalEnrichment: return Strings.BehaviorSupport.interventionEnrichment
        case .tradeUpGame: return Strings.BehaviorSupport.interventionTradeUp
        case .leaveItCommand: return Strings.BehaviorSupport.interventionLeaveIt
        case .positiveInterrupter: return Strings.BehaviorSupport.interventionInterrupter
        case .calmingSignals: return Strings.BehaviorSupport.interventionCalming
        case .thundershirt: return Strings.BehaviorSupport.interventionThundershirt
        case .medicationSupport: return Strings.BehaviorSupport.interventionMedication
        case .trainerSessions: return Strings.BehaviorSupport.interventionTrainer
        case .custom: return Strings.BehaviorSupport.interventionCustom
        }
    }

    public var description: String {
        switch self {
        case .counterConditioning: return Strings.BehaviorSupport.interventionCounterConditioningDesc
        case .desensitization: return Strings.BehaviorSupport.interventionDesensitizationDesc
        case .batTraining: return Strings.BehaviorSupport.interventionBATDesc
        case .relaxationProtocol: return Strings.BehaviorSupport.interventionRelaxationDesc
        case .managementOnly: return Strings.BehaviorSupport.interventionManagementDesc
        case .avoidTriggers: return Strings.BehaviorSupport.interventionAvoidTriggersDesc
        case .shorterWalks: return Strings.BehaviorSupport.interventionShorterWalksDesc
        case .quieterRoutes: return Strings.BehaviorSupport.interventionQuieterRoutesDesc
        case .moreExercise: return Strings.BehaviorSupport.interventionMoreExerciseDesc
        case .mentalEnrichment: return Strings.BehaviorSupport.interventionEnrichmentDesc
        case .tradeUpGame: return Strings.BehaviorSupport.interventionTradeUpDesc
        case .leaveItCommand: return Strings.BehaviorSupport.interventionLeaveItDesc
        case .positiveInterrupter: return Strings.BehaviorSupport.interventionInterrupterDesc
        case .calmingSignals: return Strings.BehaviorSupport.interventionCalmingDesc
        case .thundershirt: return Strings.BehaviorSupport.interventionThundershirtDesc
        case .medicationSupport: return Strings.BehaviorSupport.interventionMedicationDesc
        case .trainerSessions: return Strings.BehaviorSupport.interventionTrainerDesc
        case .custom: return Strings.BehaviorSupport.interventionCustomDesc
        }
    }

    /// Suggested templates for each behavior category
    public static func suggested(for category: BehaviorCategory) -> [InterventionTemplate] {
        switch category {
        case .reactivity:
            return [.counterConditioning, .desensitization, .batTraining, .avoidTriggers, .quieterRoutes, .trainerSessions]
        case .anxiety:
            return [.desensitization, .relaxationProtocol, .thundershirt, .medicationSupport, .managementOnly]
        case .destructive:
            return [.mentalEnrichment, .moreExercise, .managementOnly]
        case .barking:
            return [.positiveInterrupter, .desensitization, .managementOnly, .trainerSessions]
        case .guarding:
            return [.tradeUpGame, .counterConditioning, .trainerSessions, .managementOnly]
        case .jumping:
            return [.positiveInterrupter, .leaveItCommand, .trainerSessions]
        case .pulling:
            return [.shorterWalks, .quieterRoutes, .moreExercise, .trainerSessions]
        case .recall:
            return [.moreExercise, .mentalEnrichment, .trainerSessions]
        case .mouthing:
            return [.positiveInterrupter, .leaveItCommand, .mentalEnrichment]
        case .fearful:
            return [.counterConditioning, .desensitization, .relaxationProtocol, .thundershirt, .avoidTriggers]
        }
    }

    /// Create an intervention from this template
    public func toIntervention(for category: BehaviorCategory, notes: String? = nil) -> BehaviorIntervention {
        BehaviorIntervention(
            name: self.name,
            category: category,
            notes: notes
        )
    }
}

// MARK: - Behavior Context

/// Context where the behavior occurred
public enum BehaviorContext: String, Codable, CaseIterable, Identifiable, Sendable {
    case home
    case walk
    case park
    case vetClinic
    case car
    case publicPlace
    case other

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .home: return Strings.Behavior.contextHome
        case .walk: return Strings.Behavior.contextWalk
        case .park: return Strings.Behavior.contextPark
        case .vetClinic: return Strings.Behavior.contextVet
        case .car: return Strings.Behavior.contextCar
        case .publicPlace: return Strings.Behavior.contextPublic
        case .other: return Strings.Behavior.contextOther
        }
    }

    public var icon: String {
        switch self {
        case .home: return "house.fill"
        case .walk: return "figure.walk"
        case .park: return "leaf.fill"
        case .vetClinic: return "cross.case.fill"
        case .car: return "car.fill"
        case .publicPlace: return "building.2.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
