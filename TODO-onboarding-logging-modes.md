# TODO: Adaptive Logging & Onboarding Modes

## Overview

Not every user needs every feature. This briefing covers **module preferences** — letting users choose which tracking modules are active — and **adaptive logging** that evolves over time. The app should gracefully wind down unused features and nudge users toward a simpler setup as their needs change.

The app already has onboarding. This is about making the experience **adaptive** after onboarding, with smart defaults and user control.

## Core Concept: Module System

### Module Registry

```swift
// TrackingModule.swift (OllieShared)
import Foundation

public enum TrackingModule: String, CaseIterable, Codable, Identifiable {
    case medications = "medications"
    case walks = "walks"
    case socialization = "socialization"
    case training = "training"
    case feeding = "feeding"
    case documents = "documents"
    case milestones = "milestones"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .medications: return String(localized: "module.medications")
        case .walks: return String(localized: "module.walks")
        case .socialization: return String(localized: "module.socialization")
        case .training: return String(localized: "module.training")
        case .feeding: return String(localized: "module.feeding")
        case .documents: return String(localized: "module.documents")
        case .milestones: return String(localized: "module.milestones")
        }
    }

    public var description: String {
        switch self {
        case .medications: return String(localized: "module.medications.desc")
        case .walks: return String(localized: "module.walks.desc")
        case .socialization: return String(localized: "module.socialization.desc")
        case .training: return String(localized: "module.training.desc")
        case .feeding: return String(localized: "module.feeding.desc")
        case .documents: return String(localized: "module.documents.desc")
        case .milestones: return String(localized: "module.milestones.desc")
        }
    }

    public var systemImage: String {
        switch self {
        case .medications: return "pills"
        case .walks: return "figure.walk"
        case .socialization: return "person.3"
        case .training: return "graduationcap"
        case .feeding: return "fork.knife"
        case .documents: return "doc.text"
        case .milestones: return "star"
        }
    }

    /// Default modules enabled for new users
    public static var defaultEnabled: Set<TrackingModule> {
        [.medications, .walks, .feeding, .documents]
    }

    /// Modules that are puppy-specific and can be suggested for disabling
    public static var puppySpecific: Set<TrackingModule> {
        [.socialization, .milestones, .training]
    }
}
```

### Module Preferences Storage

Use `@AppStorage` for simple, fast access across the app:

```swift
// ModulePreferences.swift
import SwiftUI

@MainActor
final class ModulePreferences: ObservableObject {
    static let shared = ModulePreferences()

    /// Stored as comma-separated rawValues in UserDefaults
    @AppStorage("enabledModules") private var enabledModulesRaw: String = ""

    @Published var enabledModules: Set<TrackingModule> = []

    private init() {
        if enabledModulesRaw.isEmpty {
            // First launch: use defaults
            enabledModules = TrackingModule.defaultEnabled
            saveToStorage()
        } else {
            loadFromStorage()
        }
    }

    func isEnabled(_ module: TrackingModule) -> Bool {
        enabledModules.contains(module)
    }

    func setEnabled(_ module: TrackingModule, enabled: Bool) {
        if enabled {
            enabledModules.insert(module)
        } else {
            enabledModules.remove(module)
        }
        saveToStorage()
    }

    func toggleModule(_ module: TrackingModule) {
        if enabledModules.contains(module) {
            enabledModules.remove(module)
        } else {
            enabledModules.insert(module)
        }
        saveToStorage()
    }

    private func saveToStorage() {
        enabledModulesRaw = enabledModules.map(\.rawValue).joined(separator: ",")
    }

    private func loadFromStorage() {
        enabledModules = Set(
            enabledModulesRaw
                .split(separator: ",")
                .compactMap { TrackingModule(rawValue: String($0)) }
        )
    }
}
```

### Environment Integration

Make module preferences available throughout the view hierarchy:

```swift
// ModulePreferencesKey.swift
import SwiftUI

private struct ModulePreferencesKey: EnvironmentKey {
    static let defaultValue = ModulePreferences.shared
}

extension EnvironmentValues {
    var modulePreferences: ModulePreferences {
        get { self[ModulePreferencesKey.self] }
        set { self[ModulePreferencesKey.self] = newValue }
    }
}
```

Usage in any view:
```swift
@Environment(\.modulePreferences) private var modules

var body: some View {
    if modules.isEnabled(.medications) {
        MedicationReminderCard()
    }
}
```

---

## Tab Visibility

### Adapting ContentView

The main tab view should respect module preferences:

```swift
// ContentView.swift (modified)
import SwiftUI

struct ContentView: View {
    @StateObject private var modulePrefs = ModulePreferences.shared

    var body: some View {
        TabView {
            // Home is always visible
            HomeView()
                .tabItem { Label(String(localized: "tab.home"), systemImage: "house") }

            // Conditional tabs based on enabled modules
            if modulePrefs.isEnabled(.walks) {
                WalksView()
                    .tabItem { Label(String(localized: "tab.walks"), systemImage: "figure.walk") }
            }

            if modulePrefs.isEnabled(.socialization) {
                SocializationView()
                    .tabItem { Label(String(localized: "tab.socialization"), systemImage: "person.3") }
            }

            if modulePrefs.isEnabled(.medications) {
                MedicationsView()
                    .tabItem { Label(String(localized: "tab.medications"), systemImage: "pills") }
            }

            // Settings always visible
            SettingsView()
                .tabItem { Label(String(localized: "tab.settings"), systemImage: "gear") }
        }
        .environmentObject(modulePrefs)
    }
}
```

### Home View Adaptation

The home/dashboard view should only show cards for enabled modules:

```swift
// In HomeView or DashboardView
@EnvironmentObject var modulePrefs: ModulePreferences

var body: some View {
    ScrollView {
        LazyVStack(spacing: 16) {
            if modulePrefs.isEnabled(.medications) {
                MedicationReminderCard()
            }
            if modulePrefs.isEnabled(.walks) {
                WalkScheduleCard()
            }
            if modulePrefs.isEnabled(.feeding) {
                FeedingCard()
            }
            if modulePrefs.isEnabled(.milestones) {
                MilestoneProgressCard()
            }
            // etc.
        }
        .padding()
    }
}
```

---

## Module Settings View

Let users toggle modules on/off:

```swift
// ModuleSettingsView.swift
import SwiftUI

struct ModuleSettingsView: View {
    @ObservedObject var preferences: ModulePreferences

    var body: some View {
        List {
            Section {
                Text(String(localized: "modules.description"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "modules.active")) {
                ForEach(TrackingModule.allCases) { module in
                    ModuleToggleRow(
                        module: module,
                        isEnabled: preferences.isEnabled(module),
                        onToggle: { preferences.toggleModule(module) }
                    )
                }
            }

            Section {
                Button(String(localized: "modules.resetDefaults")) {
                    preferences.enabledModules = TrackingModule.defaultEnabled
                }
            }
        }
        .navigationTitle(String(localized: "modules.title"))
    }
}

struct ModuleToggleRow: View {
    let module: TrackingModule
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Toggle(isOn: Binding(get: { isEnabled }, set: { _ in onToggle() })) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(module.displayName)
                    Text(module.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: module.systemImage)
                    .foregroundStyle(isEnabled ? .blue : .gray)
            }
        }
    }
}
```

Integration into Settings:
```swift
// In DogProfileSettingsView or SettingsView
NavigationLink {
    ModuleSettingsView(preferences: ModulePreferences.shared)
} label: {
    Label(String(localized: "modules.title"), systemImage: "square.grid.2x2")
}
```

---

## Onboarding Integration

### Module Selection During Onboarding

Add a step to the existing onboarding flow where users pick which modules they want:

