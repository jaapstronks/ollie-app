# Ollie App UI/UX Testing Plan

## Testing System Overview

### Approach
1. **Scenario-based testing**: Each test starts from a specific app state/context
2. **Action-reaction validation**: Log an event, verify all affected components update
3. **Screenshot documentation**: Capture each step for UI review
4. **Issue tracking**: Log problems found with severity and recommendations
5. **Flexible iteration**: Tests can be varied/repeated with different parameters

### Test Execution Flow
```
1. Set up initial state (navigate to day, ensure specific context)
2. Screenshot BEFORE state
3. Perform action (log event)
4. Screenshot AFTER state
5. Verify all expected changes occurred
6. Note any issues or improvements
7. Move to next test
```

### Severity Levels
- **Critical**: App crash, data loss, completely broken flow
- **High**: Incorrect data displayed, confusing UX that blocks user
- **Medium**: UI glitch, minor calculation error, unclear messaging
- **Low**: Polish issues, minor text improvements, visual refinements
- **Enhancement**: Not a bug, but could be better

---

## Test Categories

### Category A: Potty Logging
Tests for pee/poop logging in various contexts

### Category B: Sleep/Wake Logging
Tests for nap start, nap end, sleep tracking

### Category C: Walk Logging
Tests for walk logging with/without potty events

### Category D: Meal Logging
Tests for feeding events

### Category E: Status Card Updates
Tests verifying cards update correctly after events

### Category F: Edge Cases
Unusual scenarios, forgotten logs, midnight crossing

### Category G: Timeline Display
Tests for timeline rendering, event ordering, day navigation

---

## Test Scenarios

### A. POTTY LOGGING SCENARIOS

#### A1: Log outdoor pee when prediction is "normal"
- **Initial state**: Puppy awake, last pee 30+ min ago, prediction shows time remaining
- **Action**: Log outdoor pee
- **Expected**:
  - PottyStatusCard changes to "justWent" (green checkmark)
  - Streak increments by 1
  - Timeline shows new pee event
  - Prediction resets

#### A2: Log outdoor pee when prediction is "overdue"
- **Initial state**: Puppy awake, prediction shows overdue (red)
- **Action**: Log outdoor pee
- **Expected**:
  - PottyStatusCard changes from red overdue to green justWent
  - Relief messaging
  - Streak maintained/incremented
  - Timeline updated

#### A3: Log indoor pee (accident)
- **Initial state**: Active outdoor streak, normal prediction
- **Action**: Log indoor pee
- **Expected**:
  - Streak breaks (reset to 0)
  - Card shows "postAccident" state with urgent message
  - Timeline shows indoor pee event
  - Appropriate feedback about going outside

#### A4: Log outdoor poop
- **Initial state**: No poops today, pattern expects 2-3
- **Action**: Log outdoor poop
- **Expected**:
  - PoopStatusCard updates count (0 -> 1)
  - Shows "1 poop today" message
  - Streak maintained
  - Timeline shows poop event

#### A5: Log both pee and poop together
- **Initial state**: Puppy awake, overdue for both
- **Action**: Log "beide" (both) outdoor
- **Expected**:
  - Both cards update
  - Single timeline entry or two entries?
  - Streak increments
  - Both predictions reset

#### A6: Log pee right after waking up
- **Initial state**: Puppy just woke from nap, post-sleep trigger active
- **Action**: Log outdoor pee
- **Expected**:
  - Post-sleep trigger cleared
  - PottyStatusCard returns to normal prediction
  - Good timing feedback

#### A7: Log pee 30 min after meal
- **Initial state**: Meal logged 25-35 min ago, post-meal trigger active
- **Action**: Log outdoor pee
- **Expected**:
  - Post-meal trigger cleared
  - Positive reinforcement messaging
  - Card returns to normal prediction

#### A8: Log multiple pees in quick succession
- **Initial state**: Normal prediction
- **Action**: Log pee, then log another pee 5 min later
- **Expected**:
  - Both events appear in timeline
  - Prediction based on most recent
  - No duplicate warnings

---

### B. SLEEP/WAKE LOGGING SCENARIOS

#### B1: Start nap when awake > 45 minutes
- **Initial state**: Puppy awake for 50 min, SleepStatusCard shows orange "suggest nap"
- **Action**: Tap "Start Nap" button
- **Expected**:
  - Sleep event logged
  - SleepStatusCard changes to "sleeping" (purple)
  - Shows "sleeping for X minutes"
  - Timeline shows sleep event

