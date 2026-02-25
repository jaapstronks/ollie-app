# Places & Memories Tab Architecture

## Context

We want to combine **Walks/Spots** and **Photos/Moments** into a unified tab experience. The current `WalksTabView` is unused, and `MomentsGalleryView` exists but is standalone.

**Key insight:** Both walks and photos are location-based experiences that tell the story of your puppy's life.

---

## User Stories

### Reliving Memories
- "Show me all the photos I've taken of my puppy" → **Gallery view**
- "What did we do last month?" → **Timeline view**
- "Where have we been together?" → **Map with photos + walks**
- "Show me photos from the park" → **Location-filtered gallery**
- "What memories do we have at this spot?" → **Spot detail with photos**

### Planning & Utility
- "Where should we walk today?" → **Spot suggestions**
- "Which are our favorite spots?" → **Favorites list**
- "I want to save this new location" → **Add spot**
- "How many times have we been here?" → **Visit history**

---

## Option A: "Places" — Location-First Architecture

**Philosophy:** The map is home. Everything radiates from locations.

```
┌─────────────────────────────────────────┐
│  PLACES (Tab)                           │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │         MAP VIEW                │   │
│  │   📍 Spots + 📷 Photo markers   │   │
│  │                                 │   │
│  │   [Tap spot → detail sheet]    │   │
│  │   [Tap photo → preview]        │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ── Quick Access ──────────────────    │
│  [⭐ Favorites] [🕐 Recent] [📷 All]   │
│                                         │
│  ── Favorite Spots ────────────────    │
│  🌳 Het Park          12 visits  →     │
│  🏖️ Strand Noord       8 visits  →     │
│  🌲 Het Bos            5 visits  →     │
│                                         │
│  ── Recent Moments ────────────────    │
│  [thumbnail] [thumbnail] [thumbnail]   │
│  [thumbnail] [thumbnail] [See all →]   │
│                                         │
└─────────────────────────────────────────┘
```

**Spot Detail View (enhanced):**
```
┌─────────────────────────────────────────┐
│  ← Het Park                    ⭐ ✏️    │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │         MINI MAP               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  📍 1.2 km away • 🚶 12 visits         │
│  Last visited: 2 days ago              │
│                                         │
│  ── Photos Here ───────────────────    │
│  [photo] [photo] [photo] [photo]       │
│  [photo] [photo] [+12 more →]          │
│                                         │
│  ── Walk History ──────────────────    │
│  Feb 22  •  25 min  •  🐕 2 potties    │
│  Feb 19  •  30 min  •  🐕 1 potty      │
│  Feb 15  •  20 min  •  🐕 3 potties    │
│                                         │
│  [Start Walk Here]                      │
└─────────────────────────────────────────┘
```

**Pros:**
- Clear mental model: "Places we go"
- Map as primary navigation is intuitive
- Natural grouping of photos by location
- Good for "where should we walk?"

**Cons:**
- Photos without location data need special handling
- Timeline browsing is secondary
- Less emotional, more utilitarian

---

## Option B: "Memories" — Time-First Architecture

**Philosophy:** Life is a timeline. Scroll through your puppy's story.

```
┌─────────────────────────────────────────┐
│  MEMORIES (Tab)                         │
├─────────────────────────────────────────┤
│  [Timeline] [Places] [Gallery]  ← Picker│
├─────────────────────────────────────────┤
│                                         │
│  ── February 2026 ─────────────────    │
│                                         │
│  Today                                  │
│  ┌─────────────────────────────────┐   │
│  │ 📷 [photo]     Morning at park  │   │
│  │     9:15 AM • Het Park          │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ 🚶 Walk        Het Park         │   │
│  │     9:00 AM • 25 min • 2 potties│   │
│  └─────────────────────────────────┘   │
│                                         │
│  Yesterday                              │
│  ┌─────────────────────────────────┐   │
│  │ 📷 [photo]     First snow!      │   │
│  │     3:30 PM • Backyard          │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ── January 2026 ──────────────────    │
│  ...                                    │
└─────────────────────────────────────────┘
```