```swift
// OnboardingModuleSelectionView.swift
import SwiftUI

struct OnboardingModuleSelectionView: View {
    @ObservedObject var preferences = ModulePreferences.shared
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text(String(localized: "onboarding.modules.title"))
                    .font(.title2.bold())

                Text(String(localized: "onboarding.modules.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            // Module grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TrackingModule.allCases) { module in
                    ModuleCard(
                        module: module,
                        isSelected: preferences.isEnabled(module),
                        onTap: { preferences.toggleModule(module) }
                    )
                }
            }
            .padding(.horizontal)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text(String(localized: "onboarding.continue"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

struct ModuleCard: View {
    let module: TrackingModule
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: module.systemImage)
                    .font(.title2)
                Text(module.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
```

---

## Graceful Wind-Down: Usage Detection

### Activity Tracking

Track when modules were last used to detect abandoned features:

```swift
// ModuleActivityTracker.swift
import Foundation

final class ModuleActivityTracker {
    static let shared = ModuleActivityTracker()

    private let defaults = UserDefaults.standard
    private let prefix = "moduleLastUsed_"

    func recordActivity(_ module: TrackingModule) {
        defaults.set(Date().timeIntervalSince1970, forKey: prefix + module.rawValue)
    }

    func lastActivity(_ module: TrackingModule) -> Date? {
        let timestamp = defaults.double(forKey: prefix + module.rawValue)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    func daysSinceLastActivity(_ module: TrackingModule) -> Int? {
        guard let lastDate = lastActivity(module) else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }

    /// Modules that haven't been used in the given number of days
    func inactiveModules(
        threshold: Int = 30,
        among enabledModules: Set<TrackingModule>
    ) -> [TrackingModule] {
        enabledModules.filter { module in
            guard let days = daysSinceLastActivity(module) else {
                // Never used — also inactive
                return true
            }
            return days >= threshold
        }
    }
}
```

Sprinkle `recordActivity` calls in existing stores:
```swift
// In MedicationStore.swift
func completeMedication(_ med: MedicationSchedule) {
    ModuleActivityTracker.shared.recordActivity(.medications)
    // ... existing code
}

// In SpotStore.swift
func startWalk(at spot: WalkSpot) {
    ModuleActivityTracker.shared.recordActivity(.walks)
    // ... existing code
}
```

---

## Nudge System

### Nudge Cards

Show contextual suggestions based on usage patterns:

```swift
// NudgeType.swift
import Foundation

enum NudgeType: Identifiable {
    case disableUnused(module: TrackingModule, daysSinceUse: Int)
    case enableSuggestion(module: TrackingModule, reason: String)
    case phaseTransition(from: DogLifePhase, to: DogLifePhase)
    case simplifyMode  // suggest disabling multiple modules at once

    var id: String {
        switch self {
        case .disableUnused(let m, _): return "disable_\(m.rawValue)"
        case .enableSuggestion(let m, _): return "enable_\(m.rawValue)"
        case .phaseTransition(_, let to): return "phase_\(to.rawValue)"
        case .simplifyMode: return "simplify"
        }
    }
}
```

```swift
// NudgeEngine.swift
import Foundation

@MainActor
final class NudgeEngine: ObservableObject {
    @Published var activeNudges: [NudgeType] = []

    private let tracker = ModuleActivityTracker.shared
    private let preferences = ModulePreferences.shared
    private let dismissedNudgesKey = "dismissedNudges"

    func evaluate(profile: PuppyProfile) {
        var nudges: [NudgeType] = []

        // Check for unused modules
        let inactive = tracker.inactiveModules(
            threshold: 30,
            among: preferences.enabledModules
        )
        for module in inactive {
            let days = tracker.daysSinceLastActivity(module) ?? 30
            nudges.append(.disableUnused(module: module, daysSinceUse: days))
        }

        // Phase transition nudge
        let currentPhase = DogLifePhase(ageInWeeks: profile.ageInWeeks)
        let puppyModulesStillEnabled = TrackingModule.puppySpecific
            .intersection(preferences.enabledModules)
        if currentPhase != .puppy && !puppyModulesStillEnabled.isEmpty {
            nudges.append(.phaseTransition(from: .puppy, to: currentPhase))
        }

        // Simplify mode: if 3+ modules are inactive
        if inactive.count >= 3 {
            nudges.append(.simplifyMode)
        }

        // Filter out dismissed nudges
        let dismissed = Set(UserDefaults.standard.stringArray(forKey: dismissedNudgesKey) ?? [])
        activeNudges = nudges.filter { !dismissed.contains($0.id) }
    }

    func dismiss(_ nudge: NudgeType) {
        var dismissed = UserDefaults.standard.stringArray(forKey: dismissedNudgesKey) ?? []
        dismissed.append(nudge.id)
        UserDefaults.standard.set(dismissed, forKey: dismissedNudgesKey)
        activeNudges.removeAll { $0.id == nudge.id }
    }
}
```

