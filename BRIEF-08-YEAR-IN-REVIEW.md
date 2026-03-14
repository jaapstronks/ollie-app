# Brief 08: Year in Review

> **Status:** Ready for Implementation
> **Priority:** Medium (High for January retention)
> **Dependencies:** None
> **Estimated Effort:** Medium

## Objective

Build an annual recap feature that summarizes the year with a dog, creating a shareable memory that reinforces the app's value and drives January subscription renewals.

## Features

### 1. Year in Review Summary

Comprehensive annual statistics:

```
┌─────────────────────────────────────┐
│         2025 with Luna              │
│         🐕                          │
├─────────────────────────────────────┤
│                                     │
│  A YEAR OF ADVENTURES               │
│                                     │
│  🚶 365 walks                       │
│     ~520 hours of adventure         │
│                                     │
│  📸 127 moments captured            │
│                                     │
│  🐕 45 social interactions          │
│     Favorite friend: Max            │
│                                     │
│  🎓 12 skills practiced             │
│     Proudest: Reliable recall       │
│                                     │
│  🦴 1,095 meals                     │
│     Favorite time: Dinner           │
│                                     │
│  😴 ~2,500 hours of sleep           │
│                                     │
│  💪 Started at 8 weeks              │
│     Now: 1 year old!                │
│                                     │
│  [ View Full Recap ]                │
│  [ Create Memory Book ]             │
│  [ Share ]                          │
│                                     │
└─────────────────────────────────────┘
```

### 2. Monthly Highlight Reel

Scrollable highlights by month:

```
┌─────────────────────────────────────┐
│  JANUARY                            │
│  ┌─────┐ ┌─────┐ ┌─────┐            │
│  │ 📷  │ │ 📷  │ │ 📷  │            │
│  └─────┘ └─────┘ └─────┘            │
│  First snow day! Luna loved it.     │
├─────────────────────────────────────┤
│  FEBRUARY                           │
│  ┌─────┐ ┌─────┐                    │
│  │ 📷  │ │ 📷  │                    │
│  └─────┘ └─────┘                    │
│  Valentine's Day photo shoot        │
├─────────────────────────────────────┤
│  MARCH                              │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ 📷  │ │ 📷  │ │ 📷  │ │ 📷  │   │
│  └─────┘ └─────┘ └─────┘ └─────┘   │
│  🏆 First beach trip!               │
│  First successful recall outdoors   │
└─────────────────────────────────────┘
```

### 3. Growth Journey

Visual growth representation:

```
┌─────────────────────────────────────┐
│  Luna's Growth Journey              │
├─────────────────────────────────────┤
│                                     │
│  WEIGHT                             │
│  Jan: 3.2 kg ───────○               │
│  Mar: 8.5 kg ──────────○            │
│  Jun: 18.2 kg ──────────────○       │
│  Sep: 24.1 kg ───────────────○      │
│  Dec: 26.8 kg ────────────────○     │
│                                     │
│  DEVELOPMENT PHASES                 │
│  ├─ Puppy (Jan-Aug)                 │
│  │  • Socialization complete        │
│  │  • House trained                 │
│  │  • Basic commands learned        │
│  └─ Teenage (Sep-Dec)               │
│     • Advanced training started     │
│     • Off-leash reliability         │
│                                     │
└─────────────────────────────────────┘
```

### 4. Top Moments

AI-selected or user-favorited highlights:

```
┌─────────────────────────────────────┐
│  Top Moments of 2025                │
├─────────────────────────────────────┤
│                                     │
│  🏆 BIGGEST MILESTONE               │
│  ┌───────────────────┐              │
│  │                   │              │
│  │      [Photo]      │              │
│  │                   │              │
│  └───────────────────┘              │
│  First off-leash adventure          │
│  October 15, 2025                   │
│                                     │
│  ❤️ MOST LOGGED                     │
│  Park walks - 156 times             │
│                                     │
│  🐕 BEST FRIEND                     │
│  Max the Labrador - 23 meetups      │
│                                     │
│  📍 FAVORITE SPOT                   │
│  Vondelpark - 89 visits             │
│                                     │
└─────────────────────────────────────┘
```

