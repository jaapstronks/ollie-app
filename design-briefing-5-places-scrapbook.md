# Design Briefing 5: Places as Scrapbook — From Map Utility to Memory Layer

## Problem Statement

The Places tab currently shows a map, a list of saved places, recent photo moments, and filter chips for Spots, Contacts, Photos, and Favorites. It's functional but disconnected—three separate things sharing a screen rather than a unified experience.

The map is a utility: here are pins. The photos are a gallery: here are thumbnails. The places are a list: here are names. There's no story connecting them.

For a puppy whose world is expanding day by day—first time at the park, first vet visit, favorite potty spot, the field where they met their best dog friend—places are memories, not just coordinates.

---

## Design Direction

Reimagine Places as a **spatial memory layer**—a view that connects where you've been with what happened there. The map becomes a scrapbook where pins tell stories and routes trace adventures.

The vision: a year from now, the user opens Places and sees their puppy's entire world mapped out—every favorite spot, every adventure, every first time—with photos and memories attached.

---

## Core Concepts

### 1. Photo Pins

Instead of separating photos into a "Recent Moments" gallery below the map, display photos **directly on the map** as pins.

**Visual treatment:**
- Photo thumbnails as circular pins on the map
- Clustered when zoomed out (shows count or mini-grid)
- Expands to show individual photos when zoomed in
- Golden ring around pins that have memories/milestones attached

**Tap behavior:**
- Tap photo pin → Expanded photo card with:
  - Full photo
  - Date taken
  - What happened (event context)
  - Place name (if saved)
  - Option to save place if not already saved

### 2. Walk Routes (Future/GPS)

If GPS tracking is available or planned, show walked routes on the map.

**Visual treatment:**
- Routes as colored lines (green for walks)
- Line thickness or color intensity indicates frequency
- Creates a "territory" view over time

**Interaction:**
- Tap a route → shows walks that used this route
- "Your most walked path: 47 times" with photo collage

**Note:** This requires GPS tracking capability. If not currently implemented, this is a v2/v3 feature. Design the system to accommodate it later.

### 3. Place Personality

Each saved place accumulates context and becomes a "character" in Ollie's story.

**Place detail view:**
```
┌─────────────────────────────────────┐
│ 📍 Veldje (nickname: "Ollie's spot")│
│                                     │
│ [Map preview centered on place]     │
│                                     │
│ 📊 Stats                            │
│ • Visited 12 times                  │
│ • 8 potty successes here            │
│ • Met 3 dogs                        │
│ • First visit: Feb 15, 2026         │
│                                     │
│ 📸 Photos from here (4)             │
│ [photo] [photo] [photo] [photo]     │
│                                     │
│ 📝 Notes                            │
│ "Great spot in the morning,         │
│  usually quiet before 8am"          │
│                                     │
│ [Navigate] [Edit] [Add Photo]       │
└─────────────────────────────────────┘
```

### 4. Contact Places Enhanced

When a place is a contact (vet, daycare, groomer), the detail view prioritizes contact functionality:

```
┌─────────────────────────────────────┐
│ 🏥 Dierenkliniek Amsterdam          │
│ Veterinarian                        │
│                                     │
│ [Call]  [Navigate]  [Website]       │
│                                     │
│ 📅 Next appointment                 │
│ Vaccination booster - March 15      │
│ [View in Calendar]                  │
│                                     │
│ 📋 Visit history                    │
│ • Feb 27: Checkup ✓                 │
│ • Feb 1: First vaccination ✓        │
│                                     │
│ 📝 Notes                            │
│ "Dr. van der Berg is Ollie's vet.   │
│  Parking behind building."          │
│                                     │
│ 📸 Photos (1)                       │
│ [photo from vet visit]              │
└─────────────────────────────────────┘
```

### 5. Explore Suggestions

Based on socialization checklist data, suggest new types of places to visit:

**Implementation:**
- Cross-reference socialization items with places visited
- Identify gaps: "Ollie hasn't been to a busy shopping area"
- Suggest nearby places that fill the gap

**UI:**
```
┌─────────────────────────────────────┐
│ 🧭 Explore Suggestions              │
│                                     │
│ For socialization, try visiting:    │
│                                     │
│ 🛒 Busy shopping area               │
│    "Albert Heijn XL" - 1.2 km       │
│    [Navigate]                       │
│                                     │
│ 🚉 Train station                    │
│    "Station Centraal" - 2.5 km      │
│    [Navigate]                       │
└─────────────────────────────────────┘
```

---

## Map View Modes

### Default: Memory View

Shows photo pins, saved places, and route overlays (if available).

**Layers (toggleable):**
- Photo pins: On/Off
- Saved places: On/Off
- Routes: On/Off (if available)

### Filtered Views

Filter chips narrow what's shown:
- **Spots:** Only saved walk spots/parks
- **Contacts:** Only vet, daycare, groomer, etc.
- **Photos:** Only photo pins
- **Favorites:** Only favorited places

### Heat Map View (Advanced)

Alternative visualization showing activity density:
- Areas with more visits appear "warmer"
- Creates a visual map of Ollie's world
- Toggle between pin view and heat map

---

## Adding Places

### From Map

Long-press on map → "Add place here"
- Set place type (spot, contact, home)
- Add name and optional details
- Add photo immediately or skip

