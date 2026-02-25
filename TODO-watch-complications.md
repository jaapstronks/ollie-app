# watchOS 26 Complications Plan

## Implementation Status

### Completed
- [x] Research watchOS 26 best practices
- [x] Create potty timer complication code (`OllieWatchWidgets/PottyTimerComplication.swift`)
- [x] Create widget data reader (`OllieWatchWidgets/WatchWidgetDataReader.swift`)
- [x] Create widget bundle (`OllieWatchWidgets/OllieWatchWidgetBundle.swift`)
- [x] Create Info.plist and entitlements for widget extension

### Next Steps: Add Widget Extension Target in Xcode

The complication code is ready in `OllieWatchWidgets/`. To activate it:

1. **Open Xcode** and the Ollie-app project

2. **Add Widget Extension Target:**
   - File > New > Target
   - Select **watchOS** tab
   - Choose **Widget Extension**
   - Name: `OllieWatchWidgets`
   - Uncheck "Include Configuration App Intent" (we use StaticConfiguration)
   - Click Finish

3. **Replace generated files:**
   - Delete the auto-generated Swift files in the new target
   - Add existing files from `OllieWatchWidgets/` folder to the target:
     - `OllieWatchWidgetBundle.swift`
     - `PottyTimerComplication.swift`
     - `WatchWidgetDataReader.swift`

4. **Configure entitlements:**
   - Select the OllieWatchWidgets target
   - Go to Signing & Capabilities
   - Add "App Groups" capability
   - Add `group.jaapstronks.Ollie`

5. **Set deployment target:**
   - Set minimum watchOS to 10.0 (for WidgetKit complications)

6. **Build and test:**
   - Select Apple Watch simulator
   - Build (Cmd+B)
   - Add complication to watch face via Watch app or simulator

---

## Research Summary

### watchOS 26 Key Features (WWDC25)

**New in watchOS 26:**
- **Widget Push Updates via APNs** - Can now send push notifications to update widgets without launching the app
- **Controls on Apple Watch** - Built with WidgetKit, allow quick actions without opening app
- **Relevant Widgets** - Show in Smart Stack when contextually relevant (time, location, routine)
- **Smart Stack Hints** - Visual cues guide users based on activity, time, and location
- **iPhone Controls on Watch** - Can add iPhone Control Center toggles to Watch, even without a Watch app

**Interactive Widgets (since watchOS 11):**
- All watchOS widget families support interactivity via `Button` and `Toggle` with `AppIntent`
- Can perform actions directly from widget without launching app
- Use `requestConfirmation()` for sensitive actions

### Widget Families for watchOS

| Family | Description | Use Case |
|--------|-------------|----------|
| `accessoryCircular` | Small circular widget | Potty timer, sleep duration |
| `accessoryRectangular` | Larger rectangular widget | Timer + streak info |
| `accessoryCorner` | Circle with curved gauge/text | Timer with urgency gauge |
| `accessoryInline` | Single line of text | "45m since pee" |

### Key APIs

