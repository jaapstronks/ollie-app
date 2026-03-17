# Brief: Growth & "Then vs Now" Cards

> **Status:** Concept
> **Priority:** High (Viral Potential)
> **Dependencies:** Photo logging feature
> **Estimated Effort:** Medium

## Objective

Create shareable growth comparison cards that showcase a puppy's transformation over time. "Then vs Now" content is consistently among the most engaging pet content on social media.

## Why This Works

- **Visual transformation** — Puppies grow fast; the change is dramatic and shareable
- **Nostalgia trigger** — Looking back creates emotional response
- **Universal appeal** — Non-dog-owners still love puppy growth content
- **Conversation starter** — "Wow, look how big she got!"
- **Simple concept** — No explanation needed, instantly understood

## Features

### 1. Then vs Now Comparison

Side-by-side comparison of first photo logged vs recent photo.

```
┌─────────────────────────────────────┐
│                                     │
│          THEN → NOW                 │
│                                     │
│   ┌─────────────┐ ┌─────────────┐   │
│   │             │ │             │   │
│   │  Day 1      │ │  Today      │   │
│   │  8 weeks    │ │  6 months   │   │
│   │             │ │             │   │
│   │  2.1 kg     │ │  18.3 kg    │   │
│   │             │ │             │   │
│   └─────────────┘ └─────────────┘   │
│                                     │
│          Luna • 4 months later      │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

### 2. Monthly Growth Grid

Shows progression month by month (or week by week for young puppies).

```
┌─────────────────────────────────────┐
│                                     │
│       Luna's First 6 Months         │
│                                     │
│   ┌───────┐ ┌───────┐ ┌───────┐    │
│   │  📸   │ │  📸   │ │  📸   │    │
│   │Month 1│ │Month 2│ │Month 3│    │
│   │ 2 kg  │ │ 5 kg  │ │ 9 kg  │    │
│   └───────┘ └───────┘ └───────┘    │
│                                     │
│   ┌───────┐ ┌───────┐ ┌───────┐    │
│   │  📸   │ │  📸   │ │  📸   │    │
│   │Month 4│ │Month 5│ │Month 6│    │
│   │ 13 kg │ │ 17 kg │ │ 21 kg │    │
│   └───────┘ └───────┘ └───────┘    │
│                                     │
│    From tiny pup to big doggo! 🐕   │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

### 3. Weight Growth Chart Card

Visual graph of weight progression with key milestones.

```
┌─────────────────────────────────────┐
│                                     │
│      Luna's Growth Journey          │
│                                     │
│  kg                                 │
│  25 │                    ●──────    │
│     │                 ●──           │
│  20 │              ●──              │
│     │           ●──                 │
│  15 │        ●──                    │
│     │     ●──                       │
│  10 │  ●──                          │
│     │●──                            │
│   5 │                               │
│     │                               │
│   0 └──────────────────────────     │
│      8w  3m  4m  5m  6m  Now       │
│                                     │
│   Started: 2.1 kg → Now: 24.8 kg   │
│   Growth: +1,081%  🚀              │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

### 4. Same Spot Comparison

When user has photos with recognizable backgrounds/objects.

```
┌─────────────────────────────────────┐
│                                     │
│          SAME SPOT                  │
│       Different Dog? 😱             │
│                                     │
│   ┌─────────────────────────────┐   │
│   │                             │   │
│   │   [Photo on couch - small]  │   │
│   │                             │   │
│   │   Week 1                    │   │
│   └─────────────────────────────┘   │
│              ↓                      │
│   ┌─────────────────────────────┐   │
│   │                             │   │
│   │   [Photo on couch - BIG]    │   │
│   │                             │   │
│   │   6 Months Later            │   │
│   └─────────────────────────────┘   │
│                                     │
│   ─────────────────────────────     │
│   Made with Ollie 🐾               │
└─────────────────────────────────────┘
```

### 5. Growth Timeline Video (Future)

Auto-generated video montage of all logged photos.

```
[Day 1] → [Week 2] → [Month 1] → [Month 2] → ...
With weight overlay and age counter
Background music option
Duration: 15-30 seconds for social media
```

## Photo Selection System

### Automatic Photo Finding

```swift
// Services/GrowthPhotoSelector.swift
class GrowthPhotoSelector {
    let eventStore: EventStore
    let photoStore: PhotoStore

