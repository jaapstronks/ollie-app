# Brief: Achievement & Milestone Cards

> **Status:** Concept
> **Priority:** High (Viral Potential)
> **Dependencies:** None
> **Estimated Effort:** Medium

## Objective

Create shareable achievement cards that celebrate puppy milestones, streaks, and accomplishments. These capture emotional moments that dog owners naturally want to share.

## Why This Works

- **Emotional peaks** — Achievements feel special and share-worthy
- **Real-time triggers** — Shared in the moment, not retrospectively
- **Social proof** — Shows the app is helping train a "good dog"
- **Pride sharing** — Dog parents love showing off accomplishments
- **FOMO effect** — Friends see achievements, wonder how to track their own dog

## Achievement Categories

### 1. Streak Achievements

Consecutive days/events of positive behavior.

| Streak | Icon | Title | Subtitle |
|--------|------|-------|----------|
| 3 days accident-free | 🔥 | "3-Day Streak!" | "{name} has been accident-free for 3 days!" |
| 7 days accident-free | ⭐ | "Perfect Week!" | "7 days, zero accidents. What a good pup!" |
| 14 days accident-free | 🏆 | "Two Week Champion!" | "{name} is officially potty trained!" |
| 30 days accident-free | 👑 | "Potty Pro!" | "A whole month of outdoor success!" |
| 7-day walk streak | 🚶 | "Walk Week!" | "7 days of daily walks with {name}!" |
| Training streak | 📚 | "Dedicated Learner!" | "{name} trained X days in a row!" |

```
┌─────────────────────────────────────┐
│                                     │
│         🔥 7-DAY STREAK! 🔥         │
│                                     │
│        ┌─────────────────┐          │
│        │  [Luna Photo]   │          │
│        │                 │          │
│        └─────────────────┘          │
│                                     │
│     Luna has been accident-free     │
│          for 7 days!                │
│                                     │
│   ○ ○ ○ ○ ○ ○ ● ← Today            │
│   M T W T F S S                     │
│                                     │
│   "The best week yet!"              │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

### 2. Training Milestones

When a dog masters a new skill.

| Achievement | Icon | Title |
|-------------|------|-------|
| First command learned | 🎓 | "First Trick!" |
| 5 commands mastered | ⭐ | "Rising Star!" |
| 10 commands mastered | 🌟 | "Trick Master!" |
| All basic commands | 🏅 | "Puppy School Graduate!" |
| Advanced trick learned | 🎪 | "Show Dog Material!" |

```
┌─────────────────────────────────────┐
│                                     │
│       🎓 SKILL UNLOCKED! 🎓        │
│                                     │
│        ┌─────────────────┐          │
│        │  [Luna doing    │          │
│        │   the trick]    │          │
│        └─────────────────┘          │
│                                     │
│      Luna learned "Shake"!          │
│                                     │
│   Skills Mastered: ●●●●○○○○○○      │
│                    4/10             │
│                                     │
│   "Such a smart pup! 🐾"           │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

### 3. Age & Growth Milestones

Automatic triggers based on age.

| Milestone | Icon | Title | When |
|-----------|------|-------|------|
| 8 weeks | 🍼 | "8 Weeks Old!" | Birthday |
| 12 weeks | 💉 | "Vaccination Ready!" | Can go outside |
| 16 weeks | 🌍 | "Socialization Star!" | Peak socialization ends |
| 6 months | 🦷 | "Big Kid Teeth!" | Adult teeth |
| 1 year | 🎂 | "Happy 1st Birthday!" | First birthday |
| Gotcha Day | 🏠 | "X Days Home!" | Homecoming anniversary |