#### B2: End nap after 30 minutes
- **Initial state**: Puppy sleeping for 30 min
- **Action**: Tap "Wake Up" button, confirm time
- **Expected**:
  - Wake event logged
  - SleepStatusCard changes to "awake" (green)
  - Post-sleep potty trigger activates (if nap >= 15 min)
  - Timeline shows wake event

#### B3: End very short nap (< 15 min)
- **Initial state**: Puppy sleeping for 10 min
- **Action**: Wake up puppy
- **Expected**:
  - Wake event logged
  - Post-sleep potty trigger should NOT activate
  - Timeline shows wake event
  - Sleep counts toward daily total

#### B4: Log nap retroactively
- **Initial state**: Puppy awake, nap happened but wasn't logged
- **Action**: Use NapLogSheet to log completed nap with past times
- **Expected**:
  - Both sleep and wake events added to timeline
  - Timeline correctly ordered by time
  - Sleep calculations include retroactive nap

#### B5: Puppy awake for 60+ minutes
- **Initial state**: Puppy awake for 65 min (too long)
- **Action**: Observe SleepStatusCard
- **Expected**:
  - Card shows red/urgent state
  - Message indicates puppy awake too long
  - Strong suggestion to start nap

#### B6: Start nap then immediately cancel
- **Initial state**: Puppy awake
- **Action**: Start nap, then end it after 2 minutes
- **Expected**:
  - Both events logged
  - Very short nap handled gracefully
  - No weird state

---

### C. WALK LOGGING SCENARIOS

#### C1: Log walk with both pee and poop
- **Initial state**: Walk window active, predictions normal
- **Action**: Log 20-min walk with pee=yes, poop=yes
- **Expected**:
  - Walk event in timeline
  - Pee event in timeline (or included in walk)
  - Poop event in timeline (or included in walk)
  - Both status cards update
  - Streak maintained/incremented

#### C2: Log walk with no potty events
- **Initial state**: Puppy recently went potty
- **Action**: Log 15-min walk without pee or poop
- **Expected**:
  - Walk event in timeline
  - No potty events created
  - Predictions unchanged
  - Walk still counts for exercise

#### C3: Log walk after scheduled walk time
- **Initial state**: Scheduled walk was 30 min ago
- **Action**: Log walk now
- **Expected**:
  - Walk event created
  - Schedule adherence tracked (late but done)
  - No duplicate reminders

#### C4: Log very long walk (60+ min)
- **Initial state**: Normal state
- **Action**: Log 75-min walk
- **Expected**:
  - Walk duration properly displayed
  - Exercise limits respected (age-based)
  - Any warnings if too long for puppy age

#### C5: Log walk with location/spot
- **Initial state**: Walk spots configured
- **Action**: Log walk at specific spot
- **Expected**:
  - Walk event includes spot
  - Spot visit count incremented
  - Insights track spot usage

---

### D. MEAL LOGGING SCENARIOS

#### D1: Log meal at scheduled time
- **Initial state**: Meal window active (scheduled meal)
- **Action**: Log meal
- **Expected**:
  - Meal event in timeline
  - Meal icon removed from quick-log bar (meal done)
  - Post-meal potty trigger activates (30 min window)
  - PottyStatusCard mentions post-meal timing

#### D2: Log meal outside scheduled time
- **Initial state**: No meal window active
- **Action**: Navigate to "more" and log meal
- **Expected**:
  - Meal event created
  - No schedule conflict
  - Post-meal trigger still activates

#### D3: Log second meal of day
- **Initial state**: One meal already logged today
- **Action**: Log another meal
- **Expected**:
  - Second meal in timeline
  - Meal count updated
  - Schedule comparison available

---

### E. STATUS CARD UPDATE SCENARIOS

#### E1: All cards update after outdoor pee
- **Initial state**: Mixed urgency states
- **Action**: Log outdoor pee
- **Verify**:
  - [ ] PottyStatusCard updated
  - [ ] StreakCard incremented
  - [ ] Timeline has new event
  - [ ] No stale data anywhere

#### E2: Cards update after time passes
- **Initial state**: Normal predictions
- **Action**: Wait or simulate time passage
- **Verify**:
  - [ ] Urgency levels increase appropriately
  - [ ] Colors change at thresholds
  - [ ] Messages update

#### E3: Night mode hides appropriate cards
- **Initial state**: Simulate night time (23:00-06:00)
- **Action**: Observe status cards
- **Verify**:
  - [ ] PottyStatusCard hidden or shows night mode
  - [ ] PoopStatusCard hidden or shows night mode
  - [ ] SleepStatusCard appropriate for night

---

### F. EDGE CASES

#### F1: No events logged today
- **Initial state**: New day, no events yet
- **Action**: Observe all views
- **Expected**:
  - Status cards show "unknown" or appropriate defaults
  - Timeline shows empty state message
  - Quick-log bar fully functional

