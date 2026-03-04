//
//  SleepCalculationsTests.swift
//  OtisSharedTests
//
//  Unit tests for sleep state calculations

import XCTest
@testable import OtisShared

final class SleepCalculationsTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(hour: Int, minute: Int = 0, daysAgo: Int = 0) -> Date {
        let calendar = Calendar.current
        var date = Date()
        if daysAgo > 0 {
            date = calendar.date(byAdding: .day, value: -daysAgo, to: date)!
        }
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private func makeSleepEvent(at date: Date, durationMin: Int? = nil) -> PuppyEvent {
        PuppyEvent(time: date, type: .slapen, durationMin: durationMin)
    }

    private func makeWakeEvent(at date: Date) -> PuppyEvent {
        PuppyEvent(time: date, type: .ontwaken)
    }

    private func makeRecentDate(minutesAgo: Int) -> Date {
        Date().addingTimeInterval(-Double(minutesAgo) * 60)
    }

    // MARK: - currentSleepState Tests

    func testCurrentSleepState_NoEvents_ReturnsUnknown() {
        let state = SleepCalculations.currentSleepState(events: [])
        XCTAssertEqual(state, .unknown)
    }

    func testCurrentSleepState_OngoingSleep_ReturnsSleeping() {
        let sleepStart = makeRecentDate(minutesAgo: 30)
        let events = [makeSleepEvent(at: sleepStart)]

        let state = SleepCalculations.currentSleepState(events: events)

        if case .sleeping(let since, let duration) = state {
            XCTAssertEqual(since, sleepStart)
            XCTAssertTrue(duration >= 29 && duration <= 31, "Duration should be ~30 minutes")
        } else {
            XCTFail("Expected sleeping state")
        }
    }

    func testCurrentSleepState_CompletedSleep_NewModel_ReturnsAwake() {
        // New model: sleep event with durationMin set = completed sleep
        let sleepStart = makeRecentDate(minutesAgo: 60)
        let events = [makeSleepEvent(at: sleepStart, durationMin: 45)]

        let state = SleepCalculations.currentSleepState(events: events)

        if case .awake(let since, let duration) = state {
            // Woke up 15 minutes ago (60 min ago sleep started, 45 min duration)
            XCTAssertTrue(duration >= 14 && duration <= 16, "Should be awake for ~15 minutes")
            _ = since // Silence warning
        } else {
            XCTFail("Expected awake state, got \(state)")
        }
    }

    func testCurrentSleepState_LegacyModel_WakeEvent_ReturnsAwake() {
        let sleepStart = makeRecentDate(minutesAgo: 60)
        let wakeTime = makeRecentDate(minutesAgo: 30)
        let events = [
            makeSleepEvent(at: sleepStart),
            makeWakeEvent(at: wakeTime)
        ]

        let state = SleepCalculations.currentSleepState(events: events)

        if case .awake(let since, let duration) = state {
            XCTAssertEqual(since, wakeTime)
            XCTAssertTrue(duration >= 29 && duration <= 31, "Should be awake for ~30 minutes")
        } else {
            XCTFail("Expected awake state")
        }
    }

    func testCurrentSleepState_ActiveCoverageGap_ReturnsUnknown() {
        let events = [
            PuppyEvent(time: makeRecentDate(minutesAgo: 60), type: .coverageGap, endTime: nil)
        ]

        let state = SleepCalculations.currentSleepState(events: events)
        XCTAssertEqual(state, .unknown)
    }

    // MARK: - isNap Tests

    func testIsNap_ShortDuration_ReturnsTrue() {
        XCTAssertTrue(SleepCalculations.isNap(durationMin: 10))
        XCTAssertTrue(SleepCalculations.isNap(durationMin: 14))
    }

    func testIsNap_AtThreshold_ReturnsFalse() {
        XCTAssertFalse(SleepCalculations.isNap(durationMin: 15))
    }

    func testIsNap_LongDuration_ReturnsFalse() {
        XCTAssertFalse(SleepCalculations.isNap(durationMin: 30))
        XCTAssertFalse(SleepCalculations.isNap(durationMin: 60))
    }

    // MARK: - totalSleepToday Tests

    func testTotalSleepToday_NoSleepEvents_ReturnsZero() {
        let events = [
            PuppyEvent(time: Date(), type: .eten)
        ]
        XCTAssertEqual(SleepCalculations.totalSleepToday(events: events), 0)
    }

    func testTotalSleepToday_NewModel_SumsDurations() {
        let events = [
            makeSleepEvent(at: makeRecentDate(minutesAgo: 120), durationMin: 30),
            makeSleepEvent(at: makeRecentDate(minutesAgo: 60), durationMin: 20)
        ]

        let total = SleepCalculations.totalSleepToday(events: events)
        XCTAssertEqual(total, 50) // 30 + 20
    }

