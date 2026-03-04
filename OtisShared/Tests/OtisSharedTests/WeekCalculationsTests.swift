//
//  WeekCalculationsTests.swift
//  OtisSharedTests
//
//  Unit tests for weekly statistics calculations

import XCTest
@testable import OtisShared

final class WeekCalculationsTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(hour: Int, minute: Int = 0, daysAgo: Int = 0) -> Date {
        let calendar = Calendar.current
        var date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private func makeEvent(type: EventType, daysAgo: Int, hour: Int = 12, location: EventLocation? = nil) -> PuppyEvent {
        PuppyEvent(time: makeDate(hour: hour, daysAgo: daysAgo), type: type, location: location)
    }

    // MARK: - calculateWeekStatsBatch Tests

    func testCalculateWeekStatsBatch_EmptyEvents_ReturnsSevenDays() {
        let stats = WeekCalculations.calculateWeekStatsBatch(from: [])

        XCTAssertEqual(stats.count, 7)
    }

    func testCalculateWeekStatsBatch_OrderedChronologically() {
        let stats = WeekCalculations.calculateWeekStatsBatch(from: [])

        // First element should be 6 days ago, last should be today
        XCTAssertFalse(stats[0].isToday)
        XCTAssertTrue(stats[6].isToday)
    }

    func testCalculateWeekStatsBatch_CountsOutdoorPotty() {
        let events = [
            makeEvent(type: .plassen, daysAgo: 0, hour: 8, location: .buiten),
            makeEvent(type: .plassen, daysAgo: 0, hour: 10, location: .buiten),
            makeEvent(type: .poepen, daysAgo: 0, hour: 12, location: .buiten)
        ]

        let stats = WeekCalculations.calculateWeekStatsBatch(from: events)
        let todayStats = stats.first { $0.isToday }

        XCTAssertEqual(todayStats?.outdoorPotty, 3)
        XCTAssertEqual(todayStats?.indoorPotty, 0)
    }

    func testCalculateWeekStatsBatch_CountsIndoorPotty() {
        let events = [
            makeEvent(type: .plassen, daysAgo: 0, hour: 8, location: .binnen),
            makeEvent(type: .poepen, daysAgo: 0, hour: 12, location: .binnen)
        ]

        let stats = WeekCalculations.calculateWeekStatsBatch(from: events)
        let todayStats = stats.first { $0.isToday }

        XCTAssertEqual(todayStats?.outdoorPotty, 0)
        XCTAssertEqual(todayStats?.indoorPotty, 2)
    }

    func testCalculateWeekStatsBatch_CountsMeals() {
        let events = [
            makeEvent(type: .eten, daysAgo: 0, hour: 7),
            makeEvent(type: .eten, daysAgo: 0, hour: 12),
            makeEvent(type: .eten, daysAgo: 0, hour: 18)
        ]

        let stats = WeekCalculations.calculateWeekStatsBatch(from: events)
        let todayStats = stats.first { $0.isToday }

        XCTAssertEqual(todayStats?.meals, 3)
    }

    func testCalculateWeekStatsBatch_CountsWalks() {
        let events = [
            makeEvent(type: .uitlaten, daysAgo: 0, hour: 7),
            makeEvent(type: .uitlaten, daysAgo: 0, hour: 18)
        ]

        let stats = WeekCalculations.calculateWeekStatsBatch(from: events)
        let todayStats = stats.first { $0.isToday }

        XCTAssertEqual(todayStats?.walks, 2)
    }

    func testCalculateWeekStatsBatch_CountsTraining() {
        let events = [
            makeEvent(type: .training, daysAgo: 0, hour: 10),
            makeEvent(type: .training, daysAgo: 0, hour: 15)
        ]

        let stats = WeekCalculations.calculateWeekStatsBatch(from: events)
        let todayStats = stats.first { $0.isToday }

        XCTAssertEqual(todayStats?.trainingSessions, 2)
    }

    func testCalculateWeekStatsBatch_GroupsByDate() {
        let events = [
            makeEvent(type: .eten, daysAgo: 0, hour: 12),
            makeEvent(type: .eten, daysAgo: 1, hour: 12),
            makeEvent(type: .eten, daysAgo: 2, hour: 12),
            makeEvent(type: .eten, daysAgo: 2, hour: 18)
        ]

        let stats = WeekCalculations.calculateWeekStatsBatch(from: events)

        // Today (index 6): 1 meal
        // Yesterday (index 5): 1 meal
        // 2 days ago (index 4): 2 meals
        XCTAssertEqual(stats[6].meals, 1)
        XCTAssertEqual(stats[5].meals, 1)
        XCTAssertEqual(stats[4].meals, 2)
    }