### 5. Shareable Year Card

Instagram-ready summary card:

```
┌─────────────────────────────────────┐
│  ╔═══════════════════════════════╗  │
│  ║       2025 with Luna          ║  │
│  ║                               ║  │
│  ║    ┌─────────────────┐        ║  │
│  ║    │                 │        ║  │
│  ║    │   [Best Photo]  │        ║  │
│  ║    │                 │        ║  │
│  ║    └─────────────────┘        ║  │
│  ║                               ║  │
│  ║   365 walks 🚶                ║  │
│  ║   127 moments 📸              ║  │
│  ║   12 skills 🎓                ║  │
│  ║                               ║  │
│  ║   Started: 8 weeks old        ║  │
│  ║   Now: 1 year old! 🎂         ║  │
│  ║                               ║  │
│  ║   Made with Ollie 🐕          ║  │
│  ╚═══════════════════════════════╝  │
│                                     │
│  [ Download ] [ Share ]             │
└─────────────────────────────────────┘
```

### 6. Printable Memory Book

Generate PDF memory book:

```
PAGE 1: Title page with best photo
PAGE 2: Year statistics overview
PAGE 3-14: Monthly highlights (1 per month)
PAGE 15: Growth journey
PAGE 16: Top moments
PAGE 17: Looking ahead to next year
```

## Models

### YearRecap

