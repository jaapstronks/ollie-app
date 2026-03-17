//
//  ConcreteHandlers.swift
//  OtisShared
//
//  Concrete sync handlers for all remaining entity types.
//  These extend GenericSyncHandler with entity-specific field mappings.
//

import CloudKit
import CoreData
import Foundation

// MARK: - Walk Spot

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class WalkSpotSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.walkSpot }

    public init() {
        super.init(entityName: "CDWalkSpot", fieldMappings: [
            "name": .init(.string),
            "category": .init(.string),
            "latitude": .init(.double),
            "longitude": .init(.double),
            "isFavorite": .init(.bool),
            "visitCount": .init(.int),
            "notes": .init(.string),
            "photoFilename": .init(.string),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
        ])
    }
}

// MARK: - Mastered Skill

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class MasteredSkillSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.masteredSkill }

    public init() {
        super.init(entityName: "CDMasteredSkill", fieldMappings: [
            "skillId": .init(.string),
            "masteredAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Medication Completion

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class MedicationCompletionSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.medicationCompletion }

    public init() {
        super.init(entityName: "CDMedicationCompletion", fieldMappings: [
            "medicationId": .init(.uuid),
            "timeId": .init(.uuid),
            "date": .init(.date),
            "completedAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Exposure

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class ExposureSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.exposure }

    public init() {
        super.init(entityName: "CDExposure", fieldMappings: [
            "itemId": .init(.string),
            "date": .init(.date),
            "distance": .init(.string),
            "reaction": .init(.string),
            "note": .init(.string),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Milestone

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class MilestoneSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.milestone }

    public init() {
        super.init(entityName: "CDMilestone", fieldMappings: [
            "labelKey": .init(.string),
            "detailKey": .init(.string),
            "category": .init(.string),
            "icon": .init(.string),
            "isCompleted": .init(.bool),
            "isCustom": .init(.bool),
            "isRecurring": .init(.bool),
            "isActionable": .init(.bool),
            "isUserDismissable": .init(.bool),
            "completedDate": .init(.date),
            "completionNotes": .init(.string),
            "completionPhotoID": .init(.uuid),
            "fixedDate": .init(.date),
            "targetAgeDays": .init(.int),
            "targetAgeWeeks": .init(.int),
            "targetAgeMonths": .init(.int),
            "recurrenceMonths": .init(.int),
            "reminderDaysBefore": .init(.int),
            "sortOrder": .init(.int),
            "vetClinicName": .init(.string),
            "calendarEventID": .init(.string),
            "linkedContactID": .init(.uuid),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Document

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class DocumentSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.document }

    public init() {
        super.init(entityName: "CDDocument", fieldMappings: [
            "title": .init(.string),
            "type": .init(.string),
            "attachmentType": .init(.string),
            "note": .init(.string),
            "documentDate": .init(.date),
            "expiryDate": .init(.date),
            "insuranceAgency": .init(.string),
            "imageData": .init(.data),
            "thumbnailData": .init(.data),
            "pdfData": .init(.data),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Dog Contact

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class DogContactSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.dogContact }

    public init() {
        super.init(entityName: "CDDogContact", fieldMappings: [
            "name": .init(.string),
            "contactType": .init(.string),
            "phone": .init(.string),
            "email": .init(.string),
            "address": .init(.string),
            "notes": .init(.string),
            "latitude": .init(.double),
            "longitude": .init(.double),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
        ])
    }
}

// MARK: - Dog Appointment

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class DogAppointmentSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.dogAppointment }

    public init() {
        super.init(entityName: "CDDogAppointment", fieldMappings: [
            "title": .init(.string),
            "appointmentType": .init(.string),
            "startDate": .init(.date),
            "endDate": .init(.date),
            "isAllDay": .init(.bool),
            "isCompleted": .init(.bool),
            "location": .init(.string),
            "notes": .init(.string),
            "completionNotes": .init(.string),
            "calendarEventID": .init(.string),
            "reminderMinutesBefore": .init(.int),
            "recurrenceFrequency": .init(.string),
            "recurrenceInterval": .init(.int),
            "recurrenceCount": .init(.int),
            "recurrenceDaysOfWeek": .init(.string),
            "recurrenceEndDate": .init(.date),
            "linkedContactID": .init(.uuid),
            "linkedMilestoneID": .init(.uuid),
            "linkedGroomingType": .init(.string),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Weight Measurement

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class WeightMeasurementSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.weightMeasurement }

    public init() {
        super.init(entityName: "CDWeightMeasurement", fieldMappings: [
            "weightKg": .init(.double),
            "date": .init(.date),
            "note": .init(.string),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Comfortable Item

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class ComfortableItemSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.comfortableItem }

    public init() {
        super.init(entityName: "CDComfortableItem", fieldMappings: [
            "itemId": .init(.string),
            "comfortableAt": .init(.date),
            "method": .init(.string),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Early Milestone

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class EarlyMilestoneSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.earlyMilestone }

    public init() {
        super.init(entityName: "CDEarlyMilestone", fieldMappings: [
            "milestoneId": .init(.string),
            "achievedAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Skill Progress

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class SkillProgressSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.skillProgress }

    public init() {
        super.init(entityName: "CDSkillProgress", fieldMappings: [
            "skillId": .init(.string),
            "phase": .init(.string),
            "durationLevel": .init(.int),
            "distanceLevel": .init(.int),
            "distractionLevel": .init(.int),
            "confidenceScore": .init(.double),
            "totalSuccessReps": .init(.int),
            "totalFailedReps": .init(.int),
            "maintenanceTier": .init(.int),
            "isInMaintenanceMode": .init(.bool),
            "nextReviewDate": .init(.date),
            "lastPracticedAt": .init(.date),
            "recentSessionsData": .init(.bytes),
            "practicedContextsData": .init(.bytes),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Regression Log

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class RegressionLogSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.regressionLog }

    public init() {
        super.init(entityName: "CDRegressionLog", fieldMappings: [
            "skillId": .init(.string),
            "occurredAt": .init(.date),
            "previousTier": .init(.int),
            "successRateAtFailure": .init(.double),
            "recoveredAt": .init(.date),
            "sessionsToRecover": .init(.int),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
        ])
    }
}

// MARK: - Routine Item

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class RoutineItemSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.routineItem }

    public init() {
        super.init(entityName: "CDRoutineItem", fieldMappings: [
            "label": .init(.string),
            "time": .init(.date),
            "category": .init(.string),
            "isEnabled": .init(.bool),
            "linkedEventType": .init(.string),
            "sortOrder": .init(.int),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Weight Goal

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class WeightGoalSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.weightGoal }

    public init() {
        super.init(entityName: "CDWeightGoal", fieldMappings: [
            "targetWeightKg": .init(.double),
            "startWeightKg": .init(.double),
            "startDate": .init(.date),
            "targetDate": .init(.date),
            "isActive": .init(.bool),
            "note": .init(.string),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Body Condition Score

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class BodyConditionScoreSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.bodyConditionScore }

    public init() {
        super.init(entityName: "CDBodyConditionScore", fieldMappings: [
            "score": .init(.int),
            "note": .init(.string),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Grooming Activity

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class GroomingActivitySyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.groomingActivity }

    public init() {
        super.init(entityName: "CDGroomingActivity", fieldMappings: [
            "type": .init(.string),
            "intervalDays": .init(.int),
            "lastCompleted": .init(.date),
            "isEnabled": .init(.bool),
            "note": .init(.string),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Enrichment Activity

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class EnrichmentActivitySyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.enrichmentActivity }

    public init() {
        super.init(entityName: "CDEnrichmentActivity", fieldMappings: [
            "type": .init(.string),
            "completedAt": .init(.date),
            "durationMinutes": .init(.int),
            "note": .init(.string),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - User Identity

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class UserIdentitySyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.userIdentity }

    public init() {
        super.init(entityName: "CDUserIdentity", fieldMappings: [
            "name": .init(.string),
            "colorHex": .init(.string),
            "cloudKitUserRecordID": .init(.string),
            "responsibilityLevel": .init(.string),
            "avatarData": .init(.data),  // Large file - use CKAsset
            "enabledNudgesData": .init(.bytes),  // Small config - use raw bytes
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - User Sentiment Check-In

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class UserSentimentCheckInSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.userSentimentCheckIn }

    public init() {
        super.init(entityName: "CDUserSentimentCheckIn", fieldMappings: [
            "category": .init(.string),
            "score": .init(.int),
            "contextSummary": .init(.string),
            "date": .init(.date),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "userIdentity": .init(.reference(entityName: "CDUserIdentity"), cloudKey: "userIdentityRef"),
        ])
    }
}

// MARK: - AI Cache

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class AICacheSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.aiCache }

    public init() {
        super.init(entityName: "CDAICache", fieldMappings: [
            "surface": .init(.string),
            "timeWindow": .init(.string),
            "locale": .init(.string),
            "providerUsed": .init(.string),
            "modelUsed": .init(.string),
            "callCount": .init(.int),
            "cachedAt": .init(.date),
            "expiresAt": .init(.date),
            "responseData": .init(.bytes),  // AI response JSON - use raw bytes
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}

// MARK: - Explored Tile

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public final class ExploredTileSyncHandler: GenericSyncHandler<NSManagedObject>, @unchecked Sendable {
    public override class var recordType: String { RecordType.exploredTile }

    public init() {
        super.init(entityName: "CDExploredTile", fieldMappings: [
            "tileKey": .init(.string),
            "walkCount": .init(.int),
            "firstExploredAt": .init(.date),
            "lastExploredAt": .init(.date),
            "createdAt": .init(.date),
            "modifiedAt": .init(.date),
            "profile": .init(.reference(entityName: "CDPuppyProfile")),
        ])
    }
}
