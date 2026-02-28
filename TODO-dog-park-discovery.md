# Dog Park Discovery Feature

Pre-populate the Explore/Places map with dog parks from open data sources.

## Domain Model

**DiscoveredSpot** - External dog parks from APIs (read-only, not user-created)
- Separate from user-saved `WalkSpot`
- Can be "saved" by user → converts to `WalkSpot`
- Has source attribution (OSM, government data, etc.)

## Implementation Phases

### Phase 1: OpenStreetMap + Dutch Government Data ✅ IN PROGRESS

**Goal:** Fetch dog parks from Overpass API and Dutch open data portals

#### 1.1 Create DiscoveredSpot Model ✅ DONE
- [x] New model in OllieShared: `DiscoveredSpot`
- [x] Properties: id, name, latitude, longitude, source, sourceId, category, address, amenities
- [x] Source enum: `.openStreetMap`, `.governmentNL`, `.governmentDE`, etc.
- [x] Localized category labels in `Strings.PlacesDiscovery`

#### 1.2 Create DogParkDiscoveryService ✅ DONE
- [x] Overpass API integration for `leisure=dog_park` queries
- [x] Query by radius (around point) and bounding box (map region)
- [x] Cache results (24h validity, grid-based cache keys)
- [x] Parse OSM response (JSON)
- [x] Extract amenities: waste bins, benches, water, lighting
- [x] Extract metadata: fenced, surface type

#### 1.3 Dutch Government Data Integration ✅ DONE
- [ ] Rotterdam: `kaartlaag.rotterdam.nl/hondenuitlaatzones` (skipped - no public GeoJSON API found)
- [x] Eindhoven: `data.eindhoven.nl/api/explore/v2.1/catalog/datasets/hondenlosloopterreinen/records`
- [x] Amsterdam: `maps.amsterdam.nl/open_geodata/geojson_lnglat.php?KAARTLAAG=HONDEN&THEMA=honden`
- [ ] National: `data.overheid.nl` datasets (future - aggregates city data)

**Implementation notes:**
- Auto-detects user location and fetches from relevant city API
- Bounding boxes defined for Eindhoven (51.35-51.52°N, 5.35-5.60°E) and Amsterdam (52.28-52.43°N, 4.73-5.07°E)
- Deduplication removes spots within 50m, preferring government data over OSM
- Eindhoven API returns street names, neighborhood info, surface types
- Amsterdam GeoJSON has polygon geometries, centroids calculated for pin placement

#### 1.4 UI Integration ✅ DONE
- [x] Show discovered spots as different pin style on map (blue ring + dog icon)
- [x] "Dog Parks" filter chip in filter bar
- [x] `DiscoveredSpotMapMarker` with fenced indicator badge
- [x] `DiscoveredSpotDetailSheet` with full details
- [x] "Save to My Spots" action converts to WalkSpot
- [x] "Open in Maps" action
- [x] Attribution footer per source
- [x] Auto-discovery on map appear (5km radius around user)

### Phase 2: Regional Expansion (Future)

**Goal:** Add more government data sources

#### 2.1 Germany
- [ ] Berlin: `gdi.berlin.de` Hundefreilaufflächen
- [ ] GovData.de national search

#### 2.2 United States
- [ ] NYC Open Data: `data.cityofnewyork.us` dog runs
- [ ] Seattle: `data.seattle.gov` off-leash parks
- [ ] Data.gov aggregated search

#### 2.3 Australia
- [ ] Brisbane: `data.brisbane.qld.gov.au` dog off-leash areas
- [ ] ACT: `data.act.gov.au` dog parks
- [ ] data.gov.au national search

#### 2.4 United Kingdom
- [ ] Individual council portals
- [ ] data.gov.uk search

### Phase 3: Commercial Enrichment (Future)

**Goal:** Add ratings, reviews, photos from commercial APIs

- [ ] Foursquare Places API (if dog_park category exists)
- [ ] Google Places API (for ratings/reviews)
- [ ] Geoapify (dog-friendly filtering)

---

## Technical Details

### Overpass API Query

```
[out:json][timeout:25];
(
  nwr["leisure"="dog_park"]({{bbox}});
);
out center tags;
```

Where `{{bbox}}` is `south,west,north,east` (lat,lon format).

Example for Rotterdam area:
```
[out:json][timeout:25];
(
  nwr["leisure"="dog_park"](51.85,4.35,51.98,4.55);
);
out center tags;
```

### Response Format (OSM)

```json
{
  "elements": [
    {
      "type": "way",
      "id": 123456789,
      "center": { "lat": 51.92, "lon": 4.48 },
      "tags": {
        "leisure": "dog_park",
        "name": "Hondenuitlaatplaats Kralingse Bos",
        "surface": "grass",
        "fence": "yes"
      }
    }
  ]
}
```

### Caching Strategy

- Cache by bounding box (rounded to 0.1 degree grid)
- 24-hour cache validity
- Store in UserDefaults or file cache
- Invalidate on significant location change

### Attribution Requirements

- OSM: "© OpenStreetMap contributors" (required)
- Government data: Source attribution per dataset license

---

## Files to Create/Modify

### New Files ✅ CREATED
- `OllieShared/Sources/OllieShared/Models/DiscoveredSpot.swift` ✅
- `Ollie-app/Services/DogParkDiscoveryService.swift` ✅

### Modified Files ✅ UPDATED
- `OllieShared/Sources/OllieShared/Utils/Strings.swift` - added `PlacesDiscovery` enum ✅
- `Ollie-app/Utils/Strings/Strings+Places.swift` - added discovery strings ✅

### Pending Files → DONE
- `Ollie-app/Views/Places/PlacesTabView.swift` - (no changes needed, uses ExpandedPlacesMapView)
- `Ollie-app/ViewModels/PlacesMapViewModel.swift` - integrated discovery service ✅
- `Ollie-app/Views/Places/PlacesFilterBar.swift` - added `.discovered` filter ✅
- `Ollie-app/Views/Places/PlacesMapComponents.swift` - added `DiscoveredSpotMapMarker` ✅
- `Ollie-app/Views/Places/ExpandedPlacesMapView.swift` - render discovered spots ✅
- `Ollie-app/Views/Places/DiscoveredSpotDetailSheet.swift` - NEW ✅

---

## Data Sources Reference

### Global (Primary)
| Source | Coverage | API | Format |
|--------|----------|-----|--------|
| OpenStreetMap Overpass | Worldwide | Yes | JSON |

### Netherlands
| Source | Coverage | API | Format |
|--------|----------|-----|--------|
| Rotterdam Kaartlaag | Rotterdam | TBD | WMS? |
| Eindhoven Open Data | Eindhoven | Yes | GeoJSON |
| Amsterdam Maps | Amsterdam | TBD | ? |
| data.overheid.nl | National | Yes | Various |

### Germany
| Source | Coverage | API | Format |
|--------|----------|-----|--------|
| Berlin GDI | Berlin | Yes | GeoData |
| GovData.de | National | Yes | Various |

### United States
| Source | Coverage | API | Format |
|--------|----------|-----|--------|
| NYC Open Data | NYC | Yes | JSON/CSV |
| Seattle Open Data | Seattle | Yes | Various |
| Data.gov | National | Yes | Various |

### Australia
| Source | Coverage | API | Format |
|--------|----------|-----|--------|
| Brisbane Open Data | Brisbane | Yes | GeoJSON |
| ACT Data | Canberra | Yes | GeoJSON |
| data.gov.au | National | Yes | Various |
