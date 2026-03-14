# Brief 07: Adult Routines

> **Status:** Ready for Implementation
> **Priority:** Medium
> **Dependencies:** Brief 02 (Medication UI) - for scheduling patterns
> **Estimated Effort:** Medium

## Objective

Build routine and wellness features for adult dogs including daily routine tracking, weight goal management, body condition scoring, and grooming schedules.

## Features

### 1. Daily Routine Tracker

Configure and track daily routines:

```
┌─────────────────────────────────────┐
│  Luna's Daily Routine               │
├─────────────────────────────────────┤
│                                     │
│  MORNING                            │
│  ✓ 7:00 AM - Wake up & potty       │
│  ✓ 7:30 AM - Breakfast             │
│  ○ 8:00 AM - Morning walk          │
│                                     │
│  MIDDAY                             │
│  ○ 12:00 PM - Potty break          │
│  ○ 12:30 PM - Lunch                │
│                                     │
│  EVENING                            │
│  ○ 5:00 PM - Evening walk          │
│  ○ 6:00 PM - Dinner                │
│  ○ 9:00 PM - Final potty           │
│                                     │
│  Today: 3/8 completed              │
│  ▓▓▓░░░░░                          │
│                                     │
│  [ Edit Routine ]                   │
└─────────────────────────────────────┘
```

### 2. Weight Goal Tracking

Set and track weight goals:

```
┌─────────────────────────────────────┐
│  Weight Management                  │
├─────────────────────────────────────┤
│                                     │
│  Current: 32.5 kg                   │
│  Goal: 28.0 kg                      │
│  To lose: 4.5 kg                    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │     32 kg ─────●            │    │
│  │     30 kg ─────┼────        │    │
│  │     28 kg ─────┼───── Goal  │    │
│  │         Jan  Feb  Mar       │    │
│  └─────────────────────────────┘    │
│                                     │
│  Progress: 1.5 kg lost (33%)        │
│  Pace: On track                     │
│                                     │
│  💡 Tip: 1-2% body weight loss      │
│     per week is healthy             │
│                                     │
│  [ Log Weight ] [ Adjust Goal ]     │
└─────────────────────────────────────┘
```

### 3. Body Condition Score

9-point BCS scale assessment:

```
┌─────────────────────────────────────┐
│  Body Condition Score               │
├─────────────────────────────────────┤
│                                     │
│  Select Luna's current condition:   │
│                                     │
│  UNDERWEIGHT                        │
│  [1] Emaciated                      │
│  [2] Very thin                      │
│  [3] Thin                           │
│                                     │
│  IDEAL                              │
│  [4] Slightly underweight           │
│  [5] Ideal ✓                        │
│  [6] Slightly overweight            │
│                                     │
│  OVERWEIGHT                         │
│  [7] Overweight                     │
│  [8] Obese                          │
│  [9] Severely obese                 │
│                                     │
│  ────────────────────────────────   │
│                                     │
│  How to assess:                     │
│  • Feel ribs without pressing hard  │
│  • Visible waist from above         │
│  • Tucked abdomen from side         │
│                                     │
│  [ View Guide ] [ Save Score ]      │
└─────────────────────────────────────┘
```

### 4. Grooming Schedule

Track grooming activities:

```
┌─────────────────────────────────────┐
│  Grooming Schedule                  │
├─────────────────────────────────────┤
│                                     │
│  DUE SOON                           │
│  ┌─────────────────────────────┐    │
│  │ 🛁 Bath                     │    │
│  │ Last: Feb 15 (3 weeks ago)  │    │
│  │ Due: This week              │    │
│  │ [ Log Bath ]                │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 💅 Nail Trim                │    │
│  │ Last: Feb 28 (1 week ago)   │    │
│  │ Due: In 1 week              │    │
│  │ [ Log Trim ]                │    │
│  └─────────────────────────────┘    │
│                                     │
│  UP TO DATE                         │
│  ✓ Brushing - Yesterday             │
│  ✓ Ear cleaning - 5 days ago        │
│  ✓ Teeth brushing - Today           │
│                                     │
│  [ Add Activity ] [ Edit Schedule ] │
└─────────────────────────────────────┘
```

