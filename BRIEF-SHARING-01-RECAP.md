# Brief: Shareable Recap Cards

> **Status:** Concept
> **Priority:** High (Viral Potential)
> **Dependencies:** None
> **Estimated Effort:** Medium

## Objective

Create "Spotify Wrapped" style recap cards that summarize a puppy's week, month, or year with beautiful, shareable graphics. These tap into the proven viral mechanic of personalized stats that people love to share.

## Why This Works

- **Personalized content** — Stats about YOUR dog feel special
- **Bragging rights** — "My dog had 14 perfect potty days!"
- **Emotional resonance** — Year recaps trigger nostalgia
- **Low friction** — One tap to share, pre-designed graphics
- **Network effect** — Friends see the card, ask "what app is this?"

## Features

### 1. Weekly Recap Card

Appears Sunday evening or Monday morning. Summarizes the past 7 days.

```
┌─────────────────────────────────────┐
│                                     │
│      🐕 Luna's Week in Review       │
│           Feb 24 - Mar 2            │
│                                     │
│  ┌─────────────────────────────┐    │
│  │     [Luna's Photo]         │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│   🎯 Potty Success     94%          │
│   🚶 Walks             12           │
│   😴 Avg Sleep         9.2 hrs      │
│   🏆 Training Sessions 8            │
│   ⭐ New Skills        2            │
│                                     │
│   "Luna had her best week yet!"     │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

**Data points to include:**
- Potty success rate (outdoor vs accidents)
- Number of walks
- Average sleep duration
- Training sessions logged
- New skills learned (if any)
- Streak achievements (if any)
- Fun stat: estimated tail wags, km walked, etc.

### 2. Monthly Recap Card

Available at month end. More comprehensive stats with growth tracking.

```
┌─────────────────────────────────────┐
│                                     │
│     🎉 February Recap               │
│        Luna's Month                 │
│                                     │
│  ┌─────┐  ┌─────┐  ┌─────┐         │
│  │ 📸  │  │ 📸  │  │ 📸  │         │
│  │Week1│  │Week2│  │Week3│         │
│  └─────┘  └─────┘  └─────┘         │
│                                     │
│   Weight: 8.2 kg → 10.1 kg (+23%)  │
│   Skills Mastered: 4               │
│   Adventures: 6 new places         │
│   Walks: 48 (longest: 45 min)      │
│   Best Day: Feb 14 ❤️              │
│                                     │
│   "Luna grew 23% and learned       │
│    4 new tricks this month!"       │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

**Data points:**
- Weight change with percentage
- Skills mastered count
- New places visited (from location data)
- Walk statistics
- Best day (most events/achievements)
- Photo grid from the month
- Milestone achievements

### 3. Year in Review

Available in late December or on adoption anniversary. Premium shareable content.

```
┌─────────────────────────────────────┐
│                                     │
│    ✨ 2025: Luna's Year ✨          │
│                                     │
│   ┌───────────────────────────┐     │
│   │   [Highlight Photo Grid]  │     │
│   │    Jan  Feb  Mar  Apr     │     │
│   │    May  Jun  Jul  Aug     │     │
│   │    Sep  Oct  Nov  Dec     │     │
│   └───────────────────────────┘     │
│                                     │
│   🎂 Started the year at 8 weeks   │
│   📈 Grew from 2.1 kg to 24.3 kg   │
│   🎓 Mastered 12 commands          │
│   🚶 Walked 847 km together        │
│   📍 Visited 34 new places         │
│   📸 127 memories captured         │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

**Data points:**
- Age progression
- Weight growth
- Commands/skills learned
- Total distance walked (estimated from duration)
- Places visited
- Photos captured
- Major milestones timeline
- "Personality type" based on logged behaviors

### 4. Gotcha Day Anniversary Card

Triggered on home date anniversary.

```
┌─────────────────────────────────────┐
│                                     │
│   🎉 1 Year Together! 🎉           │
│                                     │
│   ┌─────────┐    ┌─────────┐       │
│   │  Day 1  │ →  │  Today  │       │
│   │  📸     │    │  📸     │       │
│   └─────────┘    └─────────┘       │
│                                     │
│   "365 days of adventures,         │
│    countless memories, and         │
│    one very good boy."             │
│                                     │
│   Luna has been home for           │
│   1 year • 52 weeks • 365 days     │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

## Card Generation System

### Architecture

