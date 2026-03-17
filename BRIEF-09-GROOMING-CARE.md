# Brief 09: Grooming & Care Tracking

> **Status:** Ready for Implementation
> **Priority:** Medium
> **Dependencies:** None (standalone feature)
> **Estimated Effort:** Medium

## Objective

Track grooming and care activities with breed/coat-based recommended schedules. Show reminders when care tasks are overdue. Allow user customization of all intervals.

## Why This Matters

- Grooming frequency varies dramatically by coat type (daily brushing for long coats vs weekly for short)
- Nail trimming, ear cleaning, and dental care are often forgotten until problems arise
- Users want gentle reminders without being nagged
- Professional grooming appointments can be tracked alongside home care

## Care Activities to Track

### Regular Home Care
| Activity | Event Type | Emoji | Default Interval | Notes |
|----------|------------|-------|------------------|-------|
| Bath | `bath` | `shower` | 4-8 weeks (coat-dependent) | Most variable by coat type |
| Brushing | `brushing` | `comb` | Daily to weekly | High frequency, quick log |
| Nail trim | `nailTrim` | `scissors` | 2-4 weeks | Universal |
| Ear cleaning | `earCleaning` | `ear` | 1-2 weeks (when needed) | Track checks, not schedule |
| Teeth brushing | `teethBrushing` | `mouth` | Daily ideally | High frequency, quick log |

### Professional Care
| Activity | Event Type | Emoji | Default Interval | Notes |
|----------|------------|-------|------------------|-------|
| Professional grooming | `grooming` | `sparkles` | 4-8 weeks | Full grooming appointment |
| Professional dental | `dentalCleaning` | `tooth` | 12 months | Vet procedure, link to appointments |

### As-Needed (Symptom-Based, Not Scheduled)
| Activity | Event Type | Emoji | Notes |
|----------|------------|-------|-------|
| Anal gland expression | `analGlands` | `drop.circle` | Only when symptoms present |
| Flea/tick treatment | `fleaTick` | `ant` | Monthly, but part of medications |

## Coat Type System

### CoatType Enum

```swift
// OtisShared/Models/CoatType.swift

public enum CoatType: String, Codable, CaseIterable, Identifiable, Sendable {
    case shortSmooth    // Beagle, Boxer, Greyhound, Dachshund
    case medium         // Border Collie, Australian Shepherd
    case long           // Shih Tzu, Yorkie, Maltese, Afghan Hound
    case curly          // Poodle, Bichon, Doodles, Portuguese Water Dog
    case double         // Husky, Golden Retriever, GSD, Lab, Corgi
    case wire           // Schnauzer, most Terriers, Wirehaired Pointer
    case hairless       // Chinese Crested, Xolo, American Hairless

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .shortSmooth: return String(localized: "Short/Smooth")
        case .medium: return String(localized: "Medium")
        case .long: return String(localized: "Long")
        case .curly: return String(localized: "Curly")
        case .double: return String(localized: "Double Coat")
        case .wire: return String(localized: "Wire/Wiry")
        case .hairless: return String(localized: "Hairless")
        }
    }

    public var description: String {
        switch self {
        case .shortSmooth:
            return String(localized: "Short, sleek coat that lies close to the body")
        case .medium:
            return String(localized: "Moderate length coat, may have some feathering")
        case .long:
            return String(localized: "Long, flowing coat that requires daily attention")
        case .curly:
            return String(localized: "Curly or wavy coat that doesn't shed much but mats easily")
        case .double:
            return String(localized: "Dense undercoat with longer outer coat, heavy seasonal shedding")
        case .wire:
            return String(localized: "Coarse, bristly outer coat that may need hand-stripping")
        case .hairless:
            return String(localized: "Little to no coat, requires skin care instead")
        }
    }

    public var examples: String {
        switch self {
        case .shortSmooth: return "Beagle, Boxer, Greyhound, Dachshund"
        case .medium: return "Border Collie, Australian Shepherd, Brittany"
        case .long: return "Shih Tzu, Yorkshire Terrier, Maltese"
        case .curly: return "Poodle, Bichon Frise, Labradoodle"
        case .double: return "Golden Retriever, Husky, German Shepherd"
        case .wire: return "Schnauzer, Wire Fox Terrier, Airedale"
        case .hairless: return "Chinese Crested, Xoloitzcuintli"
        }
    }

    public var icon: String {
        switch self {
        case .shortSmooth: return "hare"
        case .medium: return "dog"
        case .long: return "wind"
        case .curly: return "circle.grid.cross"
        case .double: return "square.stack.3d.up"
        case .wire: return "line.3.horizontal"
        case .hairless: return "circle"
        }
    }
}
```

