# Appointments & Scheduling Feature

## Overview

A comprehensive scheduling system for dog-related appointments: vet visits, training classes, doggy daycare, groomer appointments, dog walker schedules, and more. Appointments can be linked to health milestones (e.g., "vaccination appointment" tied to "2nd vaccination milestone").

**Status:** Ready for implementation. Dog-contacts feature is complete.

---

## Architecture Notes (Updated)

### Current Codebase Patterns

Based on recent refactoring, here's how the codebase is structured:

**Core Data with Profile Relationships:**
- `CDPuppyProfile` has `to-many` relationships with cascade delete to:
  - `documents`, `events`, `exposures`, `masteredSkills`, `medicationCompletions`, `milestones`
- Each per-dog entity has an inverse `profile` relationship

**CDDogContact is an Exception:**
- Contacts do NOT have a profile relationship (they're household-level, not per-dog)
- A family might have multiple dogs but the same vet
- This is intentional and correct for contacts

**Appointments SHOULD have a profile relationship:**
- Appointments are per-dog (Fido's vet appointment vs Buddy's training class)
- Follow the DocumentStore pattern with ProfileStore dependency

**Store Patterns:**
1. **Per-profile stores (like DocumentStore):** Take ProfileStore dependency, filter by current profile
2. **Household-level stores (like ContactStore):** No profile dependency, shared across all dogs

**Image Storage:**
- Images stored as `Binary` with `allowsExternalBinaryDataStorage` in Core Data
- CloudKit syncs automatically via NSPersistentCloudKitContainer
- No separate file system management needed

---

## Research Summary

### iOS Calendar Integration Options

Based on current iOS 17+ best practices, there are three main approaches:

| Approach | Pros | Cons |
|----------|------|------|
| **EventKit (native calendar)** | No server needed; syncs across devices automatically; family sharing built-in; appears in user's calendar app; reminders work natively | Requires user permission; limited custom metadata; events editable by user outside app |
| **CloudKit (custom calendar)** | Full control over data; custom fields; syncs via existing CloudKit setup; no permission prompt | Doesn't appear in Calendar app; must build own reminder system; more complex sharing |
| **Hybrid approach** | Best of both worlds | Most complex to implement |

**Recommendation:** Use EventKit as primary approach with CloudKit for metadata linking. See "Architecture Decision" section.

### How Other Pet Apps Handle This

From research on [PetDesk](https://petdesk.com/), [DaySmart Vet](https://www.daysmart.com/vet/), and similar apps:

1. **Most sync with native calendars** - Users expect events to appear in their calendar app
2. **Two-way sync is rare** - Most apps only push to calendar, don't read from it
3. **Recurring events are common** - Training classes, daycare, medications
4. **Contact linking is standard** - Appointments link to the service provider

### Key Apple Documentation

- [EventKit Framework](https://developer.apple.com/documentation/eventkit)
- [Creating Recurring Events](https://developer.apple.com/documentation/eventkit/creating-a-recurring-event)
- [WWDC23: Discover Calendar and EventKit](https://developer.apple.com/videos/play/wwdc2023/10052/)
- [CloudKit Sharing](https://developer.apple.com/documentation/cloudkit/shared_records/sharing_cloudkit_data_with_other_icloud_users)

---

## Architecture Decision: Hybrid Approach

### Why Hybrid?

**The core insight:** Users want appointments in their calendar app AND we need custom metadata (like linking to milestones, contacts, notes).

**Solution:**
1. Store the **appointment data in Core Data/CloudKit** (syncs with family automatically via existing infrastructure)
2. Optionally **mirror to native calendar via EventKit** (appears in Calendar app)
3. Store the `EKEvent.eventIdentifier` to maintain the link

### Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Ollie App                                  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    CDDogAppointment                          │   │
│  │  (Core Data entity, syncs via CloudKit to family)            │   │
│  │                                                               │   │
│  │  - id, title, date, endDate, location, notes                 │   │
│  │  - appointmentType (vet, training, daycare, groomer, etc.)   │   │
│  │  - recurrenceRule (optional)                                  │   │
│  │  - linkedMilestoneID (optional)                               │   │
│  │  - linkedContactID (optional) ← from dog-contacts feature     │   │
│  │  - calendarEventID (optional) ← EKEvent link                  │   │
│  │  - reminderMinutesBefore                                      │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                              │                                       │
│                              │ (optional sync)                       │
│                              ▼                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     EKEvent (EventKit)                        │   │
│  │  (Native iOS Calendar - visible in Calendar app)              │   │
│  │                                                               │   │
│  │  - title, startDate, endDate, location, notes                │   │
│  │  - recurrenceRule                                             │   │
│  │  - alarms (reminders)                                         │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ (native sync)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    User's iCloud Calendar                            │
│  (Visible on all devices, shareable with family via Calendar app)   │
└─────────────────────────────────────────────────────────────────────┘
```

### Why This Works Without a Server

| Feature | How it works |
|---------|--------------|
| **Multi-device sync** | Core Data + CloudKit (already implemented) |
| **Family sharing** | CloudKit CKShare (already implemented via existing sharing) |
| **Appointments in Calendar app** | EventKit creates local calendar events |
| **Calendar sharing with family** | Users share via native iCloud Calendar sharing OR all family members add to calendar from within Ollie |
| **Reminders** | EventKit alarms for calendar events; local notifications for in-app |

**No custom server required!**

---

## Data Model

### New Core Data Entity: `CDDogAppointment`

> **Note:** This follows the same pattern as `CDDocument`, `CDMilestone`, etc. with a profile relationship.

```xml
Entity: CDDogAppointment
representedClassName: CDDogAppointment
syncable: YES
codeGenerationType: class

Attributes:
  - id: UUID
  - title: String (required, default "")
  - appointmentType: String (required, default "other")  // maps to AppointmentType enum
  - startDate: Date
  - endDate: Date
  - isAllDay: Bool (default NO)
  - location: String?
  - notes: String?
  - reminderMinutesBefore: Int16 (default 60)  // 0 = no reminder

  // Recurrence
  - recurrenceFrequency: String?      // "daily", "weekly", "monthly", "yearly", nil = one-time
  - recurrenceInterval: Int16 (default 1)
  - recurrenceEndDate: Date?
  - recurrenceCount: Int16 (default 0)  // 0 = use endDate, >0 = specific count
  - recurrenceDaysOfWeek: String?     // JSON array: [4] = Thursday

  // Linking
  - linkedMilestoneID: UUID?          // Links to CDMilestone
  - linkedContactID: UUID?            // Links to CDDogContact
  - calendarEventID: String?          // EKEvent.eventIdentifier

  // Metadata
  - createdAt: Date
  - modifiedAt: Date
  - isCompleted: Bool (default NO)
  - completionNotes: String?

Relationships:
  - profile: CDPuppyProfile (inverse: appointments, to-one, nullify)

FetchIndex:
  - byStartDateIndex on startDate (descending)
```

### Update CDPuppyProfile

Add new relationship:

```xml
<relationship name="appointments" optional="YES" toMany="YES" deletionRule="Cascade"
              destinationEntity="CDDogAppointment" inverseName="profile" inverseEntity="CDDogAppointment"/>
```

### OllieShared Model: `AppointmentType`

```swift
// AppointmentType.swift
import Foundation

public enum AppointmentType: String, CaseIterable, Codable, Identifiable, Sendable {
    case vetCheckup = "vet_checkup"
    case vetVaccination = "vet_vaccination"
    case vetEmergency = "vet_emergency"
    case vetSurgery = "vet_surgery"
    case grooming = "grooming"
    case training = "training"
    case daycare = "daycare"
    case boarding = "boarding"
    case dogWalker = "dog_walker"
    case playdate = "playdate"
    case petStore = "pet_store"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vetCheckup: return String(localized: "appointment.type.vetCheckup")
        case .vetVaccination: return String(localized: "appointment.type.vetVaccination")
        case .vetEmergency: return String(localized: "appointment.type.vetEmergency")
        case .vetSurgery: return String(localized: "appointment.type.vetSurgery")
        case .grooming: return String(localized: "appointment.type.grooming")
        case .training: return String(localized: "appointment.type.training")
        case .daycare: return String(localized: "appointment.type.daycare")
        case .boarding: return String(localized: "appointment.type.boarding")
        case .dogWalker: return String(localized: "appointment.type.dogWalker")
        case .playdate: return String(localized: "appointment.type.playdate")
        case .petStore: return String(localized: "appointment.type.petStore")
        case .other: return String(localized: "appointment.type.other")
        }
    }

    public var systemImage: String {
        switch self {
        case .vetCheckup: return "stethoscope"
        case .vetVaccination: return "syringe.fill"
        case .vetEmergency: return "cross.case.fill"
        case .vetSurgery: return "bandage.fill"
        case .grooming: return "scissors"
        case .training: return "figure.walk.motion"
        case .daycare: return "building.2.fill"
        case .boarding: return "house.fill"
        case .dogWalker: return "figure.walk"
        case .playdate: return "pawprint.fill"
        case .petStore: return "cart.fill"
        case .other: return "calendar"
        }
    }

    /// Whether this appointment type is typically linked to a health milestone
    public var isHealthRelated: Bool {
        switch self {
        case .vetCheckup, .vetVaccination, .vetEmergency, .vetSurgery:
            return true
        default:
            return false
        }
    }

    /// Suggested milestone category for linking
    public var suggestedMilestoneCategory: MilestoneCategory? {
        switch self {
        case .vetVaccination: return .health
        case .vetCheckup, .vetSurgery: return .health
        case .training: return .developmental
        default: return nil
        }
    }
}
```

### OllieShared Model: `DogAppointment`

```swift
// DogAppointment.swift
import Foundation

public struct DogAppointment: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var appointmentType: AppointmentType
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var location: String?
    public var notes: String?
    public var reminderMinutesBefore: Int

    // Recurrence
    public var recurrence: RecurrenceRule?

    // Linking
    public var linkedMilestoneID: UUID?
    public var linkedContactID: UUID?
    public var calendarEventID: String?

    // Completion
    public var isCompleted: Bool
    public var completionNotes: String?

    // Timestamps
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Computed

    public var isPast: Bool {
        endDate < Date()
    }

    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    public var durationMinutes: Int {
        Int(duration / 60)
    }

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        title: String,
        appointmentType: AppointmentType,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        location: String? = nil,
        notes: String? = nil,
        reminderMinutesBefore: Int = 60,
        recurrence: RecurrenceRule? = nil,
        linkedMilestoneID: UUID? = nil,
        linkedContactID: UUID? = nil,
        calendarEventID: String? = nil,
        isCompleted: Bool = false,
        completionNotes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.appointmentType = appointmentType
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrence = recurrence
        self.linkedMilestoneID = linkedMilestoneID
        self.linkedContactID = linkedContactID
        self.calendarEventID = calendarEventID
        self.isCompleted = isCompleted
        self.completionNotes = completionNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Recurrence

public struct RecurrenceRule: Codable, Hashable, Sendable {
    public enum Frequency: String, Codable, Sendable {
        case daily
        case weekly
        case monthly
        case yearly
    }

    public var frequency: Frequency
    public var interval: Int                    // Every X days/weeks/months
    public var daysOfWeek: [Int]?              // 1 = Sunday, 2 = Monday, ... 7 = Saturday
    public var endDate: Date?                   // nil = forever
    public var occurrenceCount: Int?            // Alternative to endDate

    public init(
        frequency: Frequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        endDate: Date? = nil,
        occurrenceCount: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
    }

    /// Create rule for "every Thursday for 4 weeks"
    public static func weekly(
        on weekday: Int,
        forWeeks count: Int
    ) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [weekday],
            occurrenceCount: count
        )
    }

    /// Create rule for weekly daycare (e.g., every Tuesday and Thursday)
    public static func weeklyOn(
        days: [Int],
        until endDate: Date? = nil
    ) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: days,
            endDate: endDate
        )
    }
}
```

---

## Integration with Existing Features

### Linking to Dog Contacts

**Dog contacts are now implemented!** Key patterns from the implementation:

- `ContactType` enum in OllieShared: `vet`, `emergencyVet`, `sitter`, `daycare`, `groomer`, `trainer`, `walker`, `petStore`, `breeder`, `other`
- `DogContact` struct in OllieShared with: name, phone, email, address, notes
- `CDDogContact` entity (no profile relationship - household level)
- `ContactStore` service with CRUD operations

**Contact linking in appointments:**

```swift
// In AddAppointmentSheet - use ContactStore to get available contacts
@EnvironmentObject private var contactStore: ContactStore
@State private var selectedContactID: UUID?