### Nudge Card View

```swift
// NudgeCardView.swift
import SwiftUI

struct NudgeCardView: View {
    let nudge: NudgeType
    let onAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 4) {
                Button(actionLabel, action: onAction)
                    .font(.caption.bold())
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                Button(String(localized: "nudge.dismiss"), action: onDismiss)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var icon: String {
        switch nudge {
        case .disableUnused(let m, _): return m.systemImage
        case .enableSuggestion(let m, _): return m.systemImage
        case .phaseTransition: return "sparkles"
        case .simplifyMode: return "leaf"
        }
    }

    private var iconColor: Color {
        switch nudge {
        case .disableUnused: return .orange
        case .enableSuggestion: return .blue
        case .phaseTransition: return .purple
        case .simplifyMode: return .green
        }
    }

    private var title: String {
        switch nudge {
        case .disableUnused(let m, _):
            return String(localized: "nudge.unused.title \(m.displayName)")
        case .enableSuggestion(let m, _):
            return String(localized: "nudge.suggest.title \(m.displayName)")
        case .phaseTransition(_, let to):
            return String(localized: "nudge.phase.title \(to.displayName)")
        case .simplifyMode:
            return String(localized: "nudge.simplify.title")
        }
    }

    private var subtitle: String {
        switch nudge {
        case .disableUnused(_, let days):
            return String(localized: "nudge.unused.subtitle \(days)")
        case .enableSuggestion(_, let reason):
            return reason
        case .phaseTransition:
            return String(localized: "nudge.phase.subtitle")
        case .simplifyMode:
            return String(localized: "nudge.simplify.subtitle")
        }
    }

    private var actionLabel: String {
        switch nudge {
        case .disableUnused: return String(localized: "nudge.disable")
        case .enableSuggestion: return String(localized: "nudge.enable")
        case .phaseTransition: return String(localized: "nudge.review")
        case .simplifyMode: return String(localized: "nudge.simplify")
        }
    }
}
```

### Integration on Home Screen

```swift
// In HomeView / DashboardView
@StateObject private var nudgeEngine = NudgeEngine()

var body: some View {
    ScrollView {
        VStack(spacing: 16) {
            // Nudge cards at top
            ForEach(nudgeEngine.activeNudges) { nudge in
                NudgeCardView(
                    nudge: nudge,
                    onAction: { handleNudgeAction(nudge) },
                    onDismiss: { nudgeEngine.dismiss(nudge) }
                )
            }

            // ... rest of dashboard
        }
    }
    .onAppear {
        if let profile = profileStore.currentProfile {
            nudgeEngine.evaluate(profile: profile)
        }
    }
}
```

---

## File List