### Default Schedules by Coat Type

```swift
extension CoatType {
    /// Default care schedule for this coat type
    public var defaultCareSchedule: CareSchedule {
        switch self {
        case .shortSmooth:
            return CareSchedule(
                bathIntervalDays: 60,           // Every 2-3 months
                brushingFrequency: .weekly,
                professionalGroomingIntervalDays: nil,  // Optional
                nailTrimIntervalDays: 21,
                earCheckIntervalDays: 7,
                teethBrushingFrequency: .daily
            )
        case .medium:
            return CareSchedule(
                bathIntervalDays: 35,           // Every 4-6 weeks
                brushingFrequency: .twiceWeekly,
                professionalGroomingIntervalDays: 56,   // Every 8 weeks
                nailTrimIntervalDays: 21,
                earCheckIntervalDays: 7,
                teethBrushingFrequency: .daily
            )
        case .long:
            return CareSchedule(
                bathIntervalDays: 28,           // Every 4 weeks
                brushingFrequency: .daily,
                professionalGroomingIntervalDays: 42,   // Every 6 weeks
                nailTrimIntervalDays: 21,
                earCheckIntervalDays: 7,
                teethBrushingFrequency: .daily
            )
        case .curly:
            return CareSchedule(
                bathIntervalDays: 21,           // Every 3 weeks
                brushingFrequency: .everyOtherDay,
                professionalGroomingIntervalDays: 42,   // Every 6 weeks
                nailTrimIntervalDays: 21,
                earCheckIntervalDays: 7,
                teethBrushingFrequency: .daily
            )
        case .double:
            return CareSchedule(
                bathIntervalDays: 49,           // Every 6-8 weeks
                brushingFrequency: .twiceWeekly,  // Daily during shedding
                professionalGroomingIntervalDays: 70,   // Every 10 weeks (de-shedding)
                nailTrimIntervalDays: 21,
                earCheckIntervalDays: 7,
                teethBrushingFrequency: .daily
            )
        case .wire:
            return CareSchedule(
                bathIntervalDays: 35,           // Every 4-6 weeks
                brushingFrequency: .twiceWeekly,
                professionalGroomingIntervalDays: 56,   // Every 8 weeks (hand-stripping)
                nailTrimIntervalDays: 21,
                earCheckIntervalDays: 7,
                teethBrushingFrequency: .daily
            )
        case .hairless:
            return CareSchedule(
                bathIntervalDays: 7,            // Weekly (skin care)
                brushingFrequency: .never,
                professionalGroomingIntervalDays: nil,
                nailTrimIntervalDays: 14,
                earCheckIntervalDays: 7,
                teethBrushingFrequency: .daily
            )
        }
    }

    /// Care tips specific to this coat type
    public var careTips: [String] {
        switch self {
        case .shortSmooth:
            return [
                String(localized: "Use a rubber curry brush to remove loose hair"),
                String(localized: "Occasional bathing keeps the coat shiny"),
                String(localized: "Watch for skin issues that are more visible on short coats")
            ]
        case .double:
            return [
                String(localized: "Never shave a double coat - it won't grow back the same"),
                String(localized: "Brush more frequently during spring and fall shedding"),
                String(localized: "Use an undercoat rake during heavy shedding periods")
            ]
        case .curly:
            return [
                String(localized: "Dry thoroughly after baths to prevent mildew"),
                String(localized: "Use a slicker brush to prevent matting"),
                String(localized: "Regular professional grooming keeps the coat manageable")
            ]
        case .long:
            return [
                String(localized: "Daily brushing prevents painful mats"),
                String(localized: "Pay attention to behind ears, armpits, and legs"),
                String(localized: "Consider a sanitary trim for hygiene")
            ]
        case .wire:
            return [
                String(localized: "Hand-stripping maintains coat texture and color"),
                String(localized: "Clipping will soften and lighten the coat over time"),
                String(localized: "Use a stripping knife or stone for proper technique")
            ]
        case .hairless:
            return [
                String(localized: "Apply sunscreen before outdoor time"),
                String(localized: "Moisturize regularly to prevent dry skin"),
                String(localized: "Watch for blackheads and skin irritation")
            ]
        case .medium:
            return [
                String(localized: "Focus on feathering around legs and belly"),
                String(localized: "A good brushing routine prevents tangles"),
                String(localized: "Seasonal coat changes may require more attention")
            ]
        }
    }
}
```

