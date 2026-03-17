# Brief: Puppy Personality Type Cards

> **Status:** Concept
> **Priority:** Medium (Fun Viral Feature)
> **Dependencies:** Sufficient logged data (2+ weeks)
> **Estimated Effort:** Low

## Objective

Generate a shareable "personality type" for each puppy based on logged behaviors. Similar to MBTI or "What Disney Character Are You?" quizzes — fun, relatable, and highly shareable.

## Why This Works

- **Identity content** — People love sharing "this is so my dog"
- **Conversation starter** — "What personality type is YOUR dog?"
- **Low effort, high reward** — Auto-generated from existing data
- **Repeat engagement** — Personality can evolve as dog ages
- **Quiz mechanic** — Proven viral format (Buzzfeed, etc.)

## Personality Types

### The Framework

Based on two axes:
1. **Energy Level:** Chill ↔ Energetic
2. **Social Style:** Independent ↔ Social Butterfly

This creates 4 main types with 8 subtypes:

```
                    ENERGETIC
                        │
         The Explorer   │   The Social Star
         "Adventure     │   "Party Animal"
          Seeker"       │
                        │
INDEPENDENT ────────────┼──────────── SOCIAL
                        │
         The Thinker    │   The Velcro Dog
         "Old Soul"     │   "Cuddle Champion"
                        │
                     CHILL
```

### Type Definitions

| Type | Title | Tagline | Traits |
|------|-------|---------|--------|
| 🏔️ Explorer | "The Adventure Seeker" | "Why walk when you can run?" | High walk frequency, varied locations, high activity |
| 🎉 Social Star | "The Party Animal" | "Never met a stranger" | Many socialization events, high energy after sleep |
| 🧘 Thinker | "The Old Soul" | "Wise beyond their weeks" | Calm disposition, consistent routines, independent play |
| 🤗 Velcro Dog | "The Cuddle Champion" | "Personal space? Never heard of it" | Follows everywhere, loves sleep time, people-focused |

### Subtypes (Optional Enhancement)

More specific variants:

| Subtype | Based On |
|---------|----------|
| 🌅 Early Bird | Consistently early wake times |
| 🦉 Night Owl | Active in evenings |
| 🎓 Eager Student | High training frequency, quick skill acquisition |
| 🍽️ Food Motivated | Eats quickly, food-focused training |
| 🌧️ Rain or Shine | Walks in all weather |
| 🏠 Homebody | Prefers indoor activities |
| 🐕 Pack Leader | Confident with other dogs |
| 🦋 Easily Distracted | Short training sessions, many outdoor breaks |

## Detection Algorithm

### Data Points Analyzed

```swift
// Services/PersonalityAnalyzer.swift
struct PersonalityAnalyzer {
    let events: [PuppyEvent]
    let profile: PuppyProfile

    func analyze() -> PuppyPersonality {
        // Energy axis
        let energyScore = calculateEnergyScore()

        // Social axis
        let socialScore = calculateSocialScore()

        // Determine primary type
        let primaryType = determineType(energy: energyScore, social: socialScore)

        // Find dominant traits
        let traits = identifyTraits()

        return PuppyPersonality(
            primaryType: primaryType,
            energyScore: energyScore,
            socialScore: socialScore,
            traits: traits,
            analyzedDate: Date()
        )
    }

    private func calculateEnergyScore() -> Double {
        // -1 (chill) to +1 (energetic)
        var score: Double = 0

        // Walk duration and frequency
        let walks = events.filter { $0.type == .uitlaten }
        let avgWalkDuration = walks.compactMap { $0.duration_min }.average
        if avgWalkDuration > 30 { score += 0.3 }

        // Wake time patterns
        let wakes = events.filter { $0.type == .ontwaken }
        let avgWakeHour = wakes.map { Calendar.current.component(.hour, from: $0.time) }.average
        if avgWakeHour < 7 { score += 0.2 } // Early riser = energetic

        // Time between sleeps (shorter = more energetic)
        let sleepGaps = calculateSleepGaps()
        if sleepGaps.average < 120 { score -= 0.2 } // Naps often = chill
        if sleepGaps.average > 240 { score += 0.2 } // Stays awake long = energetic

        // Training frequency
        let trainingDays = Set(events.filter { $0.type == .training }.map { $0.time.startOfDay })
        let totalDays = events.first.map { Date().daysSince($0.time) } ?? 1
        let trainingRate = Double(trainingDays.count) / Double(totalDays)
        if trainingRate > 0.5 { score += 0.2 } // Trains often

        return score.clamped(to: -1...1)
    }

    private func calculateSocialScore() -> Double {
        // -1 (independent) to +1 (social butterfly)
        var score: Double = 0

        // Socialization events
        let socialEvents = events.filter { $0.type == .sociaal }
        let daysTracked = events.first.map { Date().daysSince($0.time) } ?? 1

        let socialRate = Double(socialEvents.count) / Double(daysTracked)
        if socialRate > 0.5 { score += 0.4 }
        if socialRate > 1.0 { score += 0.2 }

        // Dog vs human interactions
        let dogInteractions = socialEvents.filter {
            $0.who?.lowercased().contains("hond") == true ||
            $0.who?.lowercased().contains("dog") == true
        }
        let humanInteractions = socialEvents.filter {
            $0.who?.lowercased().contains("hond") == false &&
            $0.who?.lowercased().contains("dog") == false
        }

        // Variety of social contacts
        let uniqueContacts = Set(socialEvents.compactMap { $0.who })
        if uniqueContacts.count > 10 { score += 0.2 }

        // Location variety (adventurous = social)
        let outdoorEvents = events.filter { $0.location == "buiten" }
        // Could analyze GPS data for place variety

        return score.clamped(to: -1...1)
    }

    private func identifyTraits() -> [PersonalityTrait] {
        var traits: [PersonalityTrait] = []

        // Early Bird / Night Owl
        let wakes = events.filter { $0.type == .ontwaken }
        let avgWakeHour = wakes.map { Calendar.current.component(.hour, from: $0.time) }.average
        if avgWakeHour < 6.5 { traits.append(.earlyBird) }
        if avgWakeHour > 8 { traits.append(.nightOwl) }

        // Eager Student
        let skillsLearned = /* from SkillProgressStore */
        let weeksTracked = profile.ageInWeeks
        if skillsLearned.count > weeksTracked { traits.append(.eagerStudent) }

        // Food Motivated
        let mealEvents = events.filter { $0.type == .eten }
        // Could analyze if training events cluster around meals

        // etc.

        return traits
    }
}
```