// Filter contacts by relevant type for the appointment type
var suggestedContacts: [DogContact] {
    switch appointmentType {
    case .vetCheckup, .vetVaccination, .vetSurgery:
        return contactStore.contacts(ofType: .vet) + contactStore.contacts(ofType: .emergencyVet)
    case .grooming:
        return contactStore.contacts(ofType: .groomer)
    case .training:
        return contactStore.contacts(ofType: .trainer)
    case .daycare:
        return contactStore.contacts(ofType: .daycare)
    case .dogWalker:
        return contactStore.contacts(ofType: .walker)
    default:
        return contactStore.contacts
    }
}

// Display on appointment detail with quick actions
if let contactID = appointment.linkedContactID,
   let contact = contactStore.contact(withId: contactID) {
    Section("Contact") {
        VStack(alignment: .leading, spacing: 8) {
            Label(contact.name, systemImage: contact.contactType.icon)
                .font(.headline)

            if let phone = contact.phone {
                Button { callPhone(phone) } label: {
                    Label(phone, systemImage: "phone.fill")
                }
            }
            if let email = contact.email {
                Button { sendEmail(email) } label: {
                    Label(email, systemImage: "envelope.fill")
                }
            }
            if let address = contact.address {
                Button { openMaps(address) } label: {
                    Label(address, systemImage: "map.fill")
                }
            }
        }
    }
}
```

### Linking to Milestones

When creating a vet appointment, suggest linking to an upcoming health milestone:

```swift
// Show linkable milestones when appointment type is health-related
if appointmentType.isHealthRelated {
    Section("Link to Milestone") {
        ForEach(upcomingHealthMilestones) { milestone in
            HStack {
                Image(systemName: milestone.icon)
                Text(milestone.localizedLabel)
                Spacer()
                if linkedMilestoneID == milestone.id {
                    Image(systemName: "checkmark")
                }
            }
            .onTapGesture {
                linkedMilestoneID = milestone.id
            }
        }
    }
}
```

**Behavior when linked:**
- Appointment shows milestone badge
- Completing appointment offers to mark milestone complete
- Milestone shows "Appointment scheduled: Feb 28, 2pm"
- If milestone is rescheduled, offer to update appointment

---

## Premium Feature Analysis

### What Should Be Premium (Ollie+)?

| Feature | Free | Premium | Rationale |
|---------|------|---------|-----------|
| View appointments | ✓ | ✓ | Core functionality |
| Add one-time appointments | ✓ | ✓ | Basic scheduling is expected |
| Basic reminders (1 hour before) | ✓ | ✓ | Essential for usability |
| Recurring appointments | | ✓ | Power feature, clear value |
| Custom reminder times | | ✓ | Nice-to-have, not essential |
| Export to Calendar app | | ✓ | Integration feature |
| Link to milestones | | ✓ | Advanced feature |
| Completion notes/photos | | ✓ | Enhanced tracking |
| Full schedule view | | ✓ | Analytics/overview feature |

### Premium Gating UX

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  📅 Sync with Calendar                          │
│                                                 │
│  Add appointments to your iPhone calendar       │
│  so your whole family stays in sync.            │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │       Unlock with Ollie+                │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  [Maybe Later]                                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Calendar Sync Strategy

### Approach: "Opt-in Sync to User's Calendar"

1. **Default:** Appointments live in Ollie, shown in Ollie's schedule view
2. **Optional:** User can tap "Add to Calendar" to sync individual appointments
3. **Bulk option:** "Sync all upcoming appointments" (premium)

### Why Not Auto-Sync Everything?

1. **Permission required:** Full calendar access is a significant permission
2. **User control:** Some users don't want dog appointments cluttering their calendar
3. **Avoid duplicates:** If multiple family members sync, they may get duplicates
4. **Predictability:** User knows exactly what's in their calendar

### Implementation Details

#### Adding to Calendar

```swift
// In CalendarService.swift (extend existing)

