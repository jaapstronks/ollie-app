# TODO: Onboarding Tightening Contract (30 Days)

## Product Promise (First Session)

Help overwhelmed new puppy owners do 3 things in one calm first session:

1. Log something quickly.
2. Understand what the timeline is showing.
3. See the next recommended action.

## Critical Path (Essential-only)

Keep setup focused on profile essentials first, defer optional details:

1. Name
2. Breed (or skip for now)
3. Birth date
4. Home status + home date
5. Optional photo
6. Confirm and continue
7. Optional permissions (notifications/location)
8. First-session handoff (quick log + timeline + next step)

Design constraints:

- Every step explains value in plain language.
- Reassure users they can edit details later.
- Keep progress confidence high (visible progress, no dead-ends).

## KPI Event Spec (Activation + Conversion)

### 1) `profile_created`

- Trigger: first profile save succeeds during onboarding.
- Source of truth: onboarding save success callback.
- Properties:
  - `profile_id`
  - `has_breed`
  - `has_photo`
  - `is_expecting`
  - `used_custom_breed`
  - `onboarding_variant` (default: `overwhelm_v1`)

### 2) `first_event_logged`

- Trigger: first successful event write after onboarding for that profile.
- Source of truth: `EventStore.addEvent`.
- Idempotency: once per profile.
- Properties:
  - `profile_id`
  - `event_type`
  - `hours_since_profile_created` (if available)
  - `has_note`
  - `has_photo`
  - `has_location`

### 3) `day_2_return`

- Trigger: first app session that occurs on day+1 after onboarding completion.
- Source of truth: app lifecycle (`didBecomeActive`) with onboarding completion timestamp.
- Idempotency: once per profile.
- Properties:
  - `profile_id`
  - `days_since_profile_created` (expected: 1)
  - `session_source` (default: `app_active`)

### 4) `trial_started`

- Trigger: successful introductory purchase transaction.
- Source of truth: StoreKit purchase success path.
- Idempotency: once per transaction id.
- Properties:
  - `product_id`
  - `is_intro_offer`
  - `trial_end_at`
  - `storefront` (if available)

### 5) `trial_converted`

- Trigger: subscription status transition from `trial` to `active`.
- Source of truth: subscription status transition observer.
- Idempotency: once per active renewal date.
- Properties:
  - `source_status` (`trial`)
  - `target_status` (`active`)
  - `active_until`

## Delivery Checklist

- [ ] Onboarding flow simplified and optionalized where possible.
- [ ] First-session handoff implemented.
- [ ] All 5 KPI events instrumented with idempotency rules.
- [ ] Weekly activation review ritual and QA scenarios documented.