```swift
// OtisShared/Sources/OtisShared/Models/YearRecap.swift

public struct YearRecap: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public let year: Int
    public var stats: YearStats
    public var monthlyHighlights: [MonthHighlight]
    public var topMoments: [TopMoment]
    public var growthJourney: GrowthJourney
    public var generatedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case year
        case stats
        case monthlyHighlights = "monthly_highlights"
        case topMoments = "top_moments"
        case growthJourney = "growth_journey"
        case generatedAt = "generated_at"
    }

    public init(year: Int) {
        self.id = UUID()
        self.year = year
        self.stats = YearStats()
        self.monthlyHighlights = []
        self.topMoments = []
        self.growthJourney = GrowthJourney()
        self.generatedAt = Date()
    }
}

public struct YearStats: Codable, Sendable, Hashable {
    public var totalWalks: Int
    public var totalWalkMinutes: Int
    public var totalMoments: Int
    public var totalSocialInteractions: Int
    public var totalTrainingSessions: Int
    public var totalMeals: Int
    public var totalSleepMinutes: Int
    public var skillsLearned: Int
    public var favoriteFriend: String?
    public var favoriteSpot: String?
    public var mostLoggedActivity: String?
    public var daysLogged: Int

    public enum CodingKeys: String, CodingKey {
        case totalWalks = "total_walks"
        case totalWalkMinutes = "total_walk_minutes"
        case totalMoments = "total_moments"
        case totalSocialInteractions = "total_social_interactions"
        case totalTrainingSessions = "total_training_sessions"
        case totalMeals = "total_meals"
        case totalSleepMinutes = "total_sleep_minutes"
        case skillsLearned = "skills_learned"
        case favoriteFriend = "favorite_friend"
        case favoriteSpot = "favorite_spot"
        case mostLoggedActivity = "most_logged_activity"
        case daysLogged = "days_logged"
    }

    public init() {
        self.totalWalks = 0
        self.totalWalkMinutes = 0
        self.totalMoments = 0
        self.totalSocialInteractions = 0
        self.totalTrainingSessions = 0
        self.totalMeals = 0
        self.totalSleepMinutes = 0
        self.skillsLearned = 0
        self.favoriteFriend = nil
        self.favoriteSpot = nil
        self.mostLoggedActivity = nil
        self.daysLogged = 0
    }

    public var walkHours: Double {
        Double(totalWalkMinutes) / 60.0
    }

    public var sleepHours: Double {
        Double(totalSleepMinutes) / 60.0
    }
}

public struct MonthHighlight: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var month: Int  // 1-12
    public var photoIds: [UUID]
    public var caption: String?
    public var milestones: [String]
    public var walkCount: Int
    public var momentCount: Int

    public enum CodingKeys: String, CodingKey {
        case id
        case month
        case photoIds = "photo_ids"
        case caption
        case milestones
        case walkCount = "walk_count"
        case momentCount = "moment_count"
    }

    public init(
        id: UUID = UUID(),
        month: Int,
        photoIds: [UUID] = [],
        caption: String? = nil,
        milestones: [String] = [],
        walkCount: Int = 0,
        momentCount: Int = 0
    ) {
        self.id = id
        self.month = month
        self.photoIds = photoIds
        self.caption = caption
        self.milestones = milestones
        self.walkCount = walkCount
        self.momentCount = momentCount
    }
}

public struct TopMoment: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var category: TopMomentCategory
    public var title: String
    public var description: String
    public var photoId: UUID?
    public var date: Date?
    public var count: Int?

    public enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case description
        case photoId = "photo_id"
        case date
        case count
    }

    public init(
        id: UUID = UUID(),
        category: TopMomentCategory,
        title: String,
        description: String = "",
        photoId: UUID? = nil,
        date: Date? = nil,
        count: Int? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.photoId = photoId
        self.date = date
        self.count = count
    }
}

public enum TopMomentCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case biggestMilestone = "biggest_milestone"
    case mostLogged = "most_logged"
    case bestFriend = "best_friend"
    case favoriteSpot = "favorite_spot"
    case funniestMoment = "funniest_moment"
    case proudestAchievement = "proudest_achievement"

    public var id: String { rawValue }
}

public struct GrowthJourney: Codable, Sendable, Hashable {
    public var weightMeasurements: [MonthWeight]
    public var phasesCompleted: [PhaseCompletion]
    public var startAge: String?
    public var currentAge: String?

    public enum CodingKeys: String, CodingKey {
        case weightMeasurements = "weight_measurements"
        case phasesCompleted = "phases_completed"
        case startAge = "start_age"
        case currentAge = "current_age"
    }

    public init() {
        self.weightMeasurements = []
        self.phasesCompleted = []
        self.startAge = nil
        self.currentAge = nil
    }
}

public struct MonthWeight: Codable, Sendable, Hashable {
    public let month: Int
    public let weightKg: Double

    public enum CodingKeys: String, CodingKey {
        case month
        case weightKg = "weight_kg"
    }

    public init(month: Int, weightKg: Double) {
        self.month = month
        self.weightKg = weightKg
    }
}

public struct PhaseCompletion: Codable, Sendable, Hashable {
    public var phase: String
    public var startMonth: Int
    public var endMonth: Int?
    public var achievements: [String]

    public enum CodingKeys: String, CodingKey {
        case phase
        case startMonth = "start_month"
        case endMonth = "end_month"
        case achievements
    }

    public init(phase: String, startMonth: Int, endMonth: Int? = nil, achievements: [String] = []) {
        self.phase = phase
        self.startMonth = startMonth
        self.endMonth = endMonth
        self.achievements = achievements
    }
}
```

## Implementation

### Files to Create

```
OtisShared/Sources/OtisShared/Models/
├── YearRecap.swift

OtisShared/Sources/OtisShared/Calculations/
├── YearCalculations.swift  (extends existing pattern from MonthCalculations.swift)

Ollie-app/ViewModels/
├── YearRecapViewModel.swift

Ollie-app/Views/Recap/
├── YearRecapView.swift           (main view)
├── YearRecapTeaseCard.swift      (timeline card)
├── YearRecapShareView.swift      (shareable image generator)
├── YearHighlightsView.swift      (monthly highlights section)
├── YearGrowthView.swift          (growth journey section)
├── YearTopMomentsView.swift      (top moments section)
├── MemoryBookGenerator.swift     (PDF generation)
```