    /// Find best "first" photo
    func findFirstPhoto(for profile: PuppyProfile) -> EventPhoto? {
        // 1. Look for photos from first week home
        let firstWeek = profile.homeDate...profile.homeDate.addingDays(7)
        if let photo = findBestPhoto(in: firstWeek) {
            return photo
        }

        // 2. Fall back to earliest photo
        return findEarliestPhoto()
    }

    /// Find best recent photo
    func findRecentPhoto(for profile: PuppyProfile) -> EventPhoto? {
        // Look in last 7 days
        let recentRange = Date().addingDays(-7)...Date()
        if let photo = findBestPhoto(in: recentRange) {
            return photo
        }

        // Fall back to most recent photo
        return findLatestPhoto()
    }

    /// Find photos for monthly grid
    func findMonthlyPhotos(for profile: PuppyProfile, months: Int) -> [Int: EventPhoto] {
        var photos: [Int: EventPhoto] = [:]

        for month in 1...months {
            let monthStart = profile.birthDate.addingMonths(month - 1)
            let monthEnd = profile.birthDate.addingMonths(month)

            if let photo = findBestPhoto(in: monthStart...monthEnd) {
                photos[month] = photo
            }
        }

        return photos
    }

    /// Score photos for selection (prefer clear face shots)
    private func scorePhoto(_ photo: EventPhoto) -> Int {
        var score = 0

        // Prefer photos attached to milestone events
        if photo.event?.type == .milestone { score += 10 }

        // Prefer photos with notes (likely memorable moments)
        if photo.event?.note != nil { score += 5 }

        // Prefer portrait orientation
        if photo.isPortrait { score += 3 }

        // Future: Use Vision framework for face detection
        return score
    }
}
```

### Manual Photo Selection

Allow users to pick their own photos:

```
┌─────────────────────────────────────┐
│  Create Growth Comparison           │
├─────────────────────────────────────┤
│                                     │
│  "Then" Photo                       │
│  ┌───────────────────────────┐      │
│  │                           │      │
│  │  [Selected: Day 1]        │ ✏️   │
│  │   March 1, 2025           │      │
│  │                           │      │
│  └───────────────────────────┘      │
│                                     │
│  "Now" Photo                        │
│  ┌───────────────────────────┐      │
│  │                           │      │
│  │  [Selected: Today]        │ ✏️   │
│  │   March 8, 2026           │      │
│  │                           │      │
│  └───────────────────────────┘      │
│                                     │
│  ☑ Show weight comparison           │
│  ☑ Show age labels                  │
│  ☐ Include growth percentage        │
│                                     │
│        [ Create Card ]              │
│                                     │
└─────────────────────────────────────┘
```

## Weight Data Integration

### Pulling Weight History

```swift
// Services/WeightHistoryService.swift
class WeightHistoryService {
    let eventStore: EventStore

    func getWeightHistory(for profile: PuppyProfile) -> [WeightEntry] {
        let weightEvents = eventStore.allEvents.filter { $0.type == .gewicht }

        return weightEvents.compactMap { event in
            guard let weight = event.weight else { return nil }
            return WeightEntry(date: event.time, weight: weight)
        }.sorted { $0.date < $1.date }
    }

    func getWeightAt(date: Date) -> Double? {
        let history = getWeightHistory(for: profile)

        // Find closest weight entry to date
        return history.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })?.weight
    }

    func calculateGrowthStats() -> GrowthStats {
        let history = getWeightHistory(for: profile)
        guard let first = history.first, let last = history.last else {
            return GrowthStats.empty
        }

        return GrowthStats(
            startWeight: first.weight,
            currentWeight: last.weight,
            percentageGain: ((last.weight - first.weight) / first.weight) * 100,
            avgWeeklyGain: (last.weight - first.weight) / weeksElapsed,
            projectedAdultWeight: calculateProjectedWeight()
        )
    }
}

struct WeightEntry {
    let date: Date
    let weight: Double
}

struct GrowthStats {
    let startWeight: Double
    let currentWeight: Double
    let percentageGain: Double
    let avgWeeklyGain: Double
    let projectedAdultWeight: Double?

    static let empty = GrowthStats(
        startWeight: 0, currentWeight: 0,
        percentageGain: 0, avgWeeklyGain: 0,
        projectedAdultWeight: nil
    )
}
```

## Card Generation

### Then vs Now Card View

```swift
// Views/Growth/ThenNowCardView.swift
struct ThenNowCardView: View {
    let profile: PuppyProfile
    let thenPhoto: UIImage
    let nowPhoto: UIImage
    let thenDate: Date
    let nowDate: Date
    let thenWeight: Double?
    let nowWeight: Double?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("THEN → NOW")
                .font(.title.bold())
                .tracking(2)

