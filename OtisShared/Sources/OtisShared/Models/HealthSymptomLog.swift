//
//  HealthSymptomLog.swift
//  OtisShared
//
//  Model for logging health symptoms with detailed tracking
//  Part of Brief 04: Health Logging
//

import Foundation

// MARK: - Body Location

/// Body locations for symptom tracking
public enum BodyLocation: String, Codable, CaseIterable, Sendable {
    // Legs
    case frontLeftLeg
    case frontRightLeg
    case rearLeftLeg
    case rearRightLeg

    // Body
    case head
    case neck
    case chest
    case back
    case abdomen
    case tail

    // Ears/Eyes
    case leftEar
    case rightEar
    case leftEye
    case rightEye

    // Paws
    case frontLeftPaw
    case frontRightPaw
    case rearLeftPaw
    case rearRightPaw

    // General
    case wholeBody
    case unspecified

    public var label: String {
        switch self {
        case .frontLeftLeg: return Strings.HealthLogging.bodyFrontLeftLeg
        case .frontRightLeg: return Strings.HealthLogging.bodyFrontRightLeg
        case .rearLeftLeg: return Strings.HealthLogging.bodyRearLeftLeg
        case .rearRightLeg: return Strings.HealthLogging.bodyRearRightLeg
        case .head: return Strings.HealthLogging.bodyHead
        case .neck: return Strings.HealthLogging.bodyNeck
        case .chest: return Strings.HealthLogging.bodyChest
        case .back: return Strings.HealthLogging.bodyBack
        case .abdomen: return Strings.HealthLogging.bodyAbdomen
        case .tail: return Strings.HealthLogging.bodyTail
        case .leftEar: return Strings.HealthLogging.bodyLeftEar
        case .rightEar: return Strings.HealthLogging.bodyRightEar
        case .leftEye: return Strings.HealthLogging.bodyLeftEye
        case .rightEye: return Strings.HealthLogging.bodyRightEye
        case .frontLeftPaw: return Strings.HealthLogging.bodyFrontLeftPaw
        case .frontRightPaw: return Strings.HealthLogging.bodyFrontRightPaw
        case .rearLeftPaw: return Strings.HealthLogging.bodyRearLeftPaw
        case .rearRightPaw: return Strings.HealthLogging.bodyRearRightPaw
        case .wholeBody: return Strings.HealthLogging.bodyWholeBody
        case .unspecified: return Strings.HealthLogging.bodyUnspecified
        }
    }

    /// Group related body locations for UI
    public var group: BodyLocationGroup {
        switch self {
        case .frontLeftLeg, .frontRightLeg, .rearLeftLeg, .rearRightLeg:
            return .legs
        case .frontLeftPaw, .frontRightPaw, .rearLeftPaw, .rearRightPaw:
            return .paws
        case .leftEar, .rightEar:
            return .ears
        case .leftEye, .rightEye:
            return .eyes
        case .head, .neck, .chest, .back, .abdomen, .tail:
            return .body
        case .wholeBody, .unspecified:
            return .general
        }
    }
}

/// Groups for organizing body locations in UI
public enum BodyLocationGroup: String, Codable, CaseIterable, Sendable {
    case legs
    case paws
    case ears
    case eyes
    case body
    case general

    public var label: String {
        switch self {
        case .legs: return Strings.HealthLogging.groupLegs
        case .paws: return Strings.HealthLogging.groupPaws
        case .ears: return Strings.HealthLogging.groupEars
        case .eyes: return Strings.HealthLogging.groupEyes
        case .body: return Strings.HealthLogging.groupBody
        case .general: return Strings.HealthLogging.groupGeneral
        }
    }

    public var locations: [BodyLocation] {
        BodyLocation.allCases.filter { $0.group == self }
    }
}

// MARK: - Symptom Duration

/// Duration of the symptom
public enum SymptomDuration: String, Codable, CaseIterable, Sendable {
    case brief          // < 15 minutes
    case shortTerm      // 15 min - 2 hours
    case hours          // 2-24 hours
    case days           // Multiple days
    case ongoing        // Currently happening
    case resolved       // Was happening, now stopped

    public var label: String {
        switch self {
        case .brief: return Strings.HealthLogging.durationBrief
        case .shortTerm: return Strings.HealthLogging.durationShortTerm
        case .hours: return Strings.HealthLogging.durationHours
        case .days: return Strings.HealthLogging.durationDays
        case .ongoing: return Strings.HealthLogging.durationOngoing
        case .resolved: return Strings.HealthLogging.durationResolved
        }
    }
}

// MARK: - Symptom Status

/// Current status of the symptom
public enum SymptomStatus: String, Codable, Sendable {
    case active     // Currently experiencing
    case resolved   // Symptom has stopped
    case recurring  // Comes and goes