func addAppointment(_ appointment: DogAppointment, profile: PuppyProfile) async throws -> String {
    guard hasAccess() else {
        throw CalendarError.accessDenied
    }

    let event = EKEvent(eventStore: eventStore)

    // Title with dog name for clarity
    event.title = "\(profile.name): \(appointment.title)"
    event.startDate = appointment.startDate
    event.endDate = appointment.endDate
    event.isAllDay = appointment.isAllDay
    event.location = appointment.location
    event.notes = appointment.notes
    event.calendar = eventStore.defaultCalendarForNewEvents

    // Add reminder
    if appointment.reminderMinutesBefore > 0 {
        let alarm = EKAlarm(relativeOffset: TimeInterval(-appointment.reminderMinutesBefore * 60))
        event.addAlarm(alarm)
    }

    // Add recurrence rule if present
    if let recurrence = appointment.recurrence {
        let ekRule = recurrence.toEKRecurrenceRule()
        event.recurrenceRules = [ekRule]
    }

    try eventStore.save(event, span: .futureEvents)
    return event.eventIdentifier
}
```

#### Converting RecurrenceRule to EKRecurrenceRule

```swift
extension RecurrenceRule {
    func toEKRecurrenceRule() -> EKRecurrenceRule {
        let ekFrequency: EKRecurrenceFrequency
        switch frequency {
        case .daily: ekFrequency = .daily
        case .weekly: ekFrequency = .weekly
        case .monthly: ekFrequency = .monthly
        case .yearly: ekFrequency = .yearly
        }

        var daysOfTheWeek: [EKRecurrenceDayOfWeek]? = nil
        if let days = daysOfWeek {
            daysOfTheWeek = days.map {
                EKRecurrenceDayOfWeek(EKWeekday(rawValue: $0)!)
            }
        }

        var end: EKRecurrenceEnd? = nil
        if let endDate = endDate {
            end = EKRecurrenceEnd(end: endDate)
        } else if let count = occurrenceCount {
            end = EKRecurrenceEnd(occurrenceCount: count)
        }

        return EKRecurrenceRule(
            recurrenceWith: ekFrequency,
            interval: interval,
            daysOfTheWeek: daysOfTheWeek,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: end
        )
    }
}
```

---

## Family Sharing Considerations

### How Family Members See Appointments

| Scenario | What Happens |
|----------|--------------|
| **User A creates appointment** | Syncs to CloudKit → User B sees it in Ollie app |
| **User A adds to Calendar** | Only User A's calendar has the event |
| **User B opens same appointment** | Can tap "Add to Calendar" to add to their own calendar |
| **Both add to Calendar** | Both have independent copies (this is expected iOS behavior) |

### Alternative: Shared iCloud Calendar

Users can create a shared "Dog" calendar in iOS Calendar app, then:
1. In Ollie, select this shared calendar for syncing
2. All family members subscribed to that calendar see events

**Implementation:**
```swift
// Let user choose which calendar to sync to
func availableCalendars() -> [EKCalendar] {
    eventStore.calendars(for: .event)
        .filter { $0.allowsContentModifications }
        .sorted { $0.title < $1.title }
}

