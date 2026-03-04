# Briefing 00: Information Architecture Restructuring — Overview

## The Problem

Socialization and developmental information is fragmented across three tabs (Schedule, Health, Train) with:
- Three different visual treatments of the same data
- Two competing data models (`DevelopmentStage` vs `SocializationPhase`)
- Duplicate "weeks remaining" counters in multiple places
- Unclear ownership of content domains

## The Solution Philosophy

**Navigation tabs = User intent.** Where am I mentally? What do I want to do?
**Sheets = Canonical content.** Complete, coherent information about a concept.
**Cards = Contextual previews.** Entry points to sheets, framed for the tab's intent.

No content duplication. Multiple entry points to the same sheet are fine.

## The New Ownership Model

| Content Domain | Owner | Other Tabs |
|----------------|-------|------------|
| Developmental stages & phases | Health | Links to sheet |
| Socialization window & progress | Health | Train links to sheet |
| Socialization logging (action) | Train | — |
| Medical milestones | Health | — |
| Appointments & scheduling | Schedule | — |
| Skills training | Train | — |

## Implementation Sequence

### Phase 1: Foundations
1. **Data Model Unification** (`BRIEFING-01`)
   - Consolidate `DevelopmentStage` and `SocializationPhase`
   - Make phases a computed view within the socialization stage
   - No UI changes yet, just clean data

### Phase 2: Build New Content Layer
2. **Canonical Sheets** (`BRIEFING-02`)
   - Development Journey Sheet
   - Socialization Window Sheet
   - Medical Care Sheet
   - These are new additions; old UI still works

### Phase 3: Migrate Tabs
3. **Health Tab Restructuring** (`BRIEFING-03`)
   - Add Socialization Status Card
   - Connect all cards to canonical sheets
   - Health becomes the knowledge home

4. **Train Tab Restructuring** (`BRIEFING-04`)
   - Simplify Socialization card (remove redundant info)
   - Link to Socialization Window Sheet for context
   - Pure action focus

5. **Schedule Tab Restructuring** (`BRIEFING-05`)
   - Eliminate Development sub-tab entirely
   - Enhance Calendar to absorb useful parts
   - Link to sheets for context

### Phase 4: Finalize
6. **Cleanup** (`BRIEFING-06`)
   - Remove orphaned components
   - Delete unused views and models
   - Verify no duplicate content remains

## Dependency Graph

```
BRIEFING-01 (Data Model)
    ↓
BRIEFING-02 (Sheets) ←── depends on clean data model
    ↓
BRIEFING-03 (Health) ←── depends on sheets existing
    ↓
BRIEFING-04 (Train) ←── can parallel with Health, but sheets must exist
    ↓
BRIEFING-05 (Schedule) ←── depends on Health owning content
    ↓
BRIEFING-06 (Cleanup) ←── must be last
```

## What Gets Deleted (Eventually)

- `Schedule → Development` sub-tab (entire view)
- `DevelopmentalPeriodBanners` in Schedule
- `SocializationWeekTimeline` in Schedule (moves to sheet)
- Duplicate "weeks remaining" displays
- `SocializationPhase` as first-class model (becomes computed)
- Medical milestones in Schedule (Health owns)

## What Gets Built

- Development Journey Sheet
- Socialization Window Sheet
- Medical Care Sheet
- Socialization Status Card (Health tab)
- Enhanced Calendar view (Schedule tab)

## Success Criteria

After all phases:
1. Each piece of information has ONE canonical location
2. Sheets are comprehensive and accessible from contextually appropriate places
3. Tabs have clear, non-overlapping purposes
4. No user-facing regressions in functionality