    public var label: String {
        switch self {
        case .active: return Strings.HealthLogging.statusActive
        case .resolved: return Strings.HealthLogging.statusResolved
        case .recurring: return Strings.HealthLogging.statusRecurring
        }
    }
}

// MARK: - Symptom Start Time

/// When the symptom started
public enum SymptomStartTime: String, Codable, CaseIterable, Sendable {
    case justNow
    case earlierToday
    case yesterday
    case ongoing

    public var label: String {
        switch self {
        case .justNow: return Strings.HealthLogging.startJustNow
        case .earlierToday: return Strings.HealthLogging.startEarlierToday
        case .yesterday: return Strings.HealthLogging.startYesterday
        case .ongoing: return Strings.HealthLogging.startBeenOngoing
        }
    }
}

// MARK: - Common Triggers

/// Common triggers for symptoms
public enum SymptomTrigger: String, Codable, CaseIterable, Sendable {
    case afterWalk
    case afterEating
    case afterWaking
    case coldWeather
    case hotWeather
    case stress
    case exercise
    case newFood
    case medication

    public var label: String {
        switch self {
        case .afterWalk: return Strings.HealthLogging.triggerAfterWalk
        case .afterEating: return Strings.HealthLogging.triggerAfterEating
        case .afterWaking: return Strings.HealthLogging.triggerAfterWaking
        case .coldWeather: return Strings.HealthLogging.triggerColdWeather
        case .hotWeather: return Strings.HealthLogging.triggerHotWeather
        case .stress: return Strings.HealthLogging.triggerStress
        case .exercise: return Strings.HealthLogging.triggerExercise
        case .newFood: return Strings.HealthLogging.triggerNewFood
        case .medication: return Strings.HealthLogging.triggerMedication
        }
    }
}

// MARK: - Symptom Trend

/// Trend direction for symptom frequency
public enum SymptomTrend: String, Codable, Sendable {
    case improving
    case stable
    case worsening

    public var label: String {
        switch self {
        case .improving: return Strings.HealthLogging.trendImproving
        case .stable: return Strings.HealthLogging.trendStable
        case .worsening: return Strings.HealthLogging.trendWorsening
        }
    }

    public var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .worsening: return "arrow.up.right"
        }
    }

    public var colorName: String {
        switch self {
        case .improving: return "otisSuccess"
        case .stable: return "otisInfo"
        case .worsening: return "otisWarning"
        }
    }
}

// MARK: - Health Symptom Log

/// A logged symptom occurrence
public struct HealthSymptomLog: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var symptomType: SymptomType
    public var severity: Int  // 1-5
    public var bodyLocation: BodyLocation?
    public var startTime: Date
    public var startTimeDescription: SymptomStartTime
    public var duration: SymptomDuration
    public var status: SymptomStatus
    public var triggers: [SymptomTrigger]
    public var customTrigger: String?
    public var relatedConditionId: UUID?  // Link to diagnosed condition
    public var note: String?
    public var photoPath: String?
    public var loggedBy: UUID?  // Household member who logged
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        symptomType: SymptomType,
        severity: Int = 3,
        bodyLocation: BodyLocation? = nil,
        startTime: Date = Date(),
        startTimeDescription: SymptomStartTime = .justNow,
        duration: SymptomDuration = .ongoing,
        status: SymptomStatus = .active,
        triggers: [SymptomTrigger] = [],
        customTrigger: String? = nil,
        relatedConditionId: UUID? = nil,
        note: String? = nil,
        photoPath: String? = nil,
        loggedBy: UUID? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.symptomType = symptomType
        self.severity = max(1, min(5, severity))
        self.bodyLocation = bodyLocation
        self.startTime = startTime
        self.startTimeDescription = startTimeDescription
        self.duration = duration
        self.status = status
        self.triggers = triggers
        self.customTrigger = customTrigger
        self.relatedConditionId = relatedConditionId
        self.note = note
        self.photoPath = photoPath
        self.loggedBy = loggedBy
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Days since this symptom was logged
    public var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    /// Whether this is a recent log (within 24 hours)
    public var isRecent: Bool {
        daysAgo == 0
    }

    /// Severity description
    public var severityDescription: String {
        switch severity {
        case 1: return Strings.HealthLogging.severityMild
        case 2: return Strings.HealthLogging.severityMildModerate
        case 3: return Strings.HealthLogging.severityModerate
        case 4: return Strings.HealthLogging.severityModSevere
        case 5: return Strings.HealthLogging.severitySevere
        default: return Strings.HealthLogging.severityModerate
        }
    }

    /// Returns a copy with updated modifiedAt timestamp
    public func withUpdatedTimestamp() -> HealthSymptomLog {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }

    /// All triggers as labels (including custom)
    public var allTriggerLabels: [String] {
        var labels = triggers.map(\.label)
        if let custom = customTrigger, !custom.isEmpty {
            labels.append(custom)
        }
        return labels
    }
}
