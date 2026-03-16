# Sync Testing Plan

Comprehensive testing plan for CloudKit sync in Ollie, covering all data types, photos, and shared database scenarios.

## Quick Start (Resume Testing)

```bash
# 1. Boot two simulators
xcrun simctl boot "iPhone 16"
xcrun simctl boot "iPhone 16 Pro"

# 2. Verify both running
xcrun simctl list | grep Booted

# 3. Start log capture (use UDID from step 2)
xcrun simctl spawn <UDID> log stream --predicate 'subsystem=="nl.jaapstronks.Otis"' --level debug

# 4. In Xcode: Run app on each simulator (Cmd+R, change destination, Cmd+R again)
```

**Key docs:** See `docs/SYNC-TESTING.md` for detailed instructions.

**Current status:** Phase 1 complete (basic sync verified). Ready for Phase 2 (photo sync) and Phase 4 (shared database).

---

## Prerequisites

- [ ] Two Apple IDs (for shared database testing)
- [ ] Xcode with two simulators available (e.g., iPhone 16 and iPhone 16 Pro)
- [ ] Both simulators signed into different iCloud accounts
- [ ] Log capture script ready: `./scripts/sync-test.sh`

---

## Phase 1: Basic Sync Verification (Single Account)

### 1.1 Test Data Sync ✅ (Already verified)
- [x] Create test data (profile + 8 events + weight)
- [x] Verify QUEUE → SEND → SENT flow in logs
- [x] Confirm records appear in CloudKit Dashboard

### 1.2 All Entity Types Sync

Test that each entity type syncs correctly:

| Entity | Create | Sync | Verify in CloudKit |
|--------|--------|------|-------------------|
| CDPuppyProfile | [ ] | [ ] | [ ] |
| CDPuppyEvent (all types) | [ ] | [ ] | [ ] |
| CDWeightMeasurement | [ ] | [ ] | [ ] |
| CDMilestone | [ ] | [ ] | [ ] |
| CDDocument | [ ] | [ ] | [ ] |
| CDDogAppointment | [ ] | [ ] | [ ] |
| CDWalkSpot | [ ] | [ ] | [ ] |
| CDDogContact | [ ] | [ ] | [ ] |
| CDExposure (socialization) | [ ] | [ ] | [ ] |
| CDComfortableItem | [ ] | [ ] | [ ] |
| CDEarlyMilestone | [ ] | [ ] | [ ] |
| CDMedicationCompletion | [ ] | [ ] | [ ] |
| CDRoutineItem | [ ] | [ ] | [ ] |
| CDWeightGoal | [ ] | [ ] | [ ] |
| CDBodyConditionScore | [ ] | [ ] | [ ] |
| CDGroomingActivity | [ ] | [ ] | [ ] |
| CDEnrichmentActivity | [ ] | [ ] | [ ] |
| CDSkillProgress | [ ] | [ ] | [ ] |
| CDMasteredSkill | [ ] | [ ] | [ ] |
| CDRegressionLog | [ ] | [ ] | [ ] |
| CDExploredTile | [ ] | [ ] | [ ] |
| CDUserIdentity | [ ] | [ ] | [ ] |
| CDUserSentimentCheckIn | [ ] | [ ] | [ ] |

**How to test each:**
1. Create an instance of the entity in the app
2. Watch logs for `[QUEUE]` and `[SENT]` with the record type
3. Verify in CloudKit Dashboard

---

## Phase 2: Photo/Image Sync (Moments)

### 2.1 Photo Upload Test
1. [ ] Create a new Moment event
2. [ ] Attach a photo from library or camera
3. [ ] Watch for `[PHOTO]` phase logs
4. [ ] Verify photo uploads to CloudKit as CKAsset
5. [ ] Check CloudKit Dashboard for the asset

### 2.2 Photo Download Test (requires second device/simulator)
1. [ ] On Device A: Create Moment with photo, sync
2. [ ] On Device B: Sign into same iCloud account
3. [ ] Verify photo downloads automatically
4. [ ] Check for `[PHOTO] [DOWNLOADED]` logs

### 2.3 Profile Photo Sync
1. [ ] Set a profile photo for a dog
2. [ ] Verify upload via `[PHOTO]` logs
3. [ ] On second device, verify photo appears

### 2.4 Thumbnail Generation
1. [ ] Add high-resolution photo
2. [ ] Verify thumbnail is generated and synced
3. [ ] Check that both full and thumbnail exist in CloudKit

---

## Phase 3: Multi-Simulator Setup

### 3.1 Boot Two Simulators
```bash
# Terminal 1
xcrun simctl boot "iPhone 16"

# Terminal 2
xcrun simctl boot "iPhone 16 Pro"
```

### 3.2 Sign into Different iCloud Accounts
- [ ] Simulator 1 (iPhone 16): Sign in with Account A
- [ ] Simulator 2 (iPhone 16 Pro): Sign in with Account B