### 5. Enrichment Suggestions

Activity ideas for mental stimulation:

```
┌─────────────────────────────────────┐
│  Enrichment Ideas                   │
├─────────────────────────────────────┤
│                                     │
│  TODAY'S SUGGESTION                 │
│  🧩 Puzzle Feeder                   │
│  Put breakfast in a Kong or snuffle │
│  mat for mental stimulation         │
│  [ Did it! ] [ Skip ]               │
│                                     │
│  ────────────────────────────────   │
│                                     │
│  ACTIVITY LIBRARY                   │
│  🔍 Sniff walks                     │
│  🧩 Puzzle feeders                  │
│  🎾 Fetch variations                │
│  🏊 Swimming                        │
│  🐕 Playdates                       │
│  🧠 Training games                  │
│  🦴 Chew time                       │
│  🌳 New locations                   │
│                                     │
└─────────────────────────────────────┘
```

## Models

### DailyRoutine

```swift
// OtisShared/Sources/OtisShared/Models/DailyRoutine.swift

public struct DailyRoutine: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var items: [RoutineItem]
    public var isActive: Bool
    public var createdAt: Date
    public var modifiedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case items
        case isActive = "is_active"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }

    public init(id: UUID = UUID(), items: [RoutineItem] = [], isActive: Bool = true) {
        self.id = id
        self.items = items
        self.isActive = isActive
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

public struct RoutineItem: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var label: String
    public var time: String  // "07:00" format
    public var category: RoutineCategory
    public var isEnabled: Bool
    public var linkedEventType: EventType?

    public enum CodingKeys: String, CodingKey {
        case id
        case label
        case time
        case category
        case isEnabled = "is_enabled"
        case linkedEventType = "linked_event_type"
    }

    public init(
        id: UUID = UUID(),
        label: String,
        time: String,
        category: RoutineCategory,
        linkedEventType: EventType? = nil
    ) {
        self.id = id
        self.label = label
        self.time = time
        self.category = category
        self.isEnabled = true
        self.linkedEventType = linkedEventType
    }
}

public enum RoutineCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case morning
    case midday
    case evening
    case night

    public var id: String { rawValue }

    // Labels resolved via Strings.Routines in views
    public var timeRange: ClosedRange<Int> {
        switch self {
        case .morning: return 5...11
        case .midday: return 11...16
        case .evening: return 16...20
        case .night: return 20...24
        }
    }
}

// Default routine templates
extension DailyRoutine {
    public static var defaultAdult: DailyRoutine {
        DailyRoutine(items: [
            RoutineItem(label: "wake_potty", time: "07:00", category: .morning, linkedEventType: .plassen),
            RoutineItem(label: "breakfast", time: "07:30", category: .morning, linkedEventType: .eten),
            RoutineItem(label: "morning_walk", time: "08:00", category: .morning, linkedEventType: .uitlaten),
            RoutineItem(label: "potty_break", time: "12:00", category: .midday, linkedEventType: .plassen),
            RoutineItem(label: "evening_walk", time: "17:00", category: .evening, linkedEventType: .uitlaten),
            RoutineItem(label: "dinner", time: "18:00", category: .evening, linkedEventType: .eten),
            RoutineItem(label: "final_potty", time: "21:00", category: .night, linkedEventType: .plassen)
        ])
    }
}
```

### WeightGoal

