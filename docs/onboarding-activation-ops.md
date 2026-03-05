# Onboarding Activation Ops

## Validation Scenarios (Deterministic)

Run these scenarios on a fresh install (or after profile reset) before each onboarding release:

1. **New profile created**
   - Complete onboarding with minimal path (skip breed, skip photo, skip permissions).
   - Expect: `profile_created` fires exactly once.
2. **First event logged**
   - Log one event from Today immediately after onboarding.
   - Expect: `first_event_logged` fires once for profile, does not fire again on second event.
3. **Day-2 return**
   - Set onboarding completion timestamp to yesterday and relaunch.
   - Expect: `day_2_return` fires once on first active session.
4. **Trial start**
   - Start introductory trial from purchase flow.
   - Expect: `trial_started` fires once for transaction id.
5. **Trial conversion**
   - Simulate/observe transition from `.trial` to `.active`.
   - Expect: `trial_converted` fires once for active-until value.

## Weekly Activation Review Ritual

Cadence: once per week, same day/time, one dashboard snapshot.

### Metrics (same cohort definition every week)

- `profile_created` rate from first open
- `first_event_logged` in first session
- `day_2_return`
- `trial_started`
- `trial_converted`

### Review Template

1. What moved most vs last week?
2. Which onboarding step has highest drop-off?
3. Which event quality issue appeared (missing/duplicate/misaligned)?
4. One change to ship this week.
5. One thing to intentionally not do this week.

## Measured Iteration #1 (Now)

### Change shipped

- Welcome step skipped by default.
- Breed is now optional with a "Skip for now" path.
- First-session handoff sheet added after onboarding completion.

### Hypothesis

Reducing setup friction and adding explicit first-session guidance will increase:

- `first_event_logged` in session 1
- `day_2_return` for new users

### Decision rule (next review)

- Keep this iteration if both metrics improve week-over-week.
- If only one improves, keep and test copy refinement first.
- If neither improves, revisit step order and handoff messaging.
