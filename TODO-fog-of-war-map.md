# Fog of War Map — Puppy's World Exploration

## Overview

A "fog of war" style map overlay that reveals areas only where the dog has walked. Unexplored areas remain masked (dark, blurred, or stylized), creating a visual metaphor for the puppy's expanding world.

**Core Concept:** Puppies should start with a small, safe world. As they grow and explore more, their world expands. The map visualization reflects this journey.

---

## User Stories

### Puppy Phase (0-6 months)
> "Keep her world small and contained"

- New puppy owners see a mostly masked map with only their immediate neighborhood revealed
- Visual reinforcement that limiting exposure is good for young puppies
- Small explored area feels intentional, not empty

### Adolescent Phase (6-12 months)
> "Time to explore more"

- Map shows growing revealed areas as walks extend further
- Encouraging milestone: "Luna has explored 2 km² of the world!"
- Gamification: "Discover new areas" nudge when walks become repetitive

### Adult Phase (12+ months)
> "Look how far you've come"

- Full exploration map showing everywhere the dog has been
- Nostalgia feature: animate the map revealing over time
- Share-worthy: export exploration map as image

---

## Technical Implementation

### Option A: Canvas Overlay (Recommended)

Use SwiftUI Canvas with a mask to reveal explored areas.

```swift
struct FogOfWarOverlay: View {
    let exploredRegions: [ExploredRegion]  // Polygons of explored areas
    let mapRect: MKMapRect

    var body: some View {
        Canvas { context, size in
            // Fill entire canvas with fog
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.black.opacity(0.7))
            )

            // Cut out explored areas using blendMode
            context.blendMode = .destinationOut
            for region in exploredRegions {
                let path = region.path(in: size, mapRect: mapRect)
                context.fill(path, with: .color(.white))
            }
        }
        .allowsHitTesting(false)
    }
}
```

**Pros:**
- Pure SwiftUI, works with Map view
- Smooth animations possible
- Easy to style (blur, gradient edges)

**Cons:**
- Performance at scale (many regions)
- Needs coordinate → screen conversion

### Option B: MKTileOverlay

Custom tile provider that renders fog for unexplored tiles.

```swift
class FogTileOverlay: MKTileOverlay {
    let explorationStore: ExplorationStore

    override func loadTile(at path: MKTileOverlayPath,
                           result: @escaping (Data?, Error?) -> Void) {
        let tileRect = rect(for: path)

        if explorationStore.isExplored(tileRect) {
            // Return transparent tile
            result(transparentTileData, nil)
        } else {
            // Return fog tile (dark/blurred)
            result(fogTileData, nil)
        }
    }
}
```

**Pros:**
- MapKit native, efficient at any zoom level
- Cached tiles = good performance

**Cons:**
- Blocky appearance (tile boundaries visible)
- More complex implementation
- Less control over visual style

### Option C: Blur + Mask (Premium Feel)

Dual-layer map with blur overlay.

```swift
ZStack {
    // Base map (blurred, desaturated)
    Map(...)
        .blur(radius: 8)
        .saturation(0.3)

    // Revealed map (clipped to explored shape)
    Map(...)
        .mask {
            ExploredAreasMask(regions: exploredRegions)
        }
}
```

**Pros:**
- Beautiful visual effect
- Real map visible through fog (teaser)

**Cons:**
- Renders map twice (performance)
- Complex state sync between maps

---

## Data Model

### ExplorationStore

Stores accumulated GPS coverage from all walks.

```swift
@Observable
@MainActor
class ExplorationStore {
    /// Grid-based exploration tracking (efficient for large areas)
    /// Key: "zoom_x_y" tile identifier
    private(set) var exploredTiles: Set<String> = []

    /// Detailed route paths for high-zoom rendering
    private(set) var routePolylines: [RoutePolyline] = []

    /// Total explored area in square meters
    var exploredAreaM2: Double { ... }

    /// Add a completed walk's route to exploration data
    func addWalkRoute(_ route: WalkRoute) {
        // 1. Add route polyline for detailed view
        routePolylines.append(RoutePolyline(from: route))

        // 2. Mark grid tiles as explored
        for coordinate in route.coordinates {
            let tile = tileKey(for: coordinate, zoom: explorationZoom)
            exploredTiles.insert(tile)
        }

        // 3. Persist to Core Data
        saveExplorationData()
    }

    /// Check if a map region has been explored
    func isExplored(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let tile = tileKey(for: coordinate, zoom: explorationZoom)
        return exploredTiles.contains(tile)
    }

    /// Generate exploration polygon for rendering
    func explorationPolygon() -> MKPolygon? {
        // Compute convex hull or alpha shape of explored tiles
    }
}
```

### Core Data Entity

```
ExploredTile
├── tileKey: String (primary key, e.g., "14_8392_5765")
├── firstExploredAt: Date
├── walkCount: Int16
└── profile: PuppyProfile (relationship)
```

### Route Buffering

Routes need "thickness" — a 20m walk corridor, not just a line.

```swift
extension WalkRoute {
    /// Create a polygon buffer around the route
    func bufferedPolygon(radiusMeters: Double = 25) -> MKPolygon {
        // Use MapKit's geodesic calculations
        // Create parallel offset lines and cap ends
    }
}
```

---