// Show picker on first sync
@AppStorage("preferredCalendarIdentifier") var preferredCalendarID: String?

func getPreferredCalendar() -> EKCalendar? {
    if let id = preferredCalendarID,
       let calendar = eventStore.calendar(withIdentifier: id) {
        return calendar
    }
    return eventStore.defaultCalendarForNewEvents
}
```

---

## Server Requirements Analysis

### Does This Feature Require a Server?

**No!** Here's why:

| Concern | Solution |
|---------|----------|
| Data sync between devices | CloudKit (already implemented) |
| Family sharing | CloudKit CKShare (already implemented) |
| Calendar sync | EventKit (local API, syncs via iCloud) |
| Push notifications for reminders | Local notifications (already implemented) |
| Recurring event expansion | Computed client-side |

### What Would Require a Server?

These are explicitly **out of scope** for MVP:

1. **Calendar subscriptions (.ics feeds)** - Would need server to host the URL
2. **Integration with vet practice software** - Would need API/backend
3. **SMS/email reminders** - Would need notification service
4. **Booking appointments with third parties** - Would need API integrations

---

## UI Design

### View Hierarchy

```
Settings > Dog Profile
  └── Appointments (new section)
        ├── NavigationLink → AppointmentsView
        └── Count badge showing upcoming

