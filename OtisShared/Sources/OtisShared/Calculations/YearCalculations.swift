//
//  YearCalculations.swift
//  OtisShared
//
//  Year in Review calculations - aggregates events into annual statistics

import Foundation

/// Utility for calculating year-end recap statistics
public struct YearCalculations {

    // MARK: - Main Entry Point

    /// Generate a complete year recap
    /// - Parameters:
    ///   - year: The year to generate the recap for
    ///   - events: All events (will be filtered to the year)
    ///   - puppyName: Name of the puppy
    ///   - weightMeasurements: Weight measurements for growth journey
    ///   - birthDate: Puppy's birth date for age calculations
    /// - Returns: Complete YearRecap
    public static func generateRecap(
        year: Int,
        events: [PuppyEvent],
        puppyName: String,
        weightMeasurements: [WeightMeasurement] = [],
        birthDate: Date? = nil
    ) -> YearRecap {
        // Filter events to the specified year
        let yearEvents = eventsInYear(year, from: events)

        // Calculate aggregated stats
        let stats = calculateStats(from: yearEvents)

        // Generate monthly highlights
        let monthHighlights = generateMonthlyHighlights(year: year, events: yearEvents)

        // Identify top moments
        let topMoments = identifyTopMoments(events: yearEvents, monthHighlights: monthHighlights)

        // Build growth journey
        let growthJourney = buildGrowthJourney(
            year: year,
            weightMeasurements: weightMeasurements,
            birthDate: birthDate
        )

        return YearRecap(
            year: year,
            puppyName: puppyName,
            stats: stats,
            monthHighlights: monthHighlights,
            topMoments: topMoments,
            growthJourney: growthJourney
        )
    }

    // MARK: - Year Filtering

    /// Filter events to a specific year
    public static func eventsInYear(_ year: Int, from events: [PuppyEvent]) -> [PuppyEvent] {
        let calendar = Calendar.current

        // Get year boundaries
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1
        guard let startOfYear = calendar.date(from: startComponents) else { return [] }

        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = 12
        endComponents.day = 31
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        guard let endOfYear = calendar.date(from: endComponents) else { return [] }

        return events.filter { event in
            event.time >= startOfYear && event.time <= endOfYear
        }
    }

    // MARK: - Stats Calculation

    /// Calculate aggregated statistics from events
    public static func calculateStats(from events: [PuppyEvent]) -> YearStats {
        var totalWalks = 0
        var totalWalkMinutes = 0
        var totalMeals = 0
        var totalSleepMinutes = 0
        var totalTrainingSessions = 0
        var totalSocialEvents = 0
        var totalPottyEvents = 0
        var outdoorPottyCount = 0
        var photoCount = 0
        var milestoneCount = 0
        var socialContacts = Set<String>()
        var daysWithEvents = Set<Date>()

        let calendar = Calendar.current

        for event in events {
            // Track unique days
            let dayStart = calendar.startOfDay(for: event.time)
            daysWithEvents.insert(dayStart)

            switch event.type {
            case .uitlaten:
                totalWalks += 1
                totalWalkMinutes += event.durationMin ?? 0
            case .eten:
                totalMeals += 1
            case .slapen:
                totalSleepMinutes += event.durationMin ?? 0
            case .training:
                totalTrainingSessions += 1
            case .sociaal:
                totalSocialEvents += 1
                if let who = event.who, !who.isEmpty {
                    socialContacts.insert(who.lowercased())
                }
            case .plassen, .poepen:
                totalPottyEvents += 1
                if event.location == .buiten {
                    outdoorPottyCount += 1
                }
            case .milestone:
                milestoneCount += 1
            default:
                break
            }

            if event.media.hasPhoto {
                photoCount += 1
            }
        }

        return YearStats(
            totalWalks: totalWalks,
            totalWalkMinutes: totalWalkMinutes,
            totalMeals: totalMeals,
            totalSleepHours: totalSleepMinutes / 60,
            totalTrainingSessions: totalTrainingSessions,
            totalSocialEvents: totalSocialEvents,
            totalPottyEvents: totalPottyEvents,
            outdoorPottyCount: outdoorPottyCount,
            photoCount: photoCount,
            milestoneCount: milestoneCount,
            uniqueSocialContacts: socialContacts.count,
            daysLogged: daysWithEvents.count
        )
    }

