# First-Week User Experience Design

## Overview
This document defines the first 7 days of app experience for new dog owners (primary account holders). The goal is to create habits, demonstrate value quickly, and achieve strong retention through the critical first 2-3 days.

## Core Principles

1. **Progressive Disclosure** — Only show features after they become relevant
2. **Earn Before Ask** — Deliver value before requesting actions (photos, invites, etc.)
3. **Celebrate Small Wins** — Acknowledge every logged event, especially early ones
4. **Smart Defaults** — The app should feel useful even with minimal data
5. **Gentle Nudges** — Never feel pushy; always feel helpful

---

## Day 0: First Session (Post-Onboarding)

### Timeline State
- Empty timeline with a friendly welcome state
- Single prominent card: **"Log your first moment with {puppyName}"**
- Quick-log bar visible but with subtle pulse animation on most common types

### What We Show
```
┌─────────────────────────────────────┐
│  Welcome to {puppyName}'s timeline! │
│                                     │
│  This is where you'll see          │
│  {puppyName}'s day unfold.         │
│                                     │
│  [Log your first moment]           │
└─────────────────────────────────────┘
```

### What We DON'T Show Yet
- ❌ Potty predictions (no data yet)
- ❌ Sleep analysis cards
- ❌ Meal reminders
- ❌ Walk suggestions
- ❌ Sentiment check-in
- ❌ Week recap tease
- ❌ AI insights cards
- ❌ Partner activity summary
- ❌ "Invite family" prompts

### First Event Celebration
When they log their first event:
- Subtle confetti animation
- Toast: "First moment logged! You're on your way."
- Timeline now shows the event with proper formatting

### Gating Logic (Feature Visibility)
```swift
struct FirstWeekGating {
    // Cards only appear after relevant events exist
    var showPottyPredictions: Bool {
        eventStore.pottyCount >= 3
    }
    var showSleepAnalysis: Bool {
        eventStore.sleepCount >= 2
    }
    var showMealReminders: Bool {
        eventStore.mealCount >= 1 && profile.mealSchedule != nil
    }
    var showWalkSuggestions: Bool {
        eventStore.walkCount >= 1
    }
    var showNapReminders: Bool {
        eventStore.napCount >= 1
    }
}
```

### First Session Goals
- Log at least 1 event ✓
- See the timeline populated ✓
- Understand the quick-log bar ✓

---

## Day 0: First Push Notification Strategy

### Timing Logic
- If user logged events and left app: No notification for 4 hours
- If user completed onboarding but logged 0 events:
  - Wait 2 hours, then send first gentle nudge

### First Notification (if 0 events after 2 hours)
```
🐕 How's {puppyName} doing?
Tap to log what they're up to right now.
```

### First Notification (if they logged events)
Don't send anything day 0 unless they explicitly enabled a reminder.

---

## Day 1: Building the Habit

### Morning (First Full Day)
The app should feel different now — they have some history.

**If they logged potty events yesterday:**
- Show "Time since last potty" indicator
- After 3+ potty events: Show first prediction card

**If they logged meals:**
- Next meal reminder unlocks
- "Meal schedule" prompt in settings becomes more visible

### New Cards That Can Appear (Based on Data)

| Card | Unlock Condition |
|------|------------------|
| Potty Predictions | 3+ potty events logged |
| Sleep Summary | 2+ sleep/wake cycles |
| Meal Reminder | 1+ meal + schedule set |
| Post-Wake Potty Reminder | 1+ sleep logged |
| Exercise Tracker | 1+ walk logged |

### Day 1 Push Notifications

**Morning (8-9 AM, if they used app yesterday):**
```
☀️ Good morning! Ready to track {puppyName}'s day?
```

**Only if they logged meals yesterday:**
```
🍽️ Breakfast time for {puppyName}?
Tap to log their meal.
```

**Evening (if no events logged today by 6 PM):**
```
📝 Don't forget to log {puppyName}'s day
Even a quick potty log helps build their routine insights.
```

### Sentiment Check-In
- **NOT on Day 0**
- First check-in appears on Day 1, afternoon/evening
- Keep it simple: "How was your day with {puppyName}?"
- Only 3 options: Great / Okay / Tough
- No follow-up questions yet

---

## Day 2: Demonstrating Value

### Unlocked Features

**If 5+ events logged:**
- "Yesterday's Summary" card appears for first time
- Shows: X potty breaks, Y hours sleep, Z meals

**If 3+ potty events:**
- Full predictions card with "Next potty likely in X min"
- Success rate begins calculating (too early to show %)

### Photo Nudge (First Appearance)
Day 2 is when we first suggest adding a photo.

**Trigger:** After logging any event on Day 2
**Placement:** Inline suggestion, not modal

```
┌─────────────────────────────────────┐
│ 📸 Capture this moment?            │
│                                     │
│ Add a photo to remember this day   │
│ with {puppyName}.                   │
│                                     │
│ [Add Photo]  [Maybe Later]         │
└─────────────────────────────────────┘
```

**Rules:**
- Only show once per day
- Don't show if they already added a photo
- "Maybe Later" dismisses for 24 hours
- Never show as a push notification

