# Brief 02: Medication UI

> **Status:** Ready for Implementation
> **Priority:** High
> **Dependencies:** None (uses existing MedicationSchedule infrastructure)
> **Estimated Effort:** Medium

## Objective

Implement the user-facing UI for medication management. The backend models (`MedicationSchedule`, `Medication`, `MedicationTime`, `MedicationCompletion`) already exist - this brief focuses on the UI layer.

## Context: What Already Exists

### Models (in OtisShared)

```swift
// MedicationSchedule.swift
public struct MedicationSchedule: Codable, Sendable {
    public var medications: [Medication]
}

public struct Medication: Codable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var instructions: String?
    public var icon: String
    public var recurrence: RecurrenceType  // daily/weekly
    public var daysOfWeek: [Int]?
    public var times: [MedicationTime]
    public var startDate: Date
    public var endDate: Date?
    public var isActive: Bool
}

public struct MedicationTime: Codable, Identifiable, Sendable {
    public var id: UUID
    public var targetTime: String  // "08:00"
    public var linkedMealId: UUID?
}
```

### Event Type

```swift
// PuppyEvent.swift
case medicatie  // Already exists!
```

### Quick Log

```swift
// Constants.swift - Senior phase already includes .medicatie
case .senior: [.uitlaten, .medicatie, .moment, .plassen, .slapen]
```

## Features to Build

### 1. Medication Log Sheet

Log when a medication was taken:

```
┌─────────────────────────────────────┐
│          Log Medication             │
├─────────────────────────────────────┤
│                                     │
│  Which medication?                  │
│  ┌─────────────────────────────┐    │
│  │ 💊 Apoquel                  │ ✓  │
│  │ 🦴 Joint Supplement         │    │
│  │ 💧 Eye Drops                │    │
│  └─────────────────────────────┘    │
│                                     │
│  Time: [10:30 AM ▼]                 │
│                                     │
│  Notes (optional):                  │
│  ┌─────────────────────────────┐    │
│  │ Gave with breakfast         │    │
│  └─────────────────────────────┘    │
│                                     │
│         [ Log Medication ]          │
└─────────────────────────────────────┘
```

### 2. Medication Reminder Card

Show on Today view when medication is due:

```
┌─────────────────────────────────────┐
│ 💊 Medication Due                   │
├─────────────────────────────────────┤
│                                     │
│  Apoquel           8:00 AM    [ ✓ ] │
│  Joint Supplement  8:00 AM    [ ✓ ] │
│  Eye Drops         Due now    [ ✓ ] │
│                                     │
│  ────────────────────────────────   │
│  Upcoming:                          │
│  Eye Drops         6:00 PM          │
│                                     │
└─────────────────────────────────────┘
```

### 3. Medication Management View

Full view for managing all medications:

```
┌─────────────────────────────────────┐
│ ← Medications                    +  │
├─────────────────────────────────────┤
│                                     │
│  ACTIVE                             │
│  ┌─────────────────────────────┐    │
│  │ 💊 Apoquel                   │    │
│  │ Daily at 8:00 AM             │    │
│  │ Started Jan 15 · Ongoing     │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🦴 Joint Supplement          │    │
│  │ Daily at 8:00 AM, 6:00 PM    │    │
│  │ Started Feb 1 · Ongoing      │    │
│  └─────────────────────────────┘    │
│                                     │
│  COMPLETED / PAUSED                 │
│  ┌─────────────────────────────┐    │
│  │ 💉 Antibiotics (completed)   │    │
│  │ 10-day course · Feb 1-10     │    │
│  └─────────────────────────────┘    │
│                                     │
│  This Week's Adherence              │
│  ▓▓▓▓▓▓░ 86% (6/7 doses)            │
│                                     │
└─────────────────────────────────────┘
```

### 4. Add/Edit Medication Sheet

```
┌─────────────────────────────────────┐
│          Add Medication             │
├─────────────────────────────────────┤
│                                     │
│  Name:                              │
│  ┌─────────────────────────────┐    │
│  │ Apoquel                     │    │
│  └─────────────────────────────┘    │
│                                     │
│  Icon:                              │
│  [💊] [💉] [🦴] [💧] [🩹] [⚕️]      │
│                                     │
│  Frequency:                         │
│  ○ Daily  ○ Specific days           │
│                                     │
│  Times:                             │
│  ┌──────────────────────────┐       │
│  │ 8:00 AM           [ × ]  │       │
│  └──────────────────────────┘       │
│  [ + Add another time ]             │
│                                     │
│  Duration:                          │
│  ○ Ongoing  ○ Fixed course          │
│    Start: [Feb 1]                   │
│    End:   [Feb 10]                  │
│                                     │
│  Instructions (optional):           │
│  ┌─────────────────────────────┐    │
│  │ Give with food              │    │
│  └─────────────────────────────┘    │
│                                     │
│           [ Save ]                  │
└─────────────────────────────────────┘
```

### 5. Medication Adherence View

Track compliance over time:

```
┌─────────────────────────────────────┐
│ ← Apoquel Adherence                 │
├─────────────────────────────────────┤
│                                     │
│  Overall: 94% (last 30 days)        │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Feb: ▓▓▓▓▓▓▓▓▓░ 93%         │    │
│  │ Jan: ▓▓▓▓▓▓▓▓▓▓ 100%        │    │
│  │ Dec: ▓▓▓▓▓▓▓▓░░ 87%         │    │
│  └─────────────────────────────┘    │
│                                     │
│  Recent:                            │
│  ✓ Feb 28, 8:15 AM                  │
│  ✓ Feb 27, 8:02 AM                  │
│  ✗ Feb 26 - Missed                  │
│  ✓ Feb 25, 8:30 AM                  │
│                                     │
└─────────────────────────────────────┘
```

