//
//  CoverageGapFilterTests.swift
//  OtisSharedTests
//
//  Unit tests for coverage gap filtering utilities

import XCTest
@testable import OtisShared

final class CoverageGapFilterTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(hour: Int, minute: Int = 0, daysAgo: Int = 0) -> Date {
        let calendar = Calendar.current
        var date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private func makeCoverageGap(startHour: Int, endHour: Int?, daysAgo: Int = 0) -> PuppyEvent {
        let startTime = makeDate(hour: startHour, daysAgo: daysAgo)
        let endTime = endHour.map { makeDate(hour: $0, daysAgo: daysAgo) }
        return PuppyEvent(time: startTime, type: .coverageGap, endTime: endTime)
    }

    // MARK: - intervalSpansGap Tests

    func testIntervalSpansGap_NoGaps_ReturnsFalse() {
        let result = CoverageGapFilter.intervalSpansGap(
            start: makeDate(hour: 8),
            end: makeDate(hour: 12),
            gaps: []
        )

        XCTAssertFalse(result)
    }

    func testIntervalSpansGap_IntervalBeforeGap_ReturnsFalse() {
        let gaps = [makeCoverageGap(startHour: 14, endHour: 18)]

        let result = CoverageGapFilter.intervalSpansGap(
            start: makeDate(hour: 8),
            end: makeDate(hour: 12),
            gaps: gaps
        )

        XCTAssertFalse(result)
    }

    func testIntervalSpansGap_IntervalAfterGap_ReturnsFalse() {
        let gaps = [makeCoverageGap(startHour: 8, endHour: 12)]

        let result = CoverageGapFilter.intervalSpansGap(
            start: makeDate(hour: 14),
            end: makeDate(hour: 18),
            gaps: gaps
        )

        XCTAssertFalse(result)
    }

    func testIntervalSpansGap_IntervalOverlapsGap_ReturnsTrue() {
        let gaps = [makeCoverageGap(startHour: 10, endHour: 14)]

        let result = CoverageGapFilter.intervalSpansGap(
            start: makeDate(hour: 8),
            end: makeDate(hour: 12),
            gaps: gaps
        )

        XCTAssertTrue(result)
    }

    func testIntervalSpansGap_IntervalInsideGap_ReturnsTrue() {
        let gaps = [makeCoverageGap(startHour: 8, endHour: 18)]

        let result = CoverageGapFilter.intervalSpansGap(
            start: makeDate(hour: 10),
            end: makeDate(hour: 14),
            gaps: gaps
        )

        XCTAssertTrue(result)
    }

    func testIntervalSpansGap_GapInsideInterval_ReturnsTrue() {
        let gaps = [makeCoverageGap(startHour: 10, endHour: 12)]

        let result = CoverageGapFilter.intervalSpansGap(
            start: makeDate(hour: 8),
            end: makeDate(hour: 18),
            gaps: gaps
        )

        XCTAssertTrue(result)
    }

    func testIntervalSpansGap_OngoingGap_ReturnsTrue() {
        let gaps = [makeCoverageGap(startHour: 10, endHour: nil)] // No end time

        let result = CoverageGapFilter.intervalSpansGap(
            start: makeDate(hour: 12),
            end: makeDate(hour: 14),
            gaps: gaps
        )

        XCTAssertTrue(result)
    }

    // MARK: - isTimeCoveredByGap Tests

    func testIsTimeCoveredByGap_NoGaps_ReturnsFalse() {
        let result = CoverageGapFilter.isTimeCoveredByGap(
            makeDate(hour: 12),
            gaps: []
        )

        XCTAssertFalse(result)
    }

    func testIsTimeCoveredByGap_TimeBeforeGap_ReturnsFalse() {
        let gaps = [makeCoverageGap(startHour: 14, endHour: 18)]

        let result = CoverageGapFilter.isTimeCoveredByGap(
            makeDate(hour: 12),
            gaps: gaps
        )

        XCTAssertFalse(result)
    }

    func testIsTimeCoveredByGap_TimeAfterGap_ReturnsFalse() {
        let gaps = [makeCoverageGap(startHour: 8, endHour: 12)]

        let result = CoverageGapFilter.isTimeCoveredByGap(
            makeDate(hour: 14),
            gaps: gaps
        )

        XCTAssertFalse(result)
    }

    func testIsTimeCoveredByGap_TimeInsideGap_ReturnsTrue() {
        let gaps = [makeCoverageGap(startHour: 10, endHour: 14)]

        let result = CoverageGapFilter.isTimeCoveredByGap(
            makeDate(hour: 12),
            gaps: gaps
        )

        XCTAssertTrue(result)
    }

    func testIsTimeCoveredByGap_TimeAtGapStart_ReturnsTrue() {
        let gaps = [makeCoverageGap(startHour: 10, endHour: 14)]

        let result = CoverageGapFilter.isTimeCoveredByGap(
            makeDate(hour: 10),
            gaps: gaps
        )

        XCTAssertTrue(result)
    }

    func testIsTimeCoveredByGap_TimeAtGapEnd_ReturnsTrue() {
        let gaps = [makeCoverageGap(startHour: 10, endHour: 14)]

        let result = CoverageGapFilter.isTimeCoveredByGap(
            makeDate(hour: 14),
            gaps: gaps
        )

        XCTAssertTrue(result)
    }

    func testIsTimeCoveredByGap_OngoingGap_ReturnsTrue() {
        let gaps = [makeCoverageGap(startHour: 10, endHour: nil)]

        let result = CoverageGapFilter.isTimeCoveredByGap(
            makeDate(hour: 23), // Any time after gap start
            gaps: gaps
        )

        XCTAssertTrue(result)
    }

