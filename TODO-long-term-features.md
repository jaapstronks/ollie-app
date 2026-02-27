# TODO: Beyond Puppy Phase — Long-Term Features

## Overview

As the dog grows out of the puppy phase, the app should transition gracefully from puppy-focused tracking to adult dog management. Many core features **already exist** in the iOS app — this briefing focuses on what's **new** or needs **enhancement**.

## Feature Audit: What Exists vs What's New

### ✅ Already Exists (enhance only)
| Feature | Files | Status |
|---------|-------|--------|
| Medication tracking | `MedicationStore.swift`, `MedicationSettingsView.swift`, `MedicationReminderCard.swift`, `AddEditMedicationSheet.swift` | Full CRUD, reminders, completion tracking |
| Walk spots & scheduling | `SpotStore.swift`, `FavoriteSpotsView.swift`, `SpotDetailView.swift`, `SpotMapView.swift`, `AddSpotSheet.swift` | Map, favorites, walking sessions |
| Profile with age tracking | `PuppyProfile` (OllieShared), `CDPuppyProfile`, `DogProfileSettingsView.swift` | Has `ageInWeeks`, birthdate |
| Notifications | `NotificationManager.swift` (or similar) | Local notifications for meds, walks |
| Widgets + Live Activities | Widget extension, `WalkSession` | Active walk tracking |
| Siri / App Intents | App Intents extension | Voice commands |

### 🆕 New Features
| Feature | Priority | Complexity |
|---------|----------|------------|
| Sitter/Oppas Mode | High | Medium |
| Feeding tracker enhancements | Medium | Medium |
| Smart Phase Transitions | Medium | Low-Medium |
| Health log / vet visit tracker | Low | Medium |

---

## 1. Sitter/Oppas Mode

### Concept
A read-only shareable summary of everything a dog sitter needs: feeding schedule, medication times, emergency contacts, walk preferences, behavioral notes. Exportable as PDF or shareable as a styled view.

### Implementation

#### Data Model

```swift
// SitterSummary.swift (OllieShared)
import Foundation

public struct SitterSummary: Codable {
    public var dogName: String
    public var dogBreed: String
    public var dogAge: String
    public var photoData: Data?

    // Routines
    public var feedingSchedule: [FeedingEntry]
    public var medications: [MedicationSummaryEntry]
    public var walkPreferences: WalkPreferences

    // Important info
    public var emergencyContacts: [EmergencyContact]
    public var vetInfo: VetContact?
    public var behavioralNotes: String?
    public var allergies: [String]
    public var commands: [String]  // commands the dog knows

    public struct FeedingEntry: Codable {
        public var time: String          // "08:00"
        public var food: String          // "Royal Canin Puppy, 150g"
        public var notes: String?
    }

    public struct MedicationSummaryEntry: Codable {
        public var name: String
        public var dosage: String
        public var schedule: String      // "Every morning with food"
        public var notes: String?
    }

    public struct WalkPreferences: Codable {
        public var frequency: String     // "3x per day"
        public var duration: String      // "20-30 minutes"
        public var favoriteSpots: [String]
        public var leashBehavior: String?
        public var notes: String?
    }

    public struct EmergencyContact: Codable, Identifiable {
        public var id: UUID
        public var name: String
        public var phone: String
        public var relationship: String  // "Owner", "Vet", "Neighbor"
    }

    public struct VetContact: Codable {
        public var name: String
        public var clinic: String?
        public var phone: String
        public var address: String?
    }
}
```

#### Views