**Sub-views via segmented picker:**

1. **Timeline** — Chronological feed of moments + walks
2. **Places** — Map view with spots and photo clusters
3. **Gallery** — Grid of all photos

**Pros:**
- Emotional, story-driven experience
- Natural for "reliving memories"
- Photos and walks interleaved naturally
- Easy to find "what did we do when..."

**Cons:**
- More complex navigation (3 sub-views)
- "Where to walk" is buried
- May feel like duplicate of main timeline

---

## Option C: "Adventures" — Hybrid with Smart Sections

**Philosophy:** One scrollable page with contextual sections that adapt.

```
┌─────────────────────────────────────────┐
│  ADVENTURES (Tab)                       │
├─────────────────────────────────────────┤
│                                         │
│  ── This Week's Highlights ────────    │
│  [large photo]  "First beach visit!"   │
│  [photo] [photo] [photo] [+3]          │
│                                         │
│  ── Where to Walk ─────────────────    │
│  Weather: ☀️ 12°C Perfect for walks    │
│                                         │
│  ⭐ Het Park        1.2 km  [Go →]     │
│  🕐 Strand Noord    2.5 km  [Go →]     │
│  💡 Try somewhere new?     [Explore]   │
│                                         │
│  ── Memory Map ────────────────────    │
│  ┌─────────────────────────────────┐   │
│  │   [Interactive map with pins]   │   │
│  │   📍 spots  📷 photos           │   │
│  │            [Expand →]           │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ── Recent Moments ────────────────    │
│  February 2026                         │
│  [thumb] [thumb] [thumb] [thumb]       │
│  January 2026                          │
│  [thumb] [thumb] [thumb] [See all]     │
│                                         │
│  ── All Spots ─────────────────────    │
│  [Favorites] [Recent] [All on map]     │
│                                         │
└─────────────────────────────────────────┘
```

**Pros:**
- Shows everything at a glance
- Adaptive: highlights change based on activity
- Both planning (where to walk) and memories visible
- Doesn't force one mental model

**Cons:**
- Can feel cluttered
- No single "home" concept
- Harder to maintain section priorities

---

## Option D: "Explore" — Map-Centric with Drawer

**Philosophy:** Full-screen map with a pull-up drawer for lists and galleries.

```
┌─────────────────────────────────────────┐
│  EXPLORE (Tab)                          │
├─────────────────────────────────────────┤
│                                         │
│         FULL SCREEN MAP                 │
│                                         │
│    📍        📷                         │
│         📍       📷 📷                  │
│    📷              📍                   │
│         📍   📷                         │
│                    📍                   │
│                                         │
│  ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐   │
│  │  ═══  (drag handle)              │   │
│  │                                  │   │
│  │  [Spots] [Moments] [Walks]       │   │
│  │                                  │   │
│  │  ⭐ Het Park        12 visits    │   │
│  │  🏖️ Strand Noord     8 visits    │   │
│  │  🌲 Het Bos          5 visits    │   │
│  │  ...                             │   │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘   │
│                                         │
└─────────────────────────────────────────┘
```

**Interaction:**
- Tap map pin → detail popup or sheet
- Pull drawer up → browse lists
- Drawer tabs: Spots / Moments / Walk History

**Pros:**
- Map is hero — very visual
- Modern UX pattern (Apple Maps style)
- Clear separation: map = browse, drawer = lists

**Cons:**
- Drawer pattern can be fiddly
- Less discoverable than scrolling
- Map-first may not suit all users

---

## Final Decision: Map-First with Timeline Escape

**Architecture:** Option A (Places) as primary, with a view toggle to Timeline.

Two ways to browse the same content:
1. **Map View (default)** — Spatial: "Where have we been?"
2. **Timeline View (toggle)** — Temporal: "When did this happen?"

---

## Proposed Final Structure