AppointmentsView
  ├── Segmented: Upcoming | Past
  ├── List grouped by date
  │     └── AppointmentRow (type icon, title, time, location preview)
  ├── Empty state (ContentUnavailableView)
  ├── Toolbar: + button → AddAppointmentSheet
  └── Swipe actions: Edit, Delete, Add to Calendar

AddAppointmentSheet
  ├── TextField: title (required)
  ├── Picker: AppointmentType
  ├── DatePicker: startDate, endDate
  ├── Toggle: isAllDay
  ├── TextField: location (optional)
  ├── TextEditor: notes (optional)
  ├── Section: Recurrence (premium)
  │     ├── Toggle: Repeats
  │     └── RecurrenceEditor (if enabled)
  ├── Section: Reminder
  │     └── Picker: reminderMinutesBefore
  ├── Section: Link to Contact (optional)
  │     └── ContactPicker
  ├── Section: Link to Milestone (for health types)
  │     └── MilestonePicker
  ├── Toggle: Add to Calendar (premium)
  └── Save button

AppointmentDetailView
  ├── Header: type icon + title
  ├── Section: Date & Time
  │     └── With calendar badge if synced
  ├── Section: Location (with map link)
  ├── Section: Linked Contact (with call/email buttons)
  ├── Section: Linked Milestone (with status)
  ├── Section: Notes
  ├── Section: After Appointment (for past)
  │     └── Completion notes, photos
  ├── Toolbar: Edit, Add to Calendar
  └── Delete button

