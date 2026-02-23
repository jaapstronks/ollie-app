//
//  PuppyEvent.swift
//  Ollie-app
//

import Foundation

// MARK: - Event Type

/// Event types for tracking puppy activities
enum EventType: String, Codable, CaseIterable, Identifiable {
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

    var id: String { rawValue }

    /// SF Symbol name for this event type
    var icon: String {
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
        }
    }

    var label: String {
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
        }
    }

    /// Whether this event type requires a location (inside/outside)
    var requiresLocation: Bool {
        self == .plassen || self == .poepen
    }

    /// Whether this event type is a potty event
    var isPottyEvent: Bool {
        self == .plassen || self == .poepen
    }

    /// Whether this event type is a sleep-related event
    var isSleepEvent: Bool {
        self == .slapen || self == .ontwaken
    }
}

// MARK: - Event Location

/// Location for potty events (inside vs outside)
enum EventLocation: String, Codable {
    case buiten  // outside
    case binnen  // inside

    var label: String {
        switch self {
        case .buiten: return Strings.EventLocation.outside
        case .binnen: return Strings.EventLocation.inside
        }
    }
}

// MARK: - Media Info

/// Encapsulates media attachments for an event
/// - `photoPath`: Path to the full-size photo (relative to documents directory)
/// - `thumbnailPath`: Path to the thumbnail image (derived from photo, used for performance)
/// - `videoPath`: Path to video file if present
///
/// Relationship: `thumbnailPath` is always derived from `photoPath`. When a photo is saved,
/// a thumbnail is generated and stored separately. Both should be set together or neither.
struct MediaInfo: Codable, Equatable {
    var photoPath: String?
    var videoPath: String?
    var thumbnailPath: String?

    /// Whether this media info has any content
    var hasMedia: Bool {
        photoPath != nil || videoPath != nil
    }

    /// Whether this has a photo (with or without thumbnail)
    var hasPhoto: Bool {
        photoPath != nil
    }

    static let empty = MediaInfo()
}

// MARK: - Location Info

/// Encapsulates GPS location data for walk events
/// - `latitude`/`longitude`: Direct GPS coordinates (from current location capture)
/// - `spotId`/`spotName`: Reference to a saved WalkSpot
///
/// Priority: When both GPS coords and spotId are set, `spotId` is used for display
/// (spotName shown in UI), but GPS coords are preserved for map functionality.
///
/// Note on `spotName`: This is intentionally denormalized from WalkSpot.name for display
/// performance. The tradeoff is that if a WalkSpot is renamed, existing events retain
/// the old name. This is acceptable because events are historical records of what
/// happened at that moment, and the spot name at logging time is the accurate record.
struct LocationInfo: Codable, Equatable {
    var latitude: Double?
    var longitude: Double?
    var spotId: UUID?
    var spotName: String?

    /// Whether this has any location data
    var hasLocation: Bool {
        hasCoordinates || spotId != nil
    }

    /// Whether this has GPS coordinates
    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    static let empty = LocationInfo()
}

// MARK: - Puppy Event

/// A single puppy event, stored as one line in JSONL files
///
/// ## Field Organization
/// - **Core fields**: `id`, `time`, `type`, `createdAt`, `modifiedAt`
/// - **Potty events**: `location` (REQUIRED for plassen/poepen)
/// - **Walk events**: `locationInfo` (GPS coords and/or spot reference)
/// - **Training events**: `exercise`, `result`
/// - **Social events**: `who`
/// - **Weight events**: `weightKg`
/// - **Sleep events**: `sleepSessionId` (auto-generated for slapen, used to link ontwaken)
/// - **Media**: `media` (photo, video, thumbnail paths)
/// - **Common optional**: `note`, `durationMin`
///
/// ## Factory Methods
/// Use the type-specific factory methods (`.potty()`, `.walk()`, `.training()`, etc.)
/// to ensure correct field combinations. The generic initializer is available for
/// decoding and migration purposes.
struct PuppyEvent: Codable, Identifiable, Equatable {
    // MARK: - Core Fields (always present)

    var id: UUID
    var time: Date
    var type: EventType
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Potty Fields