```
PLACES (Tab)
│
├── Navigation Bar
│   ├── Title: "Places"
│   ├── Left: View toggle [🗺️ Map | 📅 Timeline]
│   └── Right: + Add (spot or moment)
│
├── === MAP VIEW (default) ===
│   │
│   ├── Interactive Map (hero, ~40% of screen)
│   │   ├── Spot pins (📍) — tap → SpotDetailSheet
│   │   ├── Photo markers (📷) — tap → PhotoPreview
│   │   ├── Photo clusters with count badge
│   │   └── "Expand" button → full-screen map
│   │
│   ├── Section: Favorite Spots
│   │   ├── Horizontal scroll of spot cards
│   │   ├── Each card: name, photo count, visit count
│   │   └── Tap → SpotDetailSheet
│   │
│   ├── Section: Recent Moments
│   │   ├── 3x2 thumbnail grid (last 6 photos)
│   │   ├── Tap thumbnail → PhotoPreview
│   │   └── "See all →" → Full MomentsGalleryView
│   │
│   └── Section: All Spots (collapsible)
│       ├── List view of all spots
│       └── Sort: Favorites first, then by recency
│
└── === TIMELINE VIEW (toggle) ===
    │
    ├── Scrollable chronological feed
    │   ├── Grouped by month ("February 2026")
    │   └── Within month, grouped by day
    │
    ├── Entry types:
    │   │
    │   ├── Photo Moment
    │   │   ┌─────────────────────────────┐
    │   │   │ [Photo thumbnail]           │
    │   │   │ "Playing in the snow"       │
    │   │   │ 📍 Het Park • Feb 22, 9:15  │
    │   │   └─────────────────────────────┘
    │   │
    │   └── Walk Session
    │       ┌─────────────────────────────┐
    │       │ 🚶 Walk at Het Park         │
    │       │ 25 min • 2 potties          │
    │       │ Feb 22, 9:00 AM             │
    │       └─────────────────────────────┘
    │
    └── Tap entry → Detail view or PhotoPreview
```

---

## View Toggle Behavior

```
┌─────────────────────────────────────────┐
│  Places              [🗺️|📅]      +    │
├─────────────────────────────────────────┤
         ↑                ↑
      Title         Segmented picker
                    or icon toggle
```

**Toggle options:**
- **Segmented control:** `[Map] [Timeline]` — clearer, takes more space
- **Icon toggle:** `🗺️ ↔ 📅` — compact, fits in nav bar
- **Pull-down menu:** Tap title "Places ▾" → select view

**Recommendation:** Segmented control in nav bar for discoverability.

---

## Enhanced Spot Detail Sheet

```
SpotDetailSheet (presented as sheet or push)
│
├── Header
│   ├── Spot name (editable inline)
│   ├── Category icon + label
│   ├── ⭐ Favorite toggle
│   └── ⋮ Menu (edit, delete)
│
├── Mini Map
│   └── Single pin, non-interactive
│
├── Stats Row
│   ├── 📍 1.2 km away
│   ├── 🚶 12 visits
│   └── 📷 8 photos
│
├── Section: Photos Here
│   ├── Grid of photos within ~100m of spot
│   ├── Empty state: "No photos yet. Take one on your next visit!"
│   └── "See all →" if > 6 photos
│
├── Section: Walk History
│   ├── List of walks at this spot (most recent first)
│   ├── Each row: date, duration, potty count
│   └── Tap → Walk detail or edit
│
├── Section: Notes
│   └── Free text notes about the spot
│
└── Actions
    ├── [Navigate] — Open in Maps app
    └── [Start Walk] — Quick-log walk at this spot
```

---

## Photo-to-Spot Matching

Photos are linked to spots by proximity:

```swift
// In SpotStore or a new service
func spotForLocation(latitude: Double, longitude: Double) -> WalkSpot? {
    // Find spots within 100m radius
    let nearbySpots = spotsNear(latitude: latitude, longitude: longitude, radiusMeters: 100)
    return nearbySpots.first // Return closest
}

// When displaying spot detail
func photosAtSpot(_ spot: WalkSpot) -> [PuppyEvent] {
    return allMoments.filter { moment in
        guard let lat = moment.latitude, let lon = moment.longitude else { return false }
        return distance(from: spot, to: (lat, lon)) < 100 // meters
    }
}
```