### Minimum Data Requirements

To generate personality:
- At least 14 days of data
- At least 50 events logged
- At least 5 different event types used

Show prompt to log more if insufficient.

## Personality Card Design

```
┌─────────────────────────────────────┐
│                                     │
│      🏔️ THE ADVENTURE SEEKER 🏔️    │
│                                     │
│        ┌─────────────────┐          │
│        │  [Luna Photo]   │          │
│        │                 │          │
│        └─────────────────┘          │
│                                     │
│     "Why walk when you can run?"    │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  Energy    ●●●●●○○  High    │   │
│   │  Social    ●●●○○○○  Moderate│   │
│   └─────────────────────────────┘   │
│                                     │
│   Traits:                           │
│   🌅 Early Bird                     │
│   🎓 Eager Student                  │
│   🌧️ Rain or Shine                 │
│                                     │
│         Luna • 5 months old         │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

## Data Model

```swift
// Models/PuppyPersonality.swift
struct PuppyPersonality: Codable {
    let primaryType: PersonalityType
    let energyScore: Double      // -1 to +1
    let socialScore: Double      // -1 to +1
    let traits: [PersonalityTrait]
    let analyzedDate: Date

    enum PersonalityType: String, Codable {
        case explorer = "explorer"          // High energy, independent
        case socialStar = "social_star"     // High energy, social
        case thinker = "thinker"            // Low energy, independent
        case velcroDog = "velcro_dog"       // Low energy, social

        var emoji: String {
            switch self {
            case .explorer: return "🏔️"
            case .socialStar: return "🎉"
            case .thinker: return "🧘"
            case .velcroDog: return "🤗"
            }
        }

        var title: String {
            switch self {
            case .explorer: return "The Adventure Seeker"
            case .socialStar: return "The Party Animal"
            case .thinker: return "The Old Soul"
            case .velcroDog: return "The Cuddle Champion"
            }
        }

        var tagline: String {
            switch self {
            case .explorer: return "Why walk when you can run?"
            case .socialStar: return "Never met a stranger"
            case .thinker: return "Wise beyond their weeks"
            case .velcroDog: return "Personal space? Never heard of it"
            }
        }
    }

    enum PersonalityTrait: String, Codable {
        case earlyBird = "early_bird"
        case nightOwl = "night_owl"
        case eagerStudent = "eager_student"
        case foodMotivated = "food_motivated"
        case rainOrShine = "rain_or_shine"
        case homebody = "homebody"
        case packLeader = "pack_leader"
        case easilyDistracted = "easily_distracted"

        var emoji: String {
            switch self {
            case .earlyBird: return "🌅"
            case .nightOwl: return "🦉"
            case .eagerStudent: return "🎓"
            case .foodMotivated: return "🍽️"
            case .rainOrShine: return "🌧️"
            case .homebody: return "🏠"
            case .packLeader: return "🐕"
            case .easilyDistracted: return "🦋"
            }
        }

        var label: String {
            switch self {
            case .earlyBird: return "Early Bird"
            case .nightOwl: return "Night Owl"
            case .eagerStudent: return "Eager Student"
            case .foodMotivated: return "Food Motivated"
            case .rainOrShine: return "Rain or Shine"
            case .homebody: return "Homebody"
            case .packLeader: return "Pack Leader"
            case .easilyDistracted: return "Easily Distracted"
            }
        }
    }
}
```

## User Flow

### Personality Reveal Experience

1. **Teaser** — Show "Personality analysis ready!" in app
2. **Build-up** — Brief loading animation with fun messages
3. **Reveal** — Animated card reveal with type and traits
4. **Share prompt** — "Share your pup's personality!"

```swift
// Views/Personality/PersonalityRevealSheet.swift
struct PersonalityRevealSheet: View {
    let profile: PuppyProfile
    @State private var personality: PuppyPersonality?
    @State private var phase: RevealPhase = .analyzing

