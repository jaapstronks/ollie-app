# Responsibility Scheduling Feature

> Multi-user responsibility management for shared puppy care

## Overview

When multiple people care for a puppy together, this feature allows scheduling who is responsible at what times. The responsible person receives all reminders; others enter "monitor mode" (emergency alerts only). Supports custom time slots, weekly recurring schedules with overrides, and handoff notifications with status summaries.

## Design Decisions

| Aspect | Decision |
|--------|----------|
| Time granularity | **Custom time slots** (e.g., 09:00-13:00, 13:00-22:00) |
| Monitor mode | **Emergency only** — notify only if severely overdue (2+ hours) |
| Handoff notifications | **Yes, with status summary** ("Your turn! Last potty 45m ago...") |
| Shared responsibility | **Both get all** — independent notifications for both |
| Schedule structure | **Weekly recurring** — set up typical week, override specific days |
| User identification | **CloudKit auto-detect** — pull from existing share participants |

---

## User Stories

### Primary Use Cases

1. **As a shared caregiver**, I want to set my typical weekly schedule so I only get reminders during my shifts
2. **As a caregiver going off-duty**, I want my partner to receive a handoff summary so they know the puppy's current status
3. **As a caregiver in monitor mode**, I still want to be alerted if something is severely overdue (emergency)
4. **As a caregiver**, I want to override today's schedule when plans change (e.g., swap days)
5. **As a shared caregiver**, I want to mark certain periods as "shared responsibility" so we both get reminders
6. **As a widget user**, I want to see who's currently responsible and whether it's my turn

### Secondary Use Cases

7. **As a caregiver**, I want to see a history of who logged what event
8. **As a caregiver starting my shift**, I want a quick status view of what's been done and what's pending
9. **As a household**, we want the schedule to sync automatically across all devices

---

## Data Models

### New Models

#### `HouseholdMember`
```swift
struct HouseholdMember: Codable, Identifiable {
    let id: UUID
    var name: String                          // Display name
    var cloudKitUserRecordID: String?         // CKRecord.ID.recordName
    var isCurrentUser: Bool                   // Detected from local CloudKit identity
    var color: String?                        // Optional accent color for UI
}
```

#### `ResponsibilitySlot`
```swift
struct ResponsibilitySlot: Codable, Identifiable {
    let id: UUID
    var startTime: String                     // "09:00" (24h format)
    var endTime: String                       // "13:00"
    var assignedTo: [UUID]                    // HouseholdMember IDs (array for shared)
}
```

#### `WeeklySchedule`
```swift
struct WeeklySchedule: Codable {
    var monday: [ResponsibilitySlot]
    var tuesday: [ResponsibilitySlot]
    var wednesday: [ResponsibilitySlot]
    var thursday: [ResponsibilitySlot]
    var friday: [ResponsibilitySlot]
    var saturday: [ResponsibilitySlot]
    var sunday: [ResponsibilitySlot]

    func slots(for weekday: Int) -> [ResponsibilitySlot]
    func currentSlot(at date: Date) -> ResponsibilitySlot?
    func responsibleMembers(at date: Date) -> [UUID]
}
```

#### `ScheduleOverride`
```swift
struct ScheduleOverride: Codable, Identifiable {
    let id: UUID
    var date: Date                            // Specific date this override applies to
    var slots: [ResponsibilitySlot]           // Replaces default schedule for this date
    var note: String?                         // "Swapped with partner"
}
```

#### `ResponsibilityConfig`
```swift
struct ResponsibilityConfig: Codable {
    var isEnabled: Bool                       // Feature toggle
    var householdMembers: [HouseholdMember]
    var weeklySchedule: WeeklySchedule
    var overrides: [ScheduleOverride]         // Date-specific overrides
    var emergencyThresholdMinutes: Int        // Default: 120 (2 hours)
    var handoffNotificationsEnabled: Bool     // Default: true
}
```

### Extended Models

#### `PuppyEvent` (extend existing)
```swift
// Add field:
var loggedBy: UUID?                           // HouseholdMember.id who logged this event
```

#### `WidgetData` (extend existing)
```swift
// Add fields:
let currentlyResponsible: [String]?           // Names of currently responsible members
let isCurrentUserResponsible: Bool?           // Quick check for widget display
let nextHandoffTime: Date?                    // When responsibility changes next
let statusSummary: StatusSummary?             // For handoff display
```

#### `StatusSummary` (new, for handoffs/widget)
```swift
struct StatusSummary: Codable {
    let lastPottyMinutesAgo: Int?
    let lastMealTime: Date?
    let mealsCompletedToday: Int
    let mealsExpectedToday: Int
    let walksCompletedToday: Int
    let walksExpectedToday: Int
    let pendingTasks: [String]                // Human-readable list
}
```