#### F2: Forgot to log for half a day
- **Initial state**: Last event was 6+ hours ago
- **Action**: Start logging again
- **Expected**:
  - Predictions handle long gap gracefully
  - Can log events with past timestamps
  - No crash or weird calculations

#### F3: Log event at midnight boundary
- **Initial state**: 23:58 PM
- **Action**: Log event, wait for midnight
- **Expected**:
  - Event appears on correct day
  - Day change handled smoothly
  - Timeline navigation works

#### F4: Log many events rapidly
- **Initial state**: Normal
- **Action**: Log 5+ events in quick succession
- **Expected**:
  - All events saved
  - UI remains responsive
  - Timeline shows all events correctly

#### F5: Edit/delete event after logging
- **Initial state**: Recent event logged
- **Action**: Edit time or delete event
- **Expected**:
  - Status cards recalculate
  - Timeline updates
  - Streak recalculates if affected

#### F6: First day with new puppy profile
- **Initial state**: Fresh profile, no history
- **Action**: Observe and log first events
- **Expected**:
  - Graceful handling of no patterns
  - Defaults make sense
  - Building toward patterns

#### F7: Day with unusual pattern (many/few poops)
- **Initial state**: Pattern established, today has 5 poops (above normal)
- **Action**: Observe PoopStatusCard
- **Expected**:
  - Card notes unusual count
  - Doesn't alarm unnecessarily
  - Pattern still learning

---

### G. TIMELINE DISPLAY SCENARIOS

#### G1: Events display in chronological order
- **Initial state**: Multiple events at various times
- **Action**: View timeline
- **Expected**:
  - Events sorted by time (newest first or oldest first, consistently)
  - Time stamps accurate
  - Event types clearly shown

#### G2: Navigate to previous day
- **Initial state**: On today
- **Action**: Navigate to yesterday
- **Expected**:
  - Yesterday's events shown
  - Status cards update or hide for past day
  - Can return to today easily

#### G3: Navigate to day with no events
- **Initial state**: On day with events
- **Action**: Navigate to empty day
- **Expected**:
  - Empty state message
  - Can still log events for that day
  - Navigation works normally

#### G4: Event details display correctly
- **Initial state**: Events with notes, locations
- **Action**: View event in timeline
- **Expected**:
  - Notes visible
  - Location (indoor/outdoor) indicated
  - Time accurate
  - Correct emoji/icon

---

## Testing Session Tracker

### Session Template
```
## Session: [DATE] - [FOCUS AREA]

### Tests Executed
| Test ID | Result | Screenshot | Notes |
|---------|--------|------------|-------|
| A1      | PASS   | a1-after.png | Card updated correctly |
| A3      | FAIL   | a3-issue.png | Streak didn't break |

### Issues Found
| ID | Severity | Description | Test | Recommendation |
|----|----------|-------------|------|----------------|
| I01 | Medium | Streak count didn't update | A3 | Check streak calculation |

### Questions for User
- [ ] Q1: Should post-accident message be more prominent?

### Next Steps
- [ ] Re-test A3 after fix
- [ ] Continue with B series
```

---

## Issue Log

### Issues Found During Testing

| Issue ID | Date | Severity | Description | Test | Status | Resolution |
|----------|------|----------|-------------|------|--------|------------|
| (none yet) | | | | | | |

---

## Questions for User

| Q ID | Question | Context | Status |
|------|----------|---------|--------|
| (none yet) | | | |

---

## Screenshots Directory
Screenshots saved to: `testing-screenshots/`
Naming convention: `{test-id}-{step}-{timestamp}.png`

---

## How to Run Tests

### Before Testing Session
1. Open Ollie app in Simulator
2. Note current date/time
3. Check existing data state
4. Decide which test category to focus on

### During Testing
1. Follow test scenario steps
2. Screenshot before and after each action
3. Note any deviations from expected behavior
4. Log issues immediately
5. Continue to next test even if issues found

### After Testing Session
1. Update session tracker section
2. Compile issue list
3. Note questions for user
4. Identify tests needing re-run

---

## Current Test Queue

### Priority Order
1. **A1-A8**: Potty logging (core feature)
2. **B1-B6**: Sleep/wake logging
3. **E1-E3**: Status card updates
4. **F1-F7**: Edge cases
5. **C1-C5**: Walk logging
6. **D1-D3**: Meal logging
7. **G1-G4**: Timeline display

### Test Variations to Consider
- Same tests at different times of day
- Same tests with different existing data
- Same tests in dark mode vs light mode
- Same tests with different puppy ages (affects predictions)

