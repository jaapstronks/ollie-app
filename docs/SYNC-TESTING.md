# CloudKit Sync Testing Guide

This guide explains how to test and debug CloudKit synchronization in Ollie. The testing infrastructure provides structured logging, predictable test data, and streamlined workflows to replace the old manual copy-paste process.

## Quick Start

### 1. Open Terminal and Start Log Capture

```bash
cd ~/Github\ NW/Ollie-app
./scripts/sync-test.sh -t
```

This streams only test record logs (records with `AA000000` prefix) to your terminal and saves them to `~/Desktop/OllieSyncLogs/`.

### 2. Run the App in Simulator

Build and run Ollie in Xcode using the iOS Simulator. Make sure you're signed into iCloud in the Simulator (Settings > Apple ID).

### 3. Create Test Data

1. Open the app
2. Go to **Settings > Developer Tools** (scroll to bottom)
3. Find the **Sync Testing** section
4. Tap **Create Test Data**

This creates:
- A profile named "TestDog-Sync"
- 8 test events (pee, poop, meal, nap, walk, training, moment, weight)
- A weight measurement

All with predictable IDs starting with `AA000000`.

### 4. Trigger Sync

Tap **Force Full Sync** in the Sync Testing section, or pull-to-refresh on the Timeline.

### 5. Watch the Logs

In your terminal, you'll see structured logs like:

```
[QUEUE]  [PRIV] [AA000000] Queued for save
[SEND]   [PRIV] [AA000000] Preparing for upload
[SENT]   [PRIV] [AA000000] Confirmed CD_CDPuppyProfile
[SENT]   [PRIV] [AA000000] Confirmed CD_CDPuppyEvent
```

### 6. Clean Up

Tap **Delete Test Data** to remove the test profile and events locally. They'll be deleted from CloudKit on next sync.

---

## Log Capture Script Options

The `scripts/sync-test.sh` script supports several filtering options:

```bash
# All sync logs (verbose)
./scripts/sync-test.sh

# Test records only (recommended for testing)
./scripts/sync-test.sh -t

# Filter by sync phase
./scripts/sync-test.sh -p SEND      # Only SEND phase
./scripts/sync-test.sh -p ERROR     # Only errors
./scripts/sync-test.sh -p CONFLICT  # Only conflicts

# Filter by specific record ID (partial match)
./scripts/sync-test.sh -r AA000000

# Filter by category
./scripts/sync-test.sh -c SyncCoordinator
./scripts/sync-test.sh -c SyncEngine-private
./scripts/sync-test.sh -c SyncEngine-shared

# Stream to terminal only (no file saved)
./scripts/sync-test.sh -n

# Custom log level
./scripts/sync-test.sh -l info      # Less verbose
./scripts/sync-test.sh -l error     # Errors only

# Combine options
./scripts/sync-test.sh -t -p ERROR  # Test records, errors only
```

### Sync Phases

| Phase | Meaning |
|-------|---------|
| `QUEUE` | Local change queued for sync |
| `SEND` | Preparing to send to CloudKit |
| `SENT` | Successfully sent and confirmed |
| `RECV` | Received from CloudKit server |
| `APPLY` | Applied to Core Data |
| `CONFLICT` | Conflict detected and resolved |
| `ERROR` | Error occurred |
| `DELETE` | Deletion processed |
| `PHOTO` | Photo/asset operation |

### Database Types

| Type | Meaning |
|------|---------|
| `PRIV` | Private database (your data) |
| `SHARED` | Shared database (family sharing) |

---

## Debug Menu Reference

In **Settings > Developer Tools > Sync Testing**:

| Action | Description |
|--------|-------------|
| **Test Profile** | Shows if test profile exists |
| **Test Events** | Shows count of test events (X / 8) |
| **Pending Changes** | Number of changes waiting to sync |
| **Create Test Data** | Creates test profile + events + weight |
| **Re-queue Test Data** | Re-queues existing test data for sync (use if data exists but wasn't synced) |
| **Delete Test Data** | Deletes test data locally (syncs deletion) |
| **Force Full Sync** | Triggers immediate sync (send + fetch) |
| **Purge Test Data (CloudKit)** | Directly deletes test records from CloudKit |
| **Clear Tombstones** | Clears deletion tombstones (use if records are being rejected) |
| **Copy Log Filter Command** | Copies the xcrun log stream command |

---

## Testing Scenarios

### Basic Sync Test

1. Start log capture: `./scripts/sync-test.sh -t`
2. Create test data in app
3. Tap "Force Full Sync"
4. Verify logs show: QUEUE → SEND → SENT for each record
5. Delete test data
6. Verify deletion syncs

### Photo Sync Test

1. Start log capture: `./scripts/sync-test.sh -t`
2. Create test data
3. In Timeline, find the "moment" test event
4. Add a photo to it
5. Watch for `[PHOTO]` phase logs
6. Check CloudKit Dashboard for the asset

### Conflict Resolution Test

1. Create test data and sync
2. Open CloudKit Dashboard (icloud.developer.apple.com)
3. Find the test profile record
4. Manually edit a field (e.g., change name)
5. In app, edit the same profile
6. Sync and watch for `[CONFLICT]` logs
7. Verify server version wins

### Offline Sync Test

1. Create test data
2. Enable Airplane Mode on Simulator
3. Edit the test profile or add events
4. Watch logs show QUEUE but not SENT
5. Disable Airplane Mode
6. Watch queued changes sync

### Shared Database Test

For testing family sharing sync:

1. Need two iCloud accounts
2. Account A: Create test data, share via Settings
3. Account B: Accept share invitation
4. Start log capture on Account B with: `./scripts/sync-test.sh -c SyncEngine-shared`
5. Watch for `[RECV] [SHARED]` logs

### Multi-Simulator Testing (Two iCloud Accounts)

To test sharing between two accounts, run two simulators simultaneously.

#### Step 1: Boot Two Simulators

```bash
# Boot first simulator (Account A)
xcrun simctl boot "iPhone 16"

# Boot second simulator (Account B) - must be different device type
xcrun simctl boot "iPhone 16 Pro"

# Verify both are running
xcrun simctl list | grep Booted
```

#### Step 2: Sign Into Different iCloud Accounts

1. Open **Simulator.app** (it should show both devices)
2. Switch between devices using **File > Open Simulator > [device name]**
3. On each simulator, go to **Settings > Sign in to your iPhone**
4. Sign in with different Apple IDs on each

#### Step 3: Run the App on Both Simulators

1. In Xcode, select "iPhone 16" as run destination
2. Press **Cmd+R** to build and run
3. Change run destination to "iPhone 16 Pro" in the toolbar
4. Press **Cmd+R** again (runs second instance)

Both simulators now have the app running with different iCloud accounts.

#### Step 4: Capture Logs from Each Simulator

```bash
# Get the UDIDs of booted simulators
xcrun simctl list | grep Booted
# Output example:
#   iPhone 16 (ABCD1234-...) (Booted)
#   iPhone 16 Pro (EFGH5678-...) (Booted)

# Terminal 1: Logs from Simulator A
xcrun simctl spawn ABCD1234-XXXX-XXXX-XXXX-XXXXXXXXXXXX log stream \
  --predicate 'subsystem=="nl.jaapstronks.Otis"' --level debug

# Terminal 2: Logs from Simulator B
xcrun simctl spawn EFGH5678-XXXX-XXXX-XXXX-XXXXXXXXXXXX log stream \
  --predicate 'subsystem=="nl.jaapstronks.Otis"' --level debug
```

#### Step 5: Test Sharing Flow

1. **Account A (iPhone 16):**
   - Create a dog profile
   - Go to Settings > [Dog] > Share
   - Enter Account B's email/phone
   - Send invitation

2. **Account B (iPhone 16 Pro):**
   - Receive share notification (or open share link)
   - Accept the invitation
   - Shared profile should appear

3. **Verify sync:**
   - Account B: Add an event to the shared profile
   - Account A: Pull to refresh, event should appear
   - Watch logs for `[RECV] [SHARED]` on Account A

#### Tips

- Each simulator maintains its own iCloud state - signing out on one doesn't affect the other
- The `./scripts/sync-test.sh` script only works with one simulator (the first booted one)
- For multi-simulator testing, use the manual `xcrun simctl spawn` commands above
- If sharing doesn't work, ensure both accounts have iCloud Drive enabled

---

## Simulator vs Device

### What Works in Simulator

- Private database sync (full support)
- CKSyncEngine operations
- Log streaming via `xcrun simctl`
- Test data creation/deletion
- Most sync scenarios

### What Requires Physical Device

- Family sharing invitation flow (Simulator can access shared data but not create family groups)
- Real-world network conditions
- Push notification triggers
- Performance testing

### Simulator iCloud Setup

1. Open Simulator
2. Settings > Sign in with your Apple ID (or a test account)
3. Wait for iCloud to sync
4. Run the app

---

## Troubleshooting

### No Logs Appearing

```bash
# Check if simulator is booted
xcrun simctl list | grep Booted

# If no simulator, boot one
xcrun simctl boot "iPhone 16"

# Verify app is running
ps aux | grep Ollie
```

### "No booted device" Error

Boot a simulator first:
```bash
xcrun simctl boot "iPhone 16"
```

### Logs Too Verbose

Use filters:
```bash
# Test records only
./scripts/sync-test.sh -t

# Specific phase
./scripts/sync-test.sh -p SENT

# Errors only
./scripts/sync-test.sh -p ERROR
```

### Test Data Stuck in CloudKit

Use "Purge Test Data (CloudKit)" in the debug menu. This directly deletes test records without going through the sync queue.

### Sync Not Triggering

1. Check iCloud is signed in (Settings > Apple ID)
2. Check "Pending Changes" count in debug menu
3. Try "Force Full Sync"
4. Check for errors in logs: `./scripts/sync-test.sh -p ERROR`

### iCloud Not Available / Engine is nil

If you see `iCloud not available` or `Engine is nil` errors:

1. Open **Settings** in the Simulator
2. Sign in with an Apple ID at the top
3. Wait for iCloud to finish setting up
4. **Restart the app** (stop in Xcode, Cmd+R)

The sync engines only start when iCloud is available.

### Records Being Rejected as Tombstoned

If you see `Rejecting tombstoned record` errors:

1. Go to **Settings > Developer Tools > Sync Testing**
2. Tap **Clear Tombstones**
3. Tap **Purge Test Data (CloudKit)** to clean CloudKit
4. Create fresh test data

---

## CloudKit Dashboard

For direct inspection of CloudKit data:

1. Go to https://icloud.developer.apple.com/dashboard/
2. Sign in with your developer account
3. Select container: `iCloud.nl.jaapstronks.Otis`
4. Navigate to **Data > Private Database**
5. Select zone: `com.apple.coredata.cloudkit.zone`

### Finding Test Records

Test records have IDs like:
- `CD_CDPuppyProfile:AA000000-0000-0000-0000-000000000001`
- `CD_CDPuppyEvent:AA000000-0000-0000-0000-000000000010`

### Manual Conflict Testing

1. Find a test record in Dashboard
2. Click to edit
3. Change a field value
4. Save
5. In app, edit the same record
6. Sync and check conflict resolution

---

## Test Data IDs

All test IDs use the `AA000000` prefix for easy identification:

| Entity | ID |
|--------|-----|
| Profile | `AA000000-0000-0000-0000-000000000001` |
| Pee Event | `AA000000-0000-0000-0000-000000000010` |
| Poop Event | `AA000000-0000-0000-0000-000000000011` |
| Meal Event | `AA000000-0000-0000-0000-000000000012` |
| Nap Event | `AA000000-0000-0000-0000-000000000013` |
| Walk Event | `AA000000-0000-0000-0000-000000000014` |
| Training Event | `AA000000-0000-0000-0000-000000000015` |
| Moment Event | `AA000000-0000-0000-0000-000000000016` |
| Weight Event | `AA000000-0000-0000-0000-000000000017` |
| Weight Measurement | `AA000000-0000-0000-0000-000000000020` |
| Photo Event | `AA000000-0000-0000-0000-000000000022` |

---

## Log File Location

Logs are saved to: `~/Desktop/OllieSyncLogs/`

Files are named with timestamps: `sync-20240315-143022.log`

To view recent logs:
```bash
ls -lt ~/Desktop/OllieSyncLogs/ | head -5
cat ~/Desktop/OllieSyncLogs/sync-*.log | tail -100
```

---

## Running Unit Tests

Sync-related unit tests are in `OtisShared/Tests/OtisSharedTests/SyncTests.swift`.

Run from Xcode:
1. Open Ollie-app.xcodeproj
2. Select OtisShared scheme
3. Cmd+U to run tests

Or from command line:
```bash
xcodebuild test -scheme OtisShared -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Architecture Reference

For detailed sync architecture, see [ARCHITECTURE.md](./ARCHITECTURE.md#cloudkit-sync-architecture).

Key files:
- `OtisShared/Sources/OtisShared/CloudKit/SyncCoordinator.swift` - Main orchestrator
- `OtisShared/Sources/OtisShared/CloudKit/SyncCoordinator+Delegate.swift` - Event handling
- `OtisShared/Sources/OtisShared/CloudKit/SyncLogging.swift` - Logging utilities
- `OtisShared/Sources/OtisShared/CloudKit/SyncTestFixtures.swift` - Test data