**Edge cases:**
- Photo with no location → Appears in "Recent Moments" and Timeline, not on map
- Photo near multiple spots → Associate with closest spot
- Future: Allow manual spot assignment when logging moment

---

## Data Model Changes Needed

### 1. Link photos to spots
Photos already have `latitude`/`longitude`. We can:
- Match photos to spots within ~100m radius (SpotStore already has `spotsNear()`)
- Or add optional `spotId` to photo events for explicit linking

### 2. Aggregate spot statistics
- Total photos at spot
- Walk history at spot
- Last visited date

### 3. Photo clustering for map
- Group nearby photos into clusters
- Show count badge on cluster markers

---

## Alternative Names

| English | Dutch | Notes |
|---------|-------|-------|
| Places | Plekken | Clear, simple |
| Explore | Ontdek | Action-oriented |
| Adventures | Avonturen | Fun but maybe too playful |
| Out & About | Buitenshuis | Captures the outdoor aspect |
| Memories | Herinneringen | More emotional |
| Outings | Uitjes | Common Dutch term |

**Recommendation:** "Places" / "Plekken" — simple, universal, maps to mental model.

---

## Implementation Phases

### Phase 1: Foundation ✅
- [x] Create `PlacesTabView` as new unified tab
- [x] Add view mode state (`map` vs `timeline`)
- [x] Implement basic map view with existing spots
- [x] Wire up navigation to existing `SpotDetailView`

### Phase 2: Photo Integration ✅
- [x] Add photo markers to map (events with lat/lon)
- [x] Implement photo clustering for map (with count badges)
- [x] Add `photosAtSpot()` function using proximity matching
- [x] Enhance `SpotDetailView` with photos section

### Phase 3: Timeline View ✅
- [x] Create `PlacesTimelineView` component
- [x] Group moments + walks by month/day
- [x] Design timeline entry cards (photo moment, walk session)
- [x] Implement view toggle in nav bar

### Phase 4: Polish ✅
- [x] Add "Recent Moments" section to map view
- [x] Add "Favorite Spots" horizontal scroll
- [x] Empty states for new users
- [ ] Animations for view switching (optional enhancement)

### Phase 5: Cleanup ✅
- [x] Remove or deprecate old `WalksTabView`
- [x] Update tab bar icon and label (already using map.fill + "Places")
- [x] Add localized strings for new UI

**Removed files:**
- `Views/WalksTabView.swift`
- `Views/Walks/WalksMapSection.swift`
- `Views/Walks/WalksFavoriteSpotsSection.swift`
- `Views/Walks/WalksRecentSpotsSection.swift`
- `Views/Walks/WalksWeatherSection.swift`
- `Views/Walks/WalksTodaySection.swift`
- `Views/Walks/` (empty directory)

---

## Files to Create/Modify

**New files:**
- `Views/Places/PlacesTabView.swift` — Main tab container
- `Views/Places/PlacesMapView.swift` — Map view mode
- `Views/Places/PlacesTimelineView.swift` — Timeline view mode
- `Views/Places/PlacesTimelineEntry.swift` — Individual timeline entries
- `Views/Places/SpotCard.swift` — Compact spot card for horizontal scroll

**Modify:**
- `Views/Walk/SpotDetailView.swift` — Add photos section, walk history
- `Services/SpotStore.swift` — Add `photosAtSpot()`, enhance queries
- `ViewModels/MomentsViewModel.swift` — Add location-based filtering
- `Ollie_appApp.swift` — Update tab bar

**Remove (after migration):**
- `Views/WalksTabView.swift`
- `Views/Walks/WalksMapSection.swift` (merge into PlacesMapView)
- `Views/Walks/WalksFavoriteSpotsSection.swift` (merge into PlacesTabView)

---

## Decisions Made

1. **Tab name:** "Places" (Dutch: "Plekken")
2. **Toggle style:** Segmented control `[Map | Timeline]`
3. **Walks on map:** Show as spot pin (not routes)
4. **Photos without location:** Show in Timeline with "No location" indicator, but not on map
