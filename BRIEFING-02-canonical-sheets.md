# Briefing 02: Canonical Sheets

## Purpose

Sheets are the **single source of truth** for their content domain. They are:
- Comprehensive (tell the complete story)
- Self-contained (educational + status + actions)
- Accessible from multiple places (via different entry points)
- Consistent (same sheet, same content, regardless of how you got there)

## Sheet 1: Development Journey Sheet

### What It Replaces
- `DevelopmentRoadmapView` (currently in Schedule tab)
- `DevelopmentPhaseCard` educational content (currently in Health tab)
- Scattered developmental stage information

### Content Structure

```
┌─────────────────────────────────────────┐
│ Development Journey                  ✕  │
├─────────────────────────────────────────┤
│ [Luna's photo]                          │
│ Luna is 11 weeks old                    │
│ Currently in: Socialization Stage       │
│ ████████░░░░░░░░ 45% through stage      │
├─────────────────────────────────────────┤
│ ⚠️ ACTIVE SENSITIVE PERIODS             │
│ ┌─────────────────────────────────────┐ │
│ │ 🌱 Socialization Window             │ │
│ │ 5 weeks remaining                   │ │
│ │ Focus on new experiences now        │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 😨 First Fear Period                │ │
│ │ May show caution with new things    │ │
│ │ Keep exposures positive, don't push │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ STAGE TIMELINE                          │
│                                         │
│ ● Neonatal (0-2 weeks)         ✓       │
│   Eyes/ears opening                     │
│                                         │
│ ● Transitional (2-3 weeks)     ✓       │
│   First steps, leaving nest             │
│                                         │
│ ● Socialization (3-12 weeks)   ← NOW   │
│   ├─ First vet visit           ✓       │
│   ├─ Vaccination #1            ✓       │
│   ├─ Meet 50 people            ○ 23/50 │
│   ├─ Vaccination #2            ○ Due   │
│   └─ ...more milestones                │
│                                         │
│ ○ Juvenile (12-24 weeks)               │
│   Permanent teeth, continued learning   │
│                                         │
│ ○ Adolescent (24-72 weeks)             │
│   Sexual maturity, testing boundaries   │
│                                         │
│ ○ Adult (72+ weeks)                    │
│   Full maturity                         │
├─────────────────────────────────────────┤
│ [See Socialization Window Details]      │
│ [View Medical Timeline]                 │
└─────────────────────────────────────────┘
```

### Key Features
- Current stage prominently displayed with progress
- Active sensitive periods with actionable advice
- Full timeline with all stages (expandable/collapsible)
- Milestones inline with stages
- Cross-links to other canonical sheets

### Entry Points
- Health tab → Development Phase Card → tap
- Schedule tab → Calendar → "View Development Journey" link
- Onboarding completion (optional)

### Components to Reuse/Adapt
- `DevelopmentRoadmapView` — the timeline structure
- `DevelopmentPhaseCard` — the current stage display
- `DevelopmentalPeriodBanners` — the sensitive period alerts

---

## Sheet 2: Socialization Window Sheet

### What It Replaces
- `SocializationWeekTimeline` (currently in Schedule tab)
- `SocializationJourneyCard` header info (currently in Train tab)
- Week-by-week detail sheets scattered around
- "What is Socialization?" educational content

### Content Structure

```
┌─────────────────────────────────────────┐
│ Socialization Window                 ✕  │
├─────────────────────────────────────────┤
│ 🧠 THE CRITICAL PERIOD                  │
│                                         │
│ Weeks 3-16 of a puppy's life are the    │
│ prime time for socialization. Luna is   │
│ currently in week 11.                   │
│                                         │
│ ⏰ 5 weeks remaining                    │
│ ████████████░░░░ 69% through window     │
├─────────────────────────────────────────┤
│ WEEK-BY-WEEK PROGRESS                   │
│                                         │
│ [Visual timeline: weeks 3-16]           │
│  3  4  5  6  7  8  9 10 11 12 13 14 15 16│
│  ●  ●  ●  ●  ●  ●  ●  ●  ◐  ○  ○  ○  ○  ○│
│  ✓  ✓  ✓  ✓  ✓  ✓  ✓  ✓  now            │
│                                         │
│ Week 11 (current): 4 exposures logged   │
│ [Tap any week for details]              │
├─────────────────────────────────────────┤
│ EXPOSURE CATEGORIES                     │
│                                         │
│ 👥 People         ████████░░  23/30     │
│ 🐕 Animals        ██████░░░░  12/20     │
│ 🏠 Environments   █████░░░░░   8/15     │
│ 🔊 Sounds         ███░░░░░░░   5/15     │
│ 🚗 Vehicles       ████░░░░░░   6/10     │
│ 🎯 Handling       ██████████  10/10 ✓   │
│                                         │
│ Total: 64/100 exposures                 │
├─────────────────────────────────────────┤
│ CURRENT PHASE: Building Confidence      │
│                                         │
│ Luna is past the initial settling in    │
│ and ready for more varied experiences.  │
│ Focus on positive associations.         │
├─────────────────────────────────────────┤
│ SUGGESTED THIS WEEK                     │
│                                         │
│ • Visit a pet store (environments)      │
│ • Meet 3 new people (people)            │
│ • Hear traffic sounds (sounds)          │
│                                         │
│ [Log New Exposure]                      │
├─────────────────────────────────────────┤
│ QUICK LINKS                             │
│ [View Full Journey] → SocializationView │
│ [See Development Stage] → Dev Sheet     │
└─────────────────────────────────────────┘
```

