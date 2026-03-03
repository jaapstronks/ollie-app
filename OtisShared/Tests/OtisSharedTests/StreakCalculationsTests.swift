//
//  StreakCalculationsTests.swift
//  OtisSharedTests
//
//  Unit tests for outdoor potty streak calculations

import XCTest
@testable import OtisShared

final class StreakCalculationsTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(minutesAgo: Int) -> Date {
        Date().addingTimeInterval(-Double(minutesAgo) * 60)
    }

    private func makePeeEvent(minutesAgo: Int, location: EventLocation) -> PuppyEvent {
        PuppyEvent(time: makeDate(minutesAgo: minutesAgo), type: .plassen, location: location)
    }

    // MARK: - calculateCurrentStreak Tests

    func testCalculateCurrentStreak_EmptyEvents_ReturnsZero() {
        let streak = StreakCalculations.calculateCurrentStreak(events: [])
        XCTAssertEqual(streak, 0)
    }

    func testCalculateCurrentStreak_AllOutdoor_ReturnsCount() {
        let events = [
            makePeeEvent(minutesAgo: 30, location: .buiten),
            makePeeEvent(minutesAgo: 60, location: .buiten),
            makePeeEvent(minutesAgo: 90, location: .buiten)
        ]

        let streak = StreakCalculations.calculateCurrentStreak(events: events)
        XCTAssertEqual(streak, 3)
    }

    func testCalculateCurrentStreak_LastWasIndoor_ReturnsZero() {
        let events = [
            makePeeEvent(minutesAgo: 30, location: .binnen),  // Most recent
            makePeeEvent(minutesAgo: 60, location: .buiten),
            makePeeEvent(minutesAgo: 90, location: .buiten)
        ]

        let streak = StreakCalculations.calculateCurrentStreak(events: events)
        XCTAssertEqual(streak, 0)
    }

    func testCalculateCurrentStreak_MixedWithRecentOutdoor() {
        let events = [
            makePeeEvent(minutesAgo: 30, location: .buiten),  // Most recent
            makePeeEvent(minutesAgo: 60, location: .buiten),
            makePeeEvent(minutesAgo: 90, location: .binnen),  // Breaks streak
            makePeeEvent(minutesAgo: 120, location: .buiten)
        ]

        let streak = StreakCalculations.calculateCurrentStreak(events: events)
        XCTAssertEqual(streak, 2) // Only the last 2 outdoor events
    }

    func testCalculateCurrentStreak_SingleOutdoorEvent() {
        let events = [makePeeEvent(minutesAgo: 30, location: .buiten)]

        let streak = StreakCalculations.calculateCurrentStreak(events: events)
        XCTAssertEqual(streak, 1)
    }

    func testCalculateCurrentStreak_IgnoresNonPeeEvents() {
        let events: [PuppyEvent] = [
            makePeeEvent(minutesAgo: 30, location: .buiten),
            PuppyEvent(time: makeDate(minutesAgo: 45), type: .poepen, location: .binnen), // Poop ignored
            makePeeEvent(minutesAgo: 60, location: .buiten)
        ]

        let streak = StreakCalculations.calculateCurrentStreak(events: events)
        XCTAssertEqual(streak, 2) // Both pee events are outdoor
    }

    // MARK: - calculateBestStreak Tests

    func testCalculateBestStreak_EmptyEvents_ReturnsZero() {
        let streak = StreakCalculations.calculateBestStreak(events: [])
        XCTAssertEqual(streak, 0)
    }

    func testCalculateBestStreak_AllOutdoor_ReturnsCount() {
        let events = [
            makePeeEvent(minutesAgo: 90, location: .buiten),
            makePeeEvent(minutesAgo: 60, location: .buiten),
            makePeeEvent(minutesAgo: 30, location: .buiten)
        ]

        let streak = StreakCalculations.calculateBestStreak(events: events)
        XCTAssertEqual(streak, 3)
    }

    func testCalculateBestStreak_FindsBestNotCurrent() {
        let events = [
            // Old streak of 3
            makePeeEvent(minutesAgo: 240, location: .buiten),
            makePeeEvent(minutesAgo: 210, location: .buiten),
            makePeeEvent(minutesAgo: 180, location: .buiten),
            // Break
            makePeeEvent(minutesAgo: 150, location: .binnen),
            // Current streak of 2
            makePeeEvent(minutesAgo: 60, location: .buiten),
            makePeeEvent(minutesAgo: 30, location: .buiten)
        ]

        let streak = StreakCalculations.calculateBestStreak(events: events)
        XCTAssertEqual(streak, 3) // Best was 3, even though current is 2
    }

    func testCalculateBestStreak_MultipleBreaks() {
        let events = [
            makePeeEvent(minutesAgo: 300, location: .buiten),
            makePeeEvent(minutesAgo: 270, location: .buiten),
            makePeeEvent(minutesAgo: 240, location: .binnen),  // Break
            makePeeEvent(minutesAgo: 210, location: .buiten),
            makePeeEvent(minutesAgo: 180, location: .buiten),
            makePeeEvent(minutesAgo: 150, location: .buiten),
            makePeeEvent(minutesAgo: 120, location: .buiten),
            makePeeEvent(minutesAgo: 90, location: .binnen),   // Break
            makePeeEvent(minutesAgo: 60, location: .buiten)
        ]

        let streak = StreakCalculations.calculateBestStreak(events: events)
        XCTAssertEqual(streak, 4) // Best was 4 outdoor in a row
    }

    // MARK: - getStreakInfo Tests

    func testGetStreakInfo_EmptyEvents_ReturnsEmpty() {
        let info = StreakCalculations.getStreakInfo(events: [])

        XCTAssertEqual(info.currentStreak, 0)
        XCTAssertEqual(info.bestStreak, 0)
        XCTAssertNil(info.lastOutdoorTime)
        XCTAssertNil(info.lastIndoorTime)
        XCTAssertFalse(info.hasActiveStreak)
        XCTAssertFalse(info.isOnFire)
    }

    func testGetStreakInfo_AllOutdoor() {
        let events = [
            makePeeEvent(minutesAgo: 90, location: .buiten),
            makePeeEvent(minutesAgo: 60, location: .buiten),
            makePeeEvent(minutesAgo: 30, location: .buiten)
        ]

        let info = StreakCalculations.getStreakInfo(events: events)

        XCTAssertEqual(info.currentStreak, 3)
        XCTAssertEqual(info.bestStreak, 3)
        XCTAssertNotNil(info.lastOutdoorTime)
        XCTAssertNil(info.lastIndoorTime)
        XCTAssertTrue(info.hasActiveStreak)
    }

    func testGetStreakInfo_MixedLocations() {
        let events = [
            makePeeEvent(minutesAgo: 180, location: .binnen),  // Indoor
            makePeeEvent(minutesAgo: 120, location: .buiten),
            makePeeEvent(minutesAgo: 90, location: .buiten),
            makePeeEvent(minutesAgo: 60, location: .buiten),
            makePeeEvent(minutesAgo: 30, location: .buiten)
        ]

        let info = StreakCalculations.getStreakInfo(events: events)

        XCTAssertEqual(info.currentStreak, 4)
        XCTAssertEqual(info.bestStreak, 4)
        XCTAssertNotNil(info.lastOutdoorTime)
        XCTAssertNotNil(info.lastIndoorTime)
    }

    func testGetStreakInfo_IsOnFire_AtFive() {
        let events = (1...5).map { i in
            makePeeEvent(minutesAgo: i * 30, location: .buiten)
        }

        let info = StreakCalculations.getStreakInfo(events: events)
        XCTAssertTrue(info.isOnFire)
    }

    func testGetStreakInfo_NotOnFire_BelowFive() {
        let events = (1...4).map { i in
            makePeeEvent(minutesAgo: i * 30, location: .buiten)
        }

        let info = StreakCalculations.getStreakInfo(events: events)
        XCTAssertFalse(info.isOnFire)
    }

    // MARK: - Coverage Gap Filtering Tests

    func testGetStreakInfo_FiltersCoverageGapEvents() {
        let gapStart = makeDate(minutesAgo: 90)
        let gapEnd = makeDate(minutesAgo: 60)

        let events = [
            makePeeEvent(minutesAgo: 120, location: .buiten),
            makePeeEvent(minutesAgo: 75, location: .binnen),  // During gap - should be filtered
            makePeeEvent(minutesAgo: 30, location: .buiten)
        ]

        let coverageGaps = [
            PuppyEvent(time: gapStart, type: .coverageGap, endTime: gapEnd)
        ]

        let info = StreakCalculations.getStreakInfo(events: events, coverageGaps: coverageGaps)

        // The indoor event at 75 minutes ago is during the gap, so streak continues
        XCTAssertEqual(info.currentStreak, 2)
    }

    // MARK: - iconName Tests

    func testIconName_ZeroStreak() {
        XCTAssertEqual(StreakCalculations.iconName(for: 0), "heart.slash.fill")
    }

    func testIconName_LowStreak() {
        XCTAssertEqual(StreakCalculations.iconName(for: 1), "hand.thumbsup.fill")
        XCTAssertEqual(StreakCalculations.iconName(for: 2), "hand.thumbsup.fill")
    }

    func testIconName_MediumStreak() {
        XCTAssertEqual(StreakCalculations.iconName(for: 3), "flame.fill")
        XCTAssertEqual(StreakCalculations.iconName(for: 4), "flame.fill")
    }

    func testIconName_HighStreak() {
        XCTAssertEqual(StreakCalculations.iconName(for: 5), "flame.fill")
        XCTAssertEqual(StreakCalculations.iconName(for: 10), "flame.fill")
    }

    // MARK: - StreakInfo Computed Properties

    func testStreakInfo_HasActiveStreak() {
        let active = StreakInfo(currentStreak: 1, bestStreak: 5, lastOutdoorTime: nil, lastIndoorTime: nil)
        let inactive = StreakInfo(currentStreak: 0, bestStreak: 5, lastOutdoorTime: nil, lastIndoorTime: nil)

        XCTAssertTrue(active.hasActiveStreak)
        XCTAssertFalse(inactive.hasActiveStreak)
    }
}