Note: `Ollie-app/Views/Recap/` folder already exists with `MonthRecapTeaseCard.swift`. Extend this folder.

### Files to Modify

```
Ollie-app/Views/Timeline/TodayView.swift
  - Add YearRecapTeaseCard (show in December-January)

Ollie-app/Views/Settings/SettingsView.swift
  - Add link to Year in Review

Ollie-app/Utils/Strings/Strings+Recap.swift
  - Add year recap strings (extend existing file)

Recap.xcstrings
  - Add year recap translations (extend existing catalog)
```

### Year Calculations

```swift
// OtisShared/Sources/OtisShared/Calculations/YearCalculations.swift

import Foundation

public struct YearCalculations {
    public static func generateRecap(
        year: Int,
        events: [PuppyEvent],
        profile: PuppyProfile,
        weightMeasurements: [WeightMeasurement]
    ) -> YearRecap {
        var recap = YearRecap(year: year)

        // Filter events to this year
        let yearEvents = events.filter {
            Calendar.current.component(.year, from: $0.time) == year
        }

        // Calculate stats
        recap.stats = calculateStats(from: yearEvents)

        // Generate monthly highlights
        recap.monthlyHighlights = generateMonthlyHighlights(events: yearEvents)

        // Identify top moments
        recap.topMoments = identifyTopMoments(events: yearEvents, profile: profile)

        // Build growth journey
        recap.growthJourney = buildGrowthJourney(
            weightMeasurements: weightMeasurements,
            profile: profile,
            year: year
        )

        return recap
    }

    private static func calculateStats(from events: [PuppyEvent]) -> YearStats {
        var stats = YearStats()

        // Count by type
        for event in events {
            switch event.type {
            case .uitlaten:
                stats.totalWalks += 1
                stats.totalWalkMinutes += event.durationMin ?? 30
            case .moment:
                stats.totalMoments += 1
            case .sociaal:
                stats.totalSocialInteractions += 1
            case .training:
                stats.totalTrainingSessions += 1
            case .eten:
                stats.totalMeals += 1
            case .slapen:
                stats.totalSleepMinutes += event.durationMin ?? 0
            default:
                break
            }
        }

        // Find favorite friend (most frequent "who")
        let socialEvents = events.filter { $0.type == .sociaal }
        let friendCounts = Dictionary(grouping: socialEvents) { $0.who ?? "Unknown" }
            .mapValues { $0.count }
        stats.favoriteFriend = friendCounts.max(by: { $0.value < $1.value })?.key

        // Find favorite spot (most frequent location note in walks)
        let walkEvents = events.filter { $0.type == .uitlaten && $0.note != nil }
        let spotCounts = Dictionary(grouping: walkEvents) { $0.note ?? "" }
            .mapValues { $0.count }
        stats.favoriteSpot = spotCounts.max(by: { $0.value < $1.value })?.key

        // Count unique days with events
        let uniqueDays = Set(events.map {
            Calendar.current.startOfDay(for: $0.time)
        })
        stats.daysLogged = uniqueDays.count

        // Most logged activity type
        let typeCounts = Dictionary(grouping: events) { $0.type }.mapValues { $0.count }
        if let mostLogged = typeCounts.max(by: { $0.value < $1.value }) {
            stats.mostLoggedActivity = mostLogged.key.rawValue
        }

        return stats
    }

    private static func generateMonthlyHighlights(events: [PuppyEvent]) -> [MonthHighlight] {
        (1...12).map { month in
            let monthEvents = events.filter {
                Calendar.current.component(.month, from: $0.time) == month
            }

            // Get events with photos
            let eventsWithPhotos = monthEvents.filter { $0.photo != nil }
            let photoIds = eventsWithPhotos.prefix(4).compactMap { event -> UUID? in
                // Extract photo ID from event if available
                guard let photoUrlString = event.photo,
                      let photoUrl = URL(string: photoUrlString),
                      let idString = photoUrl.lastPathComponent.components(separatedBy: ".").first,
                      let id = UUID(uuidString: idString) else {
                    return nil
                }
                return id
            }

            // Find milestones
            let milestoneEvents = monthEvents.filter { $0.type == .milestone }
            let milestones = milestoneEvents.compactMap { $0.note }

            return MonthHighlight(
                month: month,
                photoIds: Array(photoIds),
                caption: generateMonthCaption(events: monthEvents),
                milestones: milestones,
                walkCount: monthEvents.filter { $0.type == .uitlaten }.count,
                momentCount: eventsWithPhotos.count
            )
        }
    }

    private static func generateMonthCaption(events: [PuppyEvent]) -> String? {
        // Find milestone or notable event for caption
        if let milestone = events.first(where: { $0.type == .milestone }) {
            return milestone.note
        }
        // Or find first event with a note
        if let notable = events.first(where: { $0.note != nil && !$0.note!.isEmpty }) {
            return notable.note
        }
        return nil
    }

    private static func identifyTopMoments(
        events: [PuppyEvent],
        profile: PuppyProfile
    ) -> [TopMoment] {
        var moments: [TopMoment] = []

        // Biggest milestone (from milestone events)
        let milestoneEvents = events.filter { $0.type == .milestone }
        if let milestone = milestoneEvents.first {
            moments.append(TopMoment(
                category: .biggestMilestone,
                title: milestone.note ?? "Milestone",
                description: "",
                date: milestone.time
            ))
        }

        // Most logged activity
        let typeCounts = Dictionary(grouping: events) { $0.type }.mapValues { $0.count }
        if let mostLogged = typeCounts.max(by: { $0.value < $1.value }) {
            moments.append(TopMoment(
                category: .mostLogged,
                title: mostLogged.key.rawValue,
                description: "\(mostLogged.value) times",
                count: mostLogged.value
            ))
        }

        // Best friend
        let socialEvents = events.filter { $0.type == .sociaal && $0.who != nil }
        let friendCounts = Dictionary(grouping: socialEvents) { $0.who! }
            .mapValues { $0.count }
        if let bestFriend = friendCounts.max(by: { $0.value < $1.value }) {
            moments.append(TopMoment(
                category: .bestFriend,
                title: bestFriend.key,
                description: "\(bestFriend.value) meetups",
                count: bestFriend.value
            ))
        }

        // Favorite spot
        let walkEvents = events.filter { $0.type == .uitlaten && $0.note != nil && !$0.note!.isEmpty }
        let spotCounts = Dictionary(grouping: walkEvents) { $0.note! }
            .mapValues { $0.count }
        if let favoriteSpot = spotCounts.max(by: { $0.value < $1.value }) {
            moments.append(TopMoment(
                category: .favoriteSpot,
                title: favoriteSpot.key,
                description: "\(favoriteSpot.value) visits",
                count: favoriteSpot.value
            ))
        }

        return moments
    }

    private static func buildGrowthJourney(
        weightMeasurements: [WeightMeasurement],
        profile: PuppyProfile,
        year: Int
    ) -> GrowthJourney {
        var journey = GrowthJourney()

        // Filter weight measurements to this year and group by month
        let yearMeasurements = weightMeasurements.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }

        // Get last measurement per month
        let byMonth = Dictionary(grouping: yearMeasurements) {
            Calendar.current.component(.month, from: $0.date)
        }

        journey.weightMeasurements = byMonth.compactMap { month, measurements in
            guard let last = measurements.sorted(by: { $0.date < $1.date }).last else { return nil }
            return MonthWeight(month: month, weightKg: last.weightKg)
        }.sorted { $0.month < $1.month }

        // Calculate age at start and end of year
        let startOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        let endOfYear = Calendar.current.date(from: DateComponents(year: year, month: 12, day: 31)) ?? Date()

        let ageAtStart = Calendar.current.dateComponents([.month, .weekOfYear], from: profile.birthDate, to: startOfYear)
        let ageAtEnd = Calendar.current.dateComponents([.month, .year], from: profile.birthDate, to: endOfYear)

        if let weeks = ageAtStart.weekOfYear, weeks < 52 {
            journey.startAge = "\(weeks) weeks"
        } else if let months = ageAtStart.month {
            journey.startAge = "\(months) months"
        }

        if let years = ageAtEnd.year, years >= 1 {
            journey.currentAge = "\(years) year\(years > 1 ? "s" : "") old"
        } else if let months = ageAtEnd.month {
            journey.currentAge = "\(months) months old"
        }

        return journey
    }
}
```