```swift
// OtisShared/Sources/OtisShared/Models/WeightGoal.swift

public struct WeightGoal: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var targetWeightKg: Double
    public var startWeightKg: Double
    public var startDate: Date
    public var targetDate: Date?
    public var weeklyTargetKg: Double?  // Target loss/gain per week
    public var isActive: Bool
    public var createdAt: Date
    public var modifiedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case targetWeightKg = "target_weight_kg"
        case startWeightKg = "start_weight_kg"
        case startDate = "start_date"
        case targetDate = "target_date"
        case weeklyTargetKg = "weekly_target_kg"
        case isActive = "is_active"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }

    public init(
        id: UUID = UUID(),
        targetWeightKg: Double,
        startWeightKg: Double,
        startDate: Date = Date(),
        targetDate: Date? = nil,
        weeklyTargetKg: Double? = nil
    ) {
        self.id = id
        self.targetWeightKg = targetWeightKg
        self.startWeightKg = startWeightKg
        self.startDate = startDate
        self.targetDate = targetDate
        self.weeklyTargetKg = weeklyTargetKg
        self.isActive = true
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    public func progressPercentage(currentWeightKg: Double) -> Double? {
        let totalChange = startWeightKg - targetWeightKg
        let actualChange = startWeightKg - currentWeightKg
        guard totalChange != 0 else { return nil }
        return (actualChange / totalChange) * 100
    }

    public func remainingKg(currentWeightKg: Double) -> Double {
        return currentWeightKg - targetWeightKg
    }
}
```

### BodyConditionScore

```swift
// OtisShared/Sources/OtisShared/Models/BodyConditionScore.swift

public struct BodyConditionScore: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var score: Int  // 1-9
    public var note: String?
    public var createdAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case score
        case note
        case createdAt = "created_at"
    }

    public init(id: UUID = UUID(), score: Int, note: String? = nil) {
        self.id = id
        self.score = max(1, min(9, score))
        self.note = note
        self.createdAt = Date()
    }

    public var category: BCSCategory {
        switch score {
        case 1...3: return .underweight
        case 4...5: return .ideal
        case 6...7: return .overweight
        default: return .obese
        }
    }

    // Interpretation keys resolved via Strings.Routines in views
    public var interpretationKey: String {
        "bcs_\(score)"
    }
}

public enum BCSCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case underweight
    case ideal
    case overweight
    case obese

    public var id: String { rawValue }

    public var color: String {
        switch self {
        case .underweight: return "yellow"
        case .ideal: return "green"
        case .overweight: return "orange"
        case .obese: return "red"
        }
    }
}
```

### GroomingActivity

```swift
// OtisShared/Sources/OtisShared/Models/GroomingActivity.swift

public struct GroomingActivity: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var type: GroomingType
    public var intervalDays: Int
    public var lastCompleted: Date?
    public var isEnabled: Bool
    public var createdAt: Date
    public var modifiedAt: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case type
        case intervalDays = "interval_days"
        case lastCompleted = "last_completed"
        case isEnabled = "is_enabled"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }

    public init(
        id: UUID = UUID(),
        type: GroomingType,
        intervalDays: Int? = nil,
        lastCompleted: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.intervalDays = intervalDays ?? type.defaultIntervalDays
        self.lastCompleted = lastCompleted
        self.isEnabled = true
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    public var isDue: Bool {
        guard let last = lastCompleted else { return true }
        let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return daysSince >= intervalDays
    }

    public var daysUntilDue: Int {
        guard let last = lastCompleted else { return 0 }
        let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return max(0, intervalDays - daysSince)
    }

    public var daysSinceCompleted: Int? {
        guard let last = lastCompleted else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }
}

public enum GroomingType: String, Codable, CaseIterable, Identifiable, Sendable {
    case bath
    case nailTrim = "nail_trim"
    case brushing
    case earCleaning = "ear_cleaning"
    case teethBrushing = "teeth_brushing"
    case haircut
    case analGlands = "anal_glands"
    case eyeCleaning = "eye_cleaning"

    public var id: String { rawValue }

    // Labels resolved via Strings.Routines in views

    public var icon: String {
        switch self {
        case .bath: return "shower"
        case .nailTrim: return "scissors"
        case .brushing: return "comb"
        case .earCleaning: return "ear"
        case .teethBrushing: return "mouth"
        case .haircut: return "scissors"
        case .analGlands: return "cross.case"
        case .eyeCleaning: return "eye"
        }
    }

    public var defaultIntervalDays: Int {
        switch self {
        case .bath: return 30
        case .nailTrim: return 14
        case .brushing: return 3
        case .earCleaning: return 14
        case .teethBrushing: return 1
        case .haircut: return 60
        case .analGlands: return 60
        case .eyeCleaning: return 7
        }
    }
}
```