```
┌─────────────────────────────────────┐
│                                     │
│        🎂 HAPPY BIRTHDAY! 🎂       │
│                                     │
│        ┌─────────────────┐          │
│        │  [Luna Photo]   │          │
│        │                 │          │
│        └─────────────────┘          │
│                                     │
│     Luna is 1 year old today!       │
│                                     │
│   This year, Luna...                │
│   • Learned 8 tricks                │
│   • Went on 312 walks               │
│   • Made 24 dog friends             │
│   • Grew to 25 kg                   │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

### 4. Social Milestones

Based on socialization logging.

| Milestone | Icon | Title |
|-----------|------|-------|
| First dog friend | 🐕 | "First Friend!" |
| 10 dogs met | 🐕‍🦺 | "Social Butterfly!" |
| First human friend | 👋 | "People Person!" |
| 10 environments visited | 🗺️ | "Explorer!" |
| First car ride | 🚗 | "Road Tripper!" |

### 5. Health Milestones

Wellness-related achievements.

| Milestone | Icon | Title |
|-----------|------|-------|
| First vet visit | 🏥 | "Brave Pup!" |
| Full vaccination | 💉 | "Fully Protected!" |
| Healthy weight reached | ⚖️ | "Perfect Weight!" |
| First swim | 🏊 | "Water Pup!" |

### 6. Activity Milestones

Based on cumulative activity.

| Milestone | Icon | Title |
|-----------|------|-------|
| 10 walks logged | 🚶 | "Walking Buddy!" |
| 50 walks logged | 🥾 | "Adventure Partner!" |
| 100 walks logged | 🏔️ | "Trail Blazer!" |
| 10 km walked (est.) | 📍 | "10K Club!" |
| 100 km walked | 🗺️ | "Century Walker!" |

## Achievement System Architecture

### Data Model

```swift
// Models/Achievement.swift
struct Achievement: Codable, Identifiable {
    let id: String
    let type: AchievementType
    let title: String
    let subtitle: String
    let icon: String  // SF Symbol or emoji
    let earnedDate: Date
    let relatedEventIds: [String]?
    let stats: [String: Any]?  // Flexible stats for display
    var isShared: Bool = false

    enum AchievementType: String, Codable {
        // Streaks
        case pottyStreak3, pottyStreak7, pottyStreak14, pottyStreak30
        case walkStreak7, trainingStreak7

        // Training
        case firstCommand, commands5, commands10, basicGraduate, advancedTrick

        // Age
        case weeks8, weeks12, weeks16, months6, year1, year2
        case gotchaDay1, gotchaDay6mo, gotchaDay1yr

        // Social
        case firstDogFriend, dogs10, firstHumanFriend, environments10

        // Health
        case firstVet, fullyVaccinated, healthyWeight

        // Activity
        case walks10, walks50, walks100, distance10k, distance100k
    }
}

// Store for tracking achievements
// Services/AchievementStore.swift
class AchievementStore: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var pendingCelebration: Achievement?

    private let eventStore: EventStore
    private let profileStore: ProfileStore

    func checkForNewAchievements() {
        // Run after each event logged
        checkStreaks()
        checkTrainingMilestones()
        checkAgeMilestones()
        checkActivityMilestones()
    }

    private func checkStreaks() {
        let pottyStreak = calculatePottyStreak()
        if pottyStreak >= 7 && !hasAchievement(.pottyStreak7) {
            award(.pottyStreak7)
        }
        // etc.
    }
}
```

### Achievement Detection

```swift
// Services/AchievementDetector.swift
class AchievementDetector {

    func detectStreakAchievements(events: [PuppyEvent]) -> [Achievement] {
        var achievements: [Achievement] = []

        // Calculate accident-free streak
        let pottyEvents = events.filter { $0.type == .plassen || $0.type == .poepen }
        let streak = calculateAccidentFreeStreak(events: pottyEvents)

        if streak >= 30 && !hasAchievement(.pottyStreak30) {
            achievements.append(createAchievement(.pottyStreak30, stats: ["days": 30]))
        } else if streak >= 14 && !hasAchievement(.pottyStreak14) {
            achievements.append(createAchievement(.pottyStreak14, stats: ["days": 14]))
        }
        // etc.

        return achievements
    }