## Implementation

### Files to Create

```
Ollie-app/Views/Health/Medication/
├── MedicationLogSheet.swift
├── MedicationReminderCard.swift
├── MedicationManagementView.swift
├── MedicationDetailView.swift
├── MedicationEditSheet.swift
└── MedicationAdherenceView.swift

Ollie-app/Services/
├── MedicationStore.swift (or extend existing)

Ollie-app/Utils/Strings/
├── Strings+Medication.swift
```

### Files to Modify

```
Ollie-app/ViewModels/SheetCoordinator.swift
  - Add .medicationLog case

Ollie-app/ViewModels/TimelineViewModel+Events.swift
  - Route .medicatie quick log to MedicationLogSheet

Ollie-app/Views/Timeline/TodayView.swift
  - Add MedicationReminderCard (for senior dogs or dogs with meds)

Ollie-app/Views/Settings/SettingsView.swift
  - Add link to MedicationManagementView
```

### Service Layer

```swift
// MedicationStore.swift
@Observable
class MedicationStore {
    private let profileStore: ProfileStore
    private let eventStore: EventStore

    // MARK: - Medication Management

    func addMedication(_ medication: Medication) { }
    func updateMedication(_ medication: Medication) { }
    func deleteMedication(id: UUID) { }
    func toggleMedicationActive(id: UUID) { }

    // MARK: - Completion Tracking

    func logCompletion(medicationId: UUID, time: Date, note: String?) { }
    func completionsToday(for medicationId: UUID) -> [MedicationCompletion] { }
    func isDue(_ medication: Medication, at time: Date) -> Bool { }
    func isOverdue(_ medication: Medication, at time: Date) -> Bool { }

    // MARK: - Adherence Calculation

    func adherencePercentage(for medicationId: UUID, days: Int) -> Double { }
    func missedDoses(for medicationId: UUID, days: Int) -> Int { }
    func weeklyAdherence() -> [(Date, Bool)] { }
}
```

### Card Visibility Logic

```swift
// MedicationReminderCard visibility
var shouldShowMedicationCard: Bool {
    // Show if:
    // 1. Dog has active medications, AND
    // 2. There are due/overdue doses today, OR
    // 3. Dog is in senior phase (always show for awareness)

    let hasActiveMeds = !profile.medicationSchedule.medications
        .filter { $0.isActive }.isEmpty

    let hasDueDoses = medicationStore.hasDueDosesToday()

    return hasActiveMeds && (hasDueDoses || profile.lifecyclePhase == .senior)
}
```

### Quick Log Integration

```swift
// TimelineViewModel+Events.swift
func quickLog(_ type: EventType) {
    switch type {
    case .medicatie:
        // If single medication, log directly
        // If multiple, show MedicationLogSheet for selection
        if profile.medicationSchedule.medications.filter({ $0.isActive }).count == 1 {
            logMedicationDirectly(profile.medicationSchedule.medications.first!)
        } else {
            sheetCoordinator.present(.medicationLog)
        }
    // ... other cases
    }
}
```

## Strings to Add

```swift
// Strings+Medication.swift
enum Medication {
    static let title = String(localized: "Medications")
    static let logMedication = String(localized: "Log Medication")
    static let addMedication = String(localized: "Add Medication")
    static let editMedication = String(localized: "Edit Medication")

    static let medicationName = String(localized: "Medication name")
    static let instructions = String(localized: "Instructions")
    static let frequency = String(localized: "Frequency")
    static let daily = String(localized: "Daily")
    static let specificDays = String(localized: "Specific days")
    static let times = String(localized: "Times")
    static let addTime = String(localized: "Add another time")
    static let duration = String(localized: "Duration")
    static let ongoing = String(localized: "Ongoing")
    static let fixedCourse = String(localized: "Fixed course")
    static let startDate = String(localized: "Start date")
    static let endDate = String(localized: "End date")

    static let dueNow = String(localized: "Due now")
    static let overdue = String(localized: "Overdue")
    static let upcoming = String(localized: "Upcoming")
    static let completed = String(localized: "Completed")
    static let missed = String(localized: "Missed")

    static let adherence = String(localized: "Adherence")
    static func adherencePercent(_ percent: Int) -> String {
        String(localized: "\(percent)% adherence")
    }
    static func dosesLogged(_ count: Int, total: Int) -> String {
        String(localized: "\(count)/\(total) doses")
    }

    enum Card {
        static let title = String(localized: "Medication Due")
        static let allDone = String(localized: "All medications logged for today")
    }
}
```

## Testing

- [ ] Add medication with daily schedule
- [ ] Add medication with specific days (M/W/F)
- [ ] Add fixed-course medication (10 days)
- [ ] Log medication from quick log bar
- [ ] Log medication from reminder card
- [ ] Verify overdue state shows correctly
- [ ] Verify adherence calculation is accurate
- [ ] Test medication completion persists across app restart
- [ ] Verify senior dogs see medication card even with no meds (to encourage setup)

## Notes

- Medication timing is critical for some conditions (epilepsy, diabetes) - consider push notifications
- Consider "snooze" feature for reminders
- Link medications to conditions once Brief 03 (Health Foundation) is complete
- Export medication history for vet visits