### EnrichmentActivity

```swift
// OtisShared/Sources/OtisShared/Models/EnrichmentActivity.swift

public struct EnrichmentActivity: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var type: EnrichmentType
    public var completedAt: Date
    public var durationMin: Int?
    public var note: String?

    public enum CodingKeys: String, CodingKey {
        case id
        case type
        case completedAt = "completed_at"
        case durationMin = "duration_min"
        case note
    }

    public init(
        id: UUID = UUID(),
        type: EnrichmentType,
        completedAt: Date = Date(),
        durationMin: Int? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.type = type
        self.completedAt = completedAt
        self.durationMin = durationMin
        self.note = note
    }
}

public enum EnrichmentType: String, Codable, CaseIterable, Identifiable, Sendable {
    case sniffWalk = "sniff_walk"
    case puzzleFeeder = "puzzle_feeder"
    case fetch
    case swimming
    case playdate
    case trainingGame = "training_game"
    case chewTime = "chew_time"
    case newLocation = "new_location"
    case hideAndSeek = "hide_and_seek"
    case nosework

    public var id: String { rawValue }

    // Labels and descriptions resolved via Strings.Routines in views

    public var icon: String {
        switch self {
        case .sniffWalk: return "nose"
        case .puzzleFeeder: return "puzzlepiece"
        case .fetch: return "tennisball"
        case .swimming: return "figure.pool.swim"
        case .playdate: return "dog"
        case .trainingGame: return "brain"
        case .chewTime: return "mouth"
        case .newLocation: return "mappin"
        case .hideAndSeek: return "eye.slash"
        case .nosework: return "nose"
        }
    }
}
```

## CoreData Integration

### CoreData Entities

Add to `Ollie.xcdatamodeld`:

```
CDRoutineItem
├── id: UUID
├── label: String
├── time: String
├── category: String
├── isEnabled: Bool
├── linkedEventType: String?
├── createdAt: Date
├── modifiedAt: Date

CDGroomingActivity
├── id: UUID
├── type: String
├── intervalDays: Int32
├── lastCompleted: Date?
├── isEnabled: Bool
├── createdAt: Date
├── modifiedAt: Date

CDBodyConditionScore
├── id: UUID
├── score: Int16
├── note: String?
├── createdAt: Date

CDEnrichmentActivity
├── id: UUID
├── type: String
├── completedAt: Date
├── durationMin: Int32?
├── note: String?

CDWeightGoal
├── id: UUID
├── targetWeightKg: Double
├── startWeightKg: Double
├── startDate: Date
├── targetDate: Date?
├── weeklyTargetKg: Double?
├── isActive: Bool
├── createdAt: Date
├── modifiedAt: Date
```

### CoreData Extensions

```swift
// Ollie-app/Models/CoreData/CDGroomingActivity+Extensions.swift

extension CDGroomingActivity {
    func update(from activity: GroomingActivity) {
        self.id = activity.id
        self.type = activity.type.rawValue
        self.intervalDays = Int32(activity.intervalDays)
        self.lastCompleted = activity.lastCompleted
        self.isEnabled = activity.isEnabled
        self.createdAt = activity.createdAt
        self.modifiedAt = activity.modifiedAt
    }

    static func create(from activity: GroomingActivity, in context: NSManagedObjectContext) -> CDGroomingActivity {
        let cdActivity = CDGroomingActivity(context: context)
        cdActivity.update(from: activity)
        return cdActivity
    }

    func toGroomingActivity() -> GroomingActivity? {
        guard let id = self.id,
              let typeString = self.type,
              let type = GroomingType(rawValue: typeString),
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else { return nil }

        var activity = GroomingActivity(
            id: id,
            type: type,
            intervalDays: Int(self.intervalDays),
            lastCompleted: self.lastCompleted
        )
        activity.isEnabled = self.isEnabled
        return activity
    }

    static func fetchAll(in context: NSManagedObjectContext) -> [CDGroomingActivity] {
        let request = NSFetchRequest<CDGroomingActivity>(entityName: "CDGroomingActivity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDGroomingActivity.type, ascending: true)]
        nonisolated(unsafe) var results: [CDGroomingActivity] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }
}

// Similar extensions for CDRoutineItem, CDBodyConditionScore, CDEnrichmentActivity, CDWeightGoal
```

