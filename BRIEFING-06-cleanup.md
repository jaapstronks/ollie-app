# Briefing 06: Cleanup & Validation

## Purpose

This is the final phase. After all restructuring is complete:
1. Remove orphaned components
2. Delete unused code
3. Verify no duplicate content remains
4. Validate navigation flows
5. Update any documentation

## Orphaned Components Audit

After the restructuring, these components may be orphaned:

### Likely Orphaned (Delete)

| Component | Was Used In | Replaced By |
|-----------|-------------|-------------|
| `DevelopmentalPeriodBanners` | Schedule Development tab | Development Journey Sheet |
| `SocializationWeekTimeline` | Schedule Development tab | Socialization Window Sheet |
| `CalendarAgeHeader` | Schedule Development tab | Removed (Health shows this) |
| Development sub-tab views | Schedule | Eliminated |
| `PhaseTimelineView` (if exists) | Train Socialization | Removed (Sheet has context) |

### Possibly Orphaned (Audit)

| Component | Check If Still Used |
|-----------|---------------------|
| Milestone display in Schedule | Should be simplified, not deleted |
| Week detail sheets | May be absorbed into Socialization Window Sheet |
| Phase-specific components | May be used in SocializationJourneyView still |

### Keep (Used by Sheets)

| Component | Now Used By |
|-----------|-------------|
| `DevelopmentRoadmapView` content | Development Journey Sheet |
| Socialization category lists | Socialization Window Sheet + JourneyView |
| Milestone completion flows | Medical Care Sheet |

## Code Deletion Checklist

### Phase 1: Safe Deletions (Definitely Orphaned)

After Schedule tab restructuring:
- [ ] Delete Development sub-tab enum case
- [ ] Delete Development sub-tab view file(s)
- [ ] Delete `DevelopmentalPeriodBanners` if not used in sheet
- [ ] Delete `SocializationWeekTimeline` if fully moved to sheet
- [ ] Delete `CalendarAgeHeader` if removed

### Phase 2: Conditional Deletions (Verify First)

- [ ] `SocializationPhase` enum — if fully replaced by computed property
- [ ] Phase timeline components — if removed from Train tab
- [ ] Duplicate "weeks remaining" calculation code — consolidate first
- [ ] Week detail sheets — if absorbed into main sheet

### Phase 3: Model Cleanup

- [ ] Remove unused properties from view models
- [ ] Remove duplicate calculation methods
- [ ] Consolidate status/progress calculations into single service

## Validation Checklist

### No Duplicate Information

Verify each piece of info appears in ONE place:

| Information | Should Appear In | Should NOT Appear In |
|-------------|------------------|----------------------|
| Current development stage | Health tab card | Schedule, Train |
| Weeks remaining in window | Health tab card + Sheet | Schedule, Train card |
| Socialization progress % | Health tab card + Sheet | Schedule, Train header |
| Active sensitive periods | Health tab card + Sheet | Schedule banners |
| Medical milestones list | Health tab card + Sheet | Schedule (brief OK) |
| Exposure logging | Train tab | Health, Schedule |

### Navigation Flows Work

Test these user journeys:

1. **"Check development status"**
   - Open Health tab
   - Tap Development card
   - See Development Journey Sheet
   - ✓ Complete journey, no dead ends

2. **"Check socialization progress"**
   - Open Health tab
   - Tap Socialization card
   - See Socialization Window Sheet
   - ✓ Can navigate to logging from sheet

3. **"Log socialization exposure"**
   - Open Train tab
   - Tap Socialization card
   - Either: tap "Log Exposure" directly
   - Or: tap "See All" → SocializationJourneyView → log
   - ✓ Can access context via sheet link

4. **"Plan upcoming week"**
   - Open Schedule tab
   - See Calendar with milestones
   - Tap milestone → appropriate action
   - Can access context via sheet links
   - ✓ No developmental info inline

5. **"Complete medical milestone"**
   - Open Health tab
   - Tap Medical card
   - See Medical Care Sheet
   - Complete milestone
   - ✓ Updates everywhere

### Sheet Accessibility

Verify sheets are accessible from intended entry points:

| Sheet | Entry Points |
|-------|--------------|
| Development Journey | Health card, Schedule link, (onboarding) |
| Socialization Window | Health card, Train card link, Train JourneyView link |
| Medical Care | Health card, Schedule milestone tap |

### Edge Cases

- [ ] Puppy age < 3 weeks (before socialization window)
- [ ] Puppy age 3-16 weeks (in window)
- [ ] Puppy age > 16 weeks (window closed)
- [ ] No milestones due
- [ ] Many milestones overdue
- [ ] No exposures logged
- [ ] All exposures complete

## Documentation Updates

### Files to Update

- [ ] `CLAUDE.md` — update architecture section if view structure changed
- [ ] Any README files with architecture diagrams
- [ ] Comment headers in restructured files

### Files to Delete

- [ ] This briefing series (BRIEFING-*.md) after implementation complete
- [ ] Any TODO files related to this restructuring

## Performance Check

After cleanup:
- [ ] No duplicate API calls for same data
- [ ] No duplicate state calculations
- [ ] Sheets load quickly (data already computed)
- [ ] Tab switching remains smooth

## Final Verification

Before considering complete:

1. **Fresh app launch** — everything loads correctly
2. **All tabs accessible** — no crashes or missing content
3. **All sheets open** — from all intended entry points
4. **All actions work** — logging, completing, scheduling
5. **No orphan references** — build succeeds with no warnings about unused code

## Rollback Plan

If issues are found:
- Git history preserves all deleted code
- Sheets are additive (can coexist with old UI temporarily)
- Tab changes can be reverted independently

## Definition of Done

The restructuring is complete when:

1. ✓ Health tab owns developmental/health knowledge
2. ✓ Train tab is pure action (logging, practicing)
3. ✓ Schedule tab is pure planning (calendar, appointments)
4. ✓ Three canonical sheets exist and work
5. ✓ No duplicate information displays
6. ✓ No orphaned components
7. ✓ All navigation flows work
8. ✓ Build succeeds with no warnings
9. ✓ Briefing files deleted
