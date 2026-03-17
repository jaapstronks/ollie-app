//
//  PuppyEvent.swift
//  OtisShared
//
//  Core event model for tracking puppy activities.
//  Supporting types are in separate files:
//  - EventType.swift - Event type enum
//  - EventEnums.swift - CoverageGapType, EventLocation, NapLocation
//  - EventAttachments.swift - MediaInfo, EventLike, LocationInfo
//

import Foundation

// MARK: - Puppy Event

/// A single puppy event, stored as one line in JSONL files
public struct PuppyEvent: Codable, Identifiable, Equatable, Sendable {
    // MARK: - Core Fields (always present)

    public var id: UUID
    public var time: Date
    public var type: EventType
    public var createdAt: Date
    public var modifiedAt: Date

    // MARK: - Potty Fields

    public var location: EventLocation?

    // MARK: - Common Optional Fields

    public var note: String?
    public var durationMin: Int?

    // MARK: - Type-Specific Fields

    public var who: String?
    public var exercise: String?
    public var result: String?

    // MARK: - Training Session Outcome Fields

    /// Number of successful repetitions in this training session
    public var successReps: Int?

    /// Number of failed repetitions in this training session
    public var failedReps: Int?

    /// Training context (location/environment) where training occurred
    /// Maps to StandardTrainingContext.rawValue (e.g., "home", "park")
    public var trainingContext: String?

    /// Which skill phase was being practiced
    /// Maps to SkillLearningPhase.rawValue
    public var skillPhase: String?
    public var weightKg: Double?
    public var parentWalkId: UUID?
    public var sleepSessionId: UUID?
    public var napLocation: NapLocation?

    // MARK: - Coverage Gap Fields

    public var gapType: CoverageGapType?
    public var endTime: Date?          // nil = ongoing gap
    public var gapLocation: String?    // optional location (e.g., "Grandma's house")

    // MARK: - Attribution Fields

    /// CloudKit user record ID of who logged this event
    /// Changed from UUID (HouseholdMember.id) to String (CloudKit record ID)
    /// For migration: nil for legacy events, existing UUID values are ignored
    public var loggedBy: String?

    // MARK: - Social Fields

    /// Likes on this event from other users
    public var likes: [EventLike]?

    // MARK: - Contact Linking Fields

    /// Linked contact ID (e.g., trainer for training events)
    public var linkedContactID: UUID?

    // MARK: - Behavior Incident Fields

    /// Category of behavior incident (reactivity, anxiety, etc.)
    /// Maps to BehaviorCategory.rawValue
    public var behaviorCategory: String?

    /// What triggered the behavior
    public var behaviorTrigger: String?

    /// Intensity of the incident (1-5)
    /// Maps to BehaviorIntensity.rawValue
    public var behaviorIntensity: Int?

    /// What happened after the incident
    /// Maps to BehaviorOutcome.rawValue
    public var behaviorOutcome: String?

    /// Context where the behavior occurred
    /// Maps to BehaviorContext.rawValue
    public var behaviorContext: String?

    // MARK: - Media Fields

    public var photo: String?
    public var video: String?
    public var thumbnailPath: String?
    public var cloudPhotoSynced: Bool?
    /// CloudKit zone owner name who uploaded the photo (needed for cross-user downloads)
    public var cloudPhotoOwner: String?

    // MARK: - Location Fields

    public var latitude: Double?
    public var longitude: Double?
    public var spotId: UUID?
    public var spotName: String?

    // MARK: - Computed Properties

    public var media: MediaInfo {
        get {
            MediaInfo(photoPath: photo, videoPath: video, thumbnailPath: thumbnailPath)
        }
        set {
            photo = newValue.photoPath
            video = newValue.videoPath
            thumbnailPath = newValue.thumbnailPath
        }
    }

    /// Whether this event has a local photo that needs to be uploaded to CloudKit
    public var needsPhotoUpload: Bool {
        photo != nil && !(cloudPhotoSynced ?? false)
    }

    /// Whether this event has a cloud photo that needs to be downloaded locally
    public var needsPhotoDownload: Bool {
        (cloudPhotoSynced ?? false) && photo != nil
    }

    public var locationInfo: LocationInfo {
        get {
            LocationInfo(latitude: latitude, longitude: longitude, spotId: spotId, spotName: spotName)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
            spotId = newValue.spotId
            spotName = newValue.spotName
        }
    }

    // MARK: - Generic Initializer

