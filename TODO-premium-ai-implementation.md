# Premium AI Model Implementation Tasks

> Created: 2026-03-06
> Delete this file when all tasks are complete.

This document tracks the implementation work needed to support the new premium AI pricing model.

---

## Pricing & Subscription Changes

### App Store Connect
- [ ] Create new subscription products:
  - Monthly: €5.99/mo (replace €2.99)
  - Yearly: €49.99/yr (replace €24.99)
- [ ] Update subscription group name to reflect AI positioning
- [ ] Create 14-day free trial offer
- [ ] Deprecate old pricing (grandfather existing subscribers at old rate?)

### In-App Changes
- [ ] Update `SubscriptionManager.swift` with new product IDs
- [ ] Update paywall copy to emphasize AI value
- [ ] Update `OtisPlusSheet.swift` with new pricing display
- [ ] Implement trial expiry logic (block app after 14 days if not subscribed)

---

## Trial Experience (Critical Path)

### Trial Start
- [ ] Auto-start trial on first launch (no opt-in required?)
- [ ] Or: Prominent "Start 14-Day Trial" after onboarding
- [ ] Store trial start date locally + in CloudKit
- [ ] Show trial days remaining in app (subtle but visible)

### Trial Value Demonstration
- [ ] Day 1: Show AI insight within first session
  - "Based on [Puppy]'s age, focus on: [AI recommendation]"
- [ ] Day 3: Push notification with AI insight
  - "Luna's potty pattern is emerging: [insight]"
- [ ] Day 7: In-app card showing AI value summary
  - "This week, AI helped you with: X training tips, Y potty predictions"
- [ ] Day 12: Trial ending notification
  - "2 days left — keep your personalized AI coach?"

### Trial Expiry
- [ ] Day 14: Clear conversion moment
  - Show what features will be lost
  - Easy path to subscribe
- [ ] Post-expiry state:
  - App opens but core features locked
  - Clear "Subscribe to continue" messaging
  - Allow viewing historical data? (decision needed)

---

## AI Visibility Improvements

### "AI Did This" Indicators
- [ ] Add subtle "AI" badge to AI-generated content
- [ ] Add "Personalized for [Puppy]" labels
- [ ] Consider: "Based on X events logged" context

### First-Run AI Experience
- [ ] Onboarding step: "Otis learns your puppy"
  - Explain how AI personalization works
  - Set expectation that value grows over time
- [ ] First AI card: More prominent, explain what it means
- [ ] "AI is learning..." state for users with < 10 events

### AI Quality Feedback
- [ ] Easy thumbs up/down on AI cards
- [ ] Feed back into interaction log for improvement

---

## Paywall & Conversion UX

### Updated Paywall
- [ ] Lead with AI value proposition:
  - "Your AI Puppy Coach"
  - "Personalized guidance based on [Puppy]'s data"
- [ ] Show what AI has already done (if in trial)
- [ ] Social proof: "Join X puppy parents using AI guidance"

### Pricing Display
- [ ] Monthly: €5.99/month
- [ ] Yearly: €49.99/year (save 30%)
- [ ] Emphasize annual as default/recommended
- [ ] Show monthly equivalent for annual (€4.17/mo)

### Trial Conversion Flow
- [ ] Clear "Your trial ends in X days" messaging
- [ ] Day 14: Full-screen conversion prompt (not annoying popup)
- [ ] Post-trial: Locked state with clear subscribe CTA

---

## Remove Free Tier Artifacts

### Code Changes
- [ ] Remove free tier feature gates (everything is trial or paid now)
- [ ] Simplify `EntitlementManager` — only two states: trial/paid or expired
- [ ] Remove "upgrade to premium" CTAs that imply free features exist
- [ ] Update onboarding to reflect trial model

### Copy Changes
- [ ] Remove "free forever" messaging
- [ ] Update App Store description
- [ ] Update all "unlock premium" to "continue with Otis"

---

## App Store Positioning

### Screenshots (6 required)
1. "Your AI Puppy Coach" — hero shot with AI card
2. "Personalized Training Guidance" — AI training card
3. "Smart Potty Insights" — AI potty analysis
4. "Track Everything" — timeline view
5. "Apple Watch" — quick log from wrist
6. "See Your Progress" — insights/stats

### Description
```
Otis is your AI-powered puppy coach that learns your puppy and guides you through the chaos.

Unlike generic training apps, Otis analyzes YOUR puppy's actual data — potty patterns, sleep schedule, training progress — to give personalized guidance that's actually relevant.

✦ AI Training Guidance — Know what to train next based on your progress
✦ Smart Potty Predictions — AI-powered timing based on your puppy's patterns
✦ Personalized Health Insights — Observations from your daily logs
✦ Apple Watch & Widgets — Log from anywhere

Start your 14-day free trial and see why personalized AI guidance beats generic advice.

€5.99/month or €49.99/year (save 30%)
```

### Keywords
```
ai,puppy,coach,training,personalized,tracker,smart,assistant,dog,potty,predictions
```

---

## Analytics & Monitoring

### New Metrics to Track
- [ ] Trial start rate (% of downloads)
- [ ] Trial→paid conversion rate (THE key metric)
- [ ] Day-by-day retention during trial
- [ ] AI feature usage during trial
- [ ] Conversion by AI usage (do heavy AI users convert better?)

### RevenueCat Events
- [ ] Trial started
- [ ] Trial converted
- [ ] Trial expired (no conversion)
- [ ] Subscription renewed
- [ ] Subscription churned

### AI Cost Monitoring
- [ ] Track calls per user per day
- [ ] Track cache hit rate
- [ ] Alert if cost/user exceeds threshold

---

## Migration Plan

### Existing Beta Users
- [ ] Grandfather at current experience until launch
- [ ] Email explaining new model
- [ ] Offer extended trial or discount?

### Existing Subscribers (if any)
- [ ] Honor existing subscriptions at old price
- [ ] Do not force upgrade

### Launch Sequence
1. [ ] Implement all trial logic
2. [ ] Update paywall and pricing
3. [ ] Create new App Store products
4. [ ] Update App Store listing
5. [ ] Submit for review
6. [ ] Launch

---

## Questions to Resolve

1. **Post-trial access:** Can expired trial users still view their data? Or full lockout?
   - Recommendation: Allow viewing history, but no new logging or AI features

2. **Trial extension:** Offer trial extension for users who engage but don't convert?
   - Recommendation: Not initially, but track conversion timing for future iteration

3. **Promo codes:** Mechanism for beta testers, influencers, etc.?
   - Recommendation: App Store promo codes for first 6 months

4. **Family sharing:** Support Apple Family Sharing for subscriptions?
   - Recommendation: Yes, but count as single subscription for AI cost purposes

---

## Priority Order

1. **Week 1:** Trial logic + expiry handling
2. **Week 2:** Paywall update + pricing
3. **Week 3:** AI visibility improvements
4. **Week 4:** App Store listing + screenshots
5. **Week 5:** Testing + soft launch
6. **Week 6:** Full launch

---

*Delete this file when premium AI model is fully launched.*