    private func calculateAccidentFreeStreak(events: [PuppyEvent]) -> Int {
        // Work backwards from today
        // Count consecutive days where all potty events were outdoor
        var streak = 0
        var currentDate = Date().startOfDay

        while true {
            let dayEvents = events.filter { Calendar.current.isDate($0.time, inSameDayAs: currentDate) }
            let accidents = dayEvents.filter { $0.location == "binnen" }

            if accidents.isEmpty && !dayEvents.isEmpty {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        return streak
    }
}
```

### Celebration Flow

When achievement is earned:

1. **Detect** — `AchievementDetector` finds new achievement
2. **Store** — Save to `AchievementStore`
3. **Celebrate** — Show celebration sheet with confetti
4. **Offer Share** — Prompt user to share card
5. **Track** — Mark as shared or dismissed

```swift
// Views/Achievements/AchievementCelebrationSheet.swift
struct AchievementCelebrationSheet: View {
    let achievement: Achievement
    let profile: PuppyProfile
    @State private var showShareOptions = false

    var body: some View {
        VStack(spacing: 24) {
            // Confetti animation
            ConfettiView()

            // Achievement icon (large)
            Text(achievement.icon)
                .font(.system(size: 80))

            // Title
            Text(achievement.title)
                .font(.largeTitle.bold())

            // Subtitle with dog name
            Text(achievement.subtitle.replacing("{name}", with: profile.name))
                .font(.title3)
                .multilineTextAlignment(.center)

            Spacer()

            // Share button (primary)
            Button {
                showShareOptions = true
            } label: {
                Label("Share Achievement", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Dismiss
            Button("Maybe Later") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .sheet(isPresented: $showShareOptions) {
            ShareOptionsSheet(achievement: achievement, profile: profile)
        }
    }
}
```

## Achievement Card Generation

### Card View

```swift
// Views/Achievements/AchievementCardView.swift
struct AchievementCardView: View {
    let achievement: Achievement
    let profile: PuppyProfile
    let photo: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            // Header with icon and title
            HStack {
                Text(achievement.icon)
                    .font(.system(size: 40))
                Text(achievement.title)
                    .font(.title.bold())
            }

            // Photo (if available)
            if let photo = photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            // Achievement details
            Text(achievement.subtitle.replacing("{name}", with: profile.name))
                .font(.title3)
                .multilineTextAlignment(.center)

            // Progress indicator (for streak achievements)
            if let progress = achievementProgress {
                ProgressView(value: progress.current, total: progress.goal)
                    .tint(.green)
            }

            // Stats (if applicable)
            if let stats = achievement.stats {
                statsView(stats)
            }

            Spacer()

            // Watermark
            HStack {
                Image("OllieIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Made with Ollie")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .frame(width: 1080, height: 1920)
        .background(achievementGradient)
    }

    private var achievementGradient: some View {
        LinearGradient(
            colors: achievement.type.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
```

### Gradient Themes per Achievement Type

```swift
extension Achievement.AchievementType {
    var gradientColors: [Color] {
        switch self {
        case .pottyStreak3, .pottyStreak7, .pottyStreak14, .pottyStreak30:
            return [.green.opacity(0.8), .mint.opacity(0.6)]
        case .firstCommand, .commands5, .commands10:
            return [.blue.opacity(0.8), .purple.opacity(0.6)]
        case .weeks8, .weeks12, .months6, .year1:
            return [.orange.opacity(0.8), .yellow.opacity(0.6)]
        case .firstDogFriend, .dogs10:
            return [.pink.opacity(0.8), .red.opacity(0.6)]
        // etc.
        }
    }
}
```

## Sharing Implementation

### Share Flow

```swift
// Services/AchievementShareService.swift
class AchievementShareService {
    private let cardRenderer: CardRenderer
    private let shareService: ShareService

    func shareAchievement(_ achievement: Achievement,
                          profile: PuppyProfile,
                          photo: UIImage?,
                          from viewController: UIViewController) async {

        // 1. Render card to image
        let cardView = AchievementCardView(
            achievement: achievement,
            profile: profile,
            photo: photo
        )
        guard let image = cardRenderer.render(view: cardView) else { return }

        // 2. Generate caption
        let caption = generateCaption(achievement: achievement, profile: profile)

        // 3. Share via standard sheet
        await shareService.share(
            image: image,
            caption: caption,
            from: viewController
        )
    }

    private func generateCaption(achievement: Achievement, profile: PuppyProfile) -> String {
        switch achievement.type {
        case .pottyStreak7:
            return "🎉 \(profile.name) went a whole week accident-free! So proud! #GoodDog #OllieApp"
        case .firstCommand:
            return "🎓 \(profile.name) learned their first trick! #PuppyTraining #OllieApp"
        case .year1:
            return "🎂 Happy 1st birthday to \(profile.name)! What a year it's been! #DogBirthday #OllieApp"
        // etc.
        }
    }
}
```

### Quick Share Options

```
┌─────────────────────────────────────┐
│      Share Luna's Achievement       │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │   [Achievement Card        │    │
│  │    Preview]                │    │
│  │                            │    │
│  └─────────────────────────────┘    │
│                                     │
│  Quick Share:                       │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │
│  │ IG │ │ FB │ │ 📱 │ │ ⬇️ │       │
│  │Story│ │   │ │iMsg│ │Save│       │
│  └────┘ └────┘ └────┘ └────┘       │
│                                     │
│         [ More Options ]            │
│                                     │
│  ☐ Include stats on card           │
│  ☐ Use profile photo instead       │
│                                     │
└─────────────────────────────────────┘
```

## Achievement Gallery

Show all earned achievements in a dedicated view:

```
┌─────────────────────────────────────┐
│  ← Achievements                     │
├─────────────────────────────────────┤
│                                     │
│  Luna has earned 12 achievements!   │
│                                     │
│  Recent                             │
│  ┌───────┐ ┌───────┐ ┌───────┐     │
│  │  🔥   │ │  🎓   │ │  🐕   │     │
│  │7-Day  │ │ Sit   │ │First  │     │
│  │Streak │ │Master │ │Friend │     │
│  │Mar 2  │ │Feb 28 │ │Feb 20 │     │
│  └───────┘ └───────┘ └───────┘     │
│                                     │
│  Training                           │
│  ●●●●○○○○○○  4/10 commands         │
│                                     │
│  Streaks                            │
│  Current: 7 days 🔥                 │
│  Best: 14 days                      │
│                                     │
│  Milestones                         │
│  ┌───────┐ ┌───────┐ ┌───────┐     │
│  │  🍼   │ │  💉   │ │  🦷   │     │
│  │8 Weeks│ │12 Wks │ │6 Month│     │
│  └───────┘ └───────┘ └───────┘     │
│                                     │
│  Coming Up                          │
│  🎂 1st Birthday in 47 days        │
│                                     │
└─────────────────────────────────────┘
```

## Implementation

### Files to Create

```
Ollie-app/Models/Achievement.swift
Ollie-app/Services/AchievementStore.swift
Ollie-app/Services/AchievementDetector.swift
Ollie-app/Services/AchievementShareService.swift
Ollie-app/Views/Achievements/AchievementCelebrationSheet.swift
Ollie-app/Views/Achievements/AchievementCardView.swift
Ollie-app/Views/Achievements/AchievementGalleryView.swift
Ollie-app/Views/Achievements/ShareOptionsSheet.swift
Ollie-app/Views/Components/ConfettiView.swift
Ollie-app/Utils/Strings/Strings+Achievements.swift
```

### Files to Modify

```
Ollie-app/Services/EventStore.swift
  - Call AchievementDetector after saving events

Ollie-app/OllieApp.swift (or main view)
  - Listen for pendingCelebration
  - Present celebration sheet

Ollie-app/Views/Settings/ (or Profile)
  - Add link to Achievement Gallery
```

### Integration Points

```swift
// After logging an event
func logEvent(_ event: PuppyEvent) async {
    await eventStore.save(event)

    // Check for new achievements
    let newAchievements = achievementDetector.checkAll(
        events: eventStore.allEvents,
        profile: profile
    )

    if let achievement = newAchievements.first {
        achievementStore.pendingCelebration = achievement
    }
}
```

## Notification Strategy

### Celebration Notifications

For achievements that happen in background (age milestones):

```swift
// Morning notification on birthday
"🎂 It's Luna's birthday! Tap to celebrate and share!"

// Streak about to break
"🔥 Don't break the streak! Log Luna's potty to keep the 6-day streak going!"

// Weekly streak reminder
"⭐ Luna is one day away from a 7-day streak!"
```

## Gamification Considerations

### Achievement Tiers

Consider bronze/silver/gold tiers for progressive achievements:

- **Bronze:** 3-day streak
- **Silver:** 7-day streak
- **Gold:** 14-day streak
- **Platinum:** 30-day streak

### Hidden Achievements

Fun surprises users discover:
- "Night Owl" — First late-night walk
- "Early Bird" — First 6am walk
- "Weekend Warrior" — 10 weekend adventures
- "Rain Champion" — Walked in the rain

## Testing

- [ ] Achievement detection triggers correctly
- [ ] Celebration sheet appears immediately after earning
- [ ] Card renders correctly with and without photo
- [ ] Share to Instagram Stories works
- [ ] Share to standard sheet works
- [ ] Achievement persists after app restart
- [ ] No duplicate achievements awarded
- [ ] Age-based achievements trigger on correct dates

## Notes

- Achievements should feel special, not spammy — limit to meaningful moments
- Always allow user to skip/dismiss celebration
- Consider "quiet mode" setting for users who don't want celebrations
- Track which achievements get shared most for future optimization
- Photo selection: use most recent photo, or let user pick