    public init(
        id: UUID = UUID(),
        time: Date = Date(),
        type: EventType,
        createdAt: Date? = nil,
        modifiedAt: Date? = nil,
        location: EventLocation? = nil,
        note: String? = nil,
        who: String? = nil,
        exercise: String? = nil,
        result: String? = nil,
        durationMin: Int? = nil,
        photo: String? = nil,
        video: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        thumbnailPath: String? = nil,
        cloudPhotoSynced: Bool? = nil,
        cloudPhotoOwner: String? = nil,
        weightKg: Double? = nil,
        spotId: UUID? = nil,
        spotName: String? = nil,
        parentWalkId: UUID? = nil,
        sleepSessionId: UUID? = nil,
        napLocation: NapLocation? = nil,
        gapType: CoverageGapType? = nil,
        endTime: Date? = nil,
        gapLocation: String? = nil,
        loggedBy: String? = nil,
        successReps: Int? = nil,
        failedReps: Int? = nil,
        trainingContext: String? = nil,
        skillPhase: String? = nil,
        behaviorCategory: String? = nil,
        behaviorTrigger: String? = nil,
        behaviorIntensity: Int? = nil,
        behaviorOutcome: String? = nil,
        behaviorContext: String? = nil,
        likes: [EventLike]? = nil,
        linkedContactID: UUID? = nil
    ) {
        self.id = id
        self.time = time
        self.type = type

        let now = Date()
        self.createdAt = createdAt ?? now
        self.modifiedAt = modifiedAt ?? now

        self.location = location
        self.note = note
        self.who = who
        self.exercise = exercise
        self.result = result
        self.durationMin = durationMin
        self.photo = photo
        self.video = video
        self.latitude = latitude
        self.longitude = longitude
        self.thumbnailPath = thumbnailPath
        self.cloudPhotoSynced = cloudPhotoSynced
        self.cloudPhotoOwner = cloudPhotoOwner
        self.weightKg = weightKg
        self.spotId = spotId
        self.spotName = spotName
        self.parentWalkId = parentWalkId
        self.napLocation = napLocation
        self.gapType = gapType
        self.endTime = endTime
        self.gapLocation = gapLocation
        self.loggedBy = loggedBy
        self.successReps = successReps
        self.failedReps = failedReps
        self.trainingContext = trainingContext
        self.skillPhase = skillPhase
        self.behaviorCategory = behaviorCategory
        self.behaviorTrigger = behaviorTrigger
        self.behaviorIntensity = behaviorIntensity
        self.behaviorOutcome = behaviorOutcome
        self.behaviorContext = behaviorContext
        self.likes = likes
        self.linkedContactID = linkedContactID

        if type == .slapen {
            self.sleepSessionId = sleepSessionId ?? UUID()
        } else {
            self.sleepSessionId = sleepSessionId
        }

        #if DEBUG
        if type.requiresLocation && location == nil {
            assertionFailure("Potty event (\(type)) created without location. Use PuppyEvent.potty() factory method.")
        }
        #endif
    }

    // MARK: - Coding Keys

    public enum CodingKeys: String, CodingKey {
        case id
        case time
        case type
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case location
        case note
        case who
        case exercise
        case result
        case durationMin = "duration_min"
        case photo
        case video
        case latitude
        case longitude
        case thumbnailPath = "thumbnail_path"
        case cloudPhotoSynced = "cloud_photo_synced"
        case cloudPhotoOwner = "cloud_photo_owner"
        case weightKg = "weight_kg"
        case spotId = "spot_id"
        case spotName = "spot_name"
        case parentWalkId = "parent_walk_id"
        case sleepSessionId = "sleep_session_id"
        case napLocation = "nap_location"
        case gapType = "gap_type"
        case endTime = "end_time"
        case gapLocation = "gap_location"
        case loggedBy = "logged_by"
        case successReps = "success_reps"
        case failedReps = "failed_reps"
        case trainingContext = "training_context"
        case skillPhase = "skill_phase"
        case behaviorCategory = "behavior_category"
        case behaviorTrigger = "behavior_trigger"
        case behaviorIntensity = "behavior_intensity"
        case behaviorOutcome = "behavior_outcome"
        case behaviorContext = "behavior_context"
        case likes
        case linkedContactID = "linked_contact_id"
    }

    // MARK: - Custom Decoding

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        time = try container.decode(Date.self, forKey: .time)
        type = try container.decode(EventType.self, forKey: .type)

        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? time
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? time