---

## Files to Create

| File | Purpose |
|------|---------|
| `Models/HouseholdMember.swift` | Household member model |
| `Models/ResponsibilitySchedule.swift` | Slot, WeeklySchedule, Override, Config models |
| `Models/StatusSummary.swift` | Status summary for handoffs |
| `Services/ResponsibilityService.swift` | Core logic: who's responsible, handoff detection |
| `Services/HouseholdStore.swift` | Persist/sync household config via CloudKit |
| `ViewModels/ResponsibilityViewModel.swift` | UI state management for schedule views |
| `Views/Responsibility/ScheduleEditorView.swift` | Weekly schedule setup UI |
| `Views/Responsibility/DayScheduleView.swift` | Single day slot editor |
| `Views/Responsibility/OverrideSheet.swift` | Create override for specific date |
| `Views/Responsibility/HouseholdMembersView.swift` | Manage household members |
| `Views/Responsibility/HandoffBannerView.swift` | "Your turn" banner with status |
| `Views/Responsibility/ResponsibilityBadge.swift` | Small indicator showing who's on duty |

---

## Files to Modify

### Core Services

| File | Changes |
|------|---------|
| `Services/NotificationService.swift` | Check responsibility before scheduling; add handoff notifications; implement emergency-only mode for monitor users |
| `Services/CloudKitService.swift` | Add record types for ResponsibilityConfig; detect current user identity |
| `Services/CloudKitShareManager.swift` | Extract participant info for auto-populating household members |
| `Services/EventStore.swift` | Populate `loggedBy` field on new events |
| `Utils/WidgetDataProvider.swift` | Include responsibility data in widget payload |

### Models

| File | Changes |
|------|---------|
| `Models/PuppyEvent.swift` | Add optional `loggedBy: UUID?` field |
| `Models/PuppyProfile.swift` | Add `responsibilityConfig: ResponsibilityConfig?` (or separate store) |

### Views

| File | Changes |
|------|---------|
| `Views/SettingsView.swift` | Add "Household & Responsibility" settings section |
| `Views/TodayView.swift` | Show handoff banner when responsibility just transferred; show "who's on duty" indicator |
| `Views/TimelineView.swift` | Optionally show who logged each event |

### Widget

| File | Changes |
|------|---------|
| `OllieWidget/OllieWidget.swift` | Display responsibility status; different visual treatment when user is/isn't responsible |

---

## Implementation Details

### Responsibility Resolution Logic

```swift
// ResponsibilityService.swift

func currentlyResponsibleMembers(at date: Date = Date()) -> [UUID] {
    // 1. Check for date-specific override
    if let override = config.overrides.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
        return override.slots.currentSlot(at: date)?.assignedTo ?? []
    }

    // 2. Fall back to weekly schedule
    let weekday = Calendar.current.component(.weekday, from: date)
    return config.weeklySchedule.slots(for: weekday).currentSlot(at: date)?.assignedTo ?? []
}

func isCurrentUserResponsible(at date: Date = Date()) -> Bool {
    let responsible = currentlyResponsibleMembers(at: date)
    guard let currentUser = config.householdMembers.first(where: { $0.isCurrentUser }) else {
        return true // If no household set up, user is always responsible
    }
    return responsible.contains(currentUser.id)
}

func isEmergencyOverdue(for eventType: EventType) -> Bool {
    // Check if time since last event exceeds emergency threshold
    // Only applies to potty events for now
}
```

### Notification Filtering Logic

```swift
// In NotificationService.swift

func shouldScheduleNotification(for type: ReminderType) -> Bool {
    guard responsibilityService.config.isEnabled else {
        return true // Feature disabled = always notify
    }

    if responsibilityService.isCurrentUserResponsible() {
        return true // Responsible = normal notifications
    }

    // Monitor mode: emergency only
    if type == .potty && responsibilityService.isEmergencyOverdue(for: .plassen) {
        return true
    }

    return false
}
```

### Handoff Detection

```swift
// ResponsibilityService.swift

func detectHandoff() -> HandoffEvent? {
    let now = Date()
    let fiveMinutesAgo = now.addingTimeInterval(-300)

    let wasResponsible = isCurrentUserResponsible(at: fiveMinutesAgo)
    let isResponsible = isCurrentUserResponsible(at: now)

    if !wasResponsible && isResponsible {
        return HandoffEvent(
            time: now,
            statusSummary: generateStatusSummary()
        )
    }
    return nil
}
```

### CloudKit Record Types

New record types to register:

```swift
// ResponsibilityConfig record
CKRecord.RecordType: "ResponsibilityConfig"
Fields:
  - isEnabled: Int64 (0/1)
  - householdMembers: Data (JSON encoded)
  - weeklySchedule: Data (JSON encoded)
  - emergencyThresholdMinutes: Int64
  - handoffNotificationsEnabled: Int64 (0/1)

// ScheduleOverride record
CKRecord.RecordType: "ScheduleOverride"
Fields:
  - date: Date
  - slots: Data (JSON encoded)
  - note: String?
```

---

## UI/UX Flow

### Setup Flow (First Time)

1. User goes to **Settings → Household & Responsibility**
2. App auto-detects CloudKit share participants → shows list of household members
3. User confirms/edits member names
4. User taps **"Set Up Schedule"** → opens ScheduleEditorView
5. For each day, user can:
   - Add time slots with start/end time
   - Assign slot to one or more members
   - Copy day to other days
6. User saves → schedule syncs to all household members via CloudKit

### Daily Override Flow

1. From TodayView or Settings, user taps **"Edit Today's Schedule"**
2. OverrideSheet shows current day's slots
3. User modifies as needed
4. Saves as override (doesn't affect recurring schedule)

### Handoff Experience

1. When responsibility transfers to user, **HandoffBannerView** appears at top of TodayView
2. Banner shows:
   - "Your turn! Taking over from [Partner]"
   - Status summary: "Last potty: 45m ago • Lunch: done • Walk: pending"
3. Banner dismisses after tap or 30 seconds

### Widget Experience

**When user IS responsible:**
- Normal widget display
- Optional "Your turn" badge

**When user is NOT responsible (monitor mode):**
- Muted/dimmed appearance
- Shows "[Partner]'s turn"
- Only shows emergency alerts

---

## Edge Cases & Considerations

### Edge Cases to Handle

1. **No slots defined for current time** → Fall back to "everyone responsible"
2. **Overlapping slots** → Use most recently created slot (or merge assignees)
3. **User not in CloudKit share** → Disable feature, show setup prompt
4. **Offline device** → Use cached schedule, queue override changes
5. **Time zone changes** → Store times in local timezone, recalculate on TZ change
6. **Daylight saving time** → Handle 23/25 hour days gracefully
7. **Member leaves household** → Reassign their slots or leave empty (prompt)
8. **New member joins** → Prompt to add them to schedule

### Privacy Considerations

- Event `loggedBy` field visible to all household members
- Schedule visible to all household members
- No data leaves the CloudKit shared zone

### Performance Considerations

- Cache current responsibility status (recalculate every minute or on app foreground)
- Handoff detection runs on timer, not continuous
- Widget updates include responsibility data in single payload

---

## Roadmap Integration

Add to ROADMAP.md under appropriate phase:

```markdown
### Phase X: Multi-User Responsibility Management
- [ ] Household member detection from CloudKit
- [ ] Weekly schedule editor UI
- [ ] Responsibility resolution service
- [ ] Notification filtering (responsible vs monitor mode)
- [ ] Emergency-only alerts for monitor mode
- [ ] Handoff notifications with status summary
- [ ] Schedule override for specific days
- [ ] Widget responsibility indicators
- [ ] "Logged by" attribution on events
- [ ] CloudKit sync for schedule data
```

---

## Testing Strategy

### Unit Tests
- `ResponsibilityService`: slot resolution, handoff detection, emergency threshold
- `WeeklySchedule`: correct slot lookup for any day/time
- `ScheduleOverride`: override takes precedence over weekly

### Integration Tests
- Notification scheduling respects responsibility
- CloudKit sync of schedule changes
- Widget data includes responsibility fields

### Manual Testing Scenarios
1. Set up 2-person household, verify both see same schedule
2. Verify notifications only go to responsible user
3. Test emergency alert reaches monitor-mode user
4. Test handoff notification appears at transition time
5. Create override, verify it takes effect only on that day
6. Test widget shows correct responsibility status

---

## Open Questions for Future Consideration

1. **Multiple puppies**: If household has multiple dogs, separate schedules per dog?
2. **Task-specific assignments**: Different people responsible for walks vs feeding?
3. **Location awareness**: Auto-detect who's home and adjust?
4. **Vacation mode**: Temporarily disable all notifications for a user?
5. **History/analytics**: Who logged more events? Responsibility balance?

---

## Estimated Scope

| Component | Complexity |
|-----------|------------|
| Data models | Low |
| ResponsibilityService | Medium |
| HouseholdStore + CloudKit | Medium |
| Schedule editor UI | Medium-High |
| Notification filtering | Medium |
| Handoff notifications | Low-Medium |
| Widget updates | Low |
| Override system | Low |
| **Total** | **Medium-Large feature** |

Dependencies: Requires existing CloudKit sharing to be functional.