RecurrenceEditor
  ├── Picker: frequency (weekly, daily, etc.)
  ├── Stepper: interval
  ├── DayOfWeekPicker (for weekly)
  ├── Picker: ends (never, after X times, on date)
  └── Preview: "Every Thursday for 4 weeks"
```

### Schedule View (Today Tab Integration)

Add to TodayView:

```
┌─────────────────────────────────────────────────┐
│ Today's Schedule                                │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │ 🩺 Vet - 2nd Vaccination              2pm │  │
│  │    Dierenkliniek Amsterdam                │  │
│  │    📍 Linked: Dr. van der Berg           │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │ 🎓 Puppy Training                     8pm │  │
│  │    Hondenschool de Baas                   │  │
│  │    Week 2 of 4 · Focus: Sit & Down        │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Implementation Order

### Phase 0: ~~Wait for Dog Contacts~~ COMPLETE
- [x] Complete `TODO-dog-contacts.md` implementation
- [x] Update this plan with contact integration specifics

### Phase 1: Core Data Model
1. Add `CDDogAppointment` entity to Core Data model
2. Add relationship to `CDPuppyProfile`
3. Create `AppointmentType` enum in OllieShared
4. Create `DogAppointment` struct in OllieShared
5. Create `RecurrenceRule` struct in OllieShared

### Phase 2: AppointmentStore Service
1. Create `AppointmentStore.swift` with CRUD operations
2. Implement fetch methods (upcoming, past, for date range)
3. Implement recurrence expansion (generate occurrence dates)

### Phase 3: Basic UI (Free Tier)
1. Create `AppointmentRow.swift`
2. Create `AppointmentsView.swift` (list with segments)
3. Create `AddAppointmentSheet.swift` (basic fields)
4. Create `AppointmentDetailView.swift`
5. Add to `DogProfileSettingsView.swift`

### Phase 4: Today View Integration
1. Add "Today's Schedule" section to TodayView
2. Show upcoming appointments for today

### Phase 5: Calendar Sync (Premium)
1. Extend `CalendarService.swift` with appointment methods
2. Add "Add to Calendar" button with premium gate
3. Handle calendar picker for shared calendars
4. Store `calendarEventID` link

### Phase 6: Milestone Linking (Premium)
1. Add milestone picker to appointment form
2. Show linked appointments on milestone detail
3. Offer to mark milestone complete after appointment

### Phase 7: Contact Linking
1. Add contact picker to appointment form
2. Show contact info on appointment detail
3. Quick actions (call, email, directions)

### Phase 8: Recurring Appointments (Premium)
1. Create `RecurrenceEditor.swift` component
2. Implement recurrence in appointment creation
3. Handle editing single vs all occurrences
4. Sync recurring events to calendar

### Phase 9: Polish
1. Empty states
2. Localization (all strings)
3. Accessibility
4. Haptic feedback
5. Pull-to-refresh

---

## File List

### New Files

| File | Location | Pattern Reference |
|------|----------|-------------------|
| `AppointmentType.swift` | `OllieShared/Sources/OllieShared/Models/` | Like `ContactType.swift` |
| `DogAppointment.swift` | `OllieShared/Sources/OllieShared/Models/` | Like `DogContact.swift` |
| `RecurrenceRule.swift` | `OllieShared/Sources/OllieShared/Models/` | New |
| `CDDogAppointment+Extensions.swift` | `Ollie-app/Models/CoreData/` | Like `CDDogContact+Extensions.swift` |
| `AppointmentStore.swift` | `Ollie-app/Services/` | Like `DocumentStore.swift` (with ProfileStore) |
| `AppointmentsView.swift` | `Ollie-app/Views/Appointments/` | Like `ContactsView.swift` |
| `AddAppointmentSheet.swift` | `Ollie-app/Views/Appointments/` | Like `AddContactSheet.swift` |
| `EditAppointmentSheet.swift` | `Ollie-app/Views/Appointments/` | Like `EditContactSheet.swift` |
| `AppointmentDetailView.swift` | `Ollie-app/Views/Appointments/` | Like `ContactDetailView.swift` |
| `AppointmentRow.swift` | `Ollie-app/Views/Appointments/` | Like `ContactRow.swift` |
| `RecurrenceEditor.swift` | `Ollie-app/Views/Appointments/` | New |
| `TodaysScheduleCard.swift` | `Ollie-app/Views/Cards/` | New |
| `Strings+Appointments.swift` | `Ollie-app/Utils/Strings/` | Like `Strings+Contacts.swift` |

