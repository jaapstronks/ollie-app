//
//  PuppyEvent.swift
//  Ollie-app
//

import Foundation

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

    var requiresLocation: Bool {
        self == .plassen || self == .poepen
    }
}

/// Location for potty events
enum EventLocation: String, Codable {
    case buiten
    case binnen

    var label: String {
        switch self {
        case .buiten: return Strings.EventLocation.outside
        case .binnen: return Strings.EventLocation.inside
        }
    }
}

/// A single puppy event, stored as one line in JSONL files
struct PuppyEvent: Codable, Identifiable, Equatable {
    var id: UUID
    var time: Date
    var type: EventType
    var location: EventLocation?
    var note: String?
    var who: String?
    var exercise: String?
    var result: String?
    var durationMin: Int?
    var photo: String?
    var video: String?
    var latitude: Double?
    var longitude: Double?
    var thumbnailPath: String?
    var weightKg: Double?  // Weight in kg, for gewicht events
    var spotId: UUID?      // Reference to saved WalkSpot
    var spotName: String?  // Denormalized spot name for display
    var parentWalkId: UUID?  // Links potty events to their parent walk
    var sleepSessionId: UUID?  // Links slapen + ontwaken events into a session

    init(
        id: UUID = UUID(),
        time: Date = Date(),
        type: EventType,
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
        self.sleepSessionId = sleepSessionId
    }

    // Custom coding keys for snake_case JSON compatibility
    enum CodingKeys: String, CodingKey {
        case id
        case time
        case type
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
}
