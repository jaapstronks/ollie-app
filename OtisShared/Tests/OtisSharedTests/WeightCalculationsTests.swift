//
//  WeightCalculationsTests.swift
//  OtisSharedTests
//
//  Unit tests for weight and growth calculations

import XCTest
@testable import OtisShared

final class WeightCalculationsTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDate(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    }

    private func makeWeightMeasurement(daysAgo: Int, weightKg: Double) -> WeightMeasurement {
        WeightMeasurement(date: makeDate(daysAgo: daysAgo), weightKg: weightKg)
    }

    // MARK: - latestWeight Tests

    func testLatestWeight_EmptyMeasurements_ReturnsNil() {
        let result = WeightCalculations.latestWeight(from: [])
        XCTAssertNil(result)
    }

    func testLatestWeight_SingleMeasurement_ReturnsThat() {
        let measurements = [makeWeightMeasurement(daysAgo: 0, weightKg: 5.5)]

        let result = WeightCalculations.latestWeight(from: measurements)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.weight, 5.5)
    }

    func testLatestWeight_MultipleMeasurements_ReturnsMostRecent() {
        let measurements = [
            makeWeightMeasurement(daysAgo: 14, weightKg: 4.0),
            makeWeightMeasurement(daysAgo: 7, weightKg: 5.0),
            makeWeightMeasurement(daysAgo: 0, weightKg: 6.0)
        ]

        let result = WeightCalculations.latestWeight(from: measurements)

        XCTAssertEqual(result?.weight, 6.0)
    }

    // MARK: - weightDelta Tests

    func testWeightDelta_LessThanTwoMeasurements_ReturnsNil() {
        XCTAssertNil(WeightCalculations.weightDelta(from: []))
        XCTAssertNil(WeightCalculations.weightDelta(from: [makeWeightMeasurement(daysAgo: 0, weightKg: 5.0)]))
    }

    func testWeightDelta_TwoMeasurements_ReturnsCorrectDelta() {
        let measurements = [
            makeWeightMeasurement(daysAgo: 7, weightKg: 5.0),
            makeWeightMeasurement(daysAgo: 0, weightKg: 6.5)
        ]

        let result = WeightCalculations.weightDelta(from: measurements)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.delta, 1.5, accuracy: 0.01)
    }

    func testWeightDelta_NegativeDelta() {
        let measurements = [
            makeWeightMeasurement(daysAgo: 7, weightKg: 6.0),
            makeWeightMeasurement(daysAgo: 0, weightKg: 5.5)
        ]

        let result = WeightCalculations.weightDelta(from: measurements)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.delta, -0.5, accuracy: 0.01)
    }

    // MARK: - firstWeight Tests

    func testFirstWeight_EmptyMeasurements_ReturnsNil() {
        XCTAssertNil(WeightCalculations.firstWeight(from: []))
    }

    func testFirstWeight_ReturnOldest() {
        let measurements = [
            makeWeightMeasurement(daysAgo: 30, weightKg: 3.0),
            makeWeightMeasurement(daysAgo: 14, weightKg: 5.0),
            makeWeightMeasurement(daysAgo: 0, weightKg: 7.0)
        ]

        let result = WeightCalculations.firstWeight(from: measurements)

        XCTAssertEqual(result?.weight, 3.0)
    }

    // MARK: - growthStory Tests

    func testGrowthStory_LessThanTwoMeasurements_ReturnsNil() {
        let measurements = [makeWeightMeasurement(daysAgo: 0, weightKg: 5.0)]

        let result = WeightCalculations.growthStory(
            from: measurements,
            homeDate: makeDate(daysAgo: 30),
            sizeCategory: .medium
        )

        XCTAssertNil(result)
    }

    func testGrowthStory_ValidMeasurements_CalculatesCorrectly() {
        let measurements = [
            makeWeightMeasurement(daysAgo: 30, weightKg: 3.0),
            makeWeightMeasurement(daysAgo: 0, weightKg: 6.0)
        ]

        let result = WeightCalculations.growthStory(
            from: measurements,
            homeDate: makeDate(daysAgo: 30),
            sizeCategory: .medium
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result!.firstWeight, 3.0)
        XCTAssertEqual(result!.currentWeight, 6.0)
        XCTAssertEqual(result!.growthRatio, 2.0, accuracy: 0.01)
        XCTAssertEqual(result!.daysSinceFirst, 30)
    }

    func testGrowthStory_ZeroFirstWeight_ReturnsNil() {
        let measurements = [
            makeWeightMeasurement(daysAgo: 30, weightKg: 0.0),
            makeWeightMeasurement(daysAgo: 0, weightKg: 6.0)
        ]

        let result = WeightCalculations.growthStory(
            from: measurements,
            homeDate: makeDate(daysAgo: 30),
            sizeCategory: .medium
        )

        XCTAssertNil(result)
    }

    // MARK: - GrowthStory Properties Tests

    func testGrowthStory_FormattedMultiplier_RoundNumbers() {
        let story = GrowthStory(
            firstWeight: 3.0,
            firstWeightDate: makeDate(daysAgo: 30),
            currentWeight: 6.0,
            currentWeightDate: Date(),
            growthRatio: 2.0,
            estimatedAdultWeight: 25.0,
            percentToAdult: 24.0,
            daysSinceFirst: 30
        )

        XCTAssertEqual(story.formattedMultiplier, "2x")
    }

    func testGrowthStory_FormattedMultiplier_OnePointFive() {
        let story = GrowthStory(
            firstWeight: 4.0,
            firstWeightDate: makeDate(daysAgo: 30),
            currentWeight: 6.0,
            currentWeightDate: Date(),
            growthRatio: 1.5,
            estimatedAdultWeight: 25.0,
            percentToAdult: 24.0,
            daysSinceFirst: 30
        )

        XCTAssertEqual(story.formattedMultiplier, "1.5x")
    }

    func testGrowthStory_IsSignificant() {
        let significant = GrowthStory(
            firstWeight: 4.0, firstWeightDate: makeDate(daysAgo: 30),
            currentWeight: 5.0, currentWeightDate: Date(),
            growthRatio: 1.25, estimatedAdultWeight: 25.0,
            percentToAdult: 20.0, daysSinceFirst: 30
        )

        let notSignificant = GrowthStory(
            firstWeight: 4.0, firstWeightDate: makeDate(daysAgo: 30),
            currentWeight: 4.2, currentWeightDate: Date(),
            growthRatio: 1.05, estimatedAdultWeight: 25.0,
            percentToAdult: 16.8, daysSinceFirst: 30
        )

        XCTAssertTrue(significant.isSignificant)
        XCTAssertFalse(notSignificant.isSignificant)
    }

    // MARK: - interpolatedReferenceWeight Tests

    func testInterpolatedReferenceWeight_EmptyCurve_ReturnsZero() {
        let result = WeightCalculations.interpolatedReferenceWeight(at: 12, curve: [])
        XCTAssertEqual(result, 0)
    }

    func testInterpolatedReferenceWeight_BelowCurve_ReturnsFirst() {
        let curve = [
            GrowthReference(weeks: 8, kg: 2.0, label: "8 weeks"),
            GrowthReference(weeks: 12, kg: 4.0, label: "12 weeks")
        ]

        let result = WeightCalculations.interpolatedReferenceWeight(at: 4, curve: curve)
        XCTAssertEqual(result, 2.0)
    }

    func testInterpolatedReferenceWeight_AboveCurve_ReturnsLast() {
        let curve = [
            GrowthReference(weeks: 8, kg: 2.0, label: "8 weeks"),
            GrowthReference(weeks: 52, kg: 25.0, label: "12 months")
        ]

        let result = WeightCalculations.interpolatedReferenceWeight(at: 100, curve: curve)
        XCTAssertEqual(result, 25.0)
    }

    func testInterpolatedReferenceWeight_ExactMatch_ReturnsExact() {
        let curve = [
            GrowthReference(weeks: 8, kg: 2.0, label: "8 weeks"),
            GrowthReference(weeks: 12, kg: 4.0, label: "12 weeks"),
            GrowthReference(weeks: 16, kg: 6.0, label: "16 weeks")
        ]

        let result = WeightCalculations.interpolatedReferenceWeight(at: 12, curve: curve)
        XCTAssertEqual(result, 4.0)
    }

    func testInterpolatedReferenceWeight_Interpolates() {
        let curve = [
            GrowthReference(weeks: 8, kg: 2.0, label: "8 weeks"),
            GrowthReference(weeks: 12, kg: 4.0, label: "12 weeks")
        ]

        // At week 10, midway between 8 and 12
        let result = WeightCalculations.interpolatedReferenceWeight(at: 10, curve: curve)
        XCTAssertEqual(result, 3.0, accuracy: 0.01)
    }

    // MARK: - formatWeight Tests

    func testFormatWeight_SmallWeight_TwoDecimals() {
        XCTAssertEqual(WeightCalculations.formatWeight(5.55), "5.55 kg")
        XCTAssertEqual(WeightCalculations.formatWeight(9.99), "9.99 kg")
    }

    func testFormatWeight_LargeWeight_OneDecimal() {
        XCTAssertEqual(WeightCalculations.formatWeight(10.5), "10.5 kg")
        XCTAssertEqual(WeightCalculations.formatWeight(25.0), "25.0 kg")
    }

    // MARK: - formatDelta Tests

    func testFormatDelta_Positive() {
        XCTAssertEqual(WeightCalculations.formatDelta(0.5), "+0.50 kg")
    }

    func testFormatDelta_Negative() {
        XCTAssertEqual(WeightCalculations.formatDelta(-0.25), "-0.25 kg")
    }

    func testFormatDelta_Zero() {
        XCTAssertEqual(WeightCalculations.formatDelta(0.0), "+0.00 kg")
    }

    // MARK: - weighReminder Tests

    func testWeighReminder_NeverWeighed_HighUrgency() {
        let reminder = WeightCalculations.weighReminder(
            lastWeightDate: nil,
            ageInWeeks: 12
        )

        XCTAssertNotNil(reminder)
        XCTAssertEqual(reminder?.urgency, .high)
        XCTAssertNil(reminder?.daysSinceLastWeigh)
    }

    func testWeighReminder_RecentlyWeighed_ReturnsNil() {
        let reminder = WeightCalculations.weighReminder(
            lastWeightDate: Date(), // Weighed today
            ageInWeeks: 12
        )

        XCTAssertNil(reminder)
    }

    func testWeighReminder_OverdueYoungPuppy() {
        // Young puppy (< 12 weeks) should be weighed weekly
        let lastWeightDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())

        let reminder = WeightCalculations.weighReminder(
            lastWeightDate: lastWeightDate,
            ageInWeeks: 8
        )

        XCTAssertNotNil(reminder)
        XCTAssertEqual(reminder?.recommendedIntervalDays, 7)
    }

    func testWeighReminder_AdultDog_LongerInterval() {
        // Adult dog (52+ weeks) - every 2 months
        let lastWeightDate = Calendar.current.date(byAdding: .day, value: -65, to: Date())

        let reminder = WeightCalculations.weighReminder(
            lastWeightDate: lastWeightDate,
            ageInWeeks: 60
        )

        XCTAssertNotNil(reminder)
        XCTAssertEqual(reminder?.recommendedIntervalDays, 60)
    }

    // MARK: - referenceBand Tests

    func testReferenceBand_CalculatesToleranceBand() {
        let curve = [
            GrowthReference(weeks: 12, kg: 10.0, label: "12 weeks")
        ]

        let band = WeightCalculations.referenceBand(at: 12, curve: curve)

        // Default tolerance is 15%
        XCTAssertEqual(band.min, 8.5, accuracy: 0.1)
        XCTAssertEqual(band.max, 11.5, accuracy: 0.1)
    }
}
