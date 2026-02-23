# Walk Locations & Favorite Spots

*Feature briefing for location-aware walk logging*

## Problem Statement

Multiple family members co-manage a puppy using individual app instances synced via CloudKit. When someone takes the pup for a walk, others want to know:
- **Where did they go?** (especially useful for puppies still learning the neighborhood)
- **Was it a good spot?** (share discoveries with the family)
- **What did they see/do there?** (photo context)

For young puppies, walks are short (few hundred meters in the immediate neighborhood). Full GPS route tracking is overkill. The core value is **pinning a spot + attaching a photo** to communicate: *"I went here, this was nice."*

## User Stories

### MVP (Phase 1)
1. As a family member, I want to **pin my current location** when logging a walk, so others know where I went.
2. As a family member, I want to **attach a photo** to the location, so others can see what the spot looks like.
3. As a family member, I want to **name a spot** (e.g., "Park achter school", "Rondje blok"), so we build a shared vocabulary.
4. As a family member, I want to **see walk locations on a map** in the event detail, so I can visualize where walks happen.
5. As a family member, I want to **mark spots as favorites**, so we remember good places.

### Phase 2
6. As a user, I want to **pick from previously visited spots** when logging a walk, so I don't have to re-enter the same location.
7. As a user, I want to **see a map of all favorite spots**, so I can browse walk options.
8. As a user, I want to **add notes to spots** (not just events), like "quiet in mornings" or "busy after 5pm".

### Phase 3 (Route Tracking)
9. As a user, I want to **track my walk route** while walking, so I can see the path we took.
10. As a user, I want to **see walk distance and duration**, calculated from the route.

### Phase 4 (Safety Intelligence)
11. As a user, I want **spot safety suggestions** based on my puppy's vaccination status (avoid high-dog-traffic areas before vaccinations complete).
12. As a user, I want to **tag spot types** (dog park, quiet street, playground, fields) for filtering.
13. As a user, I want to **see which spots are vet-recommended** for unvaccinated puppies.

---

## MVP Implementation Plan

### Data Model

#### WalkSpot (new model)
```swift
struct WalkSpot: Codable, Identifiable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var isFavorite: Bool
    var notes: String?
    var photoPath: String?  // Reference photo for the spot

    // Optional metadata
    var category: SpotCategory?
    var visitCount: Int  // Incremented when used in events
}

enum SpotCategory: String, Codable, CaseIterable {
    case park
    case street
    case playground
    case field
    case dogPark
    case other
}
```

#### PuppyEvent changes
The model already has `latitude` and `longitude`. Add:
```swift
var spotId: UUID?  // Reference to a WalkSpot (optional)
var spotName: String?  // Denormalized for quick display
```

### Storage

- **spots.json** — Array of WalkSpot objects in documents directory
- Synced via CloudKit alongside events and profile
- SpotStore service similar to EventStore

### New Files

```
Models/
  WalkSpot.swift              # Spot data model

Services/
  SpotStore.swift             # CRUD for spots
  LocationManager.swift       # CLLocationManager wrapper (may already exist for weather)

Views/
  Walk/
    SpotMapView.swift         # MapKit view showing spot
    SpotPickerSheet.swift     # Sheet to pick existing spot or create new
    SpotDetailView.swift      # View/edit a single spot
    FavoriteSpotsView.swift   # Map + list of all favorite spots

Components/
  SpotPinAnnotation.swift     # Custom map annotation for spots
  SpotRowView.swift           # List row for spot selection
```

### UI Flow

#### Logging a Walk with Location

1. User taps "Walk" in quick-log bar
2. `LogEventSheet` opens for `.uitlaten` event
3. **New section: "Locatie"**
   - "Huidige locatie gebruiken" button (requests location permission if needed)
   - OR "Kies een plek" button → opens SpotPickerSheet
4. If current location chosen:
   - Show mini-map preview with pin
   - "Naam deze plek" text field (optional, for creating a new spot)
   - "Voeg foto toe" button (existing photo attachment flow)
5. If existing spot chosen:
   - Show spot name + mini-map
   - Can still add event-specific photo
6. Save event with location data

#### SpotPickerSheet

```
┌─────────────────────────────────────┐
│  Kies een plek                   ✕  │
├─────────────────────────────────────┤
│  🗺️ [Map showing nearby spots]      │
│                                     │
│  ─── Favorieten ───                 │
│  ⭐ Park achter school              │
│  ⭐ Rondje blok                      │
│                                     │
│  ─── Recent ───                     │
│  📍 Speeltuin Marktstraat           │
│  📍 Grasveld bij station            │
│                                     │
│  ─── Of ───                         │
│  [+ Nieuwe plek op huidige locatie] │
└─────────────────────────────────────┘
```

#### Viewing Walk Location (Event Detail)

When viewing a walk event with location:
- Show map snippet with pin
- Tap map → full-screen map view
- If spot is linked, show spot name and favorite star
- Photo(s) displayed below map

#### Favorite Spots Screen

Access from Settings or a new "Plekken" tab:
```
┌─────────────────────────────────────┐
│  Favoriete plekken            Edit  │
├─────────────────────────────────────┤
│  🗺️ [Map with all favorite pins]    │
│                                     │
│  ⭐ Park achter school    →         │
│     12 bezoeken · 450m              │
│                                     │
│  ⭐ Rondje blok           →         │
│     8 bezoeken · 200m               │
│                                     │
│  ⭐ Speeltuin Markt       →         │
│     5 bezoeken · 600m               │
└─────────────────────────────────────┘
```

