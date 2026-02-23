# TODO: CloudKit Sync

## Status: Code Complete - Manual Xcode Setup Required

The CloudKit integration code has been implemented. You need to complete the Xcode setup manually.

## Manual Steps Required in Xcode

### Step 1: Enable iCloud Capability

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

### Step 2: Add Background Modes Capability (if not auto-added)

1. In **"Signing & Capabilities"** tab, click **"+ Capability"**
2. Add **"Background Modes"**
3. Check:
   - **"Background fetch"**
   - **"Remote notifications"**

### Step 3: Add Entitlements File to Target

1. In Xcode, go to **Build Settings** for the Ollie-app target
2. Search for "Code Signing Entitlements"
3. Set it to: `Ollie-app/Ollie-app.entitlements`

### Step 4: Build and Test

1. Build the app (`Cmd+B`)
2. Run on a real device (CloudKit doesn't work fully in Simulator)
3. Check Console for "CloudKit setup completed successfully"

## What Was Implemented

### Files Created/Modified

- **`Services/CloudKitService.swift`** (NEW)
  - Full CloudKit sync service
  - Zone management (custom zone "OllieEvents")
  - Event save/fetch/delete
  - CKShare support for partner sharing
  - Change tracking with server tokens
  - Offline queue for pending operations
  - Migration of existing local data

- **`Services/EventStore.swift`** (MODIFIED)
  - Integrated with CloudKitService
  - Local-first architecture (save locally, sync to cloud)
  - Merge logic for local + cloud events
  - Auto-sync on app launch and foreground

- **`Views/CloudSharingView.swift`** (NEW)
  - UICloudSharingController wrapper
  - ShareSettingsSection for Settings
  - SyncStatusView component

- **`Views/SettingsView.swift`** (MODIFIED)
  - Added "Delen" (sharing) section
  - Added "Synchronisatie" section with sync status

- **`Ollie_appApp.swift`** (MODIFIED)
  - AppDelegate for remote notifications
  - Foreground sync trigger

- **`Ollie-app.entitlements`** (NEW)
  - CloudKit container entitlement
  - Push notification entitlement

- **`Info.plist`** (MODIFIED)
  - Background modes for remote-notification and fetch

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Jaap's        │     │   Marjolein's   │
│   iPhone        │     │   iPhone        │
│                 │     │                 │
│   EventStore    │◄───►│   EventStore    │
│   (local cache) │     │   (local cache) │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────┬───────────────┘
                 │
          ┌──────▼───────┐
          │   CloudKit   │
          │ Private DB   │
          │   CKShare    │
          └──────────────┘
```

**Key features:**
- **Local-first**: Events save instantly to JSONL, then sync to cloud
- **Offline support**: App works without network, syncs when online
- **Multi-device**: Changes sync across all your devices
- **Partner sharing**: CKShare allows inviting partner via iCloud
- **Real-time updates**: Silent push notifications trigger background sync

## How Sharing Works

1. **Owner** (Jaap) taps "Deel met partner" in Settings
2. System shows share sheet with invite options (Messages, Mail, etc.)
3. **Participant** (Marjolein) receives invite link, taps it
4. Her phone opens Ollie app, CloudKit links her to the shared zone
5. Both can now log events, both see all events

The participant's data is stored in the owner's private database via CKShare. The participant accesses it via their shared database.

## Testing Checklist

- [ ] CloudKit capability enabled in Xcode
- [ ] App builds without errors
- [ ] Events save to CloudKit (check CloudKit Dashboard)
- [ ] Events sync between two devices (same iCloud account)
- [ ] Sharing works (invite partner, they accept)
- [ ] Offline logging works (airplane mode, then back online)
- [ ] Existing local data migrated to CloudKit
- [ ] App still works without network

## CloudKit Dashboard

To inspect your CloudKit data:
1. Go to https://icloud.developer.apple.com/
2. Sign in with your Apple Developer account
3. Select "CloudKit Database"
4. Choose container: `iCloud.nl.jaapstronks.Ollie`
5. Browse "Private Database" > "OllieEvents" zone

Delete this file when setup is complete and tested.
