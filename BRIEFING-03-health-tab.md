# Briefing 03: Health Tab Restructuring

## Role After Restructuring

Health becomes **THE home for developmental knowledge**. When users want to understand their puppy's health, growth, development, or stage-of-life context, they come here.

Health is informational with actionable entry points. It answers:
- "What stage is my puppy in?"
- "How is my puppy developing?"
- "What should I be aware of health-wise?"
- "How are my puppy's patterns (potty, sleep)?"

## Current State

The Health tab currently contains:
1. First-visit tip card
2. `DevelopmentPhaseCard` — current stage + active periods
3. Medical milestones section — upcoming + recently completed
4. `GrowthStoryCard` — weight tracking
5. Potty training section — streaks + gaps
6. Week overview section
7. Today's stats card
8. Sleep stats card
9. Pattern analysis card (premium)

### Problems
- `DevelopmentPhaseCard` shows socialization window info that's duplicated elsewhere
- Medical milestones duplicate what's in Schedule tab
- No clear entry point to the socialization journey

## Target State

### New Structure

```
Health Tab
│
├── Development Phase Card (ENHANCED)
│   └── Tap → Development Journey Sheet
│
├── Socialization Status Card (NEW)
│   └── Tap → Socialization Window Sheet
│
├── Medical Milestones Card (OWNS this domain)
│   └── Tap → Medical Care Sheet
│
├── Growth Card (unchanged)
│   └── Tap → Full weight chart
│
├── Potty Training Card (unchanged)
│   └── Tap → Potty Training Guide (in Train tab)
│
├── Sleep Stats Card (unchanged)
│
└── Pattern Analysis Card (unchanged, premium)
```

### Removed from Health Tab
- Week overview section (low value, clutters)
- Today's stats card (belongs in Today tab)
- First-visit tip (one-time, can be a sheet on first open)

## Card Specifications

### 1. Development Phase Card (Enhanced)

**Current behavior**: Shows stage name, age, active periods inline

**New behavior**:
- Compact summary: stage name + age + "X active periods"
- Single tap opens **Development Journey Sheet**
- Remove inline period details (sheet has them)

```
┌─────────────────────────────────────────┐
│ 🐕 Development                      →   │
│                                         │
│ Socialization Stage • 11 weeks old      │
│ 2 active sensitive periods              │
│                                         │
│ [Tap to see full development journey]   │
└─────────────────────────────────────────┘
```

**What moves to sheet**:
- Detailed period descriptions
- Advice text
- Weeks remaining countdown (THE sheet owns this)

### 2. Socialization Status Card (New)

**Purpose**: Quick status of socialization window, entry point to sheet

```
┌─────────────────────────────────────────┐
│ 🌱 Socialization Window             →   │
│                                         │
│ ████████████░░░░ 69%                    │
│ 5 weeks remaining                       │
│                                         │
│ 64 exposures logged                     │
│ [Tap to see details]                    │
└─────────────────────────────────────────┘
```

**If window closed**:
```
┌─────────────────────────────────────────┐
│ 🌱 Socialization                    →   │
│                                         │
│ Window closed (week 18)                 │
│ 87 exposures logged                     │
│ Continue building positive experiences  │
└─────────────────────────────────────────┘
```

**Data needed**:
- `profile.socializationWindowStatus` (from BRIEFING-01)
- Total exposures count
- Weeks remaining (if open)

**Tap action**: Opens **Socialization Window Sheet**

### 3. Medical Milestones Card (Claims Ownership)

**Current behavior**: Shows upcoming + recently completed, competes with Schedule

**New behavior**:
- Same display, but this is THE place for medical milestones
- Schedule tab will NOT show medical milestones
- Tap opens **Medical Care Sheet**

```
┌─────────────────────────────────────────┐
│ 🏥 Medical Care                     →   │
│                                         │
│ ⚠️ Vaccination #2 — 2 days overdue      │
│                                         │
│ Upcoming:                               │
│ • Deworming #3 — in 5 days              │
│ • Vaccination #3 — in 4 weeks           │
│                                         │
│ [Tap to see full medical timeline]      │
└─────────────────────────────────────────┘
```

**If nothing urgent**:
```
┌─────────────────────────────────────────┐
│ 🏥 Medical Care                     →   │
│ All caught up ✓                         │
│                                         │
│ Next: Vaccination #3 in 4 weeks         │
│ Last: Deworming #2 completed Feb 1      │
└─────────────────────────────────────────┘
```

### 4. Growth Card (Unchanged)

Keep as-is. Good card, clear ownership.

### 5. Potty Training Card (Unchanged)

Keep as-is. Could add a link to Potty Training Guide in Train tab.

### 6. Sleep Stats Card (Unchanged)

Keep as-is.

### 7. Pattern Analysis Card (Unchanged)

Keep as-is. Premium feature.

## Implementation Steps

### Step 1: Create Socialization Status Card
- New component: `SocializationStatusCard.swift`
- Uses `profile.socializationWindowStatus` from data model work
- Navigates to `SocializationWindowSheet`

### Step 2: Simplify Development Phase Card
- Remove inline sensitive period details
- Keep: stage name, age, period count
- Add: navigation to `DevelopmentJourneySheet`
- Remove: "weeks remaining" display (card doesn't own this)

### Step 3: Update Medical Milestones Card
- Add navigation to `MedicalCareSheet`
- Ensure this is the only place milestones appear (Schedule will remove its copy)

### Step 4: Clean up
- Remove week overview section
- Remove today's stats card (or move to Today tab)
- Remove first-visit tip (or make it a one-time sheet)

## Visual Hierarchy

After restructuring, the Health tab reads as:

```
DEVELOPMENT & GROWTH
├── Development Phase Card  → "Understand your puppy's stage"
├── Socialization Card      → "Track the critical window"
└── Growth Card             → "Monitor weight and growth"

HEALTH TRACKING
├── Medical Card            → "Stay on top of vet care"
├── Potty Card              → "See potty patterns"
└── Sleep Card              → "See sleep patterns"

INSIGHTS (if premium)
└── Pattern Analysis        → "Advanced pattern detection"
```

## Dependencies

- **Requires**: Data model work (BRIEFING-01) for `socializationWindowStatus`
- **Requires**: Sheets (BRIEFING-02) to exist before cards can link to them
- **Enables**: Schedule tab to remove its duplicate content

## Success Criteria

After this phase:
- Health tab is THE place to understand developmental status
- One card for development, one for socialization, one for medical
- No duplicate countdown/status displays elsewhere reference different data
- Clear navigation to comprehensive sheets