```swift
// SitterModeView.swift
import SwiftUI

struct SitterModeView: View {
    let summary: SitterSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Dog header with photo
                DogHeaderCard(summary: summary)

                // Feeding schedule
                SitterSection(title: String(localized: "sitter.feeding"), icon: "fork.knife") {
                    ForEach(summary.feedingSchedule, id: \.time) { entry in
                        FeedingRow(entry: entry)
                    }
                }

                // Medications
                if !summary.medications.isEmpty {
                    SitterSection(title: String(localized: "sitter.medications"), icon: "pills") {
                        ForEach(summary.medications, id: \.name) { med in
                            MedicationSummaryRow(entry: med)
                        }
                    }
                }

                // Walk preferences
                SitterSection(title: String(localized: "sitter.walks"), icon: "figure.walk") {
                    WalkPreferencesCard(prefs: summary.walkPreferences)
                }

                // Behavioral notes
                if let notes = summary.behavioralNotes, !notes.isEmpty {
                    SitterSection(title: String(localized: "sitter.behavior"), icon: "pawprint") {
                        Text(notes)
                    }
                }

                // Emergency contacts
                SitterSection(title: String(localized: "sitter.emergency"), icon: "phone.fill") {
                    ForEach(summary.emergencyContacts) { contact in
                        EmergencyContactRow(contact: contact)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "sitter.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: generatePDF()) {
                    Label(String(localized: "sitter.share"), systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    @MainActor
    private func generatePDF() -> URL {
        let renderer = ImageRenderer(content: self)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sitter-summary.pdf")
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        return url
    }
}
```

#### Building the Summary from Existing Data

```swift
// SitterSummaryBuilder.swift
import Foundation
import CoreData

final class SitterSummaryBuilder {
    static func build(
        profile: CDPuppyProfile,
        medications: [MedicationSchedule],
        spots: [WalkSpot],
        context: NSManagedObjectContext
    ) -> SitterSummary {
        SitterSummary(
            dogName: profile.name ?? "",
            dogBreed: profile.breed ?? "",
            dogAge: profile.puppyProfile?.ageDescription ?? "",
            photoData: profile.photo,
            feedingSchedule: [], // TODO: populate from feeding data
            medications: medications.map { med in
                SitterSummary.MedicationSummaryEntry(
                    name: med.name,
                    dosage: med.dosage ?? "",
                    schedule: med.frequencyDescription,
                    notes: med.notes
                )
            },
            walkPreferences: SitterSummary.WalkPreferences(
                frequency: "3x per day",
                duration: "20-30 min",
                favoriteSpots: spots.filter(\.isFavorite).map(\.name),
                leashBehavior: nil,
                notes: nil
            ),
            emergencyContacts: [], // TODO: new data to collect
            vetInfo: nil,          // TODO: new data to collect
            behavioralNotes: nil,
            allergies: [],
            commands: []
        )
    }
}
```

#### Integration Point

Add to `DogProfileSettingsView.swift`:
```swift
Section {
    NavigationLink {
        SitterModeSetupView()
    } label: {
        Label(String(localized: "sitter.setup"), systemImage: "person.badge.key")
    }
}
```

### New Files
| File | Location |
|------|----------|
| `SitterSummary.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `SitterSummaryBuilder.swift` | `Ollie/Services/` |
| `SitterModeView.swift` | `Ollie/Views/Sitter/` |
| `SitterModeSetupView.swift` | `Ollie/Views/Sitter/` |
| `SitterSection.swift` | `Ollie/Views/Sitter/Components/` |
| `DogHeaderCard.swift` | `Ollie/Views/Sitter/Components/` |

---

## 2. Feeding Tracker Enhancements

### Current State
The app tracks basic feeding but lacks detailed diet management. `PuppyProfile` in OllieShared has minimal feeding fields.

### What to Add

#### Extend PuppyProfile (OllieShared)

```swift
// Add to PuppyProfile or create new model
public struct FeedingProfile: Codable {
    public var currentFood: FoodBrand?
    public var feedingSchedule: [FeedingTime]
    public var portionSize: String?          // "150g"
    public var allergies: [String]
    public var dietaryNotes: String?
    public var dietHistory: [DietChange]

    public struct FoodBrand: Codable, Hashable {
        public var brand: String             // "Royal Canin"
        public var product: String           // "Golden Retriever Puppy"
        public var type: FoodType            // .dry, .wet, .raw, .mixed
    }

    public enum FoodType: String, Codable, CaseIterable {
        case dry, wet, raw, mixed, homemade
    }

    public struct FeedingTime: Codable, Identifiable {
        public var id: UUID
        public var time: Date                // time component only
        public var portionSize: String?
        public var notes: String?
    }

