# Appointments Premium Features

Status: Models complete, UI implementation pending for Ollie+ premium tier.

---

## 1. Recurring Appointments

**Status:** Model complete, UI pending

### What's Ready
- `RecurrenceRule` struct in OllieShared with full support for:
  - Daily, weekly, monthly, yearly frequencies
  - Custom intervals (every X days/weeks/months)
  - Days of week selection (for weekly recurrence)
  - End conditions: never, after X occurrences, or on specific date
  - `displayDescription` for human-readable recurrence text
- Core Data fields in `CDDogAppointment`:
  - `recurrenceFrequency`, `recurrenceInterval`, `recurrenceEndDate`, `recurrenceCount`, `recurrenceDaysOfWeek`
- Conversion logic in `CDDogAppointment+Extensions.swift`

### What's Needed
1. **RecurrenceEditor.swift** component with:
   - Frequency picker (daily, weekly, monthly, yearly)
   - Interval stepper ("Every X weeks")
   - Days of week selector (for weekly)
   - End condition picker (never, after X times, on date)
   - Preview text ("Every Thursday for 4 weeks")

2. **Integration into AddEditAppointmentSheet.swift**:
   - Add toggle: "Repeats" (premium gated)
   - Show RecurrenceEditor when enabled
   - Wire up recurrence data to appointment

3. **Editing recurring appointments**:
   - "Edit this occurrence only" vs "Edit all future occurrences"
   - Mirror iOS Calendar behavior

### Use Cases
- Weekly puppy training classes (8-week course)
- Bi-weekly grooming appointments
- Monthly flea/tick medication reminders
- Daily daycare (Tue/Thu every week)

---

## 2. EventKit Calendar Sync

**Status:** Model complete, code pending

### What's Ready
- `calendarEventID` field in Core Data model
- `calendarEventID` property in `DogAppointment` struct
- `isSyncedToCalendar` computed property
- Localization strings for calendar sync UI

### What's Needed
1. **CalendarSyncService.swift** (or extend existing CalendarService):
   ```swift
   func addAppointmentToCalendar(_ appointment: DogAppointment, profile: PuppyProfile) async throws -> String
   func removeAppointmentFromCalendar(eventId: String) async throws
   func updateAppointmentInCalendar(_ appointment: DogAppointment) async throws
   ```

2. **Calendar permission flow**:
   - Request calendar access when user first taps "Add to Calendar"
   - Handle permission denied gracefully
   - Settings deep link for permission management

3. **Calendar picker**:
   - Let user choose which calendar to sync to
   - Support shared family calendars
   - Remember preference in `@AppStorage`

4. **UI Integration**:
   - "Add to Calendar" button in AppointmentDetailView
   - "In Calendar" badge when synced
   - "Remove from Calendar" option
   - Bulk sync option ("Sync all upcoming appointments")

5. **Sync behavior**:
   - Include dog name in calendar event title
   - Add reminder/alarm from appointment settings
   - Sync recurrence rules to EKRecurrenceRule

### Reference Code (from TODO-appointments-scheduling.md)
```swift
func addAppointment(_ appointment: DogAppointment, profile: PuppyProfile) async throws -> String {
    let event = EKEvent(eventStore: eventStore)
    event.title = "\(profile.name): \(appointment.title)"
    event.startDate = appointment.startDate
    event.endDate = appointment.endDate
    event.isAllDay = appointment.isAllDay
    event.location = appointment.location
    event.notes = appointment.notes

    if appointment.reminderMinutesBefore > 0 {
        let alarm = EKAlarm(relativeOffset: TimeInterval(-appointment.reminderMinutesBefore * 60))
        event.addAlarm(alarm)
    }

    try eventStore.save(event, span: .futureEvents)
    return event.eventIdentifier
}
```

---

## 3. Milestone Linking UI

**Status:** Model complete, UI pending

### What's Ready
- `linkedMilestoneID` field in Core Data model
- `linkedMilestoneID` property in `DogAppointment` struct
- `hasLinkedMilestone` computed property
- `isHealthRelated` property on `AppointmentType` for smart suggestions
- Query methods in AppointmentStore: `appointments(linkedToMilestoneId:)`

### What's Needed
1. **MilestonePicker component**:
   - Show upcoming health milestones when appointment type is health-related
   - Filter by category (vaccinations, checkups, etc.)
   - Show milestone target date for context

2. **Integration into AddEditAppointmentSheet.swift**:
   - Show milestone picker section for health-related appointment types
   - Auto-suggest relevant milestones based on appointment type

3. **Bidirectional display**:
   - AppointmentDetailView: Show linked milestone with status
   - MilestoneDetailView: Show "Appointment scheduled: [date]"

4. **Completion flow**:
   - When marking appointment complete, offer to mark linked milestone complete
   - Pre-fill completion date from appointment date

### Use Cases
- Link "2nd Vaccination" appointment to "2nd Vaccination" milestone
- Link "Vet Checkup" to "6-month checkup" milestone
- Automatic milestone completion when appointment is marked done

---

## Premium Gating Strategy

| Feature | Free Tier | Ollie+ |
|---------|-----------|--------|
| View appointments | ✓ | ✓ |
| Add one-time appointments | ✓ | ✓ |
| Basic reminders (1 hour) | ✓ | ✓ |
| Contact linking | ✓ | ✓ |
| **Recurring appointments** | - | ✓ |
| **Custom reminder times** | - | ✓ |
| **Calendar sync** | - | ✓ |
| **Milestone linking** | - | ✓ |

### Paywall UX
When user tries to access premium feature:
1. Show feature explanation with benefit
2. "Unlock with Ollie+" CTA button
3. "Maybe Later" dismiss option

---

## Implementation Priority

1. **Calendar Sync** (highest value, most requested)
2. **Recurring Appointments** (clear power-user feature)
3. **Milestone Linking** (enhances health tracking story)

---

## Files to Create/Modify

### New Files
- `Views/Appointments/RecurrenceEditor.swift`
- `Services/CalendarSyncService.swift` (or extend CalendarService)
- `Views/Appointments/MilestonePicker.swift`

### Modified Files
- `Views/Appointments/AddEditAppointmentSheet.swift` - Add recurrence toggle, milestone picker
- `Views/Appointments/AppointmentDetailView.swift` - Add calendar sync button, milestone section
- `Views/Milestones/MilestoneDetailView.swift` - Show linked appointment
- `Utils/Strings/Strings+Appointments.swift` - Additional premium feature strings

---

*Last updated: February 2026*