    enum RevealPhase {
        case analyzing
        case revealed
    }

    var body: some View {
        VStack {
            switch phase {
            case .analyzing:
                analyzingView
            case .revealed:
                revealedView
            }
        }
        .task {
            await analyzePersonality()
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing \(profile.name)'s personality...")
                .font(.headline)

            // Fun rotating messages
            Text(analysisFacts.randomElement() ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var analysisFacts: [String] {
        [
            "Reviewing walk patterns...",
            "Counting tail wags...",
            "Analyzing sleep positions...",
            "Measuring zoomie frequency...",
            "Evaluating treat enthusiasm..."
        ]
    }

    @MainActor
    private func analyzePersonality() async {
        try? await Task.sleep(for: .seconds(2)) // Build anticipation

        let analyzer = PersonalityAnalyzer(events: eventStore.allEvents, profile: profile)
        personality = analyzer.analyze()

        withAnimation(.spring()) {
            phase = .revealed
        }
    }
}
```

### Personality in Profile

Show personality badge in profile section:

```
┌─────────────────────────────────────┐
│  Luna                               │
│  Golden Retriever • 5 months        │
├─────────────────────────────────────┤
│                                     │
│  Personality                        │
│  ┌─────────────────────────────┐    │
│  │  🏔️ The Adventure Seeker    │    │
│  │                             │    │
│  │  Tap to see full analysis   │ →  │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

## Personality Evolution

Personality can change as dog ages. Re-analyze monthly:

```swift
// When to re-analyze
func shouldReanalyze(lastAnalysis: Date) -> Bool {
    let daysSinceAnalysis = Calendar.current.dateComponents(
        [.day], from: lastAnalysis, to: Date()
    ).day ?? 0

    return daysSinceAnalysis >= 30
}

// Show evolution
struct PersonalityEvolutionView: View {
    let history: [PuppyPersonality] // Sorted by date

    var body: some View {
        VStack {
            Text("Personality Evolution")
                .font(.headline)

            ForEach(history, id: \.analyzedDate) { personality in
                HStack {
                    Text(personality.primaryType.emoji)
                    Text(personality.primaryType.title)
                    Spacer()
                    Text(personality.analyzedDate, format: .dateTime.month().year())
                        .foregroundStyle(.secondary)
                }
            }

            if hasChanged {
                Text("\(profile.name) has grown from \(history.first!.primaryType.title) to \(history.last!.primaryType.title)!")
                    .font(.caption)
            }
        }
    }
}
```

## Sharing

### Share Caption

```swift
extension PuppyPersonality {
    func shareCaption(dogName: String) -> String {
        """
        \(primaryType.emoji) \(dogName) is \(primaryType.title)!

        "\(primaryType.tagline)"

        What's YOUR pup's personality type? 🐕

        #OllieApp #PuppyPersonality #\(dogName.replacingOccurrences(of: " ", with: ""))
        """
    }
}
```

### Comparison Feature (Future)

"Compare with friends" — Shows multiple dogs' personalities side by side:

```
┌─────────────────────────────────────┐
│                                     │
│      Personality Comparison         │
│                                     │
│  Luna          vs         Max       │
│  🏔️ Explorer    🎉 Social Star     │
│                                     │
│  ●●●●● Energy   ●●●●●              │
│  ●●●○○ Social   ●●●●●              │
│                                     │
│  Compatible! Both love adventure    │
│                                     │
└─────────────────────────────────────┘
```

## Implementation

### Files to Create

```
Ollie-app/Models/PuppyPersonality.swift
Ollie-app/Services/PersonalityAnalyzer.swift
Ollie-app/Views/Personality/PersonalityRevealSheet.swift
Ollie-app/Views/Personality/PersonalityCardView.swift
Ollie-app/Views/Personality/PersonalityBadge.swift
Ollie-app/Utils/Strings/Strings+Personality.swift
```

### Files to Modify

```
Ollie-app/Views/Settings/DogSettingsCard.swift (or Profile view)
  - Add personality badge

Ollie-app/Views/Timeline/TodayView.swift
  - Show personality ready prompt when available
```

## Testing

- [ ] Personality generates correctly from varied event data
- [ ] Edge case: user with only potty events logged
- [ ] Edge case: brand new user (insufficient data message)
- [ ] Card renders at all sizes
- [ ] Share flow works
- [ ] Re-analysis triggers after 30 days
- [ ] Evolution history tracked correctly

## Notes

- Keep types positive — no "problem" personalities
- Traits should feel relatable, not clinical
- Consider breed influences (optional enhancement)
- Fun > accuracy — this is entertainment, not science
- Could add "famous dogs with this personality" (Lassie, Beethoven, etc.)
