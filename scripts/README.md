# Ollie Sync Testing Scripts

Scripts for testing and debugging CloudKit sync.

## Quick Start

```bash
# Start log capture for all sync events
./scripts/sync-test.sh

# Capture only test record logs (TEST0000 prefix)
./scripts/sync-test.sh -t

# Capture errors only
./scripts/sync-test.sh -p ERROR

# Stream to terminal only (no file)
./scripts/sync-test.sh -n
```

## Scripts

### sync-test.sh

Captures CloudKit sync logs from the iOS Simulator.

**Options:**
- `-r <id>` - Filter by record ID (partial match)
- `-p <phase>` - Filter by sync phase
- `-c <cat>` - Filter by category
- `-t` - Test records only
- `-o <file>` - Custom output filename
- `-l <level>` - Log level (debug/info/error)
- `-n` - No file output
- `-h` - Show help

**Sync Phases:**
- `QUEUE` - Change queued locally
- `SEND` - Preparing to send
- `SENT` - Successfully sent
- `RECV` - Received from server
- `APPLY` - Applied to Core Data
- `CONFLICT` - Conflict resolved
- `ERROR` - Error occurred
- `DELETE` - Deletion processed
- `PHOTO` - Photo/asset operation

**Categories:**
- `SyncCoordinator` - Main coordinator
- `SyncEngine-private` - Private database
- `SyncEngine-shared` - Shared database

## Testing Workflow

### 1. Create Test Data

In the app (Debug build), go to Settings > Sync Testing:
- Tap "Create Test Profile" to create `TestDog-Sync` with test events
- Test data uses IDs starting with `TEST0000` for easy filtering

### 2. Start Log Capture

```bash
# In terminal 1 - capture test record logs
./scripts/sync-test.sh -t
```

### 3. Trigger Sync

In the app:
- Pull-to-refresh on Timeline
- Or tap "Force Sync" in debug menu

### 4. Analyze Logs

Look for patterns like:
```
[QUEUE] [PRIV] [TEST0000] Queued for save
[SEND]  [PRIV] [TEST0000] Preparing for upload
[SENT]  [PRIV] [TEST0000] Confirmed CD_CDPuppyEvent
```

### 5. Cleanup

In the app, tap "Delete Test Data" to remove test profile.

## CloudKit Dashboard

For direct CloudKit inspection:
1. Go to https://icloud.developer.apple.com/dashboard/
2. Select container: `iCloud.nl.jaapstronks.Otis`
3. Navigate to Data > Private Database
4. Look for records like `CD_CDPuppyProfile`, `CD_CDPuppyEvent`

## Common Issues

### No logs appearing
- Make sure Simulator is running
- Check iCloud is signed in (Settings > Apple ID)
- Verify app is running with Debug configuration

### "No booted device" error
- Boot a simulator first: `xcrun simctl boot "iPhone 15"`

### Logs too verbose
- Use phase filter: `./scripts/sync-test.sh -p SENT`
- Use test records only: `./scripts/sync-test.sh -t`
