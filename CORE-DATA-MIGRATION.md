# Core Data + NSPersistentCloudKitContainer Migration

**Date:** February 2026
**Branch:** `feature/v1-briefings-fresh`

---

## The Plan

Replace the manual CloudKit sync implementation (raw CKRecord APIs + JSONL files) with Apple's `NSPersistentCloudKitContainer`, which automatically handles sync and sharing.

### Problem Statement

- **Local storage:** JSONL files (`data/YYYY-MM-DD.jsonl`), JSON files for profile/spots
- **CloudKit:** Manual sync using CKRecord, CKShare, CKDatabase APIs
- **Sharing:** Broken (participant stuck on "invited", partial sync)

### Target Architecture

- **Local storage:** Core Data (SQLite) with automatic CloudKit sync
- **Sharing:** Two-store architecture (private + shared) per Apple's recommended pattern

```
┌─────────────────────────────────────────────────────┐
│  NSPersistentCloudKitContainer                      │
│  Container: iCloud.nl.jaapstronks.Ollie             │
│                                                     │
│  ┌─────────────────┐    ┌─────────────────┐        │
│  │ Private Store   │    │ Shared Store    │        │
│  │ Ollie.sqlite    │    │ Ollie-shared.sqlite │    │
│  │ scope: .private │    │ scope: .shared  │        │
│  └─────────────────┘    └─────────────────┘        │
└─────────────────────────────────────────────────────┘
```

---

## What Was Accomplished

### Phase 1: Core Data Model ✅

Created `Ollie.xcdatamodeld` with 6 entities:

| Entity | Purpose |
|--------|---------|
| `CDPuppyProfile` | Puppy info, configs (meal schedule, exercise, etc.) |
| `CDPuppyEvent` | All logged events (potty, meals, walks, training, etc.) |
| `CDWalkSpot` | Saved walk locations |
| `CDMasteredSkill` | Training progress tracking |
| `CDMedicationCompletion` | Medication completion records |
| `CDExposure` | Socialization exposures |

All entities configured for CloudKit compatibility with optional attributes.

### Phase 2: Persistence Controller ✅

Created `PersistenceController.swift` with:
- Two-store configuration (private + shared SQLite databases)
- App Group container for data sharing with widgets/watch
- Persistent history tracking for remote change notifications
- Sharing support via `share()` and `acceptShareInvitation()` methods

### Phase 3: Data Migration ✅

Created `CoreDataMigrationCoordinator.swift`:
- One-time migration from JSONL/JSON files to Core Data
- Migrates: profile, events, spots, mastered skills, medication completions, exposures
- Archives old files to `data-archive/` after successful migration
- Uses UserDefaults flag to prevent re-migration

### Phase 4: Service Layer Updates ✅

| File | Changes |
|------|---------|
| `CoreDataEventStore.swift` | New file - replaces LocalEventFileStore with same public API |
| `EventStore.swift` | Uses CoreDataEventStore, removed manual sync |
| `ProfileStore.swift` | Uses Core Data via CDPuppyProfile |
| `SpotStore.swift` | Uses Core Data via CDWalkSpot |
| `SocializationStore.swift` | Uses Core Data via CDExposure |
| `TrainingPlanStore.swift` | Uses Core Data via CDMasteredSkill |
| `MedicationStore.swift` | Uses Core Data via CDMedicationCompletion |
| `WatchSyncService.swift` | Updated to use CoreDataEventStore |

### Phase 5: CloudKit Simplification ✅

| File | Changes |
|------|---------|
| `CloudKitService.swift` | Stripped to: sharing coordination, media uploads, participant detection |
| `CloudKitShareManager.swift` | Updated for Core Data sharing APIs |

### Phase 6: Cleanup ✅

**Deleted 10 obsolete files:**
- `EventSyncCoordinator.swift`
- `EventCache.swift`
- `LocalEventFileStore.swift`
- `CloudKitRecordConverter.swift`
- `CloudKitZoneManager.swift`
- `ExposureCloudService.swift`
- `WalkSpotCloudService.swift`
- `ProfileCloudService.swift`
- `MedicationCompletionCloudService.swift`
- `MasteredSkillsCloudService.swift`

