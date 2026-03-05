# Otis Roadmap (2026 H1)

## Purpose

Translate the new positioning into an execution plan that a solo founder can run without scope collapse.

Core principle: ship less, validate faster, scale only after retention and conversion prove out.

---

## Strategic Constraints

- Market scope now: EN, NL, DE.
- Product posture: utility-first, privacy-first, Apple-native.
- Business model: low-friction long-term subscription (not high-pressure weekly pricing).
- Success depends on retention and trust, not short-term ARPU extraction.

---

## North-Star Outcomes (by end of H1)

- D7 retention >= 30%
- D30 retention >= 20%
- Trial-to-paid >= 4%
- App Store rating >= 4.4
- 300+ paying subscribers with mostly organic or high-intent acquisition

---

## 0-30 Days: Focus and Foundation

### Product

1. Tighten onboarding for "new puppy overwhelm" use case:
   - essential-only path (name, dates, optional breed/photo)
   - explicit reassurance copy ("you can change this later")
   - remove friction before first value moment
2. Clarify first-session value in-product:
   - quick logging nudge
   - timeline orientation hint
   - one "next recommended action" prompt
3. Instrument activation events with idempotency + weekly cohort tracking:
   - profile_created
   - first_event_logged
   - day_2_return
   - trial_started
   - trial_converted

### Messaging / GTM

1. Update App Store copy to utility + calm + privacy narrative.
2. Align marketing site to "help me build this with me" founder voice.
3. Prioritize one content loop:
   - founder-led short videos
   - 3-5 value-first community responses/week
   - one practical blog post/week

### Operations

1. Weekly metrics review ritual (single dashboard, fixed template).
2. Keep a running "friction log" from support/reviews for fast product decisions.

---

## 31-60 Days: Activation and Retention Improvements

### Product

1. Ship phase-aware UX direction:
   - puppy mode (high frequency logging + reassurance)
   - routine mode (planning + summary)
2. Add lightweight owner wellbeing check-in ("how are you doing today?").
3. Add weekly planning card with 2-4 actionable priorities.

### AI

1. Ship AI-powered daily summary card:
   - yesterday highlights
   - likely needs today
   - one suggested action
2. Keep output concise and explainable.
3. Do not launch open-ended generic chat as primary UX.

### GTM

1. Optimize App Store screenshots for utility proofs:
   - timeline
   - reminders
   - watch/widget workflow
2. Run small high-intent Apple Search Ads test only if organic conversion is healthy.

---

## 61-90 Days: Monetization Quality and Controlled Scale

### Product

1. Improve paywall context at value moments (after demonstrated usage).
2. Add household planning/accountability improvements.
3. Ship "resource bookmarks" for external training content links.

### Monetization

1. Keep pricing simple (monthly/yearly).
2. Test one packaging variation:
   - household/family plan concept
3. Do not introduce aggressive weekly pricing.

### Acquisition

1. Scale only winning channel(s) with proven CAC.
2. Add Meta tests only if:
   - trial-to-paid >= 4%
   - D30 retention >= 20%
   - CAC guardrails hold

---

## 90-180 Days: Durable Expansion

### Product expansion

1. Extend beyond puppy-first into full-life utility:
   - appointments
   - meds
   - long-term routines
   - memory timeline continuity
2. Deepen Apple ecosystem differentiators:
   - watch complications
   - widget iteration
   - shortcut templates

### Market expansion

1. Re-open broader localization only after core metrics are stable for 6-8 weeks.
2. Bring back archived language assets in controlled batches.

---

## Language Scope Reset Plan (Start Now)

### Goal

Reduce active language burden while preserving past translation work.

### Execution steps

1. Freeze active GTM and review cycles to EN/NL/DE.
2. Create a dedicated archive branch, e.g. `archive/all-locales-2026-03`.
3. Keep all translation files in branch history for later restore.
4. Remove non-priority locale surface area from active marketing assets first.
5. Defer app-level localization pruning until there is a dedicated QA window.

### Why sequence this way

Marketing assets are faster to simplify and carry lower regression risk than app-level localization changes.

---

## Weekly Decision Rules

- If retention drops, pause acquisition experiments and fix product first.
- If conversion drops, improve value communication before changing price.
- If support volume spikes after a release, prioritize stability over roadmap features.
- If a feature does not move activation/retention/upgrade metrics, deprioritize it.

---

## Not Doing (H1)

- Competing on large internal training content volume.
- Live trainer/chat marketplace features.
- High-maintenance community moderation products.
- Broad multilingual growth before funnel proof.