## Store Implementation

```swift
// Ollie-app/Services/RoutineStore.swift

import Foundation
import CoreData
import os

@MainActor
final class RoutineStore: BaseStore {
    @Published private(set) var routineItems: [RoutineItem] = []
    @Published private(set) var weightGoal: WeightGoal?
    @Published private(set) var bodyConditionScores: [BodyConditionScore] = []
    @Published private(set) var groomingActivities: [GroomingActivity] = []
    @Published private(set) var enrichmentActivities: [EnrichmentActivity] = []

    init(persistenceController: PersistenceController = .shared) {
        super.init(persistenceController: persistenceController, logCategory: "RoutineStore")
    }

    override func performInitialLoad() {
        // Load routine items
        let cdItems = CDRoutineItem.fetchAll(in: viewContext)
        routineItems = cdItems.compactMap { $0.toRoutineItem() }

        // Load weight goal
        if let cdGoal = CDWeightGoal.fetchActive(in: viewContext) {
            weightGoal = cdGoal.toWeightGoal()
        }

        // Load body condition scores
        let cdScores = CDBodyConditionScore.fetchAll(in: viewContext)
        bodyConditionScores = cdScores.compactMap { $0.toBodyConditionScore() }

        // Load grooming activities
        let cdGrooming = CDGroomingActivity.fetchAll(in: viewContext)
        groomingActivities = cdGrooming.compactMap { $0.toGroomingActivity() }

        // Load enrichment activities
        let cdEnrichment = CDEnrichmentActivity.fetchAll(in: viewContext)
        enrichmentActivities = cdEnrichment.compactMap { $0.toEnrichmentActivity() }

        logger.info("Loaded \(self.routineItems.count) routine items, \(self.groomingActivities.count) grooming activities")
    }

    // MARK: - Routine Items

    @discardableResult
    func addRoutineItem(_ item: RoutineItem) -> RoutineItem {
        _ = CDRoutineItem.create(from: item, in: viewContext)
        performSave(operation: "Added routine item") {
            routineItems.append(item)
            routineItems.sort { $0.time < $1.time }
        }
        return item
    }

    func updateRoutineItem(_ item: RoutineItem) {
        guard let cdItem = CDRoutineItem.find(by: item.id, in: viewContext) else { return }
        cdItem.update(from: item)
        performSave(operation: "Updated routine item") {
            if let index = routineItems.firstIndex(where: { $0.id == item.id }) {
                routineItems[index] = item
            }
        }
    }

    func deleteRoutineItem(_ item: RoutineItem) {
        guard let cdItem = CDRoutineItem.find(by: item.id, in: viewContext) else { return }
        viewContext.delete(cdItem)
        performSave(operation: "Deleted routine item") {
            routineItems.removeAll { $0.id == item.id }
        }
    }

    func applyDefaultRoutine() {
        let defaultRoutine = DailyRoutine.defaultAdult
        for item in defaultRoutine.items {
            addRoutineItem(item)
        }
    }

    // MARK: - Weight Goal

    @discardableResult
    func setWeightGoal(_ goal: WeightGoal) -> WeightGoal {
        // Deactivate existing goal if any
        if let existing = CDWeightGoal.fetchActive(in: viewContext) {
            existing.isActive = false
        }

        _ = CDWeightGoal.create(from: goal, in: viewContext)
        performSave(operation: "Set weight goal") {
            weightGoal = goal
        }
        return goal
    }

    func clearWeightGoal() {
        guard let cdGoal = CDWeightGoal.fetchActive(in: viewContext) else { return }
        cdGoal.isActive = false
        performSave(operation: "Cleared weight goal") {
            weightGoal = nil
        }
    }

    // MARK: - Body Condition Score

    @discardableResult
    func recordBodyConditionScore(_ score: BodyConditionScore) -> BodyConditionScore {
        _ = CDBodyConditionScore.create(from: score, in: viewContext)
        performSave(operation: "Recorded BCS") {
            bodyConditionScores.insert(score, at: 0)
        }
        return score
    }

    var latestBodyConditionScore: BodyConditionScore? {
        bodyConditionScores.first
    }

    // MARK: - Grooming

    @discardableResult
    func addGroomingActivity(_ activity: GroomingActivity) -> GroomingActivity {
        _ = CDGroomingActivity.create(from: activity, in: viewContext)
        performSave(operation: "Added grooming activity") {
            groomingActivities.append(activity)
        }
        return activity
    }

    func markGroomingComplete(type: GroomingType) {
        if let index = groomingActivities.firstIndex(where: { $0.type == type }) {
            var updated = groomingActivities[index]
            updated.lastCompleted = Date()
            updateGroomingActivity(updated)
        }
    }

    func updateGroomingActivity(_ activity: GroomingActivity) {
        guard let cdActivity = CDGroomingActivity.find(by: activity.id, in: viewContext) else { return }
        cdActivity.update(from: activity)
        performSave(operation: "Updated grooming activity") {
            if let index = groomingActivities.firstIndex(where: { $0.id == activity.id }) {
                groomingActivities[index] = activity
            }
        }
    }

    var dueGroomingActivities: [GroomingActivity] {
        groomingActivities.filter { $0.isEnabled && $0.isDue }
    }

    var upToDateGroomingActivities: [GroomingActivity] {
        groomingActivities.filter { $0.isEnabled && !$0.isDue }
    }

    func setupDefaultGroomingSchedule() {
        for type in GroomingType.allCases {
            let activity = GroomingActivity(type: type)
            addGroomingActivity(activity)
        }
    }

    // MARK: - Enrichment

    @discardableResult
    func logEnrichment(_ activity: EnrichmentActivity) -> EnrichmentActivity {
        _ = CDEnrichmentActivity.create(from: activity, in: viewContext)
        performSave(operation: "Logged enrichment") {
            enrichmentActivities.insert(activity, at: 0)
        }
        return activity
    }

    func enrichmentSuggestion(excluding recentTypes: [EnrichmentType] = []) -> EnrichmentType {
        // Get types logged in last 3 days
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let recentlyLogged = enrichmentActivities
            .filter { $0.completedAt > threeDaysAgo }
            .map { $0.type }

        let allExcluded = Set(recentTypes + recentlyLogged)
        let available = EnrichmentType.allCases.filter { !allExcluded.contains($0) }

        return available.randomElement() ?? EnrichmentType.allCases.randomElement()!
    }
}
```