## Models

### CareSchedule

User-configurable care schedule with coat-based defaults:

```swift
// OtisShared/Models/CareSchedule.swift

public struct CareSchedule: Codable, Sendable, Equatable {
    // Bath
    public var bathIntervalDays: Int
    public var bathRemindersEnabled: Bool

    // Brushing
    public var brushingFrequency: CareFrequency
    public var brushingRemindersEnabled: Bool

    // Professional grooming
    public var professionalGroomingIntervalDays: Int?  // nil = not needed
    public var professionalGroomingRemindersEnabled: Bool

    // Nails
    public var nailTrimIntervalDays: Int
    public var nailTrimRemindersEnabled: Bool

    // Ears
    public var earCheckIntervalDays: Int
    public var earCheckRemindersEnabled: Bool

    // Teeth
    public var teethBrushingFrequency: CareFrequency
    public var teethBrushingRemindersEnabled: Bool

    // MARK: - Initializers

    public init(
        bathIntervalDays: Int = 28,
        brushingFrequency: CareFrequency = .weekly,
        professionalGroomingIntervalDays: Int? = nil,
        nailTrimIntervalDays: Int = 21,
        earCheckIntervalDays: Int = 7,
        teethBrushingFrequency: CareFrequency = .daily
    ) {
        self.bathIntervalDays = bathIntervalDays
        self.bathRemindersEnabled = true
        self.brushingFrequency = brushingFrequency
        self.brushingRemindersEnabled = brushingFrequency != .never
        self.professionalGroomingIntervalDays = professionalGroomingIntervalDays
        self.professionalGroomingRemindersEnabled = professionalGroomingIntervalDays != nil
        self.nailTrimIntervalDays = nailTrimIntervalDays
        self.nailTrimRemindersEnabled = true
        self.earCheckIntervalDays = earCheckIntervalDays
        self.earCheckRemindersEnabled = true
        self.teethBrushingFrequency = teethBrushingFrequency
        self.teethBrushingRemindersEnabled = teethBrushingFrequency != .never
    }

    /// Default schedule when no coat type is specified
    public static func defaultSchedule() -> CareSchedule {
        CareSchedule()  // Uses default parameter values
    }

    /// Schedule based on coat type
    public static func schedule(for coatType: CoatType) -> CareSchedule {
        coatType.defaultCareSchedule
    }
}

public enum CareFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case never
    case daily
    case everyOtherDay
    case twiceWeekly
    case weekly
    case biweekly
    case monthly

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .never: return String(localized: "Not needed")
        case .daily: return String(localized: "Daily")
        case .everyOtherDay: return String(localized: "Every other day")
        case .twiceWeekly: return String(localized: "2-3 times per week")
        case .weekly: return String(localized: "Weekly")
        case .biweekly: return String(localized: "Every 2 weeks")
        case .monthly: return String(localized: "Monthly")
        }
    }

    /// Average days between occurrences
    public var averageIntervalDays: Int? {
        switch self {
        case .never: return nil
        case .daily: return 1
        case .everyOtherDay: return 2
        case .twiceWeekly: return 3
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        }
    }
}
```

### CareEventType (extend EventType)