    public struct DietChange: Codable, Identifiable {
        public var id: UUID
        public var date: Date
        public var fromFood: FoodBrand?
        public var toFood: FoodBrand
        public var reason: String?           // "Vet recommendation", "Age transition"
    }
}
```

#### Core Data Changes

Add `CDFeedingProfile` entity or extend `CDPuppyProfile` with feeding attributes:
- `currentFoodBrand: String?`
- `currentFoodProduct: String?`
- `currentFoodType: String?`
- `portionSize: String?`
- `allergies: Transformable` (array of strings)
- `dietaryNotes: String?`

Add `CDDietChange` entity for diet history (one-to-many from profile).

#### Views

```swift
// FeedingSettingsView.swift — new view or enhance existing
struct FeedingSettingsView: View {
    @ObservedObject var store: FeedingStore

    var body: some View {
        Form {
            Section(String(localized: "feeding.currentFood")) {
                TextField(String(localized: "feeding.brand"), text: $store.currentBrand)
                TextField(String(localized: "feeding.product"), text: $store.currentProduct)
                Picker(String(localized: "feeding.type"), selection: $store.foodType) {
                    ForEach(FeedingProfile.FoodType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                TextField(String(localized: "feeding.portion"), text: $store.portionSize)
            }

            Section(String(localized: "feeding.allergies")) {
                ForEach(store.allergies, id: \.self) { allergy in
                    Text(allergy)
                }
                .onDelete { store.removeAllergy(at: $0) }

                HStack {
                    TextField(String(localized: "feeding.addAllergy"), text: $store.newAllergy)
                    Button(String(localized: "general.add")) {
                        store.addAllergy()
                    }
                }
            }

            Section(String(localized: "feeding.history")) {
                ForEach(store.dietHistory) { change in
                    DietChangeRow(change: change)
                }
            }
        }
        .navigationTitle(String(localized: "feeding.title"))
    }
}
```

### New Files
| File | Location |
|------|----------|
| `FeedingProfile.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `FeedingStore.swift` | `Ollie/ViewModels/` |
| `FeedingSettingsView.swift` | `Ollie/Views/Settings/` |
| `DietChangeRow.swift` | `Ollie/Views/Settings/Components/` |

---

## 3. Smart Phase Transitions

### Concept
The app already tracks `ageInWeeks` on `PuppyProfile`. Use this to automatically adapt the UI as the dog grows:
- **Puppy phase** (0–26 weeks): Show socialization checklist, training milestones, teething info
- **Adolescent phase** (26–52 weeks): Shift focus to advanced training, exercise increase
- **Adult phase** (52+ weeks): Hide puppy-specific features, emphasize health maintenance

### Implementation

```swift
// DogLifePhase.swift (OllieShared)
import Foundation

public enum DogLifePhase: String, Codable {
    case puppy          // 0-26 weeks
    case adolescent     // 26-52 weeks
    case adult          // 52-104 weeks (1-2 years)
    case mature         // 104+ weeks (2+ years)

    public init(ageInWeeks: Int) {
        switch ageInWeeks {
        case 0..<26: self = .puppy
        case 26..<52: self = .adolescent
        case 52..<104: self = .adult
        default: self = .mature
        }
    }

    public var displayName: String {
        switch self {
        case .puppy: return String(localized: "phase.puppy")
        case .adolescent: return String(localized: "phase.adolescent")
        case .adult: return String(localized: "phase.adult")
        case .mature: return String(localized: "phase.mature")
        }
    }

    /// Features relevant to this phase
    public var activeFeatures: Set<AppFeature> {
        switch self {
        case .puppy:
            return [.socialization, .milestones, .training, .medications, .walks, .feeding, .documents]
        case .adolescent:
            return [.training, .medications, .walks, .feeding, .documents, .milestones]
        case .adult:
            return [.medications, .walks, .feeding, .documents, .healthLog]
        case .mature:
            return [.medications, .walks, .feeding, .documents, .healthLog]
        }
    }
}

public enum AppFeature: String, Codable, CaseIterable {
    case socialization
    case milestones
    case training
    case medications
    case walks
    case feeding
    case documents
    case healthLog
}
```

#### Phase Transition Banner

```swift
// PhaseTransitionBanner.swift
struct PhaseTransitionBanner: View {
    let fromPhase: DogLifePhase
    let toPhase: DogLifePhase
    let dogName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.yellow)

            Text(String(localized: "phase.transition.title \(dogName) \(toPhase.displayName)"))
                .font(.headline)

            Text(String(localized: "phase.transition.description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(String(localized: "phase.transition.dismiss")) {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
}
```

#### Integration with Existing Views

In `ContentView.swift` or the main tab view, use the phase to control which tabs/sections are prominently shown:

```swift
// In ContentView or wherever tabs are managed
@State private var currentPhase: DogLifePhase = .puppy

var body: some View {
    TabView {
        // Always visible
        HomeView()
            .tabItem { Label("Home", systemImage: "house") }

        // Phase-dependent visibility
        if currentPhase.activeFeatures.contains(.socialization) {
            SocializationView()
                .tabItem { Label("Socialize", systemImage: "person.3") }
        }

        WalksView()
            .tabItem { Label("Walks", systemImage: "figure.walk") }

        MedicationsView()
            .tabItem { Label("Meds", systemImage: "pills") }

        SettingsView()
            .tabItem { Label("Settings", systemImage: "gear") }
    }
    .onAppear { updatePhase() }
}
```

### New Files
| File | Location |
|------|----------|
| `DogLifePhase.swift` | `OllieShared/Sources/OllieShared/Models/` |
| `AppFeature.swift` | `OllieShared/Sources/OllieShared/Models/` (or combine with DogLifePhase) |
| `PhaseTransitionBanner.swift` | `Ollie/Views/Components/` |

### Modified Files
| File | Change |
|------|--------|
| `ContentView.swift` | Conditional tab visibility based on phase |
| `PuppyProfile` (OllieShared) | Add computed `lifePhase` property |

---

## 4. Health Log / Vet Visit Tracker (Future)

Low priority but natural extension:
- Log vet visits with date, reason, notes, cost
- Weight tracking over time (chart with SwiftUI Charts)
- Link to documents (vaccination records from Documents feature)

This is noted here for completeness but should be a separate TODO when prioritized.

---

## Implementation Order

1. **DogLifePhase** — Add to OllieShared, computed property on PuppyProfile
2. **Phase-aware tab visibility** — Low-effort, high-impact change to ContentView
3. **Feeding enhancements** — Core Data + views for diet tracking
4. **Sitter Mode** — Build summary from existing data, PDF export
5. **Phase transition banner** — Polish: detect transitions, show celebration
6. **Health log** — Future phase

## Localization Keys

```
sitter.title = "Sitter Summary" / "Oppas overzicht"
sitter.setup = "Sitter Mode" / "Oppasmodus"
sitter.share = "Share" / "Delen"
sitter.feeding = "Feeding" / "Voeding"
sitter.medications = "Medications" / "Medicatie"
sitter.walks = "Walks" / "Wandelingen"
sitter.behavior = "Behavior & Notes" / "Gedrag & notities"
sitter.emergency = "Emergency Contacts" / "Noodcontacten"
feeding.title = "Feeding" / "Voeding"
feeding.currentFood = "Current Food" / "Huidig voer"
feeding.brand = "Brand" / "Merk"
feeding.product = "Product" / "Product"
feeding.type = "Type" / "Type"
feeding.portion = "Portion Size" / "Portiegrootte"
feeding.allergies = "Allergies" / "Allergieën"
feeding.addAllergy = "Add allergy..." / "Allergie toevoegen..."
feeding.history = "Diet History" / "Voedingsgeschiedenis"
phase.puppy = "Puppy" / "Puppy"
phase.adolescent = "Adolescent" / "Puber"
phase.adult = "Adult" / "Volwassen"
phase.mature = "Mature" / "Senior"
phase.transition.title = "%@ is now a %@!" / "%@ is nu een %@!"
phase.transition.description = "We've adjusted the app to match this new phase." / "We hebben de app aangepast aan deze nieuwe fase."
phase.transition.dismiss = "Got it!" / "Begrepen!"
```