    // MARK: - DayStats Properties Tests

    func testDayStats_OutdoorPercentage_AllOutdoor() {
        let stats = DayStats(
            date: Date(),
            outdoorPotty: 5,
            indoorPotty: 0,
            meals: 0,
            walks: 0,
            sleepHours: 0,
            trainingSessions: 0
        )

        XCTAssertEqual(stats.outdoorPercentage, 100)
    }

    func testDayStats_OutdoorPercentage_AllIndoor() {
        let stats = DayStats(
            date: Date(),
            outdoorPotty: 0,
            indoorPotty: 5,
            meals: 0,
            walks: 0,
            sleepHours: 0,
            trainingSessions: 0
        )

        XCTAssertEqual(stats.outdoorPercentage, 0)
    }

    func testDayStats_OutdoorPercentage_Mixed() {
        let stats = DayStats(
            date: Date(),
            outdoorPotty: 3,
            indoorPotty: 1,
            meals: 0,
            walks: 0,
            sleepHours: 0,
            trainingSessions: 0
        )

        XCTAssertEqual(stats.outdoorPercentage, 75)
    }

    func testDayStats_OutdoorPercentage_NoPotty() {
        let stats = DayStats(
            date: Date(),
            outdoorPotty: 0,
            indoorPotty: 0,
            meals: 0,
            walks: 0,
            sleepHours: 0,
            trainingSessions: 0
        )

        XCTAssertEqual(stats.outdoorPercentage, 0)
    }

    func testDayStats_IsToday() {
        let todayStats = DayStats(
            date: Date(),
            outdoorPotty: 0,
            indoorPotty: 0,
            meals: 0,
            walks: 0,
            sleepHours: 0,
            trainingSessions: 0
        )

        let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStats = DayStats(
            date: yesterdayDate,
            outdoorPotty: 0,
            indoorPotty: 0,
            meals: 0,
            walks: 0,
            sleepHours: 0,
            trainingSessions: 0
        )

        XCTAssertTrue(todayStats.isToday)
        XCTAssertFalse(yesterdayStats.isToday)
    }

    // MARK: - calculateDaySleepMinutes Tests

    func testCalculateDaySleepMinutes_NoSleepEvents_ReturnsZero() {
        let minutes = WeekCalculations.calculateDaySleepMinutes(
            date: Date(),
            todayEvents: [],
            previousDayEvents: []
        )

        XCTAssertEqual(minutes, 0)
    }

    func testCalculateDaySleepMinutes_CompletedSleep() {
        let sleepStart = makeDate(hour: 10, daysAgo: 0)
        let wakeTime = makeDate(hour: 12, daysAgo: 0)

        let events = [
            PuppyEvent(time: sleepStart, type: .slapen),
            PuppyEvent(time: wakeTime, type: .ontwaken)
        ]

        let minutes = WeekCalculations.calculateDaySleepMinutes(
            date: Date(),
            todayEvents: events,
            previousDayEvents: []
        )

        XCTAssertEqual(minutes, 120) // 2 hours
    }

    func testCalculateDaySleepMinutes_OvernightSleep() {
        // Sleep started yesterday at 22:00, woke up today at 07:00
        let sleepStart = makeDate(hour: 22, daysAgo: 1)
        let wakeTime = makeDate(hour: 7, daysAgo: 0)

        let previousDayEvents = [PuppyEvent(time: sleepStart, type: .slapen)]
        let todayEvents = [PuppyEvent(time: wakeTime, type: .ontwaken)]

        let minutes = WeekCalculations.calculateDaySleepMinutes(
            date: Date(),
            todayEvents: todayEvents,
            previousDayEvents: previousDayEvents
        )

        // From midnight to 7am = 7 hours = 420 minutes
        XCTAssertEqual(minutes, 420)
    }

    func testCalculateDaySleepMinutes_MultipleSessions() {
        let events = [
            PuppyEvent(time: makeDate(hour: 9, daysAgo: 0), type: .slapen),
            PuppyEvent(time: makeDate(hour: 10, daysAgo: 0), type: .ontwaken),
            PuppyEvent(time: makeDate(hour: 14, daysAgo: 0), type: .slapen),
            PuppyEvent(time: makeDate(hour: 15, minute: 30, daysAgo: 0), type: .ontwaken)
        ]

        let minutes = WeekCalculations.calculateDaySleepMinutes(
            date: Date(),
            todayEvents: events,
            previousDayEvents: []
        )

        // 1 hour + 1.5 hours = 150 minutes
        XCTAssertEqual(minutes, 150)
    }
}
