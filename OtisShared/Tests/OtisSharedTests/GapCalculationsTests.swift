//
//  GapCalculationsTests.swift
//  OtisSharedTests
//
//  Unit tests for potty gap calculations

import XCTest
@testable import OtisShared

final class GapCalculationsTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(hour: Int, minute: Int = 0, day: Int = 1) -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    private func makePeeEvent(at date: Date, location: EventLocation = .buiten) -> PuppyEvent {
        PuppyEvent(time: date, type: .plassen, location: location)
    }

    // MARK: - calculatePottyGaps Tests

    func testCalculatePottyGaps_EmptyEvents_ReturnsEmptyArray() {
        let gaps = GapCalculations.calculatePottyGaps(events: [])
        XCTAssertTrue(gaps.isEmpty)
    }

    func testCalculatePottyGaps_SingleEvent_ReturnsEmptyArray() {
        let events = [makePeeEvent(at: makeDate(hour: 8))]
        let gaps = GapCalculations.calculatePottyGaps(events: events)
        XCTAssertTrue(gaps.isEmpty)
    }

    func testCalculatePottyGaps_TwoEvents_ReturnsOneGap() {
        let events = [
            makePeeEvent(at: makeDate(hour: 8)),
            makePeeEvent(at: makeDate(hour: 10))
        ]
        let gaps = GapCalculations.calculatePottyGaps(events: events, filterOvernight: false)

        XCTAssertEqual(gaps.count, 1)
        XCTAssertEqual(gaps[0].durationMinutes, 120) // 2 hours
    }

    func testCalculatePottyGaps_ThreeEvents_ReturnsTwoGaps() {
        let events = [
            makePeeEvent(at: makeDate(hour: 8)),
            makePeeEvent(at: makeDate(hour: 10)),
            makePeeEvent(at: makeDate(hour: 11, minute: 30))
        ]
        let gaps = GapCalculations.calculatePottyGaps(events: events, filterOvernight: false)

        XCTAssertEqual(gaps.count, 2)
        XCTAssertEqual(gaps[0].durationMinutes, 120) // 2 hours
        XCTAssertEqual(gaps[1].durationMinutes, 90)  // 1.5 hours
    }

    func testCalculatePottyGaps_UnsortedEvents_SortedCorrectly() {
        let events = [
            makePeeEvent(at: makeDate(hour: 11)),
            makePeeEvent(at: makeDate(hour: 8)),
            makePeeEvent(at: makeDate(hour: 10))
        ]
        let gaps = GapCalculations.calculatePottyGaps(events: events, filterOvernight: false)

        XCTAssertEqual(gaps.count, 2)
        XCTAssertEqual(gaps[0].durationMinutes, 120) // 8:00 -> 10:00
        XCTAssertEqual(gaps[1].durationMinutes, 60)  // 10:00 -> 11:00
    }

    func testCalculatePottyGaps_FilterOvernight_ExcludesLongGaps() {
        let events = [
            makePeeEvent(at: makeDate(hour: 22, day: 1)),
            makePeeEvent(at: makeDate(hour: 7, day: 2)) // Next day - 9 hour gap
        ]
        let gaps = GapCalculations.calculatePottyGaps(events: events, filterOvernight: true)

        // 9 hours > 8 hours max gap, should be filtered out
        XCTAssertTrue(gaps.isEmpty)
    }

    func testCalculatePottyGaps_FilterOvernight_IncludesDaytimeGaps() {
        let events = [
            makePeeEvent(at: makeDate(hour: 10)),
            makePeeEvent(at: makeDate(hour: 14)) // 4 hour gap within daytime
        ]
        let gaps = GapCalculations.calculatePottyGaps(events: events, filterOvernight: true)

        XCTAssertEqual(gaps.count, 1)
        XCTAssertEqual(gaps[0].durationMinutes, 240)
    }

    func testCalculatePottyGaps_FilterOvernight_ExcludesNightTimeGaps() {
        let events = [
            makePeeEvent(at: makeDate(hour: 5)),  // Before 7am (not daytime)
            makePeeEvent(at: makeDate(hour: 8))
        ]
        let gaps = GapCalculations.calculatePottyGaps(events: events, filterOvernight: true)

        // Gap starts before 7am (daytimeStartHour), should be filtered
        XCTAssertTrue(gaps.isEmpty)
    }

    func testCalculatePottyGaps_RecordsLocationInfo() {
        let events = [
            makePeeEvent(at: makeDate(hour: 8), location: .buiten),
            makePeeEvent(at: makeDate(hour: 10), location: .binnen)
        ]
        let gaps = GapCalculations.calculatePottyGaps(events: events, filterOvernight: false)

        XCTAssertEqual(gaps.count, 1)
        XCTAssertEqual(gaps[0].startLocation, .buiten)
        XCTAssertEqual(gaps[0].endLocation, .binnen)
    }

    func testCalculatePottyGaps_OnlyFiltersPeeEvents() {
        let events = [
            makePeeEvent(at: makeDate(hour: 8)),
            PuppyEvent(time: makeDate(hour: 9), type: .poepen, location: .buiten), // Poop - ignored
            makePeeEvent(at: makeDate(hour: 10))
        ]
        let gaps = GapCalculations.calculatePottyGaps(events: events, filterOvernight: false)

        XCTAssertEqual(gaps.count, 1)
        XCTAssertEqual(gaps[0].durationMinutes, 120) // Gap is 8:00 -> 10:00, ignoring poop at 9:00
    }

    // MARK: - PottyGap Computed Properties Tests

    func testPottyGap_IsOutdoorToOutdoor() {
        let gap = PottyGap(
            startTime: makeDate(hour: 8),
            endTime: makeDate(hour: 10),
            durationMinutes: 120,
            startLocation: .buiten,
            endLocation: .buiten
        )
        XCTAssertTrue(gap.isOutdoorToOutdoor)
    }

    func testPottyGap_IsNotOutdoorToOutdoor_WhenEndIndoor() {
        let gap = PottyGap(
            startTime: makeDate(hour: 8),
            endTime: makeDate(hour: 10),
            durationMinutes: 120,
            startLocation: .buiten,
            endLocation: .binnen
        )
        XCTAssertFalse(gap.isOutdoorToOutdoor)
        XCTAssertTrue(gap.endedIndoor)
    }

    // MARK: - calculateGapStats Tests

    func testCalculateGapStats_EmptyGaps_ReturnsEmpty() {
        let stats = GapCalculations.calculateGapStats(gaps: [])
        XCTAssertEqual(stats.count, 0)
        XCTAssertEqual(stats.minMinutes, 0)
        XCTAssertEqual(stats.maxMinutes, 0)
        XCTAssertEqual(stats.avgMinutes, 0)
        XCTAssertEqual(stats.medianMinutes, 0)
    }

    func testCalculateGapStats_SingleGap() {
        let gaps = [
            PottyGap(
                startTime: makeDate(hour: 8),
                endTime: makeDate(hour: 10),
                durationMinutes: 120,
                startLocation: .buiten,
                endLocation: .buiten
            )
        ]
        let stats = GapCalculations.calculateGapStats(gaps: gaps)

        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats.minMinutes, 120)
        XCTAssertEqual(stats.maxMinutes, 120)
        XCTAssertEqual(stats.avgMinutes, 120)
        XCTAssertEqual(stats.medianMinutes, 120)
    }

    func testCalculateGapStats_MultipleGaps_CorrectStatistics() {
        let gaps = [
            PottyGap(startTime: makeDate(hour: 8), endTime: makeDate(hour: 9), durationMinutes: 60, startLocation: .buiten, endLocation: .buiten),
            PottyGap(startTime: makeDate(hour: 9), endTime: makeDate(hour: 11), durationMinutes: 120, startLocation: .buiten, endLocation: .buiten),
            PottyGap(startTime: makeDate(hour: 11), endTime: makeDate(hour: 14), durationMinutes: 180, startLocation: .buiten, endLocation: .binnen)
        ]
        let stats = GapCalculations.calculateGapStats(gaps: gaps)

        XCTAssertEqual(stats.count, 3)
        XCTAssertEqual(stats.minMinutes, 60)
        XCTAssertEqual(stats.maxMinutes, 180)
        XCTAssertEqual(stats.avgMinutes, 120) // (60 + 120 + 180) / 3 = 120
        XCTAssertEqual(stats.medianMinutes, 120) // Middle value
    }

    func testCalculateGapStats_EvenNumberOfGaps_MedianIsAverage() {
        let gaps = [
            PottyGap(startTime: makeDate(hour: 8), endTime: makeDate(hour: 9), durationMinutes: 60, startLocation: .buiten, endLocation: .buiten),
            PottyGap(startTime: makeDate(hour: 9), endTime: makeDate(hour: 11), durationMinutes: 120, startLocation: .buiten, endLocation: .buiten)
        ]
        let stats = GapCalculations.calculateGapStats(gaps: gaps)

        XCTAssertEqual(stats.medianMinutes, 90) // (60 + 120) / 2 = 90
    }

    func testCalculateGapStats_CountsIndoorAndOutdoor() {
        let gaps = [
            PottyGap(startTime: makeDate(hour: 8), endTime: makeDate(hour: 9), durationMinutes: 60, startLocation: .buiten, endLocation: .buiten),
            PottyGap(startTime: makeDate(hour: 9), endTime: makeDate(hour: 10), durationMinutes: 60, startLocation: .buiten, endLocation: .binnen),
            PottyGap(startTime: makeDate(hour: 10), endTime: makeDate(hour: 11), durationMinutes: 60, startLocation: .binnen, endLocation: .buiten)
        ]
        let stats = GapCalculations.calculateGapStats(gaps: gaps)

        XCTAssertEqual(stats.outdoorCount, 2)
        XCTAssertEqual(stats.indoorCount, 1)
    }

    // MARK: - GapStats Computed Properties Tests

    func testGapStats_OutdoorPercentage() {
        let stats = GapStats(
            count: 10,
            minMinutes: 60,
            maxMinutes: 180,
            avgMinutes: 120,
            medianMinutes: 120,
            outdoorCount: 8,
            indoorCount: 2
        )
        XCTAssertEqual(stats.outdoorPercentage, 80)
    }

    func testGapStats_OutdoorPercentage_ZeroCount() {
        XCTAssertEqual(GapStats.empty.outdoorPercentage, 0)
    }

    // MARK: - formatDuration Tests

    func testFormatDuration_Minutes() {
        let result = GapCalculations.formatDuration(45)
        // Should contain "45" and some time unit indicator
        XCTAssertTrue(result.contains("45"), "Duration should contain 45")
    }

    func testFormatDuration_Hours() {
        let result = GapCalculations.formatDuration(120)
        // Should contain "2" and some hour indicator
        XCTAssertTrue(result.contains("2"), "Duration should contain 2")
    }

    func testFormatDuration_HoursAndMinutes() {
        let result = GapCalculations.formatDuration(150)
        // Should contain "2" (hours) and "30" (minutes)
        XCTAssertTrue(result.contains("2"), "Duration should contain hours component")
        XCTAssertTrue(result.contains("30"), "Duration should contain minutes component")
    }
}
