//
//  OtisSharedTests.swift
//  OtisSharedTests
//
//  Basic tests to verify package compiles and core types work

import XCTest
@testable import OtisShared

final class OtisSharedTests: XCTestCase {

    // MARK: - PuppyEvent Tests

    func testPuppyEvent_Creation() {
        let event = PuppyEvent(time: Date(), type: .plassen, location: .buiten)

        XCTAssertEqual(event.type, .plassen)
        XCTAssertEqual(event.location, .buiten)
        XCTAssertNotNil(event.id)
    }

    func testPuppyEvent_PottyRequiresLocation() {
        // Potty events should have location
        let peeEvent = PuppyEvent(time: Date(), type: .plassen, location: .buiten)
        XCTAssertTrue(peeEvent.type.requiresLocation)

        // Non-potty events don't require location
        let mealEvent = PuppyEvent(time: Date(), type: .eten)
        XCTAssertFalse(mealEvent.type.requiresLocation)
    }

    func testPuppyEvent_CodingRoundTrip() throws {
        let original = PuppyEvent(
            time: Date(),
            type: .plassen,
            location: .buiten,
            note: "Test note"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PuppyEvent.self, from: data)

        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.location, original.location)
        XCTAssertEqual(decoded.note, original.note)
    }

    // MARK: - EventType Tests

    func testEventType_IsPottyEvent() {
        XCTAssertTrue(EventType.plassen.isPottyEvent)
        XCTAssertTrue(EventType.poepen.isPottyEvent)
        XCTAssertFalse(EventType.eten.isPottyEvent)
        XCTAssertFalse(EventType.slapen.isPottyEvent)
    }

    func testEventType_IsSleepEvent() {
        XCTAssertTrue(EventType.slapen.isSleepEvent)
        XCTAssertTrue(EventType.ontwaken.isSleepEvent)
        XCTAssertFalse(EventType.eten.isSleepEvent)
    }

    func testEventType_HasIcon() {
        // All event types should have an icon
        for type in EventType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type) should have an icon")
        }
    }

    func testEventType_HasLabel() {
        // All event types should have a label
        for type in EventType.allCases {
            XCTAssertFalse(type.label.isEmpty, "\(type) should have a label")
        }
    }

    // MARK: - Array Extension Tests

    func testArrayExtension_Filtering() {
        let events: [PuppyEvent] = [
            PuppyEvent(time: Date(), type: .plassen, location: .buiten),
            PuppyEvent(time: Date(), type: .poepen, location: .buiten),
            PuppyEvent(time: Date(), type: .eten),
            PuppyEvent(time: Date(), type: .slapen)
        ]

        XCTAssertEqual(events.pee().count, 1)
        XCTAssertEqual(events.poop().count, 1)
        XCTAssertEqual(events.pottyEvents().count, 2)
        XCTAssertEqual(events.meals().count, 1)
        XCTAssertEqual(events.sleeps().count, 1)
    }

    func testArrayExtension_Sorting() {
        let now = Date()
        let events: [PuppyEvent] = [
            PuppyEvent(time: now.addingTimeInterval(-60), type: .plassen, location: .buiten),
            PuppyEvent(time: now, type: .plassen, location: .buiten),
            PuppyEvent(time: now.addingTimeInterval(-120), type: .plassen, location: .buiten)
        ]

        let chronological = events.chronological()
        XCTAssertEqual(chronological.first?.time, now.addingTimeInterval(-120))
        XCTAssertEqual(chronological.last?.time, now)

        let reverse = events.reverseChronological()
        XCTAssertEqual(reverse.first?.time, now)
        XCTAssertEqual(reverse.last?.time, now.addingTimeInterval(-120))
    }

    // MARK: - WeightMeasurement Tests

    func testWeightMeasurement_Creation() {
        let measurement = WeightMeasurement(weightKg: 5.5, note: "At vet")

        XCTAssertEqual(measurement.weightKg, 5.5)
        XCTAssertEqual(measurement.note, "At vet")
        XCTAssertNotNil(measurement.id)
    }

    func testWeightMeasurement_AgeCalculation() {
        let birthDate = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: Date())!
        let measurement = WeightMeasurement(date: Date(), weightKg: 5.5)

        let ageWeeks = measurement.ageWeeks(birthDate: birthDate)

        XCTAssertEqual(ageWeeks, 12)
    }

    // MARK: - SleepSession Tests

    func testSleepSession_BuildSessions_NewModel() {
        let sleepTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let events = [
            PuppyEvent(time: sleepTime, type: .slapen, durationMin: 45)
        ]

        let sessions = SleepSession.buildSessions(from: events)

        XCTAssertEqual(sessions.count, 1)
        XCTAssertFalse(sessions[0].isOngoing)
        XCTAssertEqual(sessions[0].durationMinutes, 45)
    }

    func testSleepSession_OngoingSleep() {
        let sleepTime = Date().addingTimeInterval(-1800) // 30 minutes ago
        let events = [
            PuppyEvent(time: sleepTime, type: .slapen) // No durationMin = ongoing
        ]

        let sessions = SleepSession.buildSessions(from: events)

        XCTAssertEqual(sessions.count, 1)
        XCTAssertTrue(sessions[0].isOngoing)
    }
}
