# Otis+ Premium Features Analysis

## Philosophy

**Core principle:** Basic daily logging is free. Premium unlocks collaboration, advanced insights, power-user features, and the full Apple ecosystem experience.

**Competitive advantage:** Keep potty predictions and basic scheduling free — this is the core value prop that gets people hooked. Upgrade path is natural when they want to share with partner, go deeper on analytics, or use Watch/Siri.

---

## Final Feature Split

### Free (Otis Basic)

Everything a solo user needs for daily dog management:

| Feature | Description |
|---------|-------------|
| **Daily Event Logging** | Log meals, potty, sleep, walks, training, socialization |
| **Timeline View** | Beautiful chronological view of the day |
| **Potty Predictions** | Smart predictions based on patterns and triggers |
| **Basic Scheduling** | Meal times, basic reminders |
| **Socialization Checklist** | Track socialization milestones |
| **Dog Locations** | Save vet, parks, groomer (up to 10 locations) |
| **Basic Widgets** | Today summary widget |
| **Training Library** | First 10 training skills |
| **Single User** | One account, one dog |

### Otis+ (Premium)

For power users, families, and the full experience:

| Feature | Description | Status |
|---------|-------------|--------|
| **Partner/Family Sharing** | Share dog management with household | ✅ Implemented |
| **Advanced Analytics** | Pattern analysis, behavior insights | ✅ Implemented |
| **Photo/Video Attachments** | Add media to any event | ✅ Implemented |
| **Custom Milestones** | Create your own milestone categories | ✅ Implemented |
| **Milestone Enhancements** | Notes, photos, calendar sync | ✅ Implemented |
| **Full Training Library** | All 30+ training skills | ✅ Implemented |
| **Apple Watch App** | Quick logging from wrist | 🔨 To build |
| **Siri Shortcuts** | "Hey Siri, log potty outside" | 🔨 To build |
| **Advanced Widgets** | Multiple widget sizes, complications | 🔨 To build |
| **Document Storage** | Vet records, vaccinations, insurance | 🔨 To build |
| **Unlimited Locations** | Save unlimited dog-friendly places | 🔨 To build |
| **Weather Integration** | Weather-aware walk suggestions | 🔨 To build |
| **Smart Notifications** | Contextual, customizable reminders | 🔨 To build |
| **Vet Report Export** | Professional PDF summaries | 🔨 To build |
| **Sleep Insights** | Detailed sleep analysis, quality scores | 🔨 To build |
| **Week in Review** | Weekly summary with trends | 🔨 To build |
| **Multi-dog** | Manage 2+ dogs | 🔨 To build |

---

## Implementation Status

### Currently Gated (working)

| Feature | Where Gated | Notes |
|---------|-------------|-------|
| Partner Sharing | CloudKit sync | Free = single user only |
| Advanced Analytics | `HealthTabView.swift:75` | PatternAnalysisCard |
| Photo/Video | `TimelineViewModel+Events.swift:134,143` | Media attachments |
| Custom Milestones | `HealthView.swift:183` | User-created milestones |
| Milestone Enhancements | `MilestoneCompletionSheet.swift:302+` | Notes, photos, calendar |
| Full Training Library | `SubscriptionManager.canAccessSkill(at:)` | Skills 11+ |

### To Implement (priority order)

| Feature | Effort | Value | Priority |
|---------|--------|-------|----------|
| Apple Watch App | High | High | P1 — Major selling point |
| Document Storage | Medium | High | P1 — Real pain point |
| Siri Shortcuts | Medium | Medium | P2 — Power users love this |
| Vet Report PDF | Low | High | P2 — Easy win |
| Smart Notifications | Medium | High | P2 — Daily value |
| Weather Integration | Low | Medium | P3 — Nice to have |
| Sleep Insights | Medium | Medium | P3 — Build on existing data |
| Week in Review | Medium | Medium | P3 — Engagement feature |
| Advanced Widgets | Medium | Medium | P3 — Visibility |
| Multi-dog | High | Medium | P4 — Niche but important |

---

## Pricing Recommendation

### Monthly
- **Otis+:** $4.99/month

### Annual (recommended)
- **Otis+:** $29.99/year (~$2.50/month, 50% savings)

### Lifetime (optional)
- **Otis+ Forever:** $79.99 one-time

**Rationale:**
- Under $5/month is impulse-buy territory
- Annual discount encourages commitment
- Lifetime appeals to "I hate subscriptions" crowd
- Undercuts competitors (Zigzag is $10+/month)

---

## Marketing Copy Updates

### Fix Misleading Descriptions

```swift
// OLD (misleading):
"AI predicts when your puppy needs to go based on patterns"

// NEW (accurate):
"Smart predictions based on your puppy's schedule and triggers"
```

### Otis+ Value Proposition

> **Otis+ unlocks the full experience:**
> Share with your partner, log from your Apple Watch, ask Siri to track events, get smart notifications, store vet documents, and dive deep into your dog's patterns — all with no ads and complete privacy.

---

## Action Items

### Immediate
- [x] Partner sharing gated ✅
- [ ] Update `Strings+OtisPlus.swift` descriptions (remove "AI" claim)
- [ ] Update `OtisPlusSheet` to show accurate feature list
- [ ] Remove unbuilt features from premium UI until implemented

### Near-term (P1-P2)
- [ ] Build Apple Watch app (major differentiator)
- [ ] Build document storage feature
- [ ] Implement Siri Shortcuts
- [ ] Add PDF export to ExportService
- [ ] Build smart notifications system

### Later (P3-P4)
- [ ] Weather integration
- [ ] Sleep insights view
- [ ] Week in review
- [ ] Advanced widgets
- [ ] Multi-dog support

---

*Last updated: March 2026*