### From Event

When logging a walk or potty event:
- Option to "Save this location"
- Auto-fills coordinates from current location
- Quick save with default name or customize

### From Photo

In photo detail view:
- If photo has location data
- "Save location as place"
- Pre-populates with photo location

---

## Visual Design

### Map Style

Consider a custom map style that:
- Uses Ollie brand colors for water, parks, etc.
- Reduces visual noise from unimportant features
- Emphasizes green spaces (parks, nature)
- Maintains legibility and navigation utility

**Light mode:** Warm, inviting map colors
**Dark mode:** Clean dark map, pins remain vibrant

### Pin Design System

| Type | Design | Color |
|------|--------|-------|
| Photo pin | Circular with image | White border, slight shadow |
| Saved spot | Location icon | Green (outdoor palette) |
| Contact | Business icon | Coral (health) or purple (services) |
| Home | House icon | Orange (brand) |
| Favorite | Star badge overlay | Gold |

### Cluster Design

When zoomed out and pins cluster:
- Circular cluster showing count
- Mini-grid preview of photos (2x2)
- Tap to zoom in and expand

---

## Scrapbook Integration

### Memory Cards on Map

For places with significant memories (milestones achieved here), show as enhanced pins:
- Golden glow or special border
- Memory badge indicator
- Tap reveals the memory card, not just photo

### "Ollie's World" Summary

A summary card at the top of Places view:

```
┌─────────────────────────────────────┐
│ 🌍 Ollie's World                    │
│                                     │
│ 12 places discovered                │
│ 47 walks logged                     │
│ 3.2 km explored                     │
│                                     │
│ [See map] [View memories]           │
└─────────────────────────────────────┘
```

### "On This Day" Places

When opening Places on an anniversary:
- "1 year ago, you first visited the park!"
- Surface historical place memories

---

## Technical Considerations

### Location Data Model

Extend place model to store richer data:

```swift
struct Place: Codable {
    let id: UUID
    var name: String
    var nickname: String?
    var type: PlaceType
    var coordinate: Coordinate
    var isFavorite: Bool

    // New fields
    var visitCount: Int
    var lastVisited: Date?
    var firstVisited: Date?
    var associatedEvents: [String]  // event IDs
    var photos: [String]  // photo IDs
    var notes: String?

    // For contacts
    var phone: String?
    var website: URL?
    var businessHours: String?
}
```

### Photo Location Association

- Store coordinates with photos (from EXIF or manual)
- Query photos by proximity to location
- Handle photos without location data gracefully

### Route Tracking (Future)

If implementing GPS tracking:
- Track route during walks (when walk event is active)
- Store routes as array of coordinates with timestamps
- Privacy controls: user must opt-in
- Data size management: simplify routes for storage

### Map Performance

- Limit pins shown at once (cluster aggressively)
- Lazy load photo thumbnails
- Cache map tiles
- Use MapKit efficiently (avoid re-renders)

---

## Privacy Considerations

### Location Data Sensitivity

- Make clear that location data is stored locally
- If any cloud sync planned, explicit consent required
- Option to disable location features entirely
- Don't require location for app to function

### Photo Geotags

- Respect user's photo location settings
- Allow removing location from photos
- Don't surface location publicly (e.g., in share cards) without consent

---

## Rollout Strategy

### Phase 1: Photo Pins
- Move photos onto map as pins
- Basic tap-to-view functionality
- Clustering for zoom levels

### Phase 2: Place Personality
- Enhanced place detail views
- Visit counting and stats
- Photo association with places

### Phase 3: Contact Integration
- Vet/service places linked to appointments
- Call/navigate quick actions
- Visit history

### Phase 4: Explore Suggestions
- Socialization gap analysis
- Place type suggestions
- Integration with external maps for directions

### Phase 5: Routes (if GPS tracking added)
- Walk route recording
- Route visualization
- Territory/world expansion metrics

---

## Open Questions

1. **GPS tracking scope:** Should the app actively track routes, or rely on manual location logging? Privacy vs. richness tradeoff.

2. **Third-party place data:** Should the app integrate with Google Places / Apple Maps for business info (vet hours, etc.)?

3. **Social features:** Could users share their "Ollie's World" map with others? Privacy implications.

4. **Performance on large datasets:** A year of walks could be hundreds of locations. How to keep map performant?

5. **Offline support:** Places should work without internet. How much to cache?

6. **Multi-dog (future):** If app supports multiple dogs, do places show combined or separate?

---

## Reference Apps

- **Apple Photos:** Map view with photo clusters, tap-to-expand, location-based memories
- **Strava:** Route heatmaps showing activity patterns, segment exploration
- **Swarm/Foursquare:** Check-in history, place personality, visit counts
- **Google Maps Timeline:** Historical location tracking, photo integration
- **AllTrails:** Trail/route discovery, user photos on map pins

---

## Success Criteria

1. Users discover the photo-on-map feature and find it delightful
2. Place detail views provide useful context (visit count, photos, notes)
3. Contact places reduce friction for calling/navigating to vet
4. Explore suggestions are relevant and actionable
5. The map tells a story: users can show others "everywhere Ollie has been"
6. Performance remains smooth even with many places/photos
7. Privacy controls are clear and respected