### Key Features
- Clear explanation of what the window is and why it matters
- Countdown and progress prominently displayed (THE one place for this)
- Week-by-week visual timeline (moved from Schedule)
- Category breakdown with progress
- Current phase context (from Train tab's model)
- Actionable suggestions
- Quick link to log exposures

### Entry Points
- Health tab → Socialization Status Card → tap
- Train tab → Socialization card → "About Window" link
- Train tab → SocializationJourneyView → info button
- Development Journey Sheet → "See Socialization Window Details" link

### Components to Reuse/Adapt
- `SocializationWeekTimeline` — the week grid
- `SocializationJourneyCard` — phase display logic
- `SocializationJourneyView` — category/item structure

---

## Sheet 3: Medical Care Sheet

### What It Replaces
- Medical milestones section in Health tab (partial)
- Medical milestones mixed into Schedule tab
- Scattered milestone completion flows

### Content Structure

```
┌─────────────────────────────────────────┐
│ Medical Care                         ✕  │
├─────────────────────────────────────────┤
│ Luna's Health Timeline                  │
│                                         │
│ Next appointment: None scheduled        │
│ [Schedule Vet Visit]                    │
├─────────────────────────────────────────┤
│ ⚠️ ACTION NEEDED                        │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 💉 Vaccination #2                   │ │
│ │ Due: 2 days ago (overdue)           │ │
│ │ [Mark Complete] [Schedule]          │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 💊 Deworming #3                     │ │
│ │ Due in 5 days                       │ │
│ │ [Mark Complete] [Schedule]          │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ UPCOMING (next 90 days)                 │
│                                         │
│ • Vaccination #3 — in 4 weeks           │
│ • Microchip — in 6 weeks                │
│ • Spay consultation — in 8 weeks        │
├─────────────────────────────────────────┤
│ COMPLETED                               │
│                                         │
│ ✓ Vaccination #1 — Feb 15, 2026         │
│ ✓ First vet visit — Feb 10, 2026        │
│ ✓ Deworming #2 — Feb 1, 2026            │
│ ✓ Deworming #1 — Jan 15, 2026           │
│ [Show all completed]                    │
├─────────────────────────────────────────┤
│ WEIGHT HISTORY                          │
│                                         │
│ [Mini chart: weight over time]          │
│ Current: 8.2 kg (+0.4 kg this week)     │
│ [Log Weight] [See Full Chart]           │
└─────────────────────────────────────────┘
```

### Key Features
- Clear "action needed" section for overdue/due soon
- Full timeline of medical milestones
- Appointment scheduling integration
- Completion tracking with dates
- Weight history integration (optional, could stay separate)

### Entry Points
- Health tab → Medical Milestones Card → tap
- Development Journey Sheet → medical milestone → tap
- Schedule tab → Calendar → medical appointment → tap

### Components to Reuse/Adapt
- `MilestoneCompletionSheet` — completion flow
- Health tab medical milestones section — data and layout
- `GrowthStoryCard` — weight display (optional inclusion)

---

## Implementation Order

1. **Development Journey Sheet** — most self-contained, good starting point
2. **Socialization Window Sheet** — depends on data model cleanup
3. **Medical Care Sheet** — may already be close to existing MilestoneCompletionSheet

## Shared Patterns

All three sheets should:
- Use consistent navigation (sheet presentation, X to close)
- Have a clear header with current status
- Include "action needed" sections when relevant
- Cross-link to related sheets
- Support being opened from multiple entry points

## File Structure Suggestion

```
Views/
  Sheets/
    DevelopmentJourneySheet.swift
    SocializationWindowSheet.swift
    MedicalCareSheet.swift
    Shared/
      SheetHeader.swift
      ActionNeededSection.swift
      ...
```

Or integrate into existing structure:
```
Views/
  Development/
    DevelopmentJourneySheet.swift  (new)
    DevelopmentRoadmapView.swift   (migrate content, then delete)
  Socialization/
    SocializationWindowSheet.swift (new)
    SocializationJourneyView.swift (keep for logging, simplify)
  Health/
    MedicalCareSheet.swift         (new or rename existing)
```