```swift
// Add to OtisShared/Models/PuppyEvent.swift

public enum EventType: String, Codable, CaseIterable {
    // ... existing types ...

    // Care/Grooming
    case bath
    case brushing
    case nailTrim
    case earCleaning
    case teethBrushing
    case grooming          // Professional grooming
    case dentalCleaning    // Professional dental (vet)
    case analGlands        // Expression (as-needed)

    // MARK: - Properties

    public var isCareEvent: Bool {
        switch self {
        case .bath, .brushing, .nailTrim, .earCleaning,
             .teethBrushing, .grooming, .dentalCleaning, .analGlands:
            return true
        default:
            return false
        }
    }

    public var careCategory: CareCategory? {
        switch self {
        case .bath: return .coat
        case .brushing: return .coat
        case .nailTrim: return .nails
        case .earCleaning: return .ears
        case .teethBrushing: return .dental
        case .grooming: return .professional
        case .dentalCleaning: return .professional
        case .analGlands: return .other
        default: return nil
        }
    }
}

public enum CareCategory: String, Codable, CaseIterable, Sendable {
    case coat
    case nails
    case ears
    case dental
    case professional
    case other

    public var label: String {
        switch self {
        case .coat: return String(localized: "Coat Care")
        case .nails: return String(localized: "Nails")
        case .ears: return String(localized: "Ears")
        case .dental: return String(localized: "Dental")
        case .professional: return String(localized: "Professional")
        case .other: return String(localized: "Other")
        }
    }
}
```

## PuppyProfile Extension

Add coat type and care schedule to profile:

```swift
// Add to PuppyProfile.swift

public struct PuppyProfile {
    // ... existing fields ...

    /// Coat type - determines default care schedule
    public var coatType: CoatType?

    /// Care schedule with user overrides
    public var careSchedule: CareSchedule
}

// In defaultProfile():
careSchedule: CareSchedule.defaultSchedule()

// In init():
self.coatType = coatType
self.careSchedule = careSchedule ?? coatType?.defaultCareSchedule ?? CareSchedule.defaultSchedule()
```

## UI Components

### Care Settings Section (in Settings)

```
┌─────────────────────────────────────┐
│  Grooming & Care                    │
├─────────────────────────────────────┤
│                                     │
│  Coat Type                          │
│  [Double Coat ▼]                    │
│  "Dense undercoat with longer       │
│   outer coat, heavy shedding"       │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Bath                               │
│  Every [ 6 ] weeks         [🔔 On]  │
│                                     │
│  Brushing                           │
│  [ 2-3 times per week ▼ ]  [🔔 On]  │
│                                     │
│  Professional Grooming              │
│  Every [ 10 ] weeks        [🔔 On]  │
│                                     │
│  Nail Trim                          │
│  Every [ 3 ] weeks         [🔔 On]  │
│                                     │
│  Ear Check                          │
│  Every [ 1 ] week          [🔔 Off] │
│                                     │
│  Teeth Brushing                     │
│  [ Daily ▼ ]               [🔔 Off] │
│                                     │
│  [ Reset to Defaults ]              │
│                                     │
└─────────────────────────────────────┘
```

### CareStatusCard (on Health Tab)

Shows overdue and upcoming care tasks:

```
┌─────────────────────────────────────┐
│  🛁  Grooming & Care                │
├─────────────────────────────────────┤
│                                     │
│  ⚠️ Overdue                         │
│  ┌───────────────────────────────┐  │
│  │ 🛁 Bath                       │  │
│  │    5 days overdue             │  │
│  │              [ Log Bath ]     │  │
│  └───────────────────────────────┘  │
│                                     │
│  Coming Up                          │
│  ┌───────────────────────────────┐  │
│  │ ✂️ Nail trim in 3 days        │  │
│  │ ✨ Grooming appt in 2 weeks   │  │
│  └───────────────────────────────┘  │
│                                     │
│  Recent                             │
│  🪥 Teeth brushed today             │
│  🪮 Brushed yesterday               │
│                                     │
└─────────────────────────────────────┘
```

### CareNudgeCard (on Today Tab)

Contextual reminder when care is overdue:

```
┌─────────────────────────────────────┐
│  🛁  Time for a bath?               │
│                                     │
│  Last bath was 6 weeks ago.         │
│  Luna's double coat benefits from   │
│  a bath every 6-8 weeks.            │
│                                     │
│  [ Log Bath ]  [ Snooze 3 days ]    │
└─────────────────────────────────────┘
```

### CareQuickLogSheet

Quick logging for care events:

```
┌─────────────────────────────────────┐
│          Log Care                   │
├─────────────────────────────────────┤
│                                     │
│  [🛁 Bath] [🪮 Brushed] [✂️ Nails]  │
│  [👂 Ears] [🪥 Teeth]  [✨ Groomer] │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  When: [ Today, 2:30 PM ▼ ]         │
│                                     │
│  Notes (optional):                  │
│  ┌─────────────────────────────┐    │
│  │ Used new oatmeal shampoo    │    │
│  └─────────────────────────────┘    │
│                                     │
│  📷 Add photo                       │
│                                     │
│         [ Log Care ]                │
└─────────────────────────────────────┘
```

### CareHistoryView

Full care history with filtering:

```
┌─────────────────────────────────────┐
│  Care History                       │
├─────────────────────────────────────┤
│  [ All ▼ ]  Last 90 days            │
├─────────────────────────────────────┤
│                                     │
│  March 2026                         │
│  ├─ Mar 8: 🛁 Bath                  │
│  ├─ Mar 7: 🪮 Brushed               │
│  ├─ Mar 5: 🪮 Brushed               │
│  ├─ Mar 2: ✂️ Nail trim             │
│  └─ Mar 1: ✨ Professional grooming │
│                                     │
│  February 2026                      │
│  ├─ Feb 25: 🛁 Bath                 │
│  ...                                │
│                                     │
└─────────────────────────────────────┘
```

## Service Layer

### CareStore

```swift
// Ollie-app/Services/CareStore.swift

@Observable
class CareStore {
    private let eventStore: EventStore
    private let profileStore: ProfileStore

    // MARK: - Last Occurrence Queries

    func lastCareEvent(of type: EventType) -> PuppyEvent? {
        eventStore.events(ofType: type, limit: 1).first
    }

    func daysSinceLastCare(of type: EventType) -> Int? {
        guard let last = lastCareEvent(of: type) else { return nil }
        return Calendar.current.dateComponents([.day], from: last.time, to: Date()).day
    }

    // MARK: - Due/Overdue Calculations

    func careStatus(for type: EventType) -> CareStatus {
        let schedule = profileStore.currentProfile.careSchedule

        guard let intervalDays = intervalDays(for: type, schedule: schedule) else {
            return .notTracked
        }

        guard let daysSince = daysSinceLastCare(of: type) else {
            return .neverDone
        }

        let daysUntilDue = intervalDays - daysSince

        if daysUntilDue < -7 {
            return .veryOverdue(days: abs(daysUntilDue))
        } else if daysUntilDue < 0 {
            return .overdue(days: abs(daysUntilDue))
        } else if daysUntilDue <= 3 {
            return .dueSoon(days: daysUntilDue)
        } else {
            return .onTrack(daysUntil: daysUntilDue)
        }
    }

    func allCareStatuses() -> [EventType: CareStatus] {
        let careTypes: [EventType] = [.bath, .brushing, .nailTrim, .earCleaning, .teethBrushing, .grooming]
        var statuses: [EventType: CareStatus] = [:]
        for type in careTypes {
            statuses[type] = careStatus(for: type)
        }
        return statuses
    }

    func overdueItems() -> [(EventType, CareStatus)] {
        allCareStatuses()
            .filter { $0.value.isOverdue }
            .sorted { $0.value.urgency > $1.value.urgency }
    }

    func upcomingItems(within days: Int = 7) -> [(EventType, CareStatus)] {
        allCareStatuses()
            .filter {
                if case .dueSoon = $0.value { return true }
                if case .onTrack(let daysUntil) = $0.value { return daysUntil <= days }
                return false
            }
            .sorted { $0.value.daysUntilDue ?? 999 < $1.value.daysUntilDue ?? 999 }
    }

    // MARK: - Logging

    func logCare(type: EventType, at time: Date = Date(), note: String? = nil) {
        let event = PuppyEvent(time: time, type: type, note: note)
        eventStore.saveEvent(event)
    }

    // MARK: - Private Helpers

    private func intervalDays(for type: EventType, schedule: CareSchedule) -> Int? {
        switch type {
        case .bath: return schedule.bathIntervalDays
        case .brushing: return schedule.brushingFrequency.averageIntervalDays
        case .nailTrim: return schedule.nailTrimIntervalDays
        case .earCleaning: return schedule.earCheckIntervalDays
        case .teethBrushing: return schedule.teethBrushingFrequency.averageIntervalDays
        case .grooming: return schedule.professionalGroomingIntervalDays
        default: return nil
        }
    }
}

enum CareStatus: Equatable {
    case notTracked
    case neverDone
    case veryOverdue(days: Int)
    case overdue(days: Int)
    case dueSoon(days: Int)
    case onTrack(daysUntil: Int)

    var isOverdue: Bool {
        switch self {
        case .veryOverdue, .overdue: return true
        default: return false
        }
    }

    var urgency: Int {
        switch self {
        case .veryOverdue(let days): return 100 + days
        case .overdue(let days): return 50 + days
        case .neverDone: return 25
        case .dueSoon: return 10
        case .onTrack: return 0
        case .notTracked: return -1
        }
    }

    var daysUntilDue: Int? {
        switch self {
        case .dueSoon(let days): return days
        case .onTrack(let days): return days
        case .overdue(let days): return -days
        case .veryOverdue(let days): return -days
        default: return nil
        }
    }
}
```