## UI Integration

### WalkMapView (Live Walk)

During active walk, fog lifts in real-time as dog walks.

```swift
struct WalkMapView: View {
    @Environment(ExplorationStore.self) var explorationStore
    @State private var revealedPath: [CLLocationCoordinate2D] = []

    var body: some View {
        ZStack {
            Map(...) {
                // Walk route polyline
                MapPolyline(coordinates: trackingService.routeCoordinates)
                    .stroke(.blue, lineWidth: 4)
            }

            // Fog overlay with real-time reveal
            FogOfWarOverlay(
                exploredRegions: explorationStore.regions,
                currentPath: revealedPath,
                revealRadius: 30  // meters
            )
        }
        .onChange(of: trackingService.currentLocation) { _, newLocation in
            revealedPath.append(newLocation.coordinate)
        }
    }
}
```

### PlacesTabView (Explore Tab)

Full exploration map with historical data.

```swift
struct ExplorationMapView: View {
    @Environment(ExplorationStore.self) var explorationStore

    var body: some View {
        ZStack {
            Map(...)

            FogOfWarOverlay(exploredRegions: explorationStore.allRegions)

            // Stats overlay
            VStack {
                Spacer()
                ExplorationStatsBar(
                    areaExplored: explorationStore.exploredAreaM2,
                    totalWalks: explorationStore.walkCount
                )
            }
        }
    }
}
```

### PuppysWorldSummaryCard Enhancement

Add exploration map preview to existing card.

```swift
// In PuppysWorldSummaryCard
HStack {
    // Existing stats
    VStack { ... }

    // Mini exploration map preview
    MiniExplorationMap(regions: explorationStore.regions)
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
```

---

## Visual Design

### Fog Styles

| Style | Description | When to Use |
|-------|-------------|-------------|
| **Dark Fog** | Black at 70% opacity | Default, works light/dark mode |
| **Blur Fog** | Gaussian blur + desaturation | Premium feel, heavier render |
| **Paper Fog** | Parchment texture, old map style | Playful/vintage option |
| **Cloud Fog** | Animated cloud wisps | Whimsical, puppy-friendly |

### Reveal Animation

When new area is explored:
1. Fog fades out radially from dog's position
2. Subtle "sparkle" or "clearing" particle effect
3. Optional haptic feedback on first-time areas

### Edge Treatment

Explored area edges should be soft, not hard-cut:
- Feathered gradient at boundary (20-50m fade)
- Organic, slightly irregular edges (not geometric)

---

## Milestones & Gamification

### Exploration Achievements

| Milestone | Trigger | Message |
|-----------|---------|---------|
| First Steps | 100m explored | "[Name] took their first steps into the world!" |
| Neighborhood | 1 km² | "[Name] knows the neighborhood!" |
| Explorer | 5 km² | "[Name] is becoming an explorer!" |
| Adventurer | 25 km² | "[Name] has seen so much!" |

### Weekly Nudges

```swift
// If no new exploration in 7 days
"[Name] hasn't discovered anywhere new this week. Time for an adventure?"

// If walk patterns are repetitive
"You've walked the same route 5 times. Want to try somewhere new?"
```

---

## Performance Considerations

1. **Tile caching** — Pre-render fog tiles, cache aggressively
2. **Level of detail** — Coarse grid at low zoom, detailed at high zoom
3. **Lazy loading** — Only load exploration data for visible region
4. **Background processing** — Compute exploration polygons off main thread

### Memory Budget

- Grid tiles: ~50KB for typical urban exploration
- Route polylines: ~10KB per walk (compressed)
- Target: <5MB total for exploration data

---

## Implementation Phases

### Phase 1: Data Foundation
- [ ] Create `ExplorationStore` with grid-based tracking
- [ ] Add `ExploredTile` Core Data entity
- [ ] Migrate existing `WalkRoute` data to exploration tiles
- [ ] Add exploration data to CloudKit sync

### Phase 2: Basic Overlay
- [ ] Implement `FogOfWarOverlay` with Canvas approach
- [ ] Integrate into `WalkMapView` (live walk)
- [ ] Add toggle to enable/disable fog effect
- [ ] Test performance with 100+ walks

### Phase 3: Polish & Animation
- [ ] Add soft edge treatment to fog boundaries
- [ ] Implement real-time reveal animation during walks
- [ ] Add "first exploration" haptic/visual feedback
- [ ] Create mini-map preview for `PuppysWorldSummaryCard`

### Phase 4: Gamification
- [ ] Implement exploration milestones
- [ ] Add "New Area!" badge on timeline events
- [ ] Create shareable exploration map export
- [ ] Add exploration stats to Stats tab

---

## Open Questions

1. **Sharing** — Should fog of war persist in shared household? Or each family member reveals independently?

2. **Historical imports** — If user imports old walks, do those reveal the map? (Probably yes)

3. **Reset option** — Should users be able to "reset" their exploration? (Adventure mode?)

4. **Offline** — How does fog render when offline? (Cache tiles, show last-known state)

---

## References

- **Fog of World** app — iOS app for personal exploration tracking
- **Strava Heatmaps** — Aggregated route visualization
- **Game fog of war** — Real-time revelation in strategy games
- **MKTileOverlay** — Apple docs for custom map tiles
