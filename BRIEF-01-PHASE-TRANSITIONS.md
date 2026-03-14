# Brief 01: Phase Transitions

> **Status:** Ready for Implementation
> **Priority:** Medium
> **Dependencies:** None
> **Estimated Effort:** Low

## Objective

Polish the lifecycle transition experience with celebration sheets and smart notification profile suggestions.

## Features

### 1. Phase Transition Celebration Sheet

When a dog enters a new lifecycle phase, show a celebratory sheet explaining what changes.

```
┌─────────────────────────────────────┐
│         Luna is Growing Up!         │
│                                     │
│   Luna has entered the teenage      │
│   phase! Here's what changes:       │
│                                     │
│   • Quick log shows behavior button │
│   • Training shifts to maintenance  │
│   • More focus on adventures        │
│                                     │
│   Notification Preferences:         │
│   ┌─────────────────────────────┐   │
│   │ ○ Keep current settings     │   │
│   │ ● Use teenage defaults      │   │
│   │   (less potty, more walks)  │   │
│   └─────────────────────────────┘   │
│                                     │
│          [ Let's Go! ]              │
└─────────────────────────────────────┘
```

**Phase-specific messaging:**

| Transition | Title | Key Changes |
|------------|-------|-------------|
| Puppy → Teenage | "Growing Up!" | Behavior logging, less potty focus, training maintenance |
| Teenage → Adult | "All Grown Up!" | Routine focus, health monitoring, moments capture |
| Adult → Senior | "Golden Years" | Wellness focus, medication reminders, comfort tips |

### 2. Profile Tracking

Add field to track acknowledged phases:

```swift
// PuppyProfile.swift
public var lastAcknowledgedPhase: LifecyclePhase?
```

### 3. App Launch Check

On app launch, compare current phase to last acknowledged:

```swift
// OllieApp.swift or similar
if profile.lifecyclePhase != profile.lastAcknowledgedPhase {
    showPhaseTransitionSheet = true
}
```

### 4. Notification Profile Suggestions

Each phase has default notification preferences:

| Notification | Puppy | Teenage | Adult | Senior |
|--------------|-------|---------|-------|--------|
| Potty predictions | Every 2-3h | Off | Off | Off |
| Walk reminders | 2-3x daily | 2-3x daily | Per schedule | Per schedule |
| Training nudges | 1-2x daily | Weekly | Off | Off |
| Meal reminders | Per schedule | Per schedule | Per schedule | Per schedule |
| Medication | Off | Off | Off | Per schedule |
| Memory prompts | Off | Weekly | Weekly | Weekly |

## Implementation

### Files to Create

```
Ollie-app/Views/Onboarding/PhaseTransitionSheet.swift
```

### Files to Modify

```
OtisShared/Sources/OtisShared/Models/PuppyProfile.swift
  - Add lastAcknowledgedPhase: LifecyclePhase?

Ollie-app/OllieApp.swift (or ContentView)
  - Add phase check on appear
  - Add sheet presentation

Ollie-app/Utils/Strings/Strings+Lifecycle.swift (or Strings.swift)
  - Add transition celebration strings
```

### Model Changes

```swift
// PuppyProfile.swift
public struct PuppyProfile {
    // ... existing fields ...

    /// Last lifecycle phase the user has acknowledged via transition sheet
    public var lastAcknowledgedPhase: LifecyclePhase?
}
```

### View Implementation

```swift
// PhaseTransitionSheet.swift
struct PhaseTransitionSheet: View {
    let profile: PuppyProfile
    let onDismiss: (Bool) -> Void  // Bool = whether to apply suggested notifications

    var body: some View {
        VStack(spacing: 24) {
            // Celebration header
            celebrationHeader

            // What's changing
            changesSection

            // Notification preference picker
            notificationPreferencePicker

            // Dismiss button
            Button(Strings.Lifecycle.Transition.letsGo) {
                onDismiss(applyNotificationDefaults)
            }
            .buttonStyle(.primaryAction)
        }
    }

    private var changesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(changes(for: profile.lifecyclePhase), id: \.self) { change in
                Label(change, systemImage: "checkmark.circle.fill")
            }
        }
    }

    private func changes(for phase: LifecyclePhase) -> [String] {
        switch phase {
        case .teenage:
            return [
                Strings.Lifecycle.Transition.Teenage.behaviorTracking,
                Strings.Lifecycle.Transition.Teenage.maintenanceMode,
                Strings.Lifecycle.Transition.Teenage.adventureFocus
            ]
        case .adult:
            return [
                Strings.Lifecycle.Transition.Adult.routineFocus,
                Strings.Lifecycle.Transition.Adult.healthMonitoring,
                Strings.Lifecycle.Transition.Adult.memoriesCapture
            ]
        case .senior:
            return [
                Strings.Lifecycle.Transition.Senior.wellnessCheckins,
                Strings.Lifecycle.Transition.Senior.medicationReminders,
                Strings.Lifecycle.Transition.Senior.comfortTips
            ]
        case .puppy:
            return [] // No transition TO puppy
        }
    }
}
```

## Strings to Add

```swift
// Strings+Lifecycle.swift or Strings.swift
enum Lifecycle {
    enum Transition {
        static let letsGo = String(localized: "Let's go!")

        enum Teenage {
            static let title = String(localized: "\(name) is growing up!")
            static let subtitle = String(localized: "\(name) has entered the teenage phase!")
            static let behaviorTracking = String(localized: "Track behavior challenges")
            static let maintenanceMode = String(localized: "Training shifts to maintenance")
            static let adventureFocus = String(localized: "More focus on adventures")
        }

        enum Adult {
            static let title = String(localized: "\(name) is all grown up!")
            static let subtitle = String(localized: "\(name) is now an adult dog!")
            static let routineFocus = String(localized: "Establish daily routines")
            static let healthMonitoring = String(localized: "Health monitoring begins")
            static let memoriesCapture = String(localized: "Capture special moments")
        }

        enum Senior {
            static let title = String(localized: "\(name)'s golden years")
            static let subtitle = String(localized: "\(name) is now a senior dog!")
            static let wellnessCheckins = String(localized: "Regular wellness check-ins")
            static let medicationReminders = String(localized: "Medication tracking enabled")
            static let comfortTips = String(localized: "Comfort and care tips")
        }

        enum Notifications {
            static let keepCurrent = String(localized: "Keep current settings")
            static let useDefaults = String(localized: "Use recommended settings")
        }
    }
}
```

## Testing

- [ ] Verify sheet shows on first launch after phase change
- [ ] Verify sheet doesn't show again after acknowledgment
- [ ] Verify notification defaults apply correctly if selected
- [ ] Verify each phase has appropriate messaging
- [ ] Test edge case: app update when dog already transitioned

## Notes

- Sheet should be non-dismissible (no swipe down) to ensure acknowledgment
- Consider adding confetti or animation for celebration feel
- This is a "polish" feature - ship after core health features if time is limited