            // Photo comparison
            HStack(spacing: 16) {
                photoCard(
                    image: thenPhoto,
                    label: thenLabel,
                    weight: thenWeight
                )

                photoCard(
                    image: nowPhoto,
                    label: nowLabel,
                    weight: nowWeight
                )
            }

            // Time elapsed
            Text("\(profile.name) • \(timeElapsedText)")
                .font(.headline)

            // Growth stat (if weights available)
            if let growth = growthPercentage {
                HStack {
                    Image(systemName: "arrow.up.right")
                    Text("+\(Int(growth))% growth")
                }
                .font(.subheadline)
                .foregroundStyle(.green)
            }

            Spacer()

            // Watermark
            watermark
        }
        .padding(32)
        .frame(width: 1080, height: 1350) // 4:5 ratio for Instagram
        .background(backgroundGradient)
    }

    private func photoCard(image: UIImage, label: String, weight: Double?) -> some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 450, height: 450)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let weight = weight {
                Text("\(weight, specifier: "%.1f") kg")
                    .font(.headline)
            }
        }
    }

    private var thenLabel: String {
        if Calendar.current.isDate(thenDate, equalTo: profile.homeDate, toGranularity: .day) {
            return "Day 1"
        }
        return thenDate.formatted(.dateTime.month().day())
    }

    private var timeElapsedText: String {
        let components = Calendar.current.dateComponents(
            [.month, .day],
            from: thenDate,
            to: nowDate
        )
        if let months = components.month, months > 0 {
            return "\(months) months later"
        }
        if let days = components.day {
            return "\(days) days later"
        }
        return ""
    }
}
```

### Monthly Grid Card View

```swift
// Views/Growth/MonthlyGridCardView.swift
struct MonthlyGridCardView: View {
    let profile: PuppyProfile
    let monthlyPhotos: [Int: UIImage]  // month number -> photo
    let monthlyWeights: [Int: Double]  // month number -> weight
    let totalMonths: Int

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("\(profile.name)'s First \(totalMonths) Months")
                .font(.title2.bold())

            // Photo grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(1...totalMonths, id: \.self) { month in
                    monthCell(month: month)
                }
            }

            // Summary
            if let firstWeight = monthlyWeights[1],
               let lastWeight = monthlyWeights[totalMonths] {
                Text("\(firstWeight, specifier: "%.1f") kg → \(lastWeight, specifier: "%.1f") kg")
                    .font(.headline)
            }

            Spacer()
            watermark
        }
        .padding(32)
        .frame(width: 1080, height: 1350)
        .background(backgroundGradient)
    }

    @ViewBuilder
    private func monthCell(month: Int) -> some View {
        VStack(spacing: 4) {
            if let photo = monthlyPhotos[month] {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Placeholder for missing month
                RoundedRectangle(cornerRadius: 12)
                    .fill(.secondary.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }

            Text("Month \(month)")
                .font(.caption2)

            if let weight = monthlyWeights[month] {
                Text("\(weight, specifier: "%.1f") kg")
                    .font(.caption.bold())
            }
        }
    }
}
```

### Growth Chart Card View

```swift
// Views/Growth/GrowthChartCardView.swift
struct GrowthChartCardView: View {
    let profile: PuppyProfile
    let weightHistory: [WeightEntry]
    let stats: GrowthStats

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("\(profile.name)'s Growth Journey")
                .font(.title2.bold())

            // Chart
            Chart(weightHistory) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(.blue)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(.blue)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let kg = value.as(Double.self) {
                            Text("\(Int(kg)) kg")
                        }
                    }
                }
            }
            .frame(height: 400)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))

            // Stats summary
            HStack(spacing: 40) {
                statBadge(
                    label: "Started",
                    value: "\(stats.startWeight, specifier: "%.1f") kg"
                )
                statBadge(
                    label: "Now",
                    value: "\(stats.currentWeight, specifier: "%.1f") kg"
                )
                statBadge(
                    label: "Growth",
                    value: "+\(Int(stats.percentageGain))%"
                )
            }

            Spacer()
            watermark
        }
        .padding(32)
        .frame(width: 1080, height: 1920)
        .background(backgroundGradient)
    }
}
```

## Triggers & Prompts

### When to Prompt for Growth Cards

```swift
// Services/GrowthCardPromptService.swift
class GrowthCardPromptService {

