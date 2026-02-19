# TODO: Generalize to Any Puppy

Refactor from hardcoded Ollie constants to a configurable `PuppyProfile` model, so the app works for any puppy.

## Step 1: PuppyProfile Model

Create `Models/PuppyProfile.swift`:

```swift
struct PuppyProfile: Codable {
    var name: String
    var breed: String?               // Optional, for display + defaults
    var birthDate: Date
    var homeDate: Date               // First day home
    var sizeCategory: SizeCategory   // Determines exercise limits, meal defaults
    
    enum SizeCategory: String, Codable, CaseIterable {
        case small      // < 10kg adult
        case medium     // 10-25kg
        case large      // 25-45kg
        case extraLarge // > 45kg
    }
}
```

## Step 2: Configurable Meal Schedule

Create `Models/MealSchedule.swift`:

```swift
struct MealSchedule: Codable {
    var mealsPerDay: Int          // 3-4 for pups, 2 for adults
    var portions: [MealPortion]   // per meal
    
    struct MealPortion: Codable {
        var label: String         // "Ontbijt", "Lunch", etc.
        var amount: String        // "110g vlees compleet", freeform
        var targetTime: String?   // "07:00", optional guideline
    }
    
    /// Default schedule based on age in weeks
    static func defaultSchedule(ageWeeks: Int, size: PuppyProfile.SizeCategory) -> MealSchedule
}
```

Current Ollie schedule for reference:
- 4 meals/day: ontbijt (110g vlees), lunch +4h (110g vlees), middag +4h (110g vlees), avond +3h (80g brokjes)
- This is breed/breeder specific — make it fully editable

## Step 3: Exercise Limits

The "5 minutes per month of age" rule is widely used but conservative. Make it configurable:

```swift
struct ExerciseConfig: Codable {
    var minutesPerMonthOfAge: Int  // default: 5
    var maxWalksPerDay: Int?       // optional cap
}
```

## Step 4: Prediction Tuning

Move these from hardcoded constants to profile-level config:

```swift
struct PredictionConfig: Codable {
    var minNapDurationForPottyTrigger: Int  // default: 15 min
    var bedtimeHour: Int                     // default: 22
    var postMealGapMultiplier: Double        // default: 0.75
    var postSleepGapMultiplier: Double       // default: 0.75
    var defaultGapMinutes: Int               // default: 90
}
```

## Step 5: Onboarding Flow

Create a simple onboarding for new users:

1. "Hoe heet je puppy?" — name input + optional photo
2. "Wanneer is [name] geboren?" — date picker
3. "Wanneer kwam [name] thuis?" — date picker  
4. "Hoe groot wordt [name]?" — size category picker (with breed examples)
5. Optional: breed selector (autocomplete, for future defaults)
6. "Hoeveel maaltijden per dag?" — quick config

Store as `profile.json` in documents directory.

## Step 6: Migrate Constants

Replace all hardcoded references:
- `Constants.birthDate` → `profile.birthDate`
- `Constants.startDate` → `profile.homeDate`  
- `Constants.bedtimeHour` → `profile.predictionConfig.bedtimeHour`
- Event type labels and emoji stay universal (not per-profile)

## Step 7: Update CLAUDE.md

After implementation, update CLAUDE.md:
- Remove hardcoded dates from Constants section
- Document PuppyProfile model
- Add onboarding flow to feature list

## Done Criteria
- [ ] App starts with onboarding if no profile exists
- [ ] All dates/schedules come from PuppyProfile, not constants
- [ ] Existing Ollie data still works (backward compatible)
- [ ] Profile editable from settings screen
- [ ] Meal schedule editable

Delete this file when done.