### Day 2 Push Notifications

**If they logged consistently Day 0-1:**
```
📊 {puppyName}'s patterns are emerging!
Open to see their potty and sleep insights.
```

**If they haven't logged today by noon:**
```
🐾 {puppyName} is waiting for their first log today
```

---

## Day 3: Social & Sharing Hooks

### Partner/Family Invite Nudge
Day 3 is earliest we suggest inviting others.

**Trigger:** After logging 10+ total events across all days
**Placement:** Card on timeline (not modal, not push)

```
┌─────────────────────────────────────┐
│ 👥 Share {puppyName}'s care        │
│                                     │
│ Invite a partner or family member  │
│ to help track {puppyName}'s day.   │
│                                     │
│ [Invite Someone]  [Not Now]        │
└─────────────────────────────────────┘
```

**Rules:**
- Show max once per session
- "Not Now" = don't show for 3 days
- If dismissed twice, don't show again (rely on settings)

### Streak Introduction
After 3 consecutive days of logging:
```
🔥 3-day streak! You're building great habits.
```
- Small celebratory animation
- Streak counter now visible in app header

### Day 3 Push Notifications

**Morning:**
```
🔥 Day 3 with {puppyName}!
Keep the streak going — log their first moment.
```

**If first photo was added:**
```
📸 Your first photo of {puppyName} looks great!
Add more to build their memory book.
```

---

## Day 4-5: Deepening Engagement

### AI Insights Unlock
**Condition:** 15+ events logged, at least 3 days of data

First AI insight card appears:
```
┌─────────────────────────────────────┐
│ 🤖 AI Insight                       │
│                                     │
│ {puppyName} seems to need a potty  │
│ break about 20 minutes after       │
│ waking up. Watch for signs!        │
└─────────────────────────────────────┐
```

### Week Preview Tease
On Day 5:
```
┌─────────────────────────────────────┐
│ 📅 Your first weekly recap is      │
│ coming in 2 days!                  │
│                                     │
│ Keep logging to get the full       │
│ picture of {puppyName}'s week.     │
└─────────────────────────────────────┘
```

### Socialization/Training Hints
If no training or socialization events logged by Day 5:

```
┌─────────────────────────────────────┐
│ 🎓 Track training sessions too!    │
│                                     │
│ Log skills you're working on with  │
│ {puppyName} to track progress.     │
│                                     │
│ [Log Training]  [Learn More]       │
└─────────────────────────────────────┘
```

---

## Day 6-7: Establishing Routine

### Full Feature Access
By Day 7, users should have access to:
- ✅ All prediction cards (with enough data)
- ✅ Weekly recap (first one!)
- ✅ AI insights
- ✅ Streak tracking
- ✅ Full notification schedule
- ✅ Sentiment tracking (with follow-ups)

### First Week Recap
Day 7 (or Day 8 morning):
```
┌─────────────────────────────────────┐
│ 🎉 Your First Week with Ollie!     │
│                                     │
│ You logged 47 moments with         │
│ {puppyName} this week.             │
│                                     │
│ • 23 potty breaks (78% outside!)   │
│ • 14 meals                         │
│ • 8 naps                           │
│ • 2 training sessions              │
│                                     │
│ [See Full Recap]  [Share]          │
└─────────────────────────────────────┘
```

### Post-First-Week Transition
- Regular notification schedule takes over
- All gating flags can be removed
- User is now in "established" state

---

## Retention Signals & Intervention

### Health Metrics (Days 1-3)

| Metric | Healthy | At Risk | Critical |
|--------|---------|---------|----------|
| Events Day 1 | 5+ | 2-4 | 0-1 |
| Events Day 2 | 5+ | 2-4 | 0-1 |
| Events Day 3 | 3+ | 1-2 | 0 |
| Total Day 1-3 | 15+ | 8-14 | <8 |
| App Opens Day 1-3 | 6+ | 3-5 | <3 |
| Consecutive Days | 3 | 2 | 1 |

### Intervention Triggers

**At Risk (Day 2, <3 events):**
```
💡 Quick tip: Most puppy parents log potty breaks to spot patterns.
Try logging {puppyName}'s next bathroom break!
```

**At Risk (Day 3, no return):**
```
🐕 We miss you and {puppyName}!
Open the app to log a quick moment.
```

**Critical (Day 3, 0-2 total events):**
- Consider in-app survey on next open: "What's holding you back?"
- Options: Too complicated / Not useful / Forgot / Other
- Use feedback to improve or offer help

### Positive Reinforcement

**Power User Detection (Day 3, 20+ events):**
```
⭐ You're a natural! {puppyName} is lucky to have you.
```

**Consistent Logger (3 days, 5+ events/day):**
- Unlock "Dedicated Owner" badge (if gamification exists)
- Early access prompt to premium features

---

## Push Notification Schedule Summary

### Day 0
| Time | Condition | Message |
|------|-----------|---------|
| +2hr | 0 events | "How's {name} doing?" |

### Day 1
| Time | Condition | Message |
|------|-----------|---------|
| 8 AM | Used yesterday | "Good morning! Ready to track?" |
| 6 PM | 0 events today | "Don't forget to log" |