### Phase 7: App Integration ✅

Updated `Ollie_appApp.swift`:
- Added `PersistenceController.shared` reference
- Injected Core Data context via `.environment(\.managedObjectContext, ...)`
- Migration runs on first launch via `.task { }`
- Updated remote notification handler for automatic sync

---

## Files Created

```
Ollie-app/
├── Ollie.xcdatamodeld/
│   └── Ollie.xcdatamodel/contents          # Core Data model XML
├── Services/
│   ├── PersistenceController.swift         # Two-store container
│   ├── CoreDataMigrationCoordinator.swift  # JSONL→Core Data migration
│   └── CoreDataEventStore.swift            # Replaces LocalEventFileStore
└── Models/CoreData/
    ├── CDPuppyProfile+Extensions.swift
    ├── CDPuppyEvent+Extensions.swift
    ├── CDWalkSpot+Extensions.swift
    ├── CDMasteredSkill+Extensions.swift
    ├── CDMedicationCompletion+Extensions.swift
    └── CDExposure+Extensions.swift
```

---

## Next Actions

### 1. Complete Sharing UI Integration

The sharing section in Settings has temporary stubs. To fully enable:

```swift
// In SettingsView or a new SharingCoordinator:

// Create share
let profile = CDPuppyProfile.fetchProfile(in: context)!
let share = try await PersistenceController.shared.share([profile], to: nil)

// Stop sharing
try await PersistenceController.shared.container.purgeObjectsAndRecordsInZone(
    with: share.recordID.zoneID,
    in: privateStore
)
```

**Files to update:**
- `SettingsView.swift` - Pass `PersistenceController` and wire up sharing actions
- Create `SharingCoordinator` to encapsulate sharing logic with Core Data

### 2. Test Migration Path

1. Install current App Store version (with JSONL data)
2. Log some events
3. Install this build
4. Verify:
   - All events migrated correctly
   - Profile data intact
   - Old files archived to `data-archive/`
   - No duplicate events

### 3. Test Multi-Device Sync

1. Log event on Device A
2. Verify appears on Device B within ~30 seconds
3. Test offline: airplane mode → log events → reconnect → verify sync

### 4. Test Sharing Flow

1. Owner creates share in Settings
2. Owner sends link to Partner
3. Partner taps link, accepts
4. Partner status shows "Accepted" (not "Invited")
5. Partner sees all shared data
6. Partner logs event → appears on Owner's device

### 5. Performance Testing

- Test with 1000+ events
- Monitor memory during migration
- Check Core Data fetch performance vs. JSONL reads

### 6. Widget/Watch Verification

Ensure widgets and Apple Watch still receive data:
- `WatchSyncService` updated to use `CoreDataEventStore`
- Widget data flows through existing mechanisms
- App Group container accessible to all targets

---

## Architecture Notes

### Why Two Stores?

Apple's recommended pattern for CloudKit sharing:
- **Private store:** Owner's data, syncs to private CloudKit database
- **Shared store:** Participant's view of shared data, syncs to shared CloudKit database

When owner creates a share, data moves from private→shared zone. Participants only see the shared store.

### Why Optional Attributes?

CloudKit requires all non-optional Core Data attributes to have default values. Making date/UUID fields optional avoids this constraint while we set values in code.

### Migration Safety

- Migration only runs once (UserDefaults flag)
- Old files archived, not deleted
- Rollback possible by clearing UserDefaults key and restoring archive

---

## Verification Checklist

- [x] Build succeeds
- [ ] Fresh install works (empty Core Data, no migration)
- [ ] Upgrade from JSONL version migrates correctly
- [ ] Events sync between devices
- [ ] Share creation works
- [ ] Share acceptance works
- [ ] Participant sees shared data
- [ ] Widgets display correct data
- [ ] Watch receives sync updates
- [ ] Performance acceptable with large datasets