### Modified Files

| File | Change |
|------|--------|
| `Ollie.xcdatamodeld` | Add `CDDogAppointment` entity + `appointments` relationship on `CDPuppyProfile` |
| `CalendarService.swift` | Add appointment methods (extend existing milestone methods) |
| `DogProfileSettingsView.swift` | Add "Appointments" section (after Contacts) |
| `TodayView.swift` | Add "Today's Schedule" card |
| `Ollie_appApp.swift` | Add `AppointmentStore` to environment, wire with ProfileStore |
| `Localizable.xcstrings` | Add appointment strings |
| `Settings.xcstrings` | Add settings-related appointment strings |

---

## Localization Keys

```swift
// Strings+Appointments.swift
public enum Appointments {
    // Titles
    public static let title = String(localized: "appointments.title")
    public static let upcoming = String(localized: "appointments.upcoming")
    public static let past = String(localized: "appointments.past")
    public static let addTitle = String(localized: "appointments.add.title")
    public static let editTitle = String(localized: "appointments.edit.title")

    // Fields
    public static let titleField = String(localized: "appointments.field.title")
    public static let type = String(localized: "appointments.field.type")
    public static let date = String(localized: "appointments.field.date")
    public static let time = String(localized: "appointments.field.time")
    public static let location = String(localized: "appointments.field.location")
    public static let notes = String(localized: "appointments.field.notes")
    public static let reminder = String(localized: "appointments.field.reminder")

    // Recurrence
    public static let repeats = String(localized: "appointments.repeats")
    public static let frequency = String(localized: "appointments.frequency")
    public static let everyWeek = String(localized: "appointments.every.week")
    public static let everyXWeeks = String(localized: "appointments.every.x.weeks")
    public static let ends = String(localized: "appointments.ends")
    public static let never = String(localized: "appointments.never")
    public static let afterXTimes = String(localized: "appointments.after.x.times")
    public static let onDate = String(localized: "appointments.on.date")

    // Calendar
    public static let addToCalendar = String(localized: "appointments.addToCalendar")
    public static let inCalendar = String(localized: "appointments.inCalendar")
    public static let removeFromCalendar = String(localized: "appointments.removeFromCalendar")
    public static let chooseCalendar = String(localized: "appointments.chooseCalendar")

    // Links
    public static let linkToContact = String(localized: "appointments.linkToContact")
    public static let linkToMilestone = String(localized: "appointments.linkToMilestone")

    // Empty states
    public static let emptyTitle = String(localized: "appointments.empty.title")
    public static let emptyDescription = String(localized: "appointments.empty.description")
    public static let noUpcoming = String(localized: "appointments.noUpcoming")
    public static let noPast = String(localized: "appointments.noPast")

    // Completion
    public static let markComplete = String(localized: "appointments.markComplete")
    public static let addNotes = String(localized: "appointments.addNotes")
    public static let whatHappened = String(localized: "appointments.whatHappened")
}

// Appointment type translations
// appointment.type.vetCheckup = "Vet Checkup" / "Controle dierenarts"
// appointment.type.vetVaccination = "Vaccination" / "Vaccinatie"
// etc.
```

---

## Open Questions

### To Decide Before Implementation

1. **Calendar picker:** Show calendar picker on first sync, or always use default?
   - Recommendation: Ask on first sync, remember choice

2. **Recurring event editing:** When editing one occurrence, ask "This event only" or "All future events"?
   - Recommendation: Mirror iOS Calendar behavior

3. **Past appointments:** Show "Mark as attended" vs auto-complete?
   - Recommendation: Don't auto-complete, let user confirm

4. **Notification sound:** Use custom Ollie sound for appointment reminders?
   - Recommendation: Use system default for consistency

5. **Conflict detection:** Warn when scheduling overlapping appointments?
   - Recommendation: Not for MVP, add later

