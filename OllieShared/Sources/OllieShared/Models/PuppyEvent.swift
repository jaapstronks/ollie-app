//
//  PuppyEvent.swift
//  OllieShared
//

import Foundation

// MARK: - Coverage Gap Type

/// Types of coverage gaps when the puppy is cared for by someone else
public enum CoverageGapType: String, Codable, CaseIterable, Sendable {
    case daycare
    case family
    case sitter
    case vacation
    case other

    public var label: String {
        switch self {
        case .daycare: return Strings.CoverageGap.typeDaycare
        case .family: return Strings.CoverageGap.typeFamily
        case .sitter: return Strings.CoverageGap.typeSitter
        case .vacation: return Strings.CoverageGap.typeVacation
        case .other: return Strings.CoverageGap.typeOther
        }
    }

    public var icon: String {
        switch self {
        case .daycare: return "building.2.fill"
        case .family: return "person.2.fill"
        case .sitter: return "person.fill.checkmark"
        case .vacation: return "airplane"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Event Type

/// Event types for tracking puppy activities
public enum EventType: String, Codable, CaseIterable, Identifiable, Sendable {
    case eten
    case drinken
    case plassen
    case poepen
    case slapen
    case ontwaken
    case uitlaten
    case tuin
    case training
    case bench
    case sociaal
    case milestone
    case gedrag
    case gewicht
    case moment
    case medicatie
    case coverageGap

    public var id: String { rawValue }

    /// SF Symbol name for this event type
    public var icon: String {
        switch self {
        case .eten: return "fork.knife"
        case .drinken: return "drop.fill"
        case .plassen: return "drop.fill"
        case .poepen: return "circle.inset.filled"
        case .slapen: return "moon.zzz.fill"
        case .ontwaken: return "sun.max.fill"
        case .uitlaten: return "figure.walk"
        case .tuin: return "leaf.fill"
        case .training: return "graduationcap.fill"
        case .bench: return "house.fill"
        case .sociaal: return "dog.fill"
        case .milestone: return "star.fill"
        case .gedrag: return "note.text"
        case .gewicht: return "scalemass.fill"
        case .moment: return "camera.fill"
        case .medicatie: return "pills.fill"
        case .coverageGap: return "person.badge.clock.fill"
        }
    }

    public var label: String {
        switch self {
        case .eten: return Strings.EventType.eat
        case .drinken: return Strings.EventType.drink
        case .plassen: return Strings.EventType.pee
        case .poepen: return Strings.EventType.poop
        case .slapen: return Strings.EventType.sleep
        case .ontwaken: return Strings.EventType.wakeUp
        case .uitlaten: return Strings.EventType.walk
        case .tuin: return Strings.EventType.garden
        case .training: return Strings.EventType.training
        case .bench: return Strings.EventType.crate
        case .sociaal: return Strings.EventType.social
        case .milestone: return Strings.EventType.milestone
        case .gedrag: return Strings.EventType.behavior
        case .gewicht: return Strings.EventType.weight
        case .moment: return Strings.EventType.moment
        case .medicatie: return Strings.EventType.medication
        case .coverageGap: return Strings.CoverageGap.eventLabel
        }
    }

    /// Whether this event type requires a location (inside/outside)
    public var requiresLocation: Bool {
        self == .plassen || self == .poepen
    }

    /// Whether this event type is a potty event
    public var isPottyEvent: Bool {
        self == .plassen || self == .poepen
    }

    /// Whether this event type is a sleep-related event
    public var isSleepEvent: Bool {
        self == .slapen || self == .ontwaken
    }

    /// Whether this event type is a coverage gap
    public var isCoverageGap: Bool {
        self == .coverageGap
    }
}

// MARK: - Event Location

/// Location for potty events (inside vs outside)
public enum EventLocation: String, Codable, Sendable {
    case buiten  // outside
    case binnen  // inside

    public var label: String {
        switch self {
        case .buiten: return Strings.EventLocation.outside
        case .binnen: return Strings.EventLocation.inside
        }
    }
}

// MARK: - Media Info

/// Encapsulates media attachments for an event
public struct MediaInfo: Codable, Equatable, Sendable {
    public var photoPath: String?
    public var videoPath: String?
    public var thumbnailPath: String?

    public init(photoPath: String? = nil, videoPath: String? = nil, thumbnailPath: String? = nil) {
        self.photoPath = photoPath
        self.videoPath = videoPath
        self.thumbnailPath = thumbnailPath
    }

    /// Whether this media info has any content
    public var hasMedia: Bool {
        photoPath != nil || videoPath != nil
    }

    /// Whether this has a photo (with or without thumbnail)
    public var hasPhoto: Bool {
        photoPath != nil
    }

    public static let empty = MediaInfo()
}

// MARK: - Location Info

/// Encapsulates GPS location data for walk events
public struct LocationInfo: Codable, Equatable, Sendable {
    public var latitude: Double?
    public var longitude: Double?
    public var spotId: UUID?
    public var spotName: String?

    public init(latitude: Double? = nil, longitude: Double? = nil, spotId: UUID? = nil, spotName: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.spotId = spotId
        self.spotName = spotName
    }

    /// Whether this has any location data
    public var hasLocation: Bool {
        hasCoordinates || spotId != nil
    }

    /// Whether this has GPS coordinates
    public var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    public static let empty = LocationInfo()
}

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
    public var weightKg: Double?
    public var parentWalkId: UUID?
    public var sleepSessionId: UUID?

    // MARK: - Coverage Gap Fields

    public var gapType: CoverageGapType?
    public var endTime: Date?          // nil = ongoing gap
    public var gapLocation: String?    // optional location (e.g., "Grandma's house")

    // MARK: - Media Fields

    public var photo: String?
    public var video: String?
    public var thumbnailPath: String?
    public var cloudPhotoSynced: Bool?

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
        weightKg: Double? = nil,
        spotId: UUID? = nil,
        spotName: String? = nil,
        parentWalkId: UUID? = nil,
        sleepSessionId: UUID? = nil,
        gapType: CoverageGapType? = nil,
        endTime: Date? = nil,
        gapLocation: String? = nil
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
        self.weightKg = weightKg
        self.spotId = spotId
        self.spotName = spotName
        self.parentWalkId = parentWalkId
        self.gapType = gapType
        self.endTime = endTime
        self.gapLocation = gapLocation

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
        case weightKg = "weight_kg"
        case spotId = "spot_id"
        case spotName = "spot_name"
        case parentWalkId = "parent_walk_id"
        case sleepSessionId = "sleep_session_id"
        case gapType = "gap_type"
        case endTime = "end_time"
        case gapLocation = "gap_location"
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
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        spotId = try container.decodeIfPresent(UUID.self, forKey: .spotId)
        spotName = try container.decodeIfPresent(String.self, forKey: .spotName)
        parentWalkId = try container.decodeIfPresent(UUID.self, forKey: .parentWalkId)

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
}