    // MARK: - hasActiveGap Tests

    func testHasActiveGap_NoGaps_ReturnsFalse() {
        XCTAssertFalse(CoverageGapFilter.hasActiveGap(gaps: []))
    }

    func testHasActiveGap_OnlyCompletedGaps_ReturnsFalse() {
        let gaps = [
            makeCoverageGap(startHour: 8, endHour: 12),
            makeCoverageGap(startHour: 14, endHour: 18)
        ]

        XCTAssertFalse(CoverageGapFilter.hasActiveGap(gaps: gaps))
    }

    func testHasActiveGap_HasOngoingGap_ReturnsTrue() {
        let gaps = [
            makeCoverageGap(startHour: 8, endHour: 12),
            makeCoverageGap(startHour: 14, endHour: nil) // Active
        ]

        XCTAssertTrue(CoverageGapFilter.hasActiveGap(gaps: gaps))
    }

    // MARK: - activeGap Tests

    func testActiveGap_NoGaps_ReturnsNil() {
        XCTAssertNil(CoverageGapFilter.activeGap(gaps: []))
    }

    func testActiveGap_OnlyCompletedGaps_ReturnsNil() {
        let gaps = [makeCoverageGap(startHour: 8, endHour: 12)]

        XCTAssertNil(CoverageGapFilter.activeGap(gaps: gaps))
    }

    func testActiveGap_HasOngoingGap_ReturnsIt() {
        let activeGap = makeCoverageGap(startHour: 14, endHour: nil)
        let gaps = [
            makeCoverageGap(startHour: 8, endHour: 12),
            activeGap
        ]

        let result = CoverageGapFilter.activeGap(gaps: gaps)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.endTime)
    }

    // MARK: - filterEventsOutsideGaps Tests

    func testFilterEventsOutsideGaps_NoGaps_ReturnsAll() {
        let events = [
            PuppyEvent(time: makeDate(hour: 8), type: .plassen, location: .buiten),
            PuppyEvent(time: makeDate(hour: 12), type: .plassen, location: .buiten)
        ]

        let filtered = CoverageGapFilter.filterEventsOutsideGaps(events: events, gaps: [])

        XCTAssertEqual(filtered.count, 2)
    }

    func testFilterEventsOutsideGaps_FiltersEventsInsideGap() {
        let events = [
            PuppyEvent(time: makeDate(hour: 8), type: .plassen, location: .buiten),   // Before gap
            PuppyEvent(time: makeDate(hour: 11), type: .plassen, location: .binnen),  // Inside gap
            PuppyEvent(time: makeDate(hour: 15), type: .plassen, location: .buiten)   // After gap
        ]
        let gaps = [makeCoverageGap(startHour: 10, endHour: 14)]

        let filtered = CoverageGapFilter.filterEventsOutsideGaps(events: events, gaps: gaps)

        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered[0].time, makeDate(hour: 8))
        XCTAssertEqual(filtered[1].time, makeDate(hour: 15))
    }

    // MARK: - gapsOverlapping Tests

    func testGapsOverlapping_NoOverlap_ReturnsEmpty() {
        let gaps = [makeCoverageGap(startHour: 8, endHour: 10)]

        let overlapping = CoverageGapFilter.gapsOverlapping(
            start: makeDate(hour: 14),
            end: makeDate(hour: 18),
            gaps: gaps
        )

        XCTAssertTrue(overlapping.isEmpty)
    }

    func testGapsOverlapping_HasOverlap_ReturnsMatching() {
        let gaps = [
            makeCoverageGap(startHour: 8, endHour: 10),  // No overlap
            makeCoverageGap(startHour: 12, endHour: 16), // Overlaps
            makeCoverageGap(startHour: 20, endHour: 22)  // No overlap
        ]

        let overlapping = CoverageGapFilter.gapsOverlapping(
            start: makeDate(hour: 14),
            end: makeDate(hour: 18),
            gaps: gaps
        )

        XCTAssertEqual(overlapping.count, 1)
    }

    // MARK: - filterPottyGaps Tests

    func testFilterPottyGaps_NoOverlap_ReturnsAll() {
        let pottyGaps = [
            (start: makeDate(hour: 8), end: makeDate(hour: 10), minutes: 120),
            (start: makeDate(hour: 18), end: makeDate(hour: 20), minutes: 120)
        ]
        let coverageGaps = [makeCoverageGap(startHour: 12, endHour: 14)]

        let result = CoverageGapFilter.filterPottyGaps(gaps: pottyGaps, coverageGaps: coverageGaps)

        XCTAssertEqual(result.filtered.count, 2)
        XCTAssertEqual(result.excludedCount, 0)
    }

    func testFilterPottyGaps_WithOverlap_FiltersAndCountsExcluded() {
        let pottyGaps = [
            (start: makeDate(hour: 8), end: makeDate(hour: 10), minutes: 120),   // OK
            (start: makeDate(hour: 11), end: makeDate(hour: 15), minutes: 240),  // Overlaps gap
            (start: makeDate(hour: 18), end: makeDate(hour: 20), minutes: 120)   // OK
        ]
        let coverageGaps = [makeCoverageGap(startHour: 12, endHour: 14)]

        let result = CoverageGapFilter.filterPottyGaps(gaps: pottyGaps, coverageGaps: coverageGaps)

        XCTAssertEqual(result.filtered.count, 2)
        XCTAssertEqual(result.excludedCount, 1)
    }
}