## Implementation

### Files to Create

```
OtisShared/Sources/OtisShared/Models/
├── DailyRoutine.swift
├── WeightGoal.swift
├── BodyConditionScore.swift
├── GroomingActivity.swift
├── EnrichmentActivity.swift

Ollie-app/Models/CoreData/
├── CDRoutineItem+Extensions.swift
├── CDWeightGoal+Extensions.swift
├── CDBodyConditionScore+Extensions.swift
├── CDGroomingActivity+Extensions.swift
├── CDEnrichmentActivity+Extensions.swift

Ollie-app/Views/Routines/
├── RoutineView.swift
├── RoutineEditSheet.swift
├── RoutineStatusCard.swift
├── WeightGoalView.swift
├── WeightGoalCard.swift
├── BodyConditionSheet.swift
├── GroomingScheduleView.swift
├── GroomingCard.swift
├── EnrichmentView.swift
├── EnrichmentCard.swift

Ollie-app/Services/
├── RoutineStore.swift

Ollie-app/Utils/Strings/
├── Strings+Routines.swift
```

### Files to Modify

```
Ollie.xcdatamodeld
  - Add CDRoutineItem, CDWeightGoal, CDBodyConditionScore, CDGroomingActivity, CDEnrichmentActivity entities

Ollie-app/Views/Timeline/TodayView.swift
  - Add routine status card for adult dogs
  - Add grooming due card

Ollie-app/Views/Settings/SettingsView.swift
  - Add links to routine, grooming settings
```