### New Files
| File | Location |
|------|----------|
| `TrackingModule.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `ModulePreferences.swift` | `Ollie/Services/` |
| `ModulePreferencesKey.swift` | `Ollie/Services/` |
| `ModuleActivityTracker.swift` | `Ollie/Services/` |
| `ModuleSettingsView.swift` | `Ollie/Views/Settings/` |
| `ModuleToggleRow.swift` | `Ollie/Views/Settings/Components/` |
| `OnboardingModuleSelectionView.swift` | `Ollie/Views/Onboarding/` |
| `ModuleCard.swift` | `Ollie/Views/Onboarding/Components/` |
| `NudgeType.swift` | `Ollie/Models/` |
| `NudgeEngine.swift` | `Ollie/Services/` |
| `NudgeCardView.swift` | `Ollie/Views/Components/` |

### Modified Files
| File | Change |
|------|--------|
| `ContentView.swift` | Conditional tab visibility based on `ModulePreferences` |
| `HomeView.swift` / Dashboard | Show only enabled module cards + nudge cards |
| `MedicationStore.swift` | Add `ModuleActivityTracker.recordActivity(.medications)` calls |
| `SpotStore.swift` | Add `ModuleActivityTracker.recordActivity(.walks)` calls |
| Onboarding flow | Insert `OnboardingModuleSelectionView` step |
| `Localizable.xcstrings` | Add all `module.*`, `nudge.*`, `onboarding.modules.*` keys |

---

## Implementation Order

1. **TrackingModule enum** — Add to OllieShared
2. **ModulePreferences** — `@AppStorage`-based preference store
3. **ModuleSettingsView** — Let users toggle modules
4. **ContentView tab visibility** — Hide tabs for disabled modules
5. **Home view filtering** — Only show enabled module cards
6. **Onboarding step** — Module selection during setup
7. **ModuleActivityTracker** — Sprinkle recording calls in stores
8. **NudgeEngine + cards** — Detect unused modules, show suggestions
9. **Phase-aware nudges** — Combine with `DogLifePhase` from long-term features TODO

## Localization Keys

```
module.medications = "Medications" / "Medicatie"
module.medications.desc = "Track medications and reminders" / "Medicatie en herinneringen bijhouden"
module.walks = "Walks" / "Wandelingen"
module.walks.desc = "Walking routes and scheduling" / "Wandelroutes en planning"
module.socialization = "Socialization" / "Socialisatie"
module.socialization.desc = "Track socialization experiences" / "Socialisatie-ervaringen bijhouden"
module.training = "Training" / "Training"
module.training.desc = "Skills and training progress" / "Vaardigheden en trainingsvoortgang"
module.feeding = "Feeding" / "Voeding"
module.feeding.desc = "Diet and feeding schedule" / "Dieet en voedingsschema"
module.documents = "Documents" / "Documenten"
module.documents.desc = "Important dog documents" / "Belangrijke hondendocumenten"
module.milestones = "Milestones" / "Mijlpalen"
module.milestones.desc = "Development milestones" / "Ontwikkelingsmijlpalen"
modules.title = "Tracking Modules" / "Modules"
modules.description = "Choose which features you want to use. You can always change this later." / "Kies welke functies je wilt gebruiken. Je kunt dit later altijd wijzigen."
modules.active = "Active Modules" / "Actieve modules"
modules.resetDefaults = "Reset to Defaults" / "Standaard herstellen"
onboarding.modules.title = "What would you like to track?" / "Wat wil je bijhouden?"
onboarding.modules.subtitle = "Pick the features that matter to you. You can always add more later." / "Kies de functies die voor jou belangrijk zijn. Je kunt later altijd meer toevoegen."
onboarding.continue = "Continue" / "Doorgaan"
nudge.dismiss = "Not now" / "Niet nu"
nudge.unused.title = "Still using %@?" / "Gebruik je %@ nog?"
nudge.unused.subtitle = "You haven't used this in %d days" / "Je hebt dit %d dagen niet gebruikt"
nudge.suggest.title = "Try %@?" / "%@ proberen?"
nudge.phase.title = "Time for %@ mode" / "Tijd voor %@-modus"
nudge.phase.subtitle = "Some puppy features can be hidden now" / "Sommige puppyfuncties kunnen nu verborgen worden"
nudge.simplify.title = "Simplify your app" / "Vereenvoudig je app"
nudge.simplify.subtitle = "Several modules seem unused" / "Meerdere modules lijken ongebruikt"
nudge.disable = "Disable" / "Uitschakelen"
nudge.enable = "Enable" / "Inschakelen"
nudge.review = "Review" / "Bekijken"
nudge.simplify = "Simplify" / "Vereenvoudig"
```
