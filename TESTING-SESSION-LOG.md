# Ollie App Testing Session Log

## Session 1: 2026-02-25 - Initial Exploration & Potty Logging

### Session Info
- **Date**: 2026-02-25
- **Focus**: Initial state exploration, then A-series (potty logging) tests
- **Tester**: Claude (automated via Maestro)
- **Device**: iPhone 17 Simulator, iOS 26.2

### Pre-Session State Check
- Day 12 with Ollie
- No events logged today initially
- Scheduled: Afternoon walk (20:00), Evening walk (22:00)
- Socialization items configured (Pet store 0/2)

---

### Tests Executed

| Test ID | Result | Screenshot | Notes |
|---------|--------|------------|-------|
| INIT | PASS | init-state.png | Initial app state - empty timeline, "No events yet" |
| A1 | PASS | A1-01 through A1-05 | Logged outdoor pee successfully |
| A3 | PASS | A3-01 through A3-08 | Indoor pee breaks streak correctly |
| A4 | PASS | A4-01 through A4-06 | Outdoor poop logged, counter updates to "1 poop" |
| B1 | BLOCKED | B1-01 through B1-17 | Sleep sheet opens but "Start or Log?" button hard to tap via automation |

---

### Issues Found

| Issue ID | Severity | Description | Test | Screenshot | Recommendation |
|----------|----------|-------------|------|------------|----------------|
| I01 | Medium | THREE separate "Meal overdue" cards showing (736min, 496min, 256min overdue). This is visually overwhelming. | A1 | A1-05-scrolled.png | Consolidate into single "Meals" card or show only most urgent |
| I02 | Low | Overdue times are very large (736 min = 12+ hours). May want to cap display or show "missed" instead | A1 | A1-05-scrolled.png | Consider "Breakfast missed" instead of "Meal overdue by 736 min" |
| I03 | Low | Walk card shows "0 of 3 walks" - puppy hasn't had any walks yet today which is expected, but wording could be clearer | A1 | A1-05-scrolled.png | Consider showing this less prominently if walks are scheduled for later |
| I04 | Medium | Sleep sheet "Start or Log?" button text is confusing - unclear what action will occur | B1 | B1-15-before-button.png | Consider renaming to just "Start Nap" or "Start" for clarity |
| I05 | Low | Sleep sheet has two-step flow: (1) expand "Start nap now", (2) tap "Start or Log?" - could be simplified | B1 | B1-10 through B1-15 | Consider making "Start nap now" a direct action |

---

### UI/UX Observations

| Obs ID | Category | Description | Screenshot | Suggestion |
|--------|----------|-------------|------------|------------|
| O01 | Good | PottyStatusCard immediately shows "Just peed - 0 min ago" with green checkmark | A1-05-scrolled.png | Working as expected |
| O02 | Good | Streak counter "1 in a row" appears after outdoor pee | A1-04-after-log.png | Clear and motivating |
| O03 | Good | Poop counter "0 poops" badge provides context | A1-04-after-log.png | Helpful for tracking |
| O04 | Good | Timeline shows event with clear icon, time, and "(outside)" label | A1-04-after-log.png | Easy to read |
| O05 | Info | Weather bar shows "15° Dry ahead" at top | A1-05-scrolled.png | Nice contextual info |
| O06 | Good | "After accident — go outside now!" card with urgent styling and "Log potty" quick action | A3-05-after-accident.png | Excellent accident response UX |
| O07 | Good | "Streak broken" badge clearly communicates consequence of indoor accident | A3-07-timeline-after-accident.png | Clear feedback |
| O08 | Good | Timeline uses color-coded icons: red drop for indoor, green drop for outdoor | A3-07-timeline-after-accident.png | Easy visual differentiation |
| O09 | Good | Poop icon is distinct from pee (circle vs drop shape) | A4-06-timeline.png | Clear differentiation |
| O10 | Good | Sleep sheet offers two options: "Start nap now" vs "Log completed nap" - flexible for different scenarios | B1-03-sleep-sheet.png | Good choice architecture |

---

### Questions for User

| Q ID | Question | Context |
|------|----------|---------|
| Q01 | Should multiple overdue meal cards be consolidated into one card? | Currently shows 3 separate cards which is overwhelming |
| Q02 | Should very old overdue times (12+ hours) show "missed" instead of minutes? | "Meal overdue by 736 min" is hard to parse |

---

### Next Tests to Run
- [ ] A2: Log outdoor pee when prediction is overdue
- [ ] A3: Log indoor pee (accident) - verify streak breaks
- [ ] A4: Log outdoor poop
- [ ] B1: Start nap when awake > 45 minutes
- [ ] B2: End nap after 30 minutes