### ViewModel

```swift
// Ollie-app/ViewModels/YearRecapViewModel.swift

import Foundation
import SwiftUI

@MainActor
final class YearRecapViewModel: ObservableObject {
    @Published private(set) var recap: YearRecap?
    @Published private(set) var isLoading = false
    @Published private(set) var coverPhoto: UIImage?

    private let eventStore: EventStore
    private let profileStore: ProfileStore
    private let weightStore: WeightStore

    init(
        eventStore: EventStore,
        profileStore: ProfileStore,
        weightStore: WeightStore
    ) {
        self.eventStore = eventStore
        self.profileStore = profileStore
        self.weightStore = weightStore
    }

    func generateRecap(for year: Int) async {
        guard let profile = profileStore.profile else { return }

        isLoading = true
        defer { isLoading = false }

        // Fetch all events for the year
        let events = eventStore.loadEventsForYear(year)
        let weights = weightStore.measurements.filter {
            Calendar.current.component(.year, from: $0.date) == year
        }

        recap = YearCalculations.generateRecap(
            year: year,
            events: events,
            profile: profile,
            weightMeasurements: weights
        )
    }

    var shouldShowRecapCard: Bool {
        let now = Date()
        let month = Calendar.current.component(.month, from: now)
        let day = Calendar.current.component(.day, from: now)

        // December 15-31 or January 1-15
        return (month == 12 && day >= 15) || (month == 1 && day <= 15)
    }

    var recapYear: Int {
        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let month = Calendar.current.component(.month, from: now)

        // In January, recap the previous year
        return month == 1 ? year - 1 : year
    }
}
```