        location = try container.decodeIfPresent(EventLocation.self, forKey: .location)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        who = try container.decodeIfPresent(String.self, forKey: .who)
        exercise = try container.decodeIfPresent(String.self, forKey: .exercise)
        result = try container.decodeIfPresent(String.self, forKey: .result)
        durationMin = try container.decodeIfPresent(Int.self, forKey: .durationMin)
        photo = try container.decodeIfPresent(String.self, forKey: .photo)
        video = try container.decodeIfPresent(String.self, forKey: .video)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        thumbnailPath = try container.decodeIfPresent(String.self, forKey: .thumbnailPath)
        cloudPhotoSynced = try container.decodeIfPresent(Bool.self, forKey: .cloudPhotoSynced)
        cloudPhotoOwner = try container.decodeIfPresent(String.self, forKey: .cloudPhotoOwner)
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        spotId = try container.decodeIfPresent(UUID.self, forKey: .spotId)
        spotName = try container.decodeIfPresent(String.self, forKey: .spotName)
        parentWalkId = try container.decodeIfPresent(UUID.self, forKey: .parentWalkId)
        napLocation = try container.decodeIfPresent(NapLocation.self, forKey: .napLocation)

        let decodedSleepSessionId = try container.decodeIfPresent(UUID.self, forKey: .sleepSessionId)
        if type == .slapen && decodedSleepSessionId == nil {
            sleepSessionId = UUID()
        } else {
            sleepSessionId = decodedSleepSessionId
        }

        // Coverage gap fields
        gapType = try container.decodeIfPresent(CoverageGapType.self, forKey: .gapType)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        gapLocation = try container.decodeIfPresent(String.self, forKey: .gapLocation)

        // Attribution fields - try String first, fall back to UUID (legacy) and convert
        if let stringValue = try container.decodeIfPresent(String.self, forKey: .loggedBy) {
            loggedBy = stringValue
        } else if let uuidValue = try? container.decodeIfPresent(UUID.self, forKey: .loggedBy) {
            // Legacy UUID value - convert to string (will show as "Unknown" until migrated)
            loggedBy = uuidValue.uuidString
        } else {
            loggedBy = nil
        }

        // Training session outcome fields
        successReps = try container.decodeIfPresent(Int.self, forKey: .successReps)
        failedReps = try container.decodeIfPresent(Int.self, forKey: .failedReps)
        trainingContext = try container.decodeIfPresent(String.self, forKey: .trainingContext)
        skillPhase = try container.decodeIfPresent(String.self, forKey: .skillPhase)

        // Behavior incident fields
        behaviorCategory = try container.decodeIfPresent(String.self, forKey: .behaviorCategory)
        behaviorTrigger = try container.decodeIfPresent(String.self, forKey: .behaviorTrigger)
        behaviorIntensity = try container.decodeIfPresent(Int.self, forKey: .behaviorIntensity)
        behaviorOutcome = try container.decodeIfPresent(String.self, forKey: .behaviorOutcome)
        behaviorContext = try container.decodeIfPresent(String.self, forKey: .behaviorContext)

        // Social fields
        likes = try container.decodeIfPresent([EventLike].self, forKey: .likes)

        // Contact linking
        linkedContactID = try container.decodeIfPresent(UUID.self, forKey: .linkedContactID)
    }
}

// MARK: - Mutation Helpers

extension PuppyEvent {

    public func withUpdatedTimestamp() -> PuppyEvent {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }

    public func withMedia(_ media: MediaInfo) -> PuppyEvent {
        var copy = self
        copy.media = media
        copy.modifiedAt = Date()
        return copy
    }

    public func withLocationInfo(_ locationInfo: LocationInfo) -> PuppyEvent {
        var copy = self
        copy.locationInfo = locationInfo
        copy.modifiedAt = Date()
        return copy
    }

    /// End a coverage gap by setting the end time
    public func withEndTime(_ endTime: Date, note: String? = nil) -> PuppyEvent {
        var copy = self
        copy.endTime = endTime
        if let note = note {
            copy.note = note
        }
        copy.modifiedAt = Date()
        return copy
    }

    /// Check if this coverage gap is ongoing (no end time)
    public var isOngoingGap: Bool {
        type == .coverageGap && endTime == nil
    }

    /// Duration of coverage gap in minutes (nil if ongoing)
    public var gapDurationMinutes: Int? {
        guard type == .coverageGap, let endTime = endTime else { return nil }
        return Int(endTime.timeIntervalSince(time) / 60)
    }

    // MARK: - Likes Helpers

    /// Number of likes on this event
    public var likeCount: Int {
        likes?.count ?? 0
    }