    // MARK: - Monthly Highlights

    /// Generate highlights for each month
    public static func generateMonthlyHighlights(year: Int, events: [PuppyEvent]) -> [MonthHighlight] {
        let calendar = Calendar.current
        var highlights: [MonthHighlight] = []

        for month in 1...12 {
            // Filter events for this month
            let monthEvents = events.filter { event in
                let components = calendar.dateComponents([.month], from: event.time)
                return components.month == month
            }

            // Collect photos
            let photoIds = monthEvents
                .compactMap { $0.photo }
                .prefix(6)
                .map { String($0) }

            // Collect milestones
            let milestones = monthEvents
                .filter { $0.type == .milestone }
                .compactMap { $0.note }

            // Count activities
            let walkCount = monthEvents.filter { $0.type == .uitlaten }.count
            let trainingCount = monthEvents.filter { $0.type == .training }.count
            let socialCount = monthEvents.filter { $0.type == .sociaal }.count

            // Generate caption based on activity
            let caption = generateMonthCaption(
                walkCount: walkCount,
                trainingCount: trainingCount,
                socialCount: socialCount,
                milestones: milestones
            )

            highlights.append(MonthHighlight(
                month: month,
                year: year,
                photoIds: Array(photoIds),
                caption: caption,
                milestones: milestones,
                walkCount: walkCount,
                trainingCount: trainingCount,
                socialCount: socialCount
            ))
        }

        return highlights
    }