### Shareable View

```swift
// Ollie-app/Views/Recap/YearRecapShareView.swift

import SwiftUI

struct YearRecapShareView: View {
    let recap: YearRecap
    let profile: PuppyProfile
    let coverPhoto: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text(Strings.Recap.yearTitle(year: recap.year, name: profile.name))
                .font(.title.bold())

            // Cover photo
            if let photo = coverPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Key stats
            VStack(alignment: .leading, spacing: 8) {
                StatRow(icon: "figure.walk", label: Strings.Recap.walks(recap.stats.totalWalks))
                StatRow(icon: "camera", label: Strings.Recap.momentsCaptured(recap.stats.totalMoments))
                StatRow(icon: "graduationcap", label: Strings.Recap.skillsLearned(recap.stats.skillsLearned))
            }

            // Age journey
            if let startAge = recap.growthJourney.startAge,
               let currentAge = recap.growthJourney.currentAge {
                Text(Strings.Recap.startedAt(startAge))
                Text(Strings.Recap.nowAge(currentAge))
            }

            // Branding
            HStack {
                Image("ollie-logo")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(Strings.Recap.madeWithOllie)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 1080, height: 1080)  // Instagram square
        .background(Color(.systemBackground))
    }
}

private struct StatRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            Text(label)
        }
    }
}
```

## Strings

Extend existing `Strings+Recap.swift`:

```swift
// Ollie-app/Utils/Strings/Strings+Recap.swift

private let table = "Recap"

extension Strings {
    enum Recap {
        // Existing month recap strings...

        // Year recap
        static func yearTitle(year: Int, name: String) -> String {
            String(localized: "\(year) with \(name)", table: table)
        }
        static let yearOfAdventures = String(localized: "A Year of Adventures", table: table)
        static let viewFullRecap = String(localized: "View Full Recap", table: table)
        static let createMemoryBook = String(localized: "Create Memory Book", table: table)
        static let share = String(localized: "Share", table: table)
        static let madeWithOllie = String(localized: "Made with Ollie", table: table)

        // Stats
        static func walks(_ count: Int) -> String {
            String(localized: "\(count) walks", table: table)
        }
        static func hoursOfAdventure(_ hours: Int) -> String {
            String(localized: "~\(hours) hours of adventure", table: table)
        }
        static func momentsCaptured(_ count: Int) -> String {
            String(localized: "\(count) moments captured", table: table)
        }
        static func socialInteractions(_ count: Int) -> String {
            String(localized: "\(count) social interactions", table: table)
        }
        static func favoriteFriend(_ name: String) -> String {
            String(localized: "Favorite friend: \(name)", table: table)
        }
        static func skillsLearned(_ count: Int) -> String {
            String(localized: "\(count) skills learned", table: table)
        }
        static func meals(_ count: Int) -> String {
            String(localized: "\(count) meals", table: table)
        }
        static func sleepHours(_ hours: Int) -> String {
            String(localized: "~\(hours) hours of sleep", table: table)
        }

        // Journey
        static let growthJourney = String(localized: "Growth Journey", table: table)
        static func startedAt(_ age: String) -> String {
            String(localized: "Started at \(age)", table: table)
        }
        static func nowAge(_ age: String) -> String {
            String(localized: "Now: \(age)!", table: table)
        }
        static let weight = String(localized: "Weight", table: table)
        static let developmentPhases = String(localized: "Development Phases", table: table)

        // Top Moments
        static let topMoments = String(localized: "Top Moments", table: table)
        static let biggestMilestone = String(localized: "Biggest Milestone", table: table)
        static let mostLogged = String(localized: "Most Logged", table: table)
        static let bestFriend = String(localized: "Best Friend", table: table)
        static let favoriteSpot = String(localized: "Favorite Spot", table: table)
        static func meetups(_ count: Int) -> String {
            String(localized: "\(count) meetups", table: table)
        }
        static func visits(_ count: Int) -> String {
            String(localized: "\(count) visits", table: table)
        }
        static func times(_ count: Int) -> String {
            String(localized: "\(count) times", table: table)
        }

        // Card
        static let yourYearIsReady = String(localized: "Your Year is Ready!", table: table)
        static func yearRecapAvailable(year: Int) -> String {
            String(localized: "Your \(year) recap is ready to view", table: table)
        }

        // Accessibility
        static func yearRecapCardAccessibility(year: Int, name: String) -> String {
            String(localized: "View your \(year) recap with \(name)", table: table)
        }
    }
}
```

Extend `Recap.xcstrings` catalog with translations for new strings.

## Testing

- [ ] Verify recap generates with correct year data
- [ ] Test monthly highlights pull correct photo IDs from events
- [ ] Verify stats calculations are accurate (walks, meals, sleep, etc.)
- [ ] Test share image renders correctly at 1080x1080
- [ ] Verify tease card shows in correct date range (Dec 15 - Jan 15)
- [ ] Test with partial year data (new users who joined mid-year)
- [ ] Verify PDF memory book generates (if implementing)
- [ ] Test favorite friend/spot calculation handles ties
- [ ] Verify growth journey shows correct ages

## Notes

- Critical for January subscription renewals - ship before December 15
- Consider push notification: "Your Year with {Name} is ready!"
- Allow users to edit/customize highlights before sharing
- Cache generated recap to avoid recalculating (store in UserDefaults or file)
- Support dogs that joined mid-year with adjusted messaging
- Consider multi-dog households (separate recaps per dog)
- Integrates with existing `MonthRecapViewModel` and `Recap/` folder structure
- Uses existing `PuppyEvent` model - no new `PhotoMoment` type needed
- Weight data comes from `WeightStore.measurements`