### Permission Handling

Location permission flow:
1. Request "When In Use" for MVP (not "Always")
2. Show clear explanation: "Ollie uses location to save where you walked"
3. Handle denied state gracefully (allow manual map tap to place pin)

Already declared in `PrivacyInfo.xcprivacy` for weather functionality.

### Integration with Existing Features

- **Photo attachment** — Already in progress, integrate with spot photos
- **CloudKit sync** — Spots sync alongside events for family sharing
- **Weather** — Show weather at spot location for that walk
- **Timeline** — Show spot name in walk event row if available

---

## Phase 2: Enhanced Spot Management

### Quick-select Recent Spots
- Show last 3 spots as quick buttons in LogEventSheet
- One tap to reuse same location

### Spot Notes
- Add persistent notes to spots (separate from event notes)
- "Goed voor snuffeltraining"
- "Veel honden na 17:00"

### Spot Photos Gallery
- Multiple photos per spot (collected from events)
- Seasonal variation view

### Map Improvements
- Custom pin icons per category
- Cluster nearby spots
- Distance from current location

---

## Phase 3: Route Tracking

### Architecture
```swift
struct WalkRoute: Codable {
    var coordinates: [CLLocationCoordinate2D]
    var timestamps: [Date]
    var distanceMeters: Double
    var durationSeconds: Int
}
```

### Implementation
- Start tracking when walk event logged
- Use background location updates (battery consideration!)
- Draw polyline on map
- Auto-stop after 2 hours or manual end

### Live Activity Integration
- Show route progress in Dynamic Island
- Distance counter, duration timer

---

## Phase 4: Safety Intelligence

### Vaccination-Aware Recommendations

Based on `PuppyProfile.birthDate`, calculate vaccination milestones:
- 6-8 weeks: First vaccination
- 10-12 weeks: Second vaccination
- 14-16 weeks: Third vaccination (fully protected ~2 weeks after)

Until fully vaccinated, warn about:
- Dog parks (high traffic)
- Areas with standing water
- Heavy sniffing zones (where many dogs urinate)

### Safe Spot Tags
```swift
enum SpotSafetyTag: String, Codable {
    case lowDogTraffic      // Good for unvaccinated
    case highDogTraffic     // Avoid pre-vaccination
    case pavedOnly          // Safer than grass
    case offLeashAllowed
    case leashRequired
}
```

### UI
- Warning banner when picking unsafe spot for unvaccinated pup
- Filter spots by safety tags
- "Safe for [puppy name]" indicator on spots

### Future: Community Spots
- Share anonymized spot data with other Ollie users
- Crowdsourced safety ratings
- "Popular with puppies" indicators

---

## Technical Considerations

### Battery Impact
- "When In Use" location is fine for single-point capture
- Route tracking needs "Always" with background updates → significant battery drain
- Show battery warning before enabling route tracking
- Auto-pause tracking if app in background > 30 minutes

### Privacy
- Location data stays local by default
- CloudKit sharing only within family group
- No analytics on location data
- Clear data retention in privacy policy

### Offline Support
- Cache map tiles for frequently visited areas
- Queue location saves when offline
- Sync spots when connection restored

### Map Framework
- Use MapKit (native, no dependencies)
- Consider MapKit for SwiftUI (`Map` view, iOS 17+)
- Alternatively, older `UIViewRepresentable` wrapper for more control

---

## Effort Estimates

| Phase | Effort | Dependencies |
|-------|--------|--------------|
| MVP (spots + map) | Medium-High | Photo attachment, LocationManager |
| Phase 2 (enhanced spots) | Medium | MVP complete |
| Phase 3 (route tracking) | High | Live Activities |
| Phase 4 (safety) | Medium | Vaccination tracking in profile |

---

## Open Questions

1. **Should spots be shared with all family members by default?**
   - Probably yes, via existing CloudKit sharing

2. **How to handle conflicting spot names from different family members?**
   - First-come-first-served, anyone can edit?
   - Show who created the spot?

3. **Should we integrate with Apple Maps "Guides" feature?**
   - Could export favorite spots as a shareable guide
   - Nice-to-have for Phase 3+

4. **What about indoor "spots" like friends' houses or puppy class?**
   - Same model works, just different category
   - Useful for socialisation tracking

---

## Success Metrics

- % of walk events with location attached
- Number of favorite spots per user
- Spot reuse rate (same spot selected vs new location)
- Family members viewing each other's walk locations

---

## Related Files to Modify

- `PuppyEvent.swift` — Add spotId, spotName fields
- `LogEventSheet.swift` — Add location section for walks
- `EventRow.swift` — Show spot name in walk events
- `EventDetailView.swift` — Show map for events with location
- `SettingsView.swift` — Add "Favoriete plekken" link
- `CloudKitSyncService.swift` — Sync spots alongside events

---

## References

- Roadmap Phase 6: Maps & Location (ROADMAP.md:398-430)
- Existing location fields in PuppyEvent (latitude, longitude)
- Privacy manifest already declares location for weather
- CloudKit sync in progress for family sharing