    private static func generateMonthCaption(
        walkCount: Int,
        trainingCount: Int,
        socialCount: Int,
        milestones: [String]
    ) -> String? {
        // Prioritize milestones
        if let firstMilestone = milestones.first {
            return firstMilestone
        }

        // Generate summary if there's activity
        var parts: [String] = []
        if walkCount > 0 {
            parts.append("\(walkCount) walks")
        }
        if trainingCount > 0 {
            parts.append("\(trainingCount) training")
        }
        if socialCount > 0 {
            parts.append("\(socialCount) social")
        }

        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    // MARK: - Top Moments

    /// Identify the top moments of the year
    public static func identifyTopMoments(
        events: [PuppyEvent],
        monthHighlights: [MonthHighlight]
    ) -> [TopMoment] {
        var moments: [TopMoment] = []

        // Best Friend - most frequent social contact
        if let bestFriend = findBestFriend(from: events) {
            moments.append(bestFriend)
        }

        // Favorite Spot - most visited location
        if let favoriteSpot = findFavoriteSpot(from: events) {
            moments.append(favoriteSpot)
        }

        // Most Active Month
        if let activeMonth = findMostActiveMonth(from: monthHighlights) {
            moments.append(activeMonth)
        }

        // Biggest Milestone
        if let biggestMilestone = findBiggestMilestone(from: events) {
            moments.append(biggestMilestone)
        }

        return moments
    }

    private static func findBestFriend(from events: [PuppyEvent]) -> TopMoment? {
        let socialEvents = events.filter { $0.type == .sociaal }
        var contactCounts: [String: Int] = [:]

        for event in socialEvents {
            if let who = event.who, !who.isEmpty {
                let normalized = who.trimmingCharacters(in: .whitespaces)
                contactCounts[normalized, default: 0] += 1
            }
        }

        guard let (bestFriend, count) = contactCounts.max(by: { $0.value < $1.value }),
              count > 1 else { return nil }

        // Find a photo with this contact
        let photoPath = socialEvents
            .first { $0.who == bestFriend && $0.photo != nil }?
            .photo

        return TopMoment(
            category: .bestFriend,
            title: bestFriend,
            subtitle: "\(count) meetups",
            photoPath: photoPath,
            count: count
        )
    }

    private static func findFavoriteSpot(from events: [PuppyEvent]) -> TopMoment? {
        let walkEvents = events.filter { $0.type == .uitlaten }
        var spotCounts: [String: Int] = [:]

        for event in walkEvents {
            if let note = event.note, !note.isEmpty {
                // Extract location from note if possible
                let normalized = note.trimmingCharacters(in: .whitespaces)
                if normalized.count < 50 { // Likely a spot name, not a long note
                    spotCounts[normalized, default: 0] += 1
                }
            }
        }

        guard let (favoriteSpot, count) = spotCounts.max(by: { $0.value < $1.value }),
              count > 2 else { return nil }

        return TopMoment(
            category: .favoriteSpot,
            title: favoriteSpot,
            subtitle: "\(count) visits",
            count: count
        )
    }

    private static func findMostActiveMonth(from highlights: [MonthHighlight]) -> TopMoment? {
        let activeMonth = highlights
            .filter { $0.hasData }
            .max { a, b in
                let aTotal = a.walkCount + a.trainingCount + a.socialCount
                let bTotal = b.walkCount + b.trainingCount + b.socialCount
                return aTotal < bTotal
            }

        guard let month = activeMonth else { return nil }

        let total = month.walkCount + month.trainingCount + month.socialCount

        return TopMoment(
            category: .mostActiveMonth,
            title: month.monthName,
            subtitle: "\(total) activities",
            count: total
        )
    }

    private static func findBiggestMilestone(from events: [PuppyEvent]) -> TopMoment? {
        let milestones = events.filter { $0.type == .milestone }

        guard let firstMilestone = milestones.first else { return nil }

        return TopMoment(
            category: .biggestMilestone,
            title: firstMilestone.note ?? "Milestone achieved",
            subtitle: formatDate(firstMilestone.time),
            photoPath: firstMilestone.photo
        )
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Growth Journey

    /// Build growth journey from weight measurements
    public static func buildGrowthJourney(
        year: Int,
        weightMeasurements: [WeightMeasurement],
        birthDate: Date?
    ) -> GrowthJourney? {
        let calendar = Calendar.current

        // Filter measurements to the year
        let yearMeasurements = weightMeasurements.filter { measurement in
            let measurementYear = calendar.component(.year, from: measurement.date)
            return measurementYear == year
        }.sorted { $0.date < $1.date }

        guard !yearMeasurements.isEmpty else { return nil }

        // Get monthly snapshots (use last measurement of each month)
        var monthlyWeights: [MonthWeight] = []
        var measurementsByMonth: [Int: [WeightMeasurement]] = [:]

        for measurement in yearMeasurements {
            let month = calendar.component(.month, from: measurement.date)
            measurementsByMonth[month, default: []].append(measurement)
        }

        for month in 1...12 {
            if let monthMeasurements = measurementsByMonth[month],
               let lastMeasurement = monthMeasurements.last {
                let ageWeeks = birthDate.map { lastMeasurement.ageWeeks(birthDate: $0) }
                monthlyWeights.append(MonthWeight(
                    month: month,
                    weightKg: lastMeasurement.weightKg,
                    ageWeeks: ageWeeks
                ))
            }
        }

        // Calculate start/end weights and gain
        let startWeight = yearMeasurements.first?.weightKg
        let endWeight = yearMeasurements.last?.weightKg
        let totalGain: Double? = {
            guard let start = startWeight, let end = endWeight else { return nil }
            return end - start
        }()

        return GrowthJourney(
            monthlyWeights: monthlyWeights,
            startWeight: startWeight,
            endWeight: endWeight,
            totalGain: totalGain,
            phaseCompletions: []  // Phase completions would need profile data
        )
    }

    // MARK: - Photo Events

    /// Get events with photos for a specific year
    public static func photoEvents(for year: Int, from events: [PuppyEvent]) -> [PuppyEvent] {
        eventsInYear(year, from: events)
            .filter { $0.media.hasPhoto }
            .sorted { $0.time > $1.time }
    }

    // MARK: - Available Years

    /// Get years that have events
    public static func availableYears(from events: [PuppyEvent]) -> [Int] {
        let calendar = Calendar.current
        var years = Set<Int>()

        for event in events {
            let year = calendar.component(.year, from: event.time)
            years.insert(year)
        }

        return years.sorted(by: >)
    }
}
