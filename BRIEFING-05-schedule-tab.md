# Briefing 05: Schedule Tab Restructuring

## Role After Restructuring

Schedule is **THE place for planning ahead**. When users want to see what's coming up, schedule appointments, or plan activities for the next days/weeks, they come here.

Schedule is planning-oriented. It answers:
- "What appointments do I have this week?"
- "What's coming up that I should prepare for?"
- "When should I schedule the next vet visit?"
- "Who are my puppy's contacts (vet, trainer, etc.)?"

## Current State

The Schedule tab has three sub-tabs:
1. **Development** (default) — age header, developmental banners, socialization timeline, milestones
2. **Calendar** — grid view of appointments
3. **Contacts** — vet, trainer, emergency contacts

### The Problem with Development Sub-Tab

It's an information display masquerading as a planning tool:
- Shows current age/stage (informational → belongs in Health)
- Shows developmental period banners (informational → belongs in Health)
- Shows socialization week timeline (informational → belongs in sheet)
- Shows "This Week" milestones (planning-adjacent, could stay)
- Shows "Coming Up" milestones (planning-adjacent, could stay)
- Links to Development Roadmap (should be a sheet)

**The tab is ~80% informational, ~20% planning.**

## Target State: Eliminate Development Sub-Tab

### New Structure

```
Schedule Tab
│
├── Calendar (DEFAULT, ENHANCED)
│   ├── Compact age/stage header (optional)
│   ├── Week/Month view toggle
│   ├── Appointments grid
│   ├── Milestones due this week (integrated)
│   └── Links to sheets for context
│
└── Contacts (UNCHANGED)
```

**Two sub-tabs, not three.** Calendar becomes the default and absorbs useful planning elements.

### What Happens to Development Content

| Current Location | Disposition |
|------------------|-------------|
| Age header (CalendarAgeHeader) | MOVE to Health or COMPACT in Calendar |
| Developmental period banners | DELETE from Schedule (Health owns) |
| Socialization week timeline | DELETE from Schedule (Sheet owns) |
| "This Week" milestones | INTEGRATE into Calendar view |
| "Coming Up" milestones | INTEGRATE into Calendar view |
| Development Roadmap link | CONVERT to sheet link in Calendar |

## Enhanced Calendar View

### Current Calendar
Shows appointments in a grid. Minimal.

### New Calendar

```
┌─────────────────────────────────────────┐
│ Schedule                                │
│ [Calendar]  [Contacts]                  │
├─────────────────────────────────────────┤
│ March 2026                    [< Week >]│
│ ┌───┬───┬───┬───┬───┬───┬───┐         │
│ │Mon│Tue│Wed│Thu│Fri│Sat│Sun│         │
│ ├───┼───┼───┼───┼───┼───┼───┤         │
│ │ 2 │ 3 │ 4•│ 5 │ 6 │ 7 │ 8 │         │
│ └───┴───┴───┴───┴───┴───┴───┘         │
│                                         │
│ TODAY (March 4)                         │
│ • 2:00 PM — Vet visit                   │
│                                         │
│ THIS WEEK                               │
│ • Vaccination #2 — due in 2 days        │
│ • Deworming #3 — due in 5 days          │
│                                         │
│ COMING UP                               │
│ • Puppy class — Mar 12                  │
│ • Vaccination #3 — Mar 25               │
│ • Microchip — Apr 2                     │
│                                         │
│ [View Development Journey →]            │
│ [View Socialization Window →]           │
├─────────────────────────────────────────┤
│ [+ Add Appointment]                     │
└─────────────────────────────────────────┘
```

### Key Elements

1. **Calendar Grid** — visual week/month view with dots for events
2. **Today Section** — appointments for today
3. **This Week Section** — milestones/appointments due this week
4. **Coming Up Section** — next 2-4 weeks
5. **Context Links** — to Development Journey and Socialization Window sheets
6. **Add Action** — quick add appointment

### Optional: Compact Age Header

If we want to keep age context visible:
```
┌─────────────────────────────────────────┐
│ Luna • 11 weeks • Socialization Stage   │
└─────────────────────────────────────────┘
```

One line, non-intrusive. Tap could open Development Journey Sheet.

Or: remove entirely. Health tab shows this. Don't duplicate.

**Recommendation:** Remove. Less is more. The user can check Health for stage info.

## What Gets Deleted

### Components to Remove

1. **DevelopmentalPeriodBanners** — or move to sheet only
2. **SocializationWeekTimeline in Schedule** — lives in sheet now
3. **CalendarAgeHeader** — or make minimal
4. **"Right Now" section** — entire concept (Health shows current state)
5. **Development sub-tab toggle option** — just Calendar + Contacts

### Views to Modify

1. **ScheduleTabView** (or CalendarTabView) — remove Development option
2. **CalendarGridView** — enhance with milestones integration
3. **DevelopmentRoadmapView** — convert to sheet presentation

## Milestones: Who Shows What?

### Before (Duplicate)
- Schedule shows: all milestones (health + development + social)
- Health shows: medical milestones only

### After (Clear Ownership)
- Schedule shows: appointments (user-created) + all milestone reminders (brief)
- Health shows: medical milestones with full detail and completion
- Sheets show: comprehensive timelines

Schedule's role is "what's coming up" — a notification/reminder function.
Health's role is "understand and manage health" — the source of truth.

When user taps a medical milestone in Schedule, it could:
- Open the Medical Care Sheet, OR
- Navigate to Health tab, OR
- Open MilestoneCompletionSheet directly

**Recommendation:** Open the relevant sheet. Keep Schedule lightweight.

## Implementation Steps

### Step 1: Enhance Calendar View
- Add "This Week" section showing due milestones
- Add "Coming Up" section showing future milestones/appointments
- Add links to Development Journey and Socialization Window sheets

### Step 2: Remove Development Sub-Tab
- Update tab picker to show only Calendar + Contacts
- Remove `case development` from the tab enum
- Remove or repurpose development-specific views

### Step 3: Delete or Relocate Components
- `DevelopmentalPeriodBanners` — delete from Schedule, keep for sheet if needed
- `SocializationWeekTimeline` — delete from Schedule, move to sheet
- `CalendarAgeHeader` — delete or make minimal

### Step 4: Update Navigation
- Development Roadmap → becomes `DevelopmentJourneySheet`
- Week detail sheets → become part of `SocializationWindowSheet`

### Step 5: Test Edge Cases
- Empty state (no appointments, no milestones)
- Many milestones (scrolling behavior)
- Past due milestones (overdue display)

## Contacts Sub-Tab

**Unchanged.** Contacts are planning-relevant (who to call for vet, trainer, etc.).

Keep as-is.

## Dependencies

- **Requires**: Sheets (BRIEFING-02) to exist
- **Requires**: Health tab (BRIEFING-03) to own developmental info
- **Requires**: Data model (BRIEFING-01) for clean milestone access
- **Should follow**: Train tab changes (BRIEFING-04)

## Files to Modify

- `Views/Calendar/` — significant restructuring
  - Remove development-specific views
  - Enhance CalendarGridView
- `Views/Schedule/` (if separate from Calendar)
- Navigation/tab definitions

## Files to Delete

After restructuring, these may become orphaned:
- Development-specific banner components
- Socialization timeline in Schedule
- Any development tab toggle logic

## Success Criteria

After this phase:
- Schedule tab has TWO sub-tabs: Calendar + Contacts
- Calendar shows appointments and upcoming milestones (brief reminders)
- No developmental stage info, no socialization progress, no countdown
- Clear links to sheets for users who want context
- The tab is pure planning: "what's coming up and when"