### Day 2
| Time | Condition | Message |
|------|-----------|---------|
| 9 AM | Consistent | "Patterns are emerging!" |
| 12 PM | 0 events | "Waiting for first log" |

### Day 3
| Time | Condition | Message |
|------|-----------|---------|
| 8 AM | 2-day streak | "Day 3! Keep the streak going" |

### Day 4-7
- Transition to regular schedule based on their actual patterns
- Meal reminders if schedule set
- Potty predictions if enabled
- No more "getting started" messaging

---

## Implementation Status

### Implemented Files
- [x] `Services/FirstWeekExperienceService.swift` — Central gating service
- [x] `Views/Cards/PhotoPromptCard.swift` — Photo prompt nudge card
- [x] `Views/Cards/FamilyInvitePromptCard.swift` — Family invite nudge card
- [x] `Services/Notifications/FirstWeekNotificationScheduler.swift` — First-week notifications
- [x] `Utils/Strings/Strings+FirstWeek.swift` — Localized strings (extended)

### Data Tracked (in FirstWeekExperienceService)
- [x] `onboardingCompletedDate` — Day 0 timestamp
- [x] `firstEventDate` — When first event was logged
- [x] `firstPhotoDate` — When first photo was added
- [x] `familyInviteSent` — Boolean
- [x] `photoPromptDismissDate` + dismissCount
- [x] `invitePromptDismissDate` + dismissCount
- [x] `firstEventCelebrationShown` — Boolean
- [x] `streakCelebrationLastDay` — Last streak celebrated

### Gating Properties (computed)
- [x] `shouldShowPottyPredictions` — 3+ potty events
- [x] `shouldShowSleepAnalysis` — 2+ sleep/wake cycles
- [x] `shouldShowMealReminders` — 1+ meal logged
- [x] `shouldShowWalkSuggestions` — 1+ walk logged
- [x] `shouldShowAIInsights` — 15+ events over 3+ days
- [x] `shouldShowSentimentCheckIn` — Not on Day 0
- [x] `shouldShowWeeklyRecap` — 7+ days
- [x] `shouldShowPhotoPrompt` — Day 2+, no photo, not dismissed today
- [x] `shouldShowInvitePrompt` — Day 3+, 10+ events, not dismissed in 3 days

### Integration Points
- [x] `ContentView.swift` — Marks onboarding completed
- [x] `TimelineViewModel.swift` — Refreshes counts on event sync
- [x] `TodayStatusCardsSection.swift` — Photo & invite prompt cards
- [x] `SentimentCheckInContainer.swift` — Day 0 gating
- [x] `NotificationService.swift` — First-week scheduler

### Still TODO
- [ ] AI insight gating (in AI insight cards)
- [ ] First-event celebration toast/confetti
- [ ] Streak celebration UI (days 3, 5, 7)
- [ ] Retention health analytics tracking

---

## Success Metrics

### Primary (Day 7)
- **D7 Retention:** % of users who open app on Day 7
- **Target:** 40%+ (industry average for utilities: 25%)

### Secondary
- **D1 Retention:** Target 70%+
- **D3 Retention:** Target 50%+
- **Events per User (Week 1):** Target 35+
- **Photo Attachment Rate:** Target 20%+ users add 1+ photo
- **Family Invite Rate:** Target 10%+ send invite

### Qualitative
- Sentiment check-in responses (Day 1-7)
- App Store reviews mentioning "easy" or "helpful"
- Support tickets about confusion (should be near zero)

---

## Visual Summary: First Week Timeline

```
Day 0   Day 1   Day 2   Day 3   Day 4   Day 5   Day 6   Day 7
  │       │       │       │       │       │       │       │
  ▼       ▼       ▼       ▼       ▼       ▼       ▼       ▼
┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐
│ 1 │   │ 2 │   │ 3 │   │ 4 │   │ 5 │   │ 6 │   │   │   │ 7 │
└───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘
  │       │       │       │       │       │       │       │
  │       │       │       │       │       │       │       │
First   First   Photo   Invite  AI      Recap   ───────►Full
Event   Senti-  Nudge   Nudge   Insight Tease           Week
Celeb-  ment                                            Recap
ration  Check

1 = Welcome state, first event celebration
2 = Predictions unlock, sentiment check-in
3 = Photo prompt, streak celebration
4 = Family invite prompt
5 = AI insights unlock
6 = Week recap preview
7 = First weekly recap, transition to regular experience
```

---

## Open Questions

1. **Notification Opt-in Timing:** Should we ask for notification permission during onboarding or wait until Day 1 when we have something valuable to notify about?

2. **Photo Storage:** Day 2 photo prompt—do we have photo storage/display fully working? If not, delay this nudge.

3. **Family Sharing:** Is CloudKit sharing stable enough to promote on Day 3? If not, delay invite prompts.

4. **A/B Testing:** Should we test different nudge timings? (Day 2 vs Day 3 for photo prompt, etc.)

5. **Premium Upsell:** When is earliest appropriate premium mention? Day 7? Day 14? Never in first week?