```swift
// Models/ShareableCard.swift
struct ShareableCard {
    let type: CardType
    let profile: PuppyProfile
    let stats: CardStats
    let photos: [UIImage]
    let generatedDate: Date

    enum CardType {
        case weeklyRecap(weekOf: Date)
        case monthlyRecap(month: Int, year: Int)
        case yearInReview(year: Int)
        case gotchaAnniversary(years: Int)
    }
}

struct CardStats {
    // Common stats
    let pottySuccessRate: Double?
    let walkCount: Int
    let avgSleepHours: Double?
    let trainingSessionCount: Int
    let newSkillsCount: Int

    // Growth stats (monthly/yearly)
    let weightChange: WeightChange?
    let placesVisited: Int?
    let photosLogged: Int?
    let totalWalkMinutes: Int?

    struct WeightChange {
        let start: Double
        let end: Double
        var percentChange: Double { ((end - start) / start) * 100 }
    }
}
```

### Card Rendering

Use SwiftUI views rendered to UIImage for sharing:

```swift
// Services/CardRenderer.swift
class CardRenderer {

    @MainActor
    func render(card: ShareableCard, size: CGSize = CGSize(width: 1080, height: 1920)) -> UIImage? {
        let view = ShareableCardView(card: card)
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
```

### Stats Calculation

```swift
// Services/RecapStatsCalculator.swift
class RecapStatsCalculator {
    let eventStore: EventStore
    let profileStore: ProfileStore

    func calculateWeeklyStats(for weekOf: Date) -> CardStats {
        let events = eventStore.events(for: weekOf.weekRange)

        let pottyEvents = events.filter { $0.type == .plassen || $0.type == .poepen }
        let outdoorPotty = pottyEvents.filter { $0.location == "buiten" }
        let successRate = Double(outdoorPotty.count) / Double(pottyEvents.count)

        let walks = events.filter { $0.type == .uitlaten }
        let sleepEvents = events.filter { $0.type == .slapen || $0.type == .ontwaken }
        let trainingEvents = events.filter { $0.type == .training }

        // ... calculate all stats

        return CardStats(
            pottySuccessRate: successRate,
            walkCount: walks.count,
            // ...
        )
    }

    func calculateMonthlyStats(month: Int, year: Int) -> CardStats { ... }
    func calculateYearlyStats(year: Int) -> CardStats { ... }
}
```

## Sharing Implementation

### iOS Share Sheet (Primary Method)

The standard `UIActivityViewController` works with all apps:

```swift
// Utils/ShareService.swift
class ShareService {

    @MainActor
    func share(card: ShareableCard, from viewController: UIViewController) async {
        guard let image = await CardRenderer().render(card: card) else { return }

        let caption = generateCaption(for: card)
        let items: [Any] = [image, caption]

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // Exclude print, save to files, etc. for cleaner experience
        activityVC.excludedActivityTypes = [
            .print,
            .addToReadingList,
            .assignToContact
        ]

        viewController.present(activityVC, animated: true)
    }

    private func generateCaption(for card: ShareableCard) -> String {
        switch card.type {
        case .weeklyRecap:
            return "\(card.profile.name) had an amazing week! 🐕 #OllieApp #PuppyLife"
        case .monthlyRecap(let month, _):
            let monthName = DateFormatter().monthSymbols[month - 1]
            return "\(card.profile.name)'s \(monthName) recap is in! 📊🐾 #OllieApp"
        case .yearInReview(let year):
            return "What a year for \(card.profile.name)! 🎉 #OllieApp #\(year)Wrapped"
        case .gotchaAnniversary(let years):
            let yearText = years == 1 ? "year" : "years"
            return "\(years) \(yearText) with my best friend! 🥳❤️ #GotchaDay #OllieApp"
        }
    }
}
```

### Platform-Specific Enhancements

#### Instagram Stories (Direct Integration)

Instagram has a URL scheme for Stories:

```swift
extension ShareService {

    func shareToInstagramStories(card: ShareableCard) async {
        guard let image = await CardRenderer().render(card: card),
              let imageData = image.pngData(),
              let url = URL(string: "instagram-stories://share") else { return }

        guard UIApplication.shared.canOpenURL(url) else {
            // Instagram not installed, fall back to share sheet
            return
        }

        let pasteboardItems: [[String: Any]] = [
            [
                "com.instagram.sharedSticker.backgroundImage": imageData,
                "com.instagram.sharedSticker.contentURL": "https://ollie.app" // App Store link
            ]
        ]

        UIPasteboard.general.setItems(pasteboardItems, options: [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ])

        await UIApplication.shared.open(url)
    }
}
```

#### Facebook Stories

Similar approach with Facebook's URL scheme:

```swift
extension ShareService {

    func shareToFacebookStories(card: ShareableCard) async {
        guard let image = await CardRenderer().render(card: card),
              let imageData = image.pngData(),
              let url = URL(string: "facebook-stories://share") else { return }

        guard UIApplication.shared.canOpenURL(url) else { return }

        let pasteboardItems: [[String: Any]] = [
            [
                "com.facebook.sharedSticker.backgroundImage": imageData,
                "com.facebook.sharedSticker.appID": "YOUR_FB_APP_ID"
            ]
        ]

        UIPasteboard.general.setItems(pasteboardItems, options: [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ])

        await UIApplication.shared.open(url)
    }
}
```

#### TikTok

TikTok requires SDK integration for video sharing, but images can go through standard share sheet.

#### Save to Photos (Fallback)

Always offer "Save to Photos" for manual sharing:

```swift
extension ShareService {

    func saveToPhotos(card: ShareableCard) async throws {
        guard let image = await CardRenderer().render(card: card) else {
            throw ShareError.renderFailed
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
```

## User Interface

### Recap Tab/Section

Add a "Memories" or "Recap" section accessible from profile or as a tab:

```
┌─────────────────────────────────────┐
│  ← Memories                         │
├─────────────────────────────────────┤
│                                     │
│  This Week                          │
│  ┌─────────────────────────────┐    │
│  │  [Preview of Weekly Card]   │    │
│  │                             │    │
│  │     [ Share ]  [ View ]     │    │
│  └─────────────────────────────┘    │
│                                     │
│  February 2025                      │
│  ┌─────────────────────────────┐    │
│  │  [Preview of Monthly Card]  │    │
│  │                             │    │
│  │     [ Share ]  [ View ]     │    │
│  └─────────────────────────────┘    │
│                                     │
│  Past Recaps                        │
│  ┌───────┐ ┌───────┐ ┌───────┐     │
│  │ Jan   │ │ Dec   │ │ Nov   │     │
│  └───────┘ └───────┘ └───────┘     │
│                                     │
└─────────────────────────────────────┘
```

### Share Sheet UI

When user taps "Share":

```
┌─────────────────────────────────────┐
│           Share Luna's Recap        │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │   [Card Preview]            │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │
│  │ IG │ │ FB │ │ 💬 │ │ ⬇️ │       │
│  │Stry│ │Stry│ │Msgs│ │Save│       │
│  └────┘ └────┘ └────┘ └────┘       │
│                                     │
│         [ More Options... ]         │
│                                     │
└─────────────────────────────────────┘
```

### Weekly Notification

Push notification on Sunday evening:

```
🐕 Luna's Week in Review is Ready!
Tap to see how Luna did this week and share with friends.
```

## Implementation

### Files to Create

```
Ollie-app/Models/ShareableCard.swift
Ollie-app/Services/CardRenderer.swift
Ollie-app/Services/ShareService.swift
Ollie-app/Services/RecapStatsCalculator.swift
Ollie-app/Views/Recap/RecapListView.swift
Ollie-app/Views/Recap/ShareableCardView.swift
Ollie-app/Views/Recap/WeeklyRecapCard.swift
Ollie-app/Views/Recap/MonthlyRecapCard.swift
Ollie-app/Views/Recap/YearRecapCard.swift
Ollie-app/Views/Recap/ShareOptionsSheet.swift
Ollie-app/Utils/Strings/Strings+Recap.swift
```

### Files to Modify

```
Ollie-app/Views/MainTabView.swift (or navigation)
  - Add access point to Recaps

Ollie-app/Info.plist
  - Add LSApplicationQueriesSchemes for instagram-stories://, facebook-stories://
```

### Info.plist Additions

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram-stories</string>
    <string>facebook-stories</string>
</array>
```

## Card Design Guidelines

### Visual Style
- **Aspect ratio:** 9:16 for Stories, 1:1 for feed posts (offer both)
- **Background:** Gradient or solid color matching app theme
- **Typography:** System fonts, clean hierarchy
- **Photos:** Rounded corners, subtle shadows
- **Watermark:** Subtle "Made with Ollie 🐾" at bottom

### Branding Elements
- App logo or icon (small, corner placement)
- Consistent color palette from app
- Paw print motifs
- Dog-related emoji usage

### Accessibility
- High contrast text
- Readable font sizes
- Alt text for screen readers when saving

## Metrics to Track

- Recap views per week
- Share button taps
- Shares completed (by platform if detectable)
- App installs attributed to shared cards (via deep links)
- Recap notification open rate

## Rollout Strategy

1. **MVP:** Weekly recap only, standard share sheet
2. **V2:** Add monthly recap, Instagram Stories direct share
3. **V3:** Year in review, more platforms, custom card themes

## Notes

- Consider offering card customization (colors, layouts) in future
- Photo selection could be automated (most recent) or user-chosen
- Premium feature potential: animated recap videos
- A/B test different stat highlights to see what gets shared most
