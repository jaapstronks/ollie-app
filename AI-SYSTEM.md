# AI System Overview

**AI is the core product differentiator.** Otis is positioned as an AI-powered puppy assistant where personalized guidance based on user data is the primary value proposition.

The AI broker is live at `https://ai.otis.pet`.

## Strategic Context

- **Pricing model:** Premium (€1.99/week, €6.99/mo, or €54.99/yr) with 14-day trial
- **No free tier:** AI costs (~€1.50/user/month) make free unsustainable
- **AI is required:** All users get AI features during trial and as subscribers
- **The moat:** Competitors can copy features, but can't copy user data + AI integration

## Where Users See AI-Generated Content

| Surface | What It Does | Where It Appears |
|---------|--------------|------------------|
| **Training Guidance** | Suggests next skill, session advice, encouragement | Train tab - purple card at top |
| **Potty Analysis** | Personalized potty training insights | Potty Training Guide sheet |
| **Socialization Guidance** | Priority categories, exposure suggestions | Socialization Journey view |
| **Health Insights** | Wellness observations, recommendations | Today view - blue card |
| **Daily Status** | Generates headline/subtitle based on puppy's day | Top of timeline view |
| **Walk Ordering** | Reorders upcoming activities by priority | "Up Next" section |
| **Logging Recommendations** | Suggests reducing notification frequency | Card on timeline |
| **Notification Timing** | Adjusts potty/walk reminder timing | Push notifications (timing only) |

## UI Components

| Component | File | Color |
|-----------|------|-------|
| `AITrainingGuidanceCard` | `Views/Training/AITrainingGuidanceCard.swift` | Purple |
| `AIPottyAnalysisCard` | `Views/AI/AIPottyAnalysisCard.swift` | Green |
| `AISocializationGuidanceCard` | `Views/AI/AISocializationGuidanceCard.swift` | Pink |
| `AIHealthInsightsCard` | `Views/AI/AIHealthInsightsCard.swift` | Blue |

Cards automatically hide when:
- AI is unavailable (not enabled, user not in rollout, no subscription)
- Request fails or times out
- No meaningful content to display

## Rollout Configuration

AI features are gated by rollout settings in `AINudgeRollout`:

| Setting | Production | Beta |
|---------|------------|------|
| Enabled | Yes | Yes |
| Rollout % | 100% | 100% |
| Shadow Mode | No | No |

**With premium AI model:** All trial and paid users get AI. Rollout is now 100%.

**Shadow mode** means AI runs and makes decisions, but those decisions are logged instead of applied. Use this only for testing new prompts before deployment.

**For trial users:** Full AI access during 14-day trial to demonstrate value.
**For paid users:** Full AI access as part of subscription.
**For expired trials:** AI features disabled until subscription starts.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App                               │
├─────────────────────────────────────────────────────────────┤
│  Views → AI Cards → AI.request...() → AIOrchestrator        │
│                              │                               │
│                    ┌─────────┴─────────┐                    │
│                    │ AIContextBuilder  │                    │
│                    │ (modular context) │                    │
│                    └───────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              AI Broker (ai.otis.pet)                        │
├─────────────────────────────────────────────────────────────┤
│  • Validates requests (Zod schemas)                         │
│  • Routes to LLM provider (Anthropic/Mistral)               │
│  • Normalizes LLM output                                    │
│  • Logs usage for cost tracking                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    LLM Provider                              │
│                (Claude Haiku 4.5)                            │
└─────────────────────────────────────────────────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `Services/AI/` | Modular AI system (6 surfaces, typed responses) |
| `Services/AI/AI.swift` | Main entry point with convenience methods |
| `Services/AI/AISurfaces.swift` | Surface definitions and response types |
| `Views/AI/` | AI card components |
| `Services/AINudgeOrchestrator.swift` | Legacy orchestrator (insight_bundle, notification_policy) |
| `Services/AINudgesModels.swift` | Request/response models + rollout config |

## AI Surfaces

### New System (with UI cards)
- `training_guidance` - Training session planning → `AITrainingGuidanceCard`
- `potty_analysis` - Potty training insights → `AIPottyAnalysisCard`
- `socialization_guidance` - Socialization tips → `AISocializationGuidanceCard`
- `health_insights` - Wellness observations → `AIHealthInsightsCard`

### Legacy System (inline application)
- `insight_bundle` - Daily status, walk ordering, logging recommendations
- `notification_policy` - Notification timing adjustments

## Daily Limits & Cost Management

To control costs, each surface has per-profile daily budgets:

| Surface | Daily Limit | Cache Hours | Est. Cost/Call |
|---------|-------------|-------------|----------------|
| Training guidance | 6 | 4 | $0.002-0.005 |
| Potty analysis | 4 | 6 | $0.002-0.005 |
| Socialization guidance | 2 | 12 | $0.002-0.005 |
| Health insights | 2 | 12 | $0.002-0.005 |
| Insight bundle | 4 | 1 | $0.003-0.008 |
| Notification policy | 6 | 1 | $0.001-0.003 |

**Cost estimation per user:**
- Active user (logs daily): ~$1.00-1.50/month
- Light user (logs few times/week): ~$0.30-0.60/month
- Average across all users: ~$1.00-1.50/month

**Cost controls:**
1. **Caching:** Results cached 1-12 hours to minimize redundant calls
2. **Daily limits:** Hard caps prevent runaway costs
3. **Batch optimization:** Multiple surfaces can share context when requested together
4. **Model selection:** Using Haiku for cost efficiency while maintaining quality

**Unit economics by tier:**

| Tier | Price | After Apple | AI Cost | Margin | Margin % |
|------|-------|-------------|---------|--------|----------|
| Weekly | €1.99/wk (€8.62/mo) | €6.03/mo | €1.50 | €4.53 | 75% |
| Monthly | €6.99/mo | €4.89/mo | €1.50 | €3.39 | 49% |
| Annual | €54.99/yr (€4.58/mo) | €3.21/mo | €1.50* | €1.71+ | 35%+ |

*Annual users typically reduce AI usage after 3-6 months as puppy matures, lowering effective AI cost.

**Pricing psychology:**
- Weekly serves as anchor (makes monthly look smart)
- Monthly is the default choice for most users
- Annual offers best value and locks in retention (34% off monthly)

## Debug Controls

In Settings → Debug → AI Testing:
- Test individual AI surfaces
- Toggle shadow mode
- Clear cache
- View raw AI responses
- **View Interaction Log** - Review all AI interactions with full context

## Interaction Log & Export

All AI interactions are automatically logged for review and prompt improvement. Each log entry includes:
- Full context sent to AI (profile data, events summary)
- System prompt and output format
- AI response
- Provider, model, latency, confidence

**To export logs for prompt improvement:**
1. Settings → Debug → AI Testing → "View Interaction Log"
2. Tap "Export Full Log (JSON)" to share the complete log file
3. Or tap "Copy Summary to Clipboard" for a quick overview

**To add feedback to an interaction:**
1. Tap any interaction in the log
2. Select a rating (Helpful, Not Helpful, Wrong, Too Wordy, Missing Context)
3. Add an optional comment explaining why (e.g., "we trained with kibble, didn't log as meal")
4. Submit feedback - it will be included in exports

This feedback loop lets you collect real examples of good/bad AI responses with full context, which you can then use to improve prompts.

## Broker Deployment

The broker runs on Hetzner VPS with Caddy for TLS. To restart:

```bash
ssh user@204.168.144.71
cd ~/apps/ollie-app/ai-broker-server
docker compose -f docker-compose.prod.yml up -d --build --force-recreate
```

Health check: `curl https://ai.otis.pet/health`
