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

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .eten: return "🍽️"
        case .drinken: return "💧"
        case .plassen: return "🚽"
        case .poepen: return "💩"
        case .slapen: return "😴"
        case .ontwaken: return "☀️"
        case .uitlaten: return "🚶"
        case .tuin: return "🌳"
        case .training: return "🎓"
        case .bench: return "🏠"
        case .sociaal: return "🐕"
        case .milestone: return "🎉"
        case .gedrag: return "📝"
        case .gewicht: return "⚖️"
        }
    }

    var label: String {
        switch self {
        case .eten: return "Eten"
        case .drinken: return "Drinken"
        case .plassen: return "Plassen"
        case .poepen: return "Poepen"
        case .slapen: return "Slapen"
        case .ontwaken: return "Wakker"
        case .uitlaten: return "Uitlaten"
        case .tuin: return "Tuin"
        case .training: return "Training"
        case .bench: return "Bench"
        case .sociaal: return "Sociaal"
        case .milestone: return "Mijlpaal"
        case .gedrag: return "Gedrag"
        case .gewicht: return "Gewicht"
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
        case .buiten: return "Buiten"
        case .binnen: return "Binnen"
        }
    }
}

/// A single puppy event, stored as one line in JSONL files
struct PuppyEvent: Codable, Identifiable {
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
        video: String? = nil
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
    }

    // Custom decoder to handle missing id (web app data doesn't include it)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Generate UUID if not present in JSON
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()

        self.time = try container.decode(Date.self, forKey: .time)
        self.type = try container.decode(EventType.self, forKey: .type)
        self.location = try container.decodeIfPresent(EventLocation.self, forKey: .location)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.who = try container.decodeIfPresent(String.self, forKey: .who)
        self.exercise = try container.decodeIfPresent(String.self, forKey: .exercise)
        self.result = try container.decodeIfPresent(String.self, forKey: .result)
        self.durationMin = try container.decodeIfPresent(Int.self, forKey: .durationMin)
        self.photo = try container.decodeIfPresent(String.self, forKey: .photo)
        self.video = try container.decodeIfPresent(String.self, forKey: .video)
    }
}