    func shouldPromptForGrowthCard(profile: PuppyProfile, lastPrompt: Date?) -> Bool {
        // Monthly prompt
        if let lastPrompt = lastPrompt {
            let monthsSincePrompt = Calendar.current.dateComponents(
                [.month], from: lastPrompt, to: Date()
            ).month ?? 0
            if monthsSincePrompt < 1 { return false }
        }

        // Key milestones to prompt
        let ageWeeks = profile.ageInWeeks

        // Prompt at: 12w, 16w, 6mo, 9mo, 1yr
        let promptWeeks = [12, 16, 26, 39, 52]
        if promptWeeks.contains(ageWeeks) {
            return true
        }

        // Monthly after 3 months
        if ageWeeks > 12 && ageWeeks % 4 == 0 {
            return true
        }

        return false
    }
}
```

### In-App Prompt

```
┌─────────────────────────────────────┐
│                                     │
│   📸 Luna has grown so much!        │
│                                     │
│   Create a "Then vs Now" card to    │
│   see the transformation.           │
│                                     │
│  ┌─────────┐    ┌─────────┐        │
│  │  Day 1  │ →  │  Today  │        │
│  └─────────┘    └─────────┘        │
│                                     │
│       [ Create Card ]               │
│       [ Maybe Later ]               │
│                                     │
└─────────────────────────────────────┘
```

## Sharing Captions

```swift
extension GrowthCard {
    var shareCaption: String {
        switch type {
        case .thenVsNow:
            return "From tiny pup to big doggo! 🐕 Look how much \(profile.name) has grown! #ThenVsNow #PuppyGrowth #OllieApp"

        case .monthlyGrid:
            return "\(profile.name)'s first \(months) months in photos! 📸🐾 #PuppyGrowth #OllieApp"

        case .growthChart:
            return "\(profile.name) has grown \(Int(stats.percentageGain))% since coming home! 📈🐕 #PuppyGrowth #OllieApp"
        }
    }
}
```

## Implementation

### Files to Create

```
Ollie-app/Models/GrowthCard.swift
Ollie-app/Services/GrowthPhotoSelector.swift
Ollie-app/Services/WeightHistoryService.swift
Ollie-app/Services/GrowthCardPromptService.swift
Ollie-app/Views/Growth/ThenNowCardView.swift
Ollie-app/Views/Growth/MonthlyGridCardView.swift
Ollie-app/Views/Growth/GrowthChartCardView.swift
Ollie-app/Views/Growth/GrowthCardCreatorSheet.swift
Ollie-app/Views/Growth/PhotoPickerSheet.swift
Ollie-app/Utils/Strings/Strings+Growth.swift
```

### Files to Modify

```
Ollie-app/Views/Health/HealthView.swift (or Growth section)
  - Add "Create Growth Card" entry point

Ollie-app/Views/Timeline/TodayView.swift
  - Show growth card prompt when appropriate
```

## Edge Cases

### Missing Photos
- Show placeholder cells in grid with prompt to add photo
- Allow user to select from camera roll for missing periods
- Still create card with available photos

### Missing Weight Data
- Omit weight labels from card
- Prompt user to log weight for better cards
- "Add your first weight measurement to track growth"

### Few Photos Available
- Suggest "Then vs Now" over grid when < 3 photos
- Prompt to take more photos for future cards

### Very Young Puppy
- Weekly grid instead of monthly for puppies < 3 months
- "Week 1, Week 2, Week 3..." labels

## Metrics to Track

- Growth cards created
- Growth cards shared
- Platform shared to
- Card type preference
- Photo selection method (auto vs manual)
- Conversion from prompt to card creation

## Future Enhancements

- **Video montage** — Animated slideshow of growth photos
- **AR comparison** — Show life-size first vs now
- **Breed comparison** — "Luna is larger than 60% of Labradors her age"
- **Growth predictions** — "Luna will likely reach 28kg adult weight"
- **Parent/sibling comparison** — Compare to other dogs in household

## Notes

- Photo quality matters — consider tips for taking good comparison photos
- Respect user privacy — never auto-share or upload photos
- Handle missing data gracefully — partial cards are better than none
- Consider accessibility — alt text for growth cards
