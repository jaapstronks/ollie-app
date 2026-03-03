//
//  WalkSuggestionCalculationsTests.swift
//  OtisSharedTests
//
//  Unit tests for walk suggestion calculations

import XCTest
@testable import OtisShared

final class WalkSuggestionCalculationsTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(hour: Int, minute: Int = 0) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    private func makeWalkEvent(at date: Date) -> PuppyEvent {
        PuppyEvent(time: date, type: .uitlaten)
    }

    private func makeDefaultSchedule(walksPerDay: Int = 4) -> WalkSchedule {
        let walks = (0..<walksPerDay).map { index in
            let hour = 7 + index * 4
            return WalkSchedule.ScheduledWalk(
                label: "Walk \(index + 1)",
                targetTime: String(format: "%02d:00", hour)
            )
        }
        return WalkSchedule(
            mode: .flexible,
            walks: walks,
            intervalMinutes: 120,
            dayStartHour: 6,
            dayEndHour: 22
        )
    }

    // MARK: - Flexible Mode Tests

    func testFlexibleMode_NoWalksToday_SuggestsFirstScheduled() {
        let schedule = makeDefaultSchedule()
        let currentTime = makeDate(hour: 8)

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: [],
            walkSchedule: schedule,
            date: currentTime
        )

        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.walksCompletedToday, 0)
        XCTAssertEqual(suggestion?.targetWalksPerDay, 4)
    }

    func testFlexibleMode_OneWalkDone_SuggestsNextBasedOnInterval() {
        let schedule = makeDefaultSchedule()
        let lastWalkTime = makeDate(hour: 8)
        let currentTime = makeDate(hour: 9) // 1 hour after last walk

        let events = [makeWalkEvent(at: lastWalkTime)]

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: schedule,
            date: currentTime
        )

        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.walksCompletedToday, 1)
        // Next walk should be at lastWalk + interval (8:00 + 2 hours = 10:00)
        XCTAssertEqual(suggestion?.minutesUntilSuggested, 60) // 1 hour until 10:00
    }

    func testFlexibleMode_OverdueWalk_ShowsOverdue() {
        let schedule = makeDefaultSchedule()
        let lastWalkTime = makeDate(hour: 6)
        let currentTime = makeDate(hour: 10) // 4 hours after last walk

        let events = [makeWalkEvent(at: lastWalkTime)]

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: schedule,
            date: currentTime
        )

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion?.isOverdue ?? false)
    }

    func testFlexibleMode_AllWalksDone_ReturnsNil() {
        var schedule = makeDefaultSchedule(walksPerDay: 3)
        schedule.walks = [
            .init(label: "Morning", targetTime: "07:00"),
            .init(label: "Afternoon", targetTime: "12:00"),
            .init(label: "Evening", targetTime: "18:00")
        ]

        let events = [
            makeWalkEvent(at: makeDate(hour: 7)),
            makeWalkEvent(at: makeDate(hour: 12)),
            makeWalkEvent(at: makeDate(hour: 18))
        ]

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: schedule,
            date: makeDate(hour: 19)
        )

        XCTAssertNil(suggestion)
    }

    func testFlexibleMode_PastDayEndHour_ReturnsNil() {
        let schedule = makeDefaultSchedule() // dayEndHour = 22

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: [],
            walkSchedule: schedule,
            date: makeDate(hour: 23)
        )

        XCTAssertNil(suggestion)
    }

    // MARK: - Strict Mode Tests

    func testStrictMode_NoWalksToday_SuggestsFirstScheduled() {
        var schedule = makeDefaultSchedule()
        schedule.mode = .strict

        let currentTime = makeDate(hour: 6)

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: [],
            walkSchedule: schedule,
            date: currentTime
        )

        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.scheduledWalkIndex, 0)
        XCTAssertEqual(suggestion?.label, "Walk 1")
    }

    func testStrictMode_OneWalkDone_SuggestsSecondScheduled() {
        var schedule = makeDefaultSchedule()
        schedule.mode = .strict

        let events = [makeWalkEvent(at: makeDate(hour: 7))]
        let currentTime = makeDate(hour: 9)

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: schedule,
            date: currentTime
        )

        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.scheduledWalkIndex, 1)
        XCTAssertEqual(suggestion?.label, "Walk 2")
    }

    func testStrictMode_UsesScheduledTimes_NotInterval() {
        var schedule = makeDefaultSchedule()
        schedule.mode = .strict
        // First walk at 7:00, second at 11:00

        let events = [makeWalkEvent(at: makeDate(hour: 7))]
        let currentTime = makeDate(hour: 8)

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: events,
            walkSchedule: schedule,
            date: currentTime
        )

        // In strict mode, next walk is at scheduled time (11:00), not 7:00 + interval
        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.minutesUntilSuggested, 180) // 3 hours until 11:00
    }

    // MARK: - calculateRemainingSuggestions Tests

    func testCalculateRemainingSuggestions_FlexibleMode_ReturnsMultiple() {
        let schedule = makeDefaultSchedule(walksPerDay: 3)
        let currentTime = makeDate(hour: 6)

        let suggestions = WalkSuggestionCalculations.calculateRemainingSuggestions(
            events: [],
            walkSchedule: schedule,
            date: currentTime
        )

        XCTAssertEqual(suggestions.count, 3)
    }

    func testCalculateRemainingSuggestions_PartialComplete() {
        var schedule = makeDefaultSchedule(walksPerDay: 4)
        schedule.mode = .strict

        let events = [
            makeWalkEvent(at: makeDate(hour: 7)),
            makeWalkEvent(at: makeDate(hour: 11))
        ]
        let currentTime = makeDate(hour: 12)

        let suggestions = WalkSuggestionCalculations.calculateRemainingSuggestions(
            events: events,
            walkSchedule: schedule,
            date: currentTime
        )

        XCTAssertEqual(suggestions.count, 2) // 2 remaining walks
    }

    func testCalculateRemainingSuggestions_AllDone_ReturnsEmpty() {
        var schedule = makeDefaultSchedule(walksPerDay: 2)
        schedule.walks = [
            .init(label: "Morning", targetTime: "08:00"),
            .init(label: "Evening", targetTime: "18:00")
        ]

        let events = [
            makeWalkEvent(at: makeDate(hour: 8)),
            makeWalkEvent(at: makeDate(hour: 18))
        ]

        let suggestions = WalkSuggestionCalculations.calculateRemainingSuggestions(
            events: events,
            walkSchedule: schedule,
            date: makeDate(hour: 19)
        )

        XCTAssertTrue(suggestions.isEmpty)
    }

    // MARK: - WalkSuggestion Properties Tests

    func testWalkSuggestion_IsDayComplete() {
        let complete = WalkSuggestion(
            suggestedTime: Date(),
            label: "Walk",
            isOverdue: false,
            minutesSinceLastWalk: 120,
            minutesUntilSuggested: 0,
            walksCompletedToday: 4,
            targetWalksPerDay: 4
        )

        let incomplete = WalkSuggestion(
            suggestedTime: Date(),
            label: "Walk",
            isOverdue: false,
            minutesSinceLastWalk: 120,
            minutesUntilSuggested: 60,
            walksCompletedToday: 2,
            targetWalksPerDay: 4
        )

        XCTAssertTrue(complete.isDayComplete)
        XCTAssertFalse(incomplete.isDayComplete)
    }

    // MARK: - Edge Cases

    func testFlexibleMode_FirstWalkTimePassed_SuggestsWalk() {
        let schedule = WalkSchedule(
            mode: .flexible,
            walks: [.init(label: "Morning", targetTime: "06:00")],
            intervalMinutes: 120,
            dayStartHour: 6,
            dayEndHour: 22
        )

        let currentTime = makeDate(hour: 8) // 2 hours after first scheduled

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: [],
            walkSchedule: schedule,
            date: currentTime
        )

        // Should still suggest a walk even though first scheduled time passed
        XCTAssertNotNil(suggestion)
        XCTAssertEqual(suggestion?.walksCompletedToday, 0)
    }

    func testMidnightDayEnd_NeverCaps() {
        let schedule = WalkSchedule(
            mode: .flexible,
            walks: [.init(label: "Night", targetTime: "23:00")],
            intervalMinutes: 120,
            dayStartHour: 6,
            dayEndHour: 24  // Midnight
        )

        let currentTime = makeDate(hour: 23, minute: 30)

        let suggestion = WalkSuggestionCalculations.calculateNextSuggestion(
            events: [],
            walkSchedule: schedule,
            date: currentTime
        )

        // Should still suggest even at 23:30 since dayEndHour is 24
        XCTAssertNotNil(suggestion)
    }
}