## Strings

```swift
// Ollie-app/Utils/Strings/Strings+Routines.swift

private let table = "Routines"

extension Strings {
    enum Routines {
        // Categories
        static let morning = String(localized: "Morning", table: table)
        static let midday = String(localized: "Midday", table: table)
        static let evening = String(localized: "Evening", table: table)
        static let night = String(localized: "Night", table: table)

        // Routine labels
        static let wakePotty = String(localized: "Wake up & potty", table: table)
        static let breakfast = String(localized: "Breakfast", table: table)
        static let morningWalk = String(localized: "Morning walk", table: table)
        static let pottyBreak = String(localized: "Potty break", table: table)
        static let eveningWalk = String(localized: "Evening walk", table: table)
        static let dinner = String(localized: "Dinner", table: table)
        static let finalPotty = String(localized: "Final potty", table: table)

        static func routineLabel(for key: String) -> String {
            switch key {
            case "wake_potty": return wakePotty
            case "breakfast": return breakfast
            case "morning_walk": return morningWalk
            case "potty_break": return pottyBreak
            case "evening_walk": return eveningWalk
            case "dinner": return dinner
            case "final_potty": return finalPotty
            default: return key
            }
        }

        // Weight
        static let weightManagement = String(localized: "Weight Management", table: table)
        static let currentWeight = String(localized: "Current", table: table)
        static let goalWeight = String(localized: "Goal", table: table)
        static func toLose(_ kg: String) -> String {
            String(localized: "To lose: \(kg)", table: table)
        }
        static func toGain(_ kg: String) -> String {
            String(localized: "To gain: \(kg)", table: table)
        }
        static let onTrack = String(localized: "On track", table: table)
        static let weightTip = String(localized: "1-2% body weight loss per week is healthy", table: table)

        // BCS
        static let bodyConditionScore = String(localized: "Body Condition Score", table: table)
        static let bcsEmaciated = String(localized: "Emaciated - Ribs, spine, hip bones very visible", table: table)
        static let bcsVeryThin = String(localized: "Very thin - Ribs easily felt, minimal fat", table: table)
        static let bcsThin = String(localized: "Thin - Ribs felt with light pressure", table: table)
        static let bcsSlightlyUnderweight = String(localized: "Slightly underweight - Ribs felt, slight waist", table: table)
        static let bcsIdeal = String(localized: "Ideal - Ribs palpable, clear waist, tuck", table: table)
        static let bcsSlightlyOverweight = String(localized: "Slightly overweight - Ribs hard to feel", table: table)
        static let bcsOverweight = String(localized: "Overweight - Ribs hard to feel, no waist", table: table)
        static let bcsObese = String(localized: "Obese - No waist, obvious fat deposits", table: table)
        static let bcsSeverelyObese = String(localized: "Severely obese - Heavy fat deposits", table: table)

        static func bcsInterpretation(for score: Int) -> String {
            switch score {
            case 1: return bcsEmaciated
            case 2: return bcsVeryThin
            case 3: return bcsThin
            case 4: return bcsSlightlyUnderweight
            case 5: return bcsIdeal
            case 6: return bcsSlightlyOverweight
            case 7: return bcsOverweight
            case 8: return bcsObese
            case 9: return bcsSeverelyObese
            default: return ""
            }
        }

        // Grooming
        static let groomingSchedule = String(localized: "Grooming Schedule", table: table)
        static let dueSoon = String(localized: "Due Soon", table: table)
        static let upToDate = String(localized: "Up to Date", table: table)
        static let bath = String(localized: "Bath", table: table)
        static let nailTrim = String(localized: "Nail Trim", table: table)
        static let brushing = String(localized: "Brushing", table: table)
        static let earCleaning = String(localized: "Ear Cleaning", table: table)
        static let teethBrushing = String(localized: "Teeth Brushing", table: table)
        static let haircut = String(localized: "Haircut", table: table)
        static let analGlands = String(localized: "Anal Glands", table: table)
        static let eyeCleaning = String(localized: "Eye Cleaning", table: table)

        static func groomingLabel(for type: GroomingType) -> String {
            switch type {
            case .bath: return bath
            case .nailTrim: return nailTrim
            case .brushing: return brushing
            case .earCleaning: return earCleaning
            case .teethBrushing: return teethBrushing
            case .haircut: return haircut
            case .analGlands: return analGlands
            case .eyeCleaning: return eyeCleaning
            }
        }

        static func dueIn(_ days: Int) -> String {
            String(localized: "Due in \(days) days", table: table)
        }
        static let dueThisWeek = String(localized: "Due this week", table: table)
        static let overdue = String(localized: "Overdue", table: table)

        // Enrichment
        static let enrichmentIdeas = String(localized: "Enrichment Ideas", table: table)
        static let todaysSuggestion = String(localized: "Today's Suggestion", table: table)
        static let activityLibrary = String(localized: "Activity Library", table: table)
        static let sniffWalk = String(localized: "Sniff Walk", table: table)
        static let puzzleFeeder = String(localized: "Puzzle Feeder", table: table)
        static let fetch = String(localized: "Fetch", table: table)
        static let swimming = String(localized: "Swimming", table: table)
        static let playdate = String(localized: "Playdate", table: table)
        static let trainingGame = String(localized: "Training Game", table: table)
        static let chewTime = String(localized: "Chew Time", table: table)
        static let newLocation = String(localized: "New Location", table: table)
        static let hideAndSeek = String(localized: "Hide and Seek", table: table)
        static let nosework = String(localized: "Nosework", table: table)

        static func enrichmentLabel(for type: EnrichmentType) -> String {
            switch type {
            case .sniffWalk: return sniffWalk
            case .puzzleFeeder: return puzzleFeeder
            case .fetch: return fetch
            case .swimming: return swimming
            case .playdate: return playdate
            case .trainingGame: return trainingGame
            case .chewTime: return chewTime
            case .newLocation: return newLocation
            case .hideAndSeek: return hideAndSeek
            case .nosework: return nosework
            }
        }

        static let puzzleFeederDescription = String(localized: "Put food in a Kong, snuffle mat, or puzzle toy", table: table)
        static let sniffWalkDescription = String(localized: "Let your dog lead and sniff at their own pace", table: table)
    }
}
```

Also create `Routines.xcstrings` catalog file.

## Testing

- [ ] Verify routine items display in correct time order
- [ ] Test routine completion tracking via linked event types
- [ ] Verify weight goal progress calculation
- [ ] Test BCS score saving and interpretation display
- [ ] Verify grooming due date calculations
- [ ] Test enrichment suggestion rotation excludes recent activities
- [ ] Verify routine templates apply correctly
- [ ] Test CoreData persistence across app restarts

## Notes

- Routine tracking uses existing event data via `linkedEventType` - no separate completion tracking needed
- Weight goal integrates with existing `WeightStore` for current weight
- Consider breed-specific grooming defaults (e.g., more brushing for double-coated breeds) in future iteration
- Enrichment suggestions personalized based on logged activities
- This brief focuses on adult dogs but features can apply to any lifecycle phase
- Store follows `BaseStore` pattern for consistency with other stores
