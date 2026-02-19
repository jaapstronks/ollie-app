//
//  PuppyEvent.swift
//  Ollie-app
//

import Foundation

// Event types matching the web app
enum EventType: String, Codable, CaseIterable, Sendable {
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
}

// Location for potty events
enum PottyLocation: String, Codable, Sendable {
    case buiten
    case binnen
}

// Main event struct matching JSONL format
struct PuppyEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let time: Date
    let type: EventType
    var location: PottyLocation?
    var note: String?
    var who: String?
    var exercise: String?
    var result: String?
    var durationMin: Int?
    var photo: String?
    var video: String?

    // Custom coding keys to match snake_case JSON
    enum CodingKeys: String, CodingKey {
        case time, type, location, note, who, exercise, result, photo, video
        case durationMin = "duration_min"
    }

    // Custom decoder to handle ISO 8601 with timezone
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let timeString = try container.decode(String.self, forKey: .time)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: timeString) else {
            throw DecodingError.dataCorruptedError(forKey: .time, in: container, debugDescription: "Invalid date format")
        }
        self.time = date

        self.type = try container.decode(EventType.self, forKey: .type)
        self.location = try container.decodeIfPresent(PottyLocation.self, forKey: .location)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.who = try container.decodeIfPresent(String.self, forKey: .who)
        self.exercise = try container.decodeIfPresent(String.self, forKey: .exercise)
        self.result = try container.decodeIfPresent(String.self, forKey: .result)
        self.durationMin = try container.decodeIfPresent(Int.self, forKey: .durationMin)
        self.photo = try container.decodeIfPresent(String.self, forKey: .photo)
        self.video = try container.decodeIfPresent(String.self, forKey: .video)
        self.id = UUID()
    }

    // Custom encoder to output ISO 8601 with timezone
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone.current
        let timeString = formatter.string(from: time)
        try container.encode(timeString, forKey: .time)

        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(who, forKey: .who)
        try container.encodeIfPresent(exercise, forKey: .exercise)
        try container.encodeIfPresent(result, forKey: .result)
        try container.encodeIfPresent(durationMin, forKey: .durationMin)
        try container.encodeIfPresent(photo, forKey: .photo)
        try container.encodeIfPresent(video, forKey: .video)
    }

    // Memberwise initializer for creating events in code
    init(time: Date = Date(), type: EventType, location: PottyLocation? = nil, note: String? = nil, who: String? = nil, exercise: String? = nil, result: String? = nil, durationMin: Int? = nil, photo: String? = nil, video: String? = nil) {
        self.id = UUID()
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
}