    /// Whether this event has any likes
    public var hasLikes: Bool {
        likeCount > 0
    }

    /// Check if a specific user has liked this event
    public func isLikedBy(_ userRecordID: String) -> Bool {
        likes?.contains { $0.likedBy == userRecordID } ?? false
    }

    /// Add a like from a user
    public func withLike(from userRecordID: String) -> PuppyEvent {
        var copy = self
        // Don't add duplicate likes
        guard !isLikedBy(userRecordID) else { return copy }

        var newLikes = copy.likes ?? []
        newLikes.append(EventLike(likedBy: userRecordID))
        copy.likes = newLikes
        copy.modifiedAt = Date()
        return copy
    }

    /// Remove a like from a user
    public func withoutLike(from userRecordID: String) -> PuppyEvent {
        var copy = self
        copy.likes = copy.likes?.filter { $0.likedBy != userRecordID }
        if copy.likes?.isEmpty == true {
            copy.likes = nil
        }
        copy.modifiedAt = Date()
        return copy
    }

    /// Toggle like state for a user
    public func withLikeToggled(by userRecordID: String) -> PuppyEvent {
        if isLikedBy(userRecordID) {
            return withoutLike(from: userRecordID)
        } else {
            return withLike(from: userRecordID)
        }
    }

    // MARK: - Training Session Helpers

    /// Total reps in this training session
    public var totalTrainingReps: Int {
        (successReps ?? 0) + (failedReps ?? 0)
    }

    /// Success rate for this training session (0.0 - 1.0)
    public var trainingSuccessRate: Double? {
        guard type == .training, totalTrainingReps > 0 else { return nil }
        return Double(successReps ?? 0) / Double(totalTrainingReps)
    }

    /// Whether this training session met the 80% threshold
    public var trainingMetThreshold: Bool {
        guard let rate = trainingSuccessRate else { return false }
        return rate >= 0.8
    }

    /// Create a training event with session outcome tracking
    public static func training(
        id: UUID = UUID(),
        time: Date = Date(),
        skillId: String,
        successReps: Int,
        failedReps: Int,
        context: String? = nil,
        phase: String? = nil,
        durationMin: Int? = nil,
        note: String? = nil,
        loggedBy: String? = nil
    ) -> PuppyEvent {
        PuppyEvent(
            id: id,
            time: time,
            type: .training,
            exercise: skillId,
            durationMin: durationMin,
            successReps: successReps,
            failedReps: failedReps,
            trainingContext: context,
            skillPhase: phase
        )
    }

    /// Create a behavior incident event
    public static func behaviorIncident(
        id: UUID = UUID(),
        time: Date = Date(),
        category: BehaviorCategory,
        trigger: String? = nil,
        intensity: BehaviorIntensity? = nil,
        outcome: BehaviorOutcome? = nil,
        context: BehaviorContext? = nil,
        durationMin: Int? = nil,
        note: String? = nil,
        loggedBy: String? = nil
    ) -> PuppyEvent {
        PuppyEvent(
            id: id,
            time: time,
            type: .gedrag,
            note: note,
            durationMin: durationMin,
            loggedBy: loggedBy,
            behaviorCategory: category.rawValue,
            behaviorTrigger: trigger,
            behaviorIntensity: intensity?.rawValue,
            behaviorOutcome: outcome?.rawValue,
            behaviorContext: context?.rawValue
        )
    }
}

// MARK: - Behavior Incident Helpers

extension PuppyEvent {
    /// Whether this is a behavior incident event
    public var isBehaviorIncident: Bool {
        type == .gedrag && behaviorCategory != nil
    }

    /// Get the behavior category as the enum type
    public var behaviorCategoryEnum: BehaviorCategory? {
        guard let categoryStr = behaviorCategory else { return nil }
        return BehaviorCategory(rawValue: categoryStr)
    }

    /// Get the behavior intensity as the enum type
    public var behaviorIntensityEnum: BehaviorIntensity? {
        guard let intensity = behaviorIntensity else { return nil }
        return BehaviorIntensity(rawValue: intensity)
    }

    /// Get the behavior outcome as the enum type
    public var behaviorOutcomeEnum: BehaviorOutcome? {
        guard let outcome = behaviorOutcome else { return nil }
        return BehaviorOutcome(rawValue: outcome)
    }

    /// Get the behavior context as the enum type
    public var behaviorContextEnum: BehaviorContext? {
        guard let context = behaviorContext else { return nil }
        return BehaviorContext(rawValue: context)
    }
}
