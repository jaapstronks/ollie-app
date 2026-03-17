# Grooming & Care Tracking Feature

## The Big Idea

Dogs need regular grooming and care, but the frequency varies dramatically by coat type. A Poodle needs brushing every other day and bathing every 3 weeks, while a Beagle only needs weekly brushing and bathing every 2 months. This feature provides:

1. **Coat-type-aware defaults** - Set your dog's coat type once, get a customized grooming schedule
2. **Gentle reminders** - See nudges on the Today tab when grooming is overdue
3. **Easy logging** - Mark activities complete with one tap
4. **User customization** - Override any interval to match your routine

## What Was Implemented

### Core Model: CoatType (`OtisShared/Models/CoatType.swift`)

Seven coat types with research-backed defaults:

| Coat Type | Examples | Bath | Brushing | Pro Grooming |
|-----------|----------|------|----------|--------------|
| Short/Smooth | Beagle, Boxer | 2 months | Weekly | Not needed |
| Medium | Border Collie | 5 weeks | Every 3 days | 8 weeks |
| Long | Shih Tzu, Yorkie | 4 weeks | Daily | 6 weeks |
| Curly | Poodle, Doodles | 3 weeks | Every other day | 6 weeks |
| Double | Golden, Husky | 7 weeks | Every 3 days | 10 weeks |
| Wire | Schnauzer, Terriers | 5 weeks | Every 3 days | 8 weeks |
| Hairless | Chinese Crested | Weekly | Not needed | Not needed |

Each coat type includes:
- Default intervals for all grooming activities
- Care tips (e.g., "Never shave a double coat")
- Breed auto-detection (Golden Retriever → Double Coat)

### Profile Integration

- Added `coatType: CoatType?` field to `PuppyProfile`
- Added `suggestedCoatType` computed property (breed-based suggestion)
- Added `effectiveCoatType` (explicit or suggested)
- Full Core Data support via `CDPuppyProfile`

### Settings UI (`Views/Settings/GroomingSettingsView.swift`)

- Coat type picker with breed-based suggestions
- Per-activity interval configuration (stepper)
- Enable/disable toggles for each activity
- Care tips section based on coat type
- "Reset to Defaults" button

### Today Tab Integration

- `GroomingNudgeCard` shows when activities are overdue
- Displays most urgent activity with "Mark Complete" button
- Shows additional overdue items if multiple
- Snooze/dismiss for today
- "View All" links to settings

### Wiring

- `SheetCoordinator` has `.groomingSettings` case
- `TodayStatusCardsSection` includes grooming nudge card
- `TodayView` passes overdue activities from `RoutineStore`
- `DogSettingsCard` has navigation link to grooming settings
- `RoutineStore` uses coat type when seeding defaults

## Current State

### What Works
- Setting coat type in Settings → Dog → Grooming Schedule
- Breed auto-suggestion for coat type
- Customizing grooming intervals
- Seeing overdue reminders on Today tab
- Marking activities complete from nudge card
- Resetting to coat-type defaults

### What's Partially Working
- Strings are defined inline (extensions) rather than in main Strings files
- Preview providers need RoutineStore environment

### Known Issues
- Pre-existing build errors in ShareAnalytics.swift/ShareService.swift (unrelated to this feature)

## Next Steps

### Short Term
1. **Add to onboarding** - Ask coat type during dog setup (after breed)
2. **Localize strings** - Move inline strings to Strings+Routines.swift and add translations
3. **Add quick log sheet** - Allow logging from Today tab without going to settings

### Medium Term
4. **Care event history** - Show history of grooming activities in Health tab
5. **Photo attachments** - Before/after grooming photos
6. **Professional appointment linking** - Connect grooming activities to appointments
7. **Notifications** - Push notifications when grooming is due

### Future Ideas
8. **Seasonal adjustments** - "It's shedding season, brush more often"
9. **Activity triggers** - "Your dog swam today - consider a rinse"
10. **Groomer notes** - Store notes from professional visits
11. **AI insights** - "Luna's coat health has improved since increasing brushing"

## Files Created/Modified

### New Files
- `OtisShared/Models/CoatType.swift` - Coat type enum with defaults
- `Views/Settings/GroomingSettingsView.swift` - Settings UI
- `Views/Cards/GroomingNudgeCard.swift` - Today tab nudge
- `BRIEF-09-GROOMING-CARE.md` - Full design brief

### Modified Files
- `PuppyProfile.swift` - Added coatType field
- `CDPuppyProfile+Extensions.swift` - Core Data support
- `Ollie.xcdatamodel` - Added coatType attribute
- `RoutineStore.swift` - Coat-aware seeding + reset method
- `TodayStatusCardsSection.swift` - Grooming nudge integration
- `TodayView.swift` - RoutineStore + grooming callbacks
- `SheetCoordinator.swift` - Added .groomingSettings case
- `SheetContent+Events.swift` - Grooming settings sheet builder
- `DogSettingsCard.swift` - Navigation link to grooming

## Related Documentation

- `BRIEF-09-GROOMING-CARE.md` - Full design brief with all code patterns