### Future Enhancements (Post-MVP)

1. **Import from iOS Contacts** - Auto-create contacts from vet visits
2. **Vet portal integration** - If vet uses PetDesk, etc.
3. **Travel time alerts** - "Leave now to arrive on time"
4. **Cost tracking** - How much do appointments cost?
5. **Document attachment** - Upload vet records, receipts
6. **Appointment history** - Weight tracking over time from vet visits

---

## Testing Checklist

### Manual Testing

- [ ] Create one-time appointment
- [ ] Create recurring appointment (weekly for 4 weeks)
- [ ] Edit single occurrence of recurring
- [ ] Edit all occurrences of recurring
- [ ] Delete appointment
- [ ] Link to contact, verify quick actions
- [ ] Link to milestone, verify bidirectional display
- [ ] Add to calendar, verify appears in Calendar app
- [ ] Remove from calendar
- [ ] Test reminder notification fires
- [ ] Test family member sees appointment (CloudKit sync)
- [ ] Test premium gates work correctly

### Edge Cases

- [ ] Create appointment in past
- [ ] Create all-day appointment
- [ ] Create recurring with no end
- [ ] Create recurring ending after 100 occurrences
- [ ] Edit appointment after adding to calendar
- [ ] Delete contact that's linked to appointment
- [ ] Delete milestone that's linked to appointment
- [ ] Calendar permission denied flow
- [ ] Offline creation, sync when online

---

## Summary

This feature enables comprehensive appointment scheduling without requiring a custom server by leveraging:

1. **Core Data + CloudKit** for data storage and family sync (existing infrastructure)
2. **EventKit** for optional calendar integration (native iOS API)
3. **Local notifications** for reminders (existing infrastructure)

The hybrid approach gives users the best of both worlds:
- Full appointment data with custom fields lives in Ollie
- Appointments optionally appear in their native Calendar app
- Family members automatically see appointments via CloudKit
- Calendar sharing works via standard iCloud Calendar sharing

Premium features (recurring, calendar sync, milestone linking) provide clear value-add while keeping core scheduling free.

---

## Quick Reference: Code Patterns to Follow

### Store Pattern (like DocumentStore)

```swift
@MainActor
class AppointmentStore: ObservableObject {
    @Published private(set) var appointments: [DogAppointment] = []
    @Published private(set) var lastError: (message: String, date: Date)?

    private let persistenceController: PersistenceController
    private weak var profileStore: ProfileStore?
    private let logger = Logger.ollie(category: "AppointmentStore")

    init(
        persistenceController: PersistenceController = .shared,
        profileStore: ProfileStore? = nil
    ) {
        self.persistenceController = persistenceController
        self.profileStore = profileStore
        setupObservers()
        loadAppointments()
    }

    func setProfileStore(_ profileStore: ProfileStore) {
        self.profileStore = profileStore
        loadAppointments()
    }

    private func getCurrentProfile() -> CDPuppyProfile? {
        guard let profileId = profileStore?.profile?.id else { return nil }
        return CDPuppyProfile.fetch(byId: profileId, in: viewContext)
    }

    // ... CRUD operations following DocumentStore pattern
}
```

### Core Data Extension Pattern (like CDDogContact+Extensions)

```swift
extension CDDogAppointment {
    func update(from appointment: DogAppointment) {
        self.id = appointment.id
        self.title = appointment.title
        // ... set all fields
        self.modifiedAt = Date()
    }

    static func create(from appointment: DogAppointment, profile: CDPuppyProfile, in context: NSManagedObjectContext) -> CDDogAppointment {
        let entity = CDDogAppointment(context: context)
        entity.update(from: appointment)
        entity.profile = profile
        return entity
    }

    func toAppointment() -> DogAppointment? {
        guard let id = self.id,
              let title = self.title,
              // ... validate required fields
        else { return nil }

        return DogAppointment(
            id: id,
            title: title,
            // ... map all fields
        )
    }

    // Fetch helpers
    static func fetchAppointments(for profile: CDPuppyProfile, in context: NSManagedObjectContext) -> [CDDogAppointment] {
        let request = NSFetchRequest<CDDogAppointment>(entityName: "CDDogAppointment")
        request.predicate = NSPredicate(format: "profile == %@", profile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDogAppointment.startDate, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
}
```

---

*Last updated: Ready for implementation (dog-contacts complete, architecture patterns documented)*
