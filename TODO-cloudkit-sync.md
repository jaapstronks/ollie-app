# TODO: CloudKit Sync (PRIORITY — do before v2 features)

Replace local-only JSONL storage with CloudKit so multiple devices share the same data. Do this BEFORE building v2 features to avoid refactoring the storage layer later.

## Priority Note
This should be implemented BEFORE TODO-v2.md. The EventStore abstraction is already clean, so this is mostly replacing the backend, not rewriting the app.

## Step 0: Enable CloudKit in Xcode

This must be done manually in Xcode (not via code):

1. Open `Ollie-app.xcodeproj` in Xcode
2. Click on the **Ollie-app** target (blue icon, top of file navigator)
3. Go to the **"Signing & Capabilities"** tab
4. Click **"+ Capability"** (top left of that tab)
5. Search for **"iCloud"** and double-click to add it
6. In the iCloud capability section that appears:
   - Check **"CloudKit"**
   - Under "Containers", click the **"+"** button
   - Add: `iCloud.nl.jaapstronks.Ollie`
7. Xcode will auto-create the container in your Apple Developer account

That's it. Xcode modifies the `.entitlements` file and project settings automatically. Commit those changes.

## Step 1: CloudKit Data Model

Use a single record type `PuppyEvent` in CloudKit:

```
Record Type: PuppyEvent
Fields:
  - eventTime (Date/Time)     — the event timestamp
  - eventType (String)        — "plassen", "eten", etc.
  - location (String?)        — "buiten" / "binnen"
  - note (String?)
  - who (String?)
  - exercise (String?)
  - result (String?)
  - durationMin (Int?)
  - photo (Asset?)            — for future photo support
  - video (Asset?)
  - deviceId (String)         — which device created it (for conflict resolution)
  - localId (String)          — UUID from local creation (for dedup)
```

Use a **CKRecordZone** (custom zone) for the shared data:
- Zone name: `"OllieEvents"`
- This enables atomic commits and change tracking

For sharing between users: use a **CKShare** on the custom zone. This lets Jaap invite Marjolein via iCloud, and both can read/write.

## Step 2: Refactor EventStore

Keep the `EventStore` interface the same but swap the backend:

```swift
@MainActor
final class EventStore {
    static let shared = EventStore()
    
    private let container = CKContainer(identifier: "iCloud.nl.jaapstronks.Ollie")
    private let zoneName = "OllieEvents"
    
    // Keep local cache (JSONL files) as offline fallback
    // CloudKit is source of truth, local is cache
    
    func loadEvents(for date: Date) async -> [PuppyEvent]
    func saveEvent(_ event: PuppyEvent) async throws
    func syncFromCloud() async throws
}
```

**Strategy: local-first with cloud sync**
1. Save locally first (instant, works offline)
2. Push to CloudKit in background
3. Subscribe to CloudKit changes (CKSubscription) for incoming changes from other devices
4. On app launch: pull latest changes from cloud

This way the app always feels fast and works offline.

## Step 3: Sharing Setup

To share data between Jaap and Marjolein:

```swift
// Create a CKShare for the OllieEvents zone
let share = CKShare(recordZoneID: zoneID)
share[CKShare.SystemFieldKey.title] = "Ollie Events"
share.publicPermission = .none  // invite-only

// Use UICloudSharingController to send invite
// Marjolein accepts via iCloud → both see same data
```

Add a "Delen" button in settings that presents the `UICloudSharingController`. Marjolein gets a link, taps it, done.

## Step 4: Change Tracking

Use `CKFetchRecordZoneChangesOperation` to efficiently sync:
- Store a `serverChangeToken` locally
- On each sync, only fetch changes since last token
- This is cheap and fast — no full re-download

Subscribe to push notifications for changes:
```swift
let subscription = CKRecordZoneSubscription(zoneID: zoneID)
subscription.notificationInfo = CKSubscription.NotificationInfo()
subscription.notificationInfo?.shouldSendContentAvailable = true  // silent push
```

This triggers a background sync when Marjolein logs an event → it appears on Jaap's phone within seconds.

## Step 5: Migration

For existing local data (from MVP development):
- On first launch after CloudKit is enabled, upload all local JSONL events to CloudKit
- Use `localId` (UUID) for deduplication — don't create duplicates
- After migration, local files become a cache

## Step 6: JSONL Export (keep compatibility)

Keep the ability to export/import JSONL for web app compatibility:
- "Exporteer data" in settings → generates JSONL files
- "Importeer data" → reads JSONL and pushes to CloudKit
- This maintains the bridge to the web app / GitHub repo

## Architecture Summary

```
┌─────────────┐     ┌─────────────┐
│  Jaap's      │     │  Marjolein's │
│  iPhone      │     │  iPhone      │
│             │     │             │
│  EventStore  │◄───►│  EventStore  │
│  (local cache)│     │  (local cache)│
└──────┬───────┘     └──────┬───────┘
       │                     │
       └──────┬──────────────┘
              │
       ┌──────▼───────┐
       │   CloudKit     │
       │  (shared zone) │
       │  CKShare       │
       └───────────────┘
              │
       ┌──────▼───────┐
       │  Web app       │
       │  (JSONL export) │
       └───────────────┘
```

## Done Criteria
- [ ] CloudKit capability enabled in Xcode
- [ ] Events sync between two devices
- [ ] Sharing works (Jaap invites Marjolein)
- [ ] Offline logging works (syncs when back online)
- [ ] Existing local data migrated to CloudKit
- [ ] App still works without network

Delete this file when done.