## Implementation

### Files to Create

```
OtisShared/Sources/OtisShared/Models/
├── CoatType.swift           (CoatType enum with defaults)
├── CareSchedule.swift       (CareSchedule, CareFrequency)

Ollie-app/Services/
├── CareStore.swift          (Care status tracking)

Ollie-app/Views/Health/
├── CareStatusCard.swift     (Overview card for Health tab)
├── CareHistoryView.swift    (Full history view)

Ollie-app/Views/Cards/
├── CareNudgeCard.swift      (Today tab reminder)

Ollie-app/Views/Components/Sheets/
├── CareQuickLogSheet.swift  (Quick logging)

Ollie-app/Views/Settings/
├── CareSettingsView.swift   (Schedule configuration)

Ollie-app/Utils/Strings/
├── Strings+Care.swift       (Localized strings)
```

### Files to Modify

```
OtisShared/Models/PuppyProfile.swift
  - Add coatType: CoatType?
  - Add careSchedule: CareSchedule
  - Update init, CodingKeys, encode/decode

OtisShared/Models/PuppyEvent.swift
  - Add care event types to EventType enum
  - Add isCareEvent, careCategory properties

Ollie-app/Views/Health/HealthView.swift
  - Add CareStatusCard section

Ollie-app/Views/Timeline/TodayView.swift
  - Add CareNudgeCard when items overdue

Ollie-app/Views/Settings/DogSettingsCard.swift
  - Add link to CareSettingsView

Ollie-app/Views/Components/Modifiers/SheetContent+Events.swift
  - Wire up CareQuickLogSheet
```

## Onboarding Integration

### When to Ask About Coat Type

1. **New user onboarding**: Add optional step after breed selection
2. **Breed auto-detection**: If breed is selected, suggest likely coat type
3. **Settings prompt**: Show card in settings if coatType is nil

### Breed → Coat Type Mapping (partial)