    /// Location for potty events (REQUIRED for plassen/poepen)
    /// For non-potty events, this should be nil
    var location: EventLocation?

    // MARK: - Common Optional Fields

    var note: String?
    var durationMin: Int?

    // MARK: - Type-Specific Fields

    /// Person or dog involved (sociaal events)
    var who: String?

    /// Exercise name (training events)
    var exercise: String?

    /// Training result/evaluation (training events)
    var result: String?

    /// Weight in kg (gewicht events)
    var weightKg: Double?

    /// Links potty events logged during a walk to their parent walk event
    var parentWalkId: UUID?

    /// Links slapen + ontwaken events into a session
    /// Auto-generated for slapen events, should be copied to matching ontwaken
    var sleepSessionId: UUID?

    // MARK: - Media Fields (kept flat for JSON compatibility)

    /// Photo file path (relative to documents directory)
    var photo: String?

    /// Video file path
    var video: String?

    /// Thumbnail path (derived from photo, for performance)
    var thumbnailPath: String?

    // MARK: - Location Fields (kept flat for JSON compatibility)

    /// GPS latitude (walk events, current location capture)
    var latitude: Double?

    /// GPS longitude
    var longitude: Double?

    /// Reference to saved WalkSpot
    var spotId: UUID?

    /// Denormalized spot name for display (see LocationInfo documentation)
    var spotName: String?

    // MARK: - Computed Properties

    /// Media info accessor (for cleaner access to media fields)
    var media: MediaInfo {
        get {
            MediaInfo(photoPath: photo, videoPath: video, thumbnailPath: thumbnailPath)
        }
        set {
            photo = newValue.photoPath
            video = newValue.videoPath
            thumbnailPath = newValue.thumbnailPath
        }
    }

    /// Location info accessor (for cleaner access to GPS/spot fields)
    var locationInfo: LocationInfo {
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

    /// Generic initializer - use factory methods for type-specific events when possible
    init(
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
        weightKg: Double? = nil,
        spotId: UUID? = nil,
        spotName: String? = nil,
        parentWalkId: UUID? = nil,
        sleepSessionId: UUID? = nil
    ) {
        self.id = id
        self.time = time
        self.type = type

        // Set timestamps - default to now if not provided
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
        self.weightKg = weightKg
        self.spotId = spotId
        self.spotName = spotName
        self.parentWalkId = parentWalkId

        // Auto-generate sleepSessionId for sleep events if not provided
        if type == .slapen {
            self.sleepSessionId = sleepSessionId ?? UUID()
        } else {
            self.sleepSessionId = sleepSessionId
        }

        // Validate potty events have location (debug assertion, not fatal in production)
        #if DEBUG
        if type.requiresLocation && location == nil {
            assertionFailure("Potty event (\(type)) created without location. Use PuppyEvent.potty() factory method.")
        }
        #endif
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
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
        case weightKg = "weight_kg"
        case spotId = "spot_id"
        case spotName = "spot_name"
        case parentWalkId = "parent_walk_id"
        case sleepSessionId = "sleep_session_id"
    }

    // MARK: - Custom Decoding (for backwards compatibility)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        time = try container.decode(Date.self, forKey: .time)
        type = try container.decode(EventType.self, forKey: .type)

        // Handle missing timestamps for legacy data
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
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        spotId = try container.decodeIfPresent(UUID.self, forKey: .spotId)
        spotName = try container.decodeIfPresent(String.self, forKey: .spotName)
        parentWalkId = try container.decodeIfPresent(UUID.self, forKey: .parentWalkId)

        // Auto-generate sleepSessionId for legacy sleep events that don't have one
        let decodedSleepSessionId = try container.decodeIfPresent(UUID.self, forKey: .sleepSessionId)
        if type == .slapen && decodedSleepSessionId == nil {
            sleepSessionId = UUID()
        } else {
            sleepSessionId = decodedSleepSessionId
        }
    }
}

// MARK: - Factory Methods

extension PuppyEvent {