    func testTotalSleepToday_LegacyModel_CalculatesFromPairs() {
        let sleepStart = makeRecentDate(minutesAgo: 90)
        let wakeTime = makeRecentDate(minutesAgo: 60)
        let events = [
            makeSleepEvent(at: sleepStart),
            makeWakeEvent(at: wakeTime)
        ]

        let total = SleepCalculations.totalSleepToday(events: events)
        XCTAssertEqual(total, 30) // 90 - 60 = 30 minutes
    }

    func testTotalSleepToday_OngoingSleep_IncludesCurrent() {
        let sleepStart = makeRecentDate(minutesAgo: 45)
        let events = [makeSleepEvent(at: sleepStart)]

        let total = SleepCalculations.totalSleepToday(events: events)
        XCTAssertTrue(total >= 44 && total <= 46, "Should include ongoing sleep of ~45 min")
    }

    // MARK: - lastCompleteSleep Tests

    func testLastCompleteSleep_NoSleepEvents_ReturnsNil() {
        let events: [PuppyEvent] = []
        XCTAssertNil(SleepCalculations.lastCompleteSleep(events: events))
    }

    func testLastCompleteSleep_OnlyOngoingSleep_ReturnsNil() {
        let events = [makeSleepEvent(at: makeRecentDate(minutesAgo: 30))]
        XCTAssertNil(SleepCalculations.lastCompleteSleep(events: events))
    }

    func testLastCompleteSleep_NewModel_ReturnsCorrectSession() {
        let sleepStart = makeRecentDate(minutesAgo: 60)
        let duration = 30
        let events = [makeSleepEvent(at: sleepStart, durationMin: duration)]

        let result = SleepCalculations.lastCompleteSleep(events: events)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.start, sleepStart)
        XCTAssertEqual(result?.durationMin, duration)
    }

    func testLastCompleteSleep_LegacyModel_ReturnsCorrectSession() {
        let sleepStart = makeRecentDate(minutesAgo: 90)
        let wakeTime = makeRecentDate(minutesAgo: 60)
        let events = [
            makeSleepEvent(at: sleepStart),
            makeWakeEvent(at: wakeTime)
        ]

        let result = SleepCalculations.lastCompleteSleep(events: events)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.start, sleepStart)
        XCTAssertEqual(result?.end, wakeTime)
        XCTAssertEqual(result?.durationMin, 30)
    }

    // MARK: - justWokeFromSignificantNap Tests

    func testJustWokeFromSignificantNap_RecentSignificantNap_ReturnsTrue() {
        // Nap >= 15 minutes, woke up within window
        let sleepStart = makeRecentDate(minutesAgo: 30)
        let events = [makeSleepEvent(at: sleepStart, durationMin: 20)]

        let result = SleepCalculations.justWokeFromSignificantNap(events: events, windowMinutes: 20)
        XCTAssertTrue(result)
    }

    func testJustWokeFromSignificantNap_ShortNap_ReturnsFalse() {
        // Nap < 15 minutes (not significant)
        let sleepStart = makeRecentDate(minutesAgo: 20)
        let events = [makeSleepEvent(at: sleepStart, durationMin: 10)]

        let result = SleepCalculations.justWokeFromSignificantNap(events: events)
        XCTAssertFalse(result)
    }

    func testJustWokeFromSignificantNap_WokeUpTooLongAgo_ReturnsFalse() {
        // Significant nap but woke up more than 20 minutes ago
        let sleepStart = makeRecentDate(minutesAgo: 60)
        let events = [makeSleepEvent(at: sleepStart, durationMin: 30)]

        // Woke up 30 minutes ago (60 - 30), outside default 20 minute window
        let result = SleepCalculations.justWokeFromSignificantNap(events: events, windowMinutes: 20)
        XCTAssertFalse(result)
    }

    // MARK: - defaultNapDuration Tests

    func testDefaultNapDuration_NoData_Returns30() {
        let events: [PuppyEvent] = []
        let duration = SleepCalculations.defaultNapDuration(events: events)
        XCTAssertEqual(duration, 30)
    }

    func testDefaultNapDuration_MinimumBound() {
        // Even if average would be lower, minimum is 15
        let duration = SleepCalculations.defaultNapDuration(events: [])
        XCTAssertTrue(duration >= 15)
    }

    // MARK: - SleepState Computed Properties Tests

    func testSleepState_IsSleeping() {
        let sleeping = SleepState.sleeping(since: Date(), durationMin: 30)
        let awake = SleepState.awake(since: Date(), durationMin: 30)
        let unknown = SleepState.unknown

        XCTAssertTrue(sleeping.isSleeping)
        XCTAssertFalse(awake.isSleeping)
        XCTAssertFalse(unknown.isSleeping)
    }

    func testSleepState_IsAwake() {
        let sleeping = SleepState.sleeping(since: Date(), durationMin: 30)
        let awake = SleepState.awake(since: Date(), durationMin: 30)
        let unknown = SleepState.unknown

        XCTAssertFalse(sleeping.isAwake)
        XCTAssertTrue(awake.isAwake)
        XCTAssertFalse(unknown.isAwake)
    }
}
