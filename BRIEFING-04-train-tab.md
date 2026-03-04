# Briefing 04: Train Tab Restructuring

## Role After Restructuring

Train is **THE place for taking action on training**. When users want to DO something — train a skill, log a socialization exposure, follow a training guide — they come here.

Train is action-oriented. It answers:
- "What should I train today?"
- "How do I log this socialization experience?"
- "How do I house train / crate train?"
- "What skill should I work on next?"

## Current State

The Train tab currently contains:
1. First-visit tip card
2. Training Guides section (Potty + Crate)
3. Skills section (SkillsPreviewCard)
4. Socialization section (SocializationJourneyCard)

### Problems with SocializationJourneyCard
- Shows "weeks remaining" (duplicated in Health, Schedule)
- Shows phase timeline visualization (informational, not actionable)
- Shows window status badges (informational)
- Mixes context/education with action

The card tries to do too much: explain socialization AND track progress AND provide actions.

## Target State

### Keep What Works
- Training Guides — clear, actionable, good
- Skills section — clear, actionable, good

### Simplify Socialization
- Remove informational elements (Health owns that)
- Focus on: "What's next? Log it."
- Link to sheet for context/understanding

### New Structure

```
Train Tab
│
├── Training Guides (UNCHANGED)
│   ├── Potty Training Guide
│   └── Crate Training Guide
│
├── Skills Section (UNCHANGED)
│   └── Tap → TrainingView (skill list)
│
└── Socialization Action Card (SIMPLIFIED)
    ├── Current focus item
    ├── Quick log button
    └── Link → Socialization Window Sheet (context)
```

## Socialization Card: Before & After

### Current (Too Much)

```
┌─────────────────────────────────────────┐
│ Socialization                       ⓘ   │
│                                         │
│ Building Confidence                     │
│ Luna is ready for varied experiences    │
│                                         │
│ ⏰ 5 weeks remaining                ← REMOVE
│ ████████████░░░░ 69%                ← REMOVE
│                                         │
│ [Phase timeline dots]               ← REMOVE
│   ●  ●  ●  ○  ○                         │
│                                         │
│ Progress: 7/12 items comfortable        │
│ Next: Visit a pet store                 │
│                                         │
│ [Continue Socialization →]              │
└─────────────────────────────────────────┘
```

### After (Action-Focused)

```
┌─────────────────────────────────────────┐
│ 🐕 Socialization                        │
│                                         │
│ Today's focus:                          │
│ 🏪 Visit a pet store                    │
│                                         │
│ [Log Exposure]  [See All Items]         │
│                                         │
│ 64 exposures logged                     │
│ [About the Socialization Window →]      │
└─────────────────────────────────────────┘
```

### Key Changes

| Element | Before | After |
|---------|--------|-------|
| Weeks remaining | Shown prominently | **REMOVED** (Health owns) |
| Progress bar | Shown | **REMOVED** (Sheet owns) |
| Phase timeline dots | Shown | **REMOVED** (Sheet owns) |
| Phase name/description | Shown | **REMOVED** (Sheet owns) |
| Current focus item | Shown | **KEPT** |
| Log action | Via navigation | **PROMOTED** (primary CTA) |
| Context link | Info button | **Explicit** link to sheet |

## SocializationJourneyView (Full Screen)

When user taps "See All Items" they go to `SocializationJourneyView`.

### Current Issues
- Has its own phase timeline header (duplicate)
- Has educational "What is Socialization?" button
- Mixes logging with context

### Changes Needed

**Remove from header:**
- Phase timeline visualization
- Weeks remaining display
- Phase description paragraphs

**Keep/enhance:**
- Category list with items
- Logging functionality (the core purpose)
- Quick-check mode

**Add:**
- Clear link to Socialization Window Sheet at top
- "View full progress" link that opens the sheet

### New Structure

```
┌─────────────────────────────────────────┐
│ ← Socialization                         │
├─────────────────────────────────────────┤
│ 64/100 exposures • 5 weeks left         │
│ [View Socialization Window →]           │
├─────────────────────────────────────────┤
│ 👥 PEOPLE                        23/30  │
│ ├── Strangers              ●●●○○  3/5  │
│ ├── Children               ●●●●○  4/5  │
│ ├── Elderly people         ●●○○○  2/5  │
│ └── [+] Log new person exposure         │
│                                         │
│ 🐕 ANIMALS                       12/20  │
│ ├── Other dogs             ●●●●●  5/5 ✓│
│ ├── Cats                   ●●○○○  2/5  │
│ └── [+] Log new animal exposure         │
│                                         │
│ ... more categories ...                 │
└─────────────────────────────────────────┘
```

The view is now pure action: a checklist to work through, with logging.

## Implementation Steps

### Step 1: Simplify SocializationJourneyCard
- Remove: weeks remaining, progress bar, phase timeline, phase description
- Keep: suggested item, exposure count
- Add: prominent "Log Exposure" button
- Add: link to Socialization Window Sheet

### Step 2: Simplify SocializationJourneyView
- Remove: phase timeline header, educational paragraphs
- Keep: category lists, item toggling, logging
- Add: compact status line + link to sheet at top

### Step 3: Update Navigation
- "About Socialization Window" → opens `SocializationWindowSheet`
- Info button (ⓘ) → opens `SocializationWindowSheet`

### Step 4: Verify Training Guides & Skills
- These should be unchanged
- Verify they don't have creeping informational content

## Edge Cases

### Settling In Phase (First Week)
Currently shows a checklist of early milestones instead of exposure categories.

**Keep this behavior** but simplify:
```
┌─────────────────────────────────────────┐
│ 🐕 Socialization                        │
│                                         │
│ Getting settled:                        │
│ ✓ Survived first night                  │
│ ○ First outdoor potty                   │
│ ○ Comfortable in crate                  │
│                                         │
│ [Mark Complete]                         │
│ [About the Socialization Window →]      │
└─────────────────────────────────────────┘
```

### Window Closed
```
┌─────────────────────────────────────────┐
│ 🐕 Socialization                        │
│                                         │
│ Great work! 87 exposures logged.        │
│ Keep building positive experiences.     │
│                                         │
│ [Log Exposure]  [View History]          │
│                                         │
│ [About Ongoing Socialization →]         │
└─────────────────────────────────────────┘
```

## Dependencies

- **Requires**: Socialization Window Sheet (BRIEFING-02) to exist
- **Requires**: Data model (BRIEFING-01) for clean status access
- **Can parallel with**: Health tab restructuring (BRIEFING-03)

## Files to Modify

- `Views/Socialization/SocializationJourneyCard.swift` — simplify heavily
- `Views/Socialization/SocializationJourneyView.swift` — remove header, add sheet link
- `Views/Training/TrainTabView.swift` — may need navigation updates

## Success Criteria

After this phase:
- Train tab has ZERO informational displays about the socialization window
- All context/understanding lives in Health tab or sheets
- Train tab is pure action: log, practice, progress
- User can still access context via explicit "About" links