    /// Create a potty event (plassen or poepen) with required location
    static func potty(
        type: EventType,
        time: Date = Date(),
        location: EventLocation,
        note: String? = nil,
        photo: String? = nil,
        thumbnailPath: String? = nil,
        parentWalkId: UUID? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> PuppyEvent {
        precondition(type.isPottyEvent, "potty() factory only accepts plassen or poepen")

        return PuppyEvent(
            time: time,
            type: type,
            location: location,
            note: note,
            photo: photo,
            latitude: latitude,
            longitude: longitude,
            thumbnailPath: thumbnailPath,
            parentWalkId: parentWalkId
        )
    }

    /// Create a walk event with optional spot/location info
    static func walk(
        time: Date = Date(),
        durationMin: Int? = nil,
        note: String? = nil,
        spot: WalkSpot? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        photo: String? = nil,
        thumbnailPath: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .uitlaten,
            note: note,
            durationMin: durationMin,
            photo: photo,
            latitude: latitude ?? spot?.latitude,
            longitude: longitude ?? spot?.longitude,
            thumbnailPath: thumbnailPath,
            spotId: spot?.id,
            spotName: spot?.name
        )
    }

    /// Create a training event with exercise details
    static func training(
        time: Date = Date(),
        exercise: String,
        result: String? = nil,
        durationMin: Int? = nil,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .training,
            note: note,
            exercise: exercise,
            result: result,
            durationMin: durationMin
        )
    }

    /// Create a social event with who was involved
    static func social(
        time: Date = Date(),
        who: String,
        note: String? = nil,
        durationMin: Int? = nil,
        photo: String? = nil,
        thumbnailPath: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .sociaal,
            note: note,
            who: who,
            durationMin: durationMin,
            photo: photo,
            thumbnailPath: thumbnailPath
        )
    }

    /// Create a sleep event (auto-generates sleepSessionId)
    static func sleep(
        time: Date = Date(),
        note: String? = nil,
        sleepSessionId: UUID? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .slapen,
            note: note,
            sleepSessionId: sleepSessionId  // Will auto-generate if nil
        )
    }

    /// Create a wake event (should use sleepSessionId from matching sleep event)
    static func wake(
        time: Date = Date(),
        sleepSessionId: UUID?,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .ontwaken,
            note: note,
            sleepSessionId: sleepSessionId
        )
    }

    /// Create a weight event
    static func weight(
        time: Date = Date(),
        weightKg: Double,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .gewicht,
            note: note,
            weightKg: weightKg
        )
    }

    /// Create a meal event
    static func meal(
        time: Date = Date(),
        note: String? = nil,
        durationMin: Int? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .eten,
            note: note,
            durationMin: durationMin
        )
    }

    /// Create a drink event
    static func drink(
        time: Date = Date(),
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .drinken,
            note: note
        )
    }

    /// Create a medication event
    static func medication(
        time: Date = Date(),
        medicationName: String
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .medicatie,
            note: medicationName
        )
    }

    /// Create a photo moment event
    static func moment(
        time: Date = Date(),
        photo: String,
        thumbnailPath: String? = nil,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .moment,
            note: note,
            photo: photo,
            thumbnailPath: thumbnailPath
        )
    }

    /// Create a milestone event
    static func milestone(
        time: Date = Date(),
        note: String
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .milestone,
            note: note
        )
    }

    /// Create a simple event (for types without special fields)
    static func simple(
        type: EventType,
        time: Date = Date(),
        note: String? = nil,
        durationMin: Int? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: type,
            note: note,
            durationMin: durationMin
        )
    }
}

// MARK: - Mutation Helpers

extension PuppyEvent {

    /// Returns a copy with updated modifiedAt timestamp
    func withUpdatedTimestamp() -> PuppyEvent {
        var copy = self
        copy.modifiedAt = Date()
        return copy
    }

    /// Returns a copy with media info updated
    func withMedia(_ media: MediaInfo) -> PuppyEvent {
        var copy = self
        copy.media = media
        copy.modifiedAt = Date()
        return copy
    }

    /// Returns a copy with location info updated
    func withLocationInfo(_ locationInfo: LocationInfo) -> PuppyEvent {
        var copy = self
        copy.locationInfo = locationInfo
        copy.modifiedAt = Date()
        return copy
    }
}