- **WidgetKit** - Core framework for complications
- **AppIntents** - Required for interactive widgets (Button/Toggle)
- **RelevanceEntry + RelevanceConfiguration** - For Smart Stack relevance
- **CLKComplicationWidgetMigrator** - Only needed if migrating from ClockKit (we're not)

---

## Proposed Complications for Ollie

### 1. Potty Timer Complication (Priority: High)

**Purpose:** Show time since last pee with urgency indicator

**Families to support:**
- `accessoryCircular` - Timer only (e.g., "47m")
- `accessoryRectangular` - Timer + "since last pee" + urgency color
- `accessoryCorner` - Timer with gauge showing urgency (green→yellow→orange→red)
- `accessoryInline` - "47m since pee" or "🟡 47m"

**Data needed from WidgetData:**
- `lastPlasTime`
- Computed urgency level

**Rendering modes:**
- Full color: Green/yellow/orange/red based on urgency
- Accented: System accent + text
- Vibrant: Works on always-on display

### 2. Sleep Duration Complication (Priority: High)

**Purpose:** Show current sleep duration when puppy is sleeping

**Families to support:**
- `accessoryCircular` - Moon icon + duration (e.g., "1h 23m")
- `accessoryRectangular` - "Sleeping" label + duration + moon icon
- `accessoryInline` - "💤 Sleeping 1h 23m"

**Smart Stack Relevance:**
- Highly relevant when `isCurrentlySleeping == true`
- Can use `RelevantIntent` to surface automatically during sleep

**Data needed:**
- `isCurrentlySleeping`
- `sleepStartTime`

### 3. Quick Log Controls (Priority: High - New in watchOS 26!)

**Purpose:** One-tap logging without opening app

**Controls to create:**
- **Log Pee Outside** - Single tap logs outdoor pee
- **Log Poop Outside** - Single tap logs outdoor poop
- **Toggle Sleep** - Start/stop sleep tracking
- **Log Meal** - Quick meal log

**Implementation:**
```swift
struct LogPeeOutsideControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LogPeeOutside") {
            ControlWidgetButton(action: LogPeeOutsideIntent()) {
                Label("Pee Outside", systemImage: "drop.fill")
            }
        }
        .displayName("Log Pee (Outside)")
        .description("Quickly log an outdoor pee")
    }
}
```

**AppIntents needed:**
```swift
struct LogPeeOutsideIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Outdoor Pee"

    func perform() async throws -> some IntentResult {
        // Log event via shared data store
        let event = PuppyEvent.potty(type: .plassen, location: .buiten)
        try WatchIntentDataStore.shared.addEvent(event)
        return .result()
    }
}
```

**Where controls appear:**
- Control Center on Watch
- Smart Stack (if pinned)
- Action button on Apple Watch Ultra

### 4. Streak Complication (Priority: Medium)

**Purpose:** Show current outdoor potty streak

**Families:**
- `accessoryCircular` - Number in circle with fire icon
- `accessoryInline` - "🔥 5 streak"

**Data needed:**
- `currentStreak`
- `bestStreak` (for context in rectangular)

### 5. Meals Today Complication (Priority: Medium)

**Purpose:** Show meals logged vs expected

**Families:**
- `accessoryCircular` - Ring showing 2/3 meals
- `accessoryRectangular` - "Meals: 2/3" + next meal time

**Data needed:**
- `mealsLoggedToday`
- `mealsExpectedToday`
- `nextScheduledMealTime`

---

## Implementation Plan

### Phase 1: Foundation (Controls + Basic Complications)

**1.1 Create Widget Extension Target**
```
OllieWatchWidgets/
├── OllieWatchWidgets.swift          # Widget bundle
├── PottyTimerWidget.swift           # Complication
├── SleepDurationWidget.swift        # Complication
├── Controls/
│   ├── LogPeeOutsideControl.swift
│   ├── LogPoopOutsideControl.swift
│   ├── LogMealControl.swift
│   └── ToggleSleepControl.swift
├── Intents/
│   ├── LogPottyIntent.swift
│   ├── LogMealIntent.swift
│   └── ToggleSleepIntent.swift
└── Assets.xcassets/
```

**1.2 Extend WidgetData**
Add fields if needed:
- Urgency level (pre-computed or compute in widget)
- Sleep duration (or compute from sleepStartTime)

**1.3 App Group Setup**
- Ensure `com.jaapstronks.ollie.shared` is in both:
  - Main Watch app entitlements
  - Widget extension entitlements
- Use `WidgetDataProvider.read()` in widgets

### Phase 2: Complications

**2.1 Potty Timer Widget**
```swift
struct PottyTimerWidget: Widget {
    let kind = "PottyTimer"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PottyTimerProvider()) { entry in
            PottyTimerView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Potty Timer")
        .description("Time since last pee with urgency indicator")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}
```

**2.2 Sleep Duration Widget**
- Show moon + duration when sleeping
- Show "Awake" or hide when not sleeping

### Phase 3: Relevant Widgets (Smart Stack)

**3.1 Sleep Relevance**
```swift
struct SleepRelevanceProvider: AppIntentRelevanceProvider {
    func relevance() async -> WidgetRelevance<SleepConfigurationIntent> {
        let data = WidgetDataProvider.shared.read()
        if data?.isCurrentlySleeping == true {
            return WidgetRelevance(configuration: SleepConfigurationIntent(), relevance: .high)
        }
        return WidgetRelevance(configuration: SleepConfigurationIntent(), relevance: .low)
    }
}
```

**3.2 Potty Urgency Relevance**
- High relevance when urgency is orange/red
- Push to Smart Stack top when puppy likely needs to go

### Phase 4: Push Updates (Optional)

If real-time updates needed:
- Set up APNs for widget push
- Server can push when events logged on iPhone
- Useful for multi-device sync

---

## Technical Considerations

### Data Freshness
- Widgets have limited update frequency
- Use `TimelineReloadPolicy.after(date)` for next urgency threshold
- Example: If urgency goes yellow at 60min, schedule reload at that time

### Rendering Modes
```swift
@Environment(\.widgetRenderingMode) var renderingMode

var urgencyColor: Color {
    switch renderingMode {
    case .fullColor:
        return actualUrgencyColor
    case .accented:
        return .accentColor
    case .vibrant:
        return .white
    }
}
```

### Deep Linking (Known Issue)
- `.widgetURL()` works for tap-to-open
- `.onOpenURL` doesn't work reliably on watchOS
- Use `NavigationPath` or manual state for navigation
- Alternative: Use `EnvironmentValues.openURL` in widget button intent

### Interactive Widget Limitations
- Only `Button` and `Toggle` with `AppIntent` work
- Actions run in widget extension process
- Use shared data store (App Group) for persistence
- Widget UI only updates after app is fully backgrounded (known bug)

---

## File Structure

```
OllieWatchWidgets/                    # Widget Extension (separate target)
├── OllieWatchWidgetBundle.swift      # @main entry point ✅
├── PottyTimerComplication.swift      # Potty timer complication ✅
├── WatchWidgetDataReader.swift       # Reads data from App Group ✅
├── Info.plist                        # Extension config ✅
├── OllieWatchWidgets.entitlements    # App Group entitlement ✅
├── SleepDurationComplication.swift   # TODO
├── StreakComplication.swift          # TODO
├── Controls/                         # TODO: watchOS 26 Controls
│   ├── LogPeeControl.swift
│   ├── LogPoopControl.swift
│   ├── LogMealControl.swift
│   └── ToggleSleepControl.swift
└── Intents/                          # TODO: AppIntents for Controls
    ├── LogPottyIntent.swift
    ├── LogMealIntent.swift
    └── ToggleSleepIntent.swift
```

---

## Priority Order

1. **Log Pee Outside Control** - Most valuable quick action
2. **Potty Timer Complication** - Core use case
3. **Toggle Sleep Control** - Second most used action
4. **Sleep Duration Complication** - Shows during sleep
5. **Log Poop/Meal Controls** - Complete the set
6. **Streak Complication** - Nice to have
7. **Relevant Widget integration** - Smart Stack auto-surfacing

---

## Sources

- [What's new in watchOS 26 - WWDC25](https://developer.apple.com/videos/play/wwdc2025/334/)
- [What's new in widgets - WWDC25](https://developer.apple.com/videos/play/wwdc2025/278/)
- [Creating accessory widgets and watch complications](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications)
- [Migrating ClockKit complications to WidgetKit](https://developer.apple.com/documentation/widgetkit/converting-a-clockkit-app)
- [Go further with Complications in WidgetKit - WWDC22](https://developer.apple.com/videos/play/wwdc2022/10051/)
- [Build widgets for the Smart Stack - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10029/)
- [What's new in watchOS 11 - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10205/)
- [Human Interface Guidelines - Complications](https://developer.apple.com/design/human-interface-guidelines/watchos/overview/complications/)