```swift
extension CoatType {
    /// Suggest coat type based on breed name
    public static func suggested(for breed: String?) -> CoatType? {
        guard let breed = breed?.lowercased() else { return nil }

        // Short/Smooth
        if breed.contains("beagle") || breed.contains("boxer") ||
           breed.contains("greyhound") || breed.contains("dachshund") ||
           breed.contains("bulldog") || breed.contains("pit bull") {
            return .shortSmooth
        }

        // Double coat
        if breed.contains("retriever") || breed.contains("husky") ||
           breed.contains("shepherd") || breed.contains("corgi") ||
           breed.contains("labrador") || breed.contains("malamute") ||
           breed.contains("bernese") || breed.contains("samoyed") {
            return .double
        }

        // Curly
        if breed.contains("poodle") || breed.contains("bichon") ||
           breed.contains("doodle") || breed.contains("portuguese water") {
            return .curly
        }

        // Long
        if breed.contains("shih tzu") || breed.contains("yorkie") ||
           breed.contains("maltese") || breed.contains("afghan") ||
           breed.contains("lhasa") || breed.contains("havanese") {
            return .long
        }

        // Wire
        if breed.contains("schnauzer") || breed.contains("terrier") &&
           (breed.contains("wire") || breed.contains("airedale") ||
            breed.contains("scottish") || breed.contains("west highland")) {
            return .wire
        }

        return nil
    }
}
```

## Strings to Add

```swift
// Strings+Care.swift

enum Care {
    static let title = String(localized: "Grooming & Care")
    static let coatType = String(localized: "Coat Type")
    static let careSchedule = String(localized: "Care Schedule")

    // Event labels
    static let bath = String(localized: "Bath")
    static let brushing = String(localized: "Brushing")
    static let nailTrim = String(localized: "Nail Trim")
    static let earCleaning = String(localized: "Ear Cleaning")
    static let teethBrushing = String(localized: "Teeth Brushing")
    static let grooming = String(localized: "Professional Grooming")
    static let dentalCleaning = String(localized: "Dental Cleaning")

    // Status
    static let overdue = String(localized: "Overdue")
    static let comingUp = String(localized: "Coming Up")
    static let recent = String(localized: "Recent")
    static let daysOverdue = String(localized: "%d days overdue")
    static let dueInDays = String(localized: "Due in %d days")
    static let dueToday = String(localized: "Due today")
    static let lastDone = String(localized: "Last done %@")
    static let neverDone = String(localized: "Never logged")

    // Nudge
    static func bathNudgeTitle(name: String) -> String {
        String(localized: "Time for \(name)'s bath?")
    }
    static let snooze = String(localized: "Snooze")
    static let snoozeDays = String(localized: "Snooze %d days")

    // Settings
    static let resetToDefaults = String(localized: "Reset to Defaults")
    static let reminders = String(localized: "Reminders")
    static let every = String(localized: "Every")
    static let weeks = String(localized: "weeks")
    static let days = String(localized: "days")
}
```

## AI Context Integration

```swift
// Add to AIContextComponents.swift

struct CareContext: AIContextComponent {
    let coatType: String?
    let overdueItems: [CareItem]
    let recentCare: [CareItem]

    struct CareItem: Codable {
        let type: String
        let daysAgo: Int?
        let status: String
    }
}

// Example context:
// "Luna has a double coat. Bath is 5 days overdue. Last brushed 2 days ago.
//  Nail trim due in 3 days."
```

## Notifications

Add to existing notification system:

```swift
extension NotificationSettings {
    var careRemindersEnabled: Bool
    var careReminderTime: Date  // Default: 9:00 AM
}

// Notification types
enum CareNotification {
    case bathDue(daysOverdue: Int)
    case nailTrimDue(daysOverdue: Int)
    case groomingAppointmentReminder(days: Int)
}
```

## Testing

- [ ] Set coat type and verify default schedule applies
- [ ] Override individual schedule values
- [ ] Log care events and verify status updates
- [ ] Test overdue calculations across date boundaries
- [ ] Verify nudge card appears when items overdue
- [ ] Test snooze functionality
- [ ] Verify care history displays correctly
- [ ] Test breed → coat type suggestions
- [ ] Verify AI context includes care data
- [ ] Test notifications fire at correct times

## Future Enhancements

- **Seasonal adjustments**: Prompt for more brushing during shedding season (double coats)
- **Activity triggers**: "Luna swam today - consider a rinse bath"
- **Professional appointment booking**: Deep link to groomer contact
- **Photo progress**: Before/after grooming photos
- **Coat condition tracking**: Track coat quality over time
- **Groomer notes**: Store notes from professional grooming visits