### 3.3 Run App on Both
1. [ ] In Xcode, run on iPhone 16 first
2. [ ] Change destination to iPhone 16 Pro
3. [ ] Run again (second instance)

### 3.4 Set Up Log Capture for Each
```bash
# Get UDIDs
xcrun simctl list | grep Booted

# Terminal for Simulator 1
xcrun simctl spawn <UDID1> log stream --predicate 'subsystem=="nl.jaapstronks.Otis"' --level debug

# Terminal for Simulator 2
xcrun simctl spawn <UDID2> log stream --predicate 'subsystem=="nl.jaapstronks.Otis"' --level debug
```

---

## Phase 4: Shared Database Testing (Family Sharing)

### 4.1 Create and Share a Profile
1. [ ] On Account A: Create a dog profile
2. [ ] Go to Settings > [Dog Name] > Share
3. [ ] Share with Account B's email/phone
4. [ ] Verify share invitation is created

### 4.2 Accept Share Invitation
1. [ ] On Account B: Receive notification or open share link
2. [ ] Accept the share invitation
3. [ ] Verify profile appears in Account B's app
4. [ ] Watch for `[RECV] [SHARED]` logs

### 4.3 Shared Data Sync - Account B Creates Data
1. [ ] On Account B: Add an event to the shared profile
2. [ ] Watch for `[QUEUE] [SHARED]` and `[SENT] [SHARED]` logs
3. [ ] On Account A: Verify the event appears
4. [ ] Watch for `[RECV] [SHARED]` logs on Account A

### 4.4 Shared Data Sync - Photos
1. [ ] On Account B: Add a Moment with photo to shared profile
2. [ ] Verify photo uploads to shared database
3. [ ] On Account A: Verify photo downloads
4. [ ] Check both accounts see the same photo

### 4.5 Conflict Resolution in Shared Database
1. [ ] Both accounts edit the same event simultaneously
2. [ ] Trigger sync on both
3. [ ] Watch for `[CONFLICT]` logs
4. [ ] Verify server version wins

### 4.6 Shared Profile Deletion
1. [ ] Owner (Account A) stops sharing
2. [ ] Verify Account B loses access
3. [ ] Data should remain for Account A

---

## Phase 5: Edge Cases and Error Handling

### 5.1 Offline Sync
1. [ ] Enable Airplane Mode in Simulator
2. [ ] Create/edit data
3. [ ] Watch QUEUE logs accumulate
4. [ ] Disable Airplane Mode
5. [ ] Verify queued changes sync

### 5.2 Conflict Resolution
1. [ ] Create data and sync
2. [ ] Manually edit record in CloudKit Dashboard
3. [ ] Edit same record in app
4. [ ] Sync and verify server wins

### 5.3 Deletion Sync
1. [ ] Create data and sync
2. [ ] Delete the data locally
3. [ ] Verify `[DELETE]` logs
4. [ ] Verify record removed from CloudKit

### 5.4 Large Batch Sync
1. [ ] Create many events (20+)
2. [ ] Trigger sync
3. [ ] Verify all sync without errors
4. [ ] Check for batch processing in logs

### 5.5 Account Change Handling
1. [ ] Sign out of iCloud in Simulator
2. [ ] Verify app handles gracefully
3. [ ] Sign into different account
4. [ ] Verify fresh sync with new account

---

## Phase 6: Performance and Reliability

### 6.1 Initial Sync Performance
- [ ] Fresh install, many records in CloudKit
- [ ] Measure time to initial sync completion
- [ ] Check for UI responsiveness during sync

### 6.2 Background Sync
- [ ] Background the app
- [ ] Make changes on another device
- [ ] Return to app
- [ ] Verify changes appear via push notification

### 6.3 Stress Test
- [ ] Rapid create/delete/edit cycles
- [ ] Verify no data loss or corruption
- [ ] Check for proper error handling

---

## Log Filters for Each Phase

```bash
# Phase 1-2: Private database
./scripts/sync-test.sh

# Phase 4: Shared database focus
./scripts/sync-test.sh -c SyncEngine-shared

# Photos only
./scripts/sync-test.sh -p PHOTO

# Errors only
./scripts/sync-test.sh -p ERROR

# Conflicts only
./scripts/sync-test.sh -p CONFLICT
```

---

## Success Criteria

- [ ] All entity types sync without errors
- [ ] Photos upload/download correctly
- [ ] Shared database works between two accounts
- [ ] Conflicts resolve correctly (server wins)
- [ ] Offline changes sync when back online
- [ ] No data loss in any scenario
- [ ] Logs are clear and traceable

---

## Notes

- Delete this file when testing is complete
- Document any bugs found in GitHub Issues
- Update SYNC-TESTING.md with any new learnings
