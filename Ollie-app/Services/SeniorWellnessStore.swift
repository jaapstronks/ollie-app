//
//  SeniorWellnessStore.swift
//  Ollie-app
//
//  Manages senior dog wellness data: mobility assessments, cognitive screenings,
//  quality of life assessments, and respiratory rate readings.
//  Part of Brief 05: Senior Wellness
//

import Combine
import Foundation
import SwiftUI
import OtisShared

// MARK: - Senior Wellness Store

@MainActor
final class SeniorWellnessStore: ObservableObject {
    static let shared = SeniorWellnessStore()

    // MARK: - Published State

    @Published private(set) var mobilityAssessments: [MobilityAssessment] = []
    @Published private(set) var cognitiveAssessments: [CognitiveAssessment] = []
    @Published private(set) var qualityOfLifeAssessments: [QualityOfLifeAssessment] = []
    @Published private(set) var respiratoryReadings: [RespiratoryRateReading] = []

    // MARK: - Storage

    private let storageURL: URL
    private let calendar = Calendar.current

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.storageURL = documentsPath.appendingPathComponent("senior_wellness.json")
        load()
    }

    // MARK: - Mobility State

    /// Current mobility state for AI context
    var mobilityState: MobilityState {
        let latest = latestMobility
        let trend = calculateMobilityTrend()
        let weekAssessments = mobilityAssessmentsThisWeek()
        let avgScore = weekAssessments.isEmpty ? nil : Double(weekAssessments.reduce(0) { $0 + $1.score }) / Double(weekAssessments.count)
        let stiffMornings = weekAssessments.filter { $0.observations.contains(.stiffAfterRest) }.count

        return MobilityState(
            latestAssessment: latest,
            trend: trend,
            averageScore: avgScore,
            assessmentCount: mobilityAssessments.count,
            stiffMorningsThisWeek: stiffMornings
        )
    }

    var latestMobility: MobilityAssessment? {
        mobilityAssessments.first
    }

    func mobilityAssessmentsThisWeek() -> [MobilityAssessment] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return mobilityAssessments.filter { $0.createdAt >= startOfWeek }
    }

    private func calculateMobilityTrend() -> MobilityTrend? {
        guard mobilityAssessments.count >= 3 else { return nil }

        let recentThree = Array(mobilityAssessments.prefix(3))
        let recentAvg = Double(recentThree.reduce(0) { $0 + $1.score }) / 3.0

        guard mobilityAssessments.count >= 6 else {
            // Compare to first assessments
            let first = mobilityAssessments.last!
            let diff = recentAvg - Double(first.score)
            return diff > 0.5 ? .improving : (diff < -0.5 ? .declining : .stable)
        }

        let olderThree = Array(mobilityAssessments[3..<6])
        let olderAvg = Double(olderThree.reduce(0) { $0 + $1.score }) / 3.0

        let diff = recentAvg - olderAvg
        return diff > 0.5 ? .improving : (diff < -0.5 ? .declining : .stable)
    }

    // MARK: - Cognitive State

    /// Current cognitive state for AI context
    var cognitiveState: CognitiveState {
        let latest = latestCognitive
        let months = latest.map { $0.monthsAgo }

        return CognitiveState(
            latestAssessment: latest,
            severity: latest?.severity,
            assessmentCount: cognitiveAssessments.count,
            monthsSinceLastAssessment: months
        )
    }

    var latestCognitive: CognitiveAssessment? {
        cognitiveAssessments.first
    }

    /// Whether a cognitive assessment is due (monthly for seniors)
    var cognitiveAssessmentDue: Bool {
        guard let latest = latestCognitive else { return true }
        return latest.monthsAgo >= 1
    }

    // MARK: - Quality of Life State

    /// Current QoL state for AI context
    var qolState: QoLState {
        let latest = latestQoL
        let days = latest.map { $0.daysAgo }

        return QoLState(
            latestAssessment: latest,
            interpretation: latest?.interpretation,
            assessmentCount: qualityOfLifeAssessments.count,
            daysSinceLastAssessment: days
        )
    }

    var latestQoL: QualityOfLifeAssessment? {
        qualityOfLifeAssessments.first
    }

    /// Whether a QoL assessment is due (monthly, or more frequently for compromised)
    var qolAssessmentDue: Bool {
        guard let latest = latestQoL else { return true }
        let threshold = latest.interpretation == .compromised || latest.interpretation == .poor ? 14 : 30
        return latest.daysAgo >= threshold
    }

    // MARK: - Respiratory Rate State

    /// Current RRR state for AI context
    /// - Parameter activeConditions: The dog's active health conditions (pass from profile)
    func rrrState(activeConditions: [HealthCondition] = []) -> RRRState {
        let latest = latestRRR
        let trend = calculateRRRTrend()
        let weekReadings = rrrReadingsThisWeek()
        let avgBPM = weekReadings.isEmpty ? nil : Double(weekReadings.reduce(0) { $0 + $1.breathsPerMinute }) / Double(weekReadings.count)
        let elevatedCount = weekReadings.filter { $0.isConcerning }.count
        let hasHeartCondition = activeConditions.contains { condition in
            [.heartMurmur, .congestiveHeartFailure].contains(condition.type)
        }

        return RRRState(
            latestReading: latest,
            trend: trend,
            averageBPM: avgBPM,
            readingCount: respiratoryReadings.count,
            elevatedReadingsThisWeek: elevatedCount,
            hasHeartCondition: hasHeartCondition
        )
    }

    var latestRRR: RespiratoryRateReading? {
        respiratoryReadings.first
    }

    func rrrReadingsThisWeek() -> [RespiratoryRateReading] {
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return respiratoryReadings.filter { $0.createdAt >= startOfWeek }
    }

    private func calculateRRRTrend() -> RRRTrend? {
        guard respiratoryReadings.count >= 3 else { return nil }

        let recentThree = Array(respiratoryReadings.prefix(3))
        let recentAvg = Double(recentThree.reduce(0) { $0 + $1.breathsPerMinute }) / 3.0

        guard respiratoryReadings.count >= 6 else {
            let first = respiratoryReadings.last!
            let diff = recentAvg - Double(first.breathsPerMinute)
            return diff > 2 ? .increasing : (diff < -2 ? .decreasing : .stable)
        }

        let olderThree = Array(respiratoryReadings[3..<6])
        let olderAvg = Double(olderThree.reduce(0) { $0 + $1.breathsPerMinute }) / 3.0

        let diff = recentAvg - olderAvg
        return diff > 2 ? .increasing : (diff < -2 ? .decreasing : .stable)
    }

    // MARK: - Recording Methods

    /// Record a mobility assessment
    func recordMobility(score: Int, observations: [MobilityObservation] = [], note: String? = nil) {
        let assessment = MobilityAssessment(
            score: score,
            observations: observations,
            note: note
        )
        mobilityAssessments.insert(assessment, at: 0)
        save()
    }

    /// Record a cognitive assessment
    func recordCognitive(symptoms: Set<CCDSymptom>, note: String? = nil) {
        let assessment = CognitiveAssessment(
            symptoms: symptoms,
            note: note
        )
        cognitiveAssessments.insert(assessment, at: 0)
        save()
    }

    /// Record a quality of life assessment
    func recordQoL(
        hurt: Int,
        hunger: Int,
        hydration: Int,
        hygiene: Int,
        happiness: Int,
        mobility: Int,
        moreDays: Int,
        note: String? = nil
    ) {
        let assessment = QualityOfLifeAssessment(
            hurt: hurt,
            hunger: hunger,
            hydration: hydration,
            hygiene: hygiene,
            happiness: happiness,
            mobility: mobility,
            moreDays: moreDays,
            note: note
        )
        qualityOfLifeAssessments.insert(assessment, at: 0)
        save()
    }

    /// Record a respiratory rate reading
    func recordRRR(breathsPerMinute: Int, wasResting: Bool = true, note: String? = nil) {
        let reading = RespiratoryRateReading(
            breathsPerMinute: breathsPerMinute,
            wasResting: wasResting,
            note: note
        )
        respiratoryReadings.insert(reading, at: 0)
        save()
    }

    /// Record a respiratory rate reading from 30-second count
    func recordRRRFromHalfMinute(breaths: Int, wasResting: Bool = true, note: String? = nil) {
        let reading = RespiratoryRateReading.fromHalfMinuteCount(
            breaths,
            wasResting: wasResting,
            note: note
        )
        respiratoryReadings.insert(reading, at: 0)
        save()
    }

    // MARK: - History

    /// Get mobility assessments for a date range
    func mobilityHistory(days: Int) -> [MobilityAssessment] {
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return mobilityAssessments.filter { $0.createdAt >= startDate }
    }

    /// Get cognitive assessments for a date range
    func cognitiveHistory(months: Int) -> [CognitiveAssessment] {
        let startDate = calendar.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        return cognitiveAssessments.filter { $0.createdAt >= startDate }
    }

    /// Get QoL assessments for a date range
    func qolHistory(months: Int) -> [QualityOfLifeAssessment] {
        let startDate = calendar.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        return qualityOfLifeAssessments.filter { $0.createdAt >= startDate }
    }

    /// Get RRR readings for a date range
    func rrrHistory(days: Int) -> [RespiratoryRateReading] {
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return respiratoryReadings.filter { $0.createdAt >= startDate }
    }

    // MARK: - AI Context

    /// Generate context summary for AI
    func contextSummary(puppyName: String) -> String {
        var parts: [String] = []

        // Mobility
        if let latest = latestMobility, latest.isFresh {
            let trend = mobilityState.trend?.label ?? "unknown"
            parts.append("Mobility: \(latest.scoreDescription) (trend: \(trend))")
            if !latest.observations.isEmpty {
                let observations = latest.observations.prefix(2).map(\.label).joined(separator: ", ")
                parts.append("Recent observations: \(observations)")
            }
        }

        // Cognitive
        if let latest = latestCognitive, latest.isCurrent {
            parts.append("Cognitive: \(latest.severity.label) (\(latest.totalScore)/\(CognitiveAssessment.maxScore) symptoms)")
        }

        // QoL
        if let latest = latestQoL, latest.isCurrent {
            parts.append("Quality of Life: \(latest.interpretation.label) (\(latest.totalScore)/\(QualityOfLifeAssessment.maxScore))")
            if !latest.concerningCategories.isEmpty {
                let concerns = latest.concerningCategories.prefix(2).map(\.label).joined(separator: ", ")
                parts.append("QoL concerns: \(concerns)")
            }
        }

        // RRR
        if let latest = latestRRR, latest.isRecent {
            parts.append("Resting respiratory rate: \(latest.formattedBPM) (\(latest.status.label))")
        }

        return parts.isEmpty ? "No recent senior wellness data" : parts.joined(separator: ". ")
    }

    // MARK: - Dashboard Helpers

    /// Whether to show senior wellness features (senior phase or has relevant conditions)
    /// - Parameter profile: The puppy profile to check
    func shouldShowSeniorFeatures(for profile: PuppyProfile?) -> Bool {
        guard let profile = profile else { return false }
        if profile.lifecyclePhase == .senior { return true }

        // Also show for certain age-related conditions in adults
        let seniorConditions: Set<HealthConditionType> = [
            .arthritis, .hipDysplasia, .canineCognitiveDysfunction,
            .heartMurmur, .congestiveHeartFailure
        ]
        return profile.healthConditions.contains { condition in
            condition.status == .active && seniorConditions.contains(condition.type)
        }
    }

    /// Whether to show RRR tracking (heart conditions)
    /// - Parameter activeConditions: The dog's active health conditions
    func shouldShowRRRTracking(activeConditions: [HealthCondition]) -> Bool {
        let heartConditions: Set<HealthConditionType> = [
            .heartMurmur, .congestiveHeartFailure
        ]
        return activeConditions.contains { condition in
            heartConditions.contains(condition.type)
        }
    }

    // MARK: - Persistence

    private struct StorageModel: Codable {
        let mobilityAssessments: [MobilityAssessment]
        let cognitiveAssessments: [CognitiveAssessment]
        let qualityOfLifeAssessments: [QualityOfLifeAssessment]
        let respiratoryReadings: [RespiratoryRateReading]
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let storage = try decoder.decode(StorageModel.self, from: data)

            self.mobilityAssessments = storage.mobilityAssessments.sorted { $0.createdAt > $1.createdAt }
            self.cognitiveAssessments = storage.cognitiveAssessments.sorted { $0.createdAt > $1.createdAt }
            self.qualityOfLifeAssessments = storage.qualityOfLifeAssessments.sorted { $0.createdAt > $1.createdAt }
            self.respiratoryReadings = storage.respiratoryReadings.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("Failed to load senior wellness data: \(error)")
        }
    }

    private func save() {
        do {
            let storage = StorageModel(
                mobilityAssessments: mobilityAssessments,
                cognitiveAssessments: cognitiveAssessments,
                qualityOfLifeAssessments: qualityOfLifeAssessments,
                respiratoryReadings: respiratoryReadings
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(storage)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save senior wellness data: \(error)")
        }
    }

    /// Clear all data (for testing)
    func clearAll() {
        mobilityAssessments.removeAll()
        cognitiveAssessments.removeAll()
        qualityOfLifeAssessments.removeAll()
        respiratoryReadings.removeAll()
        save()
    }
}
