# Ollie AI Broker Worker

Vendor-agnostic AI relay for paid nudges in Ollie.

## What it does

- Accepts app requests at `POST /ai/nudges/decide`
- Validates request shape
- Routes to Anthropic and/or Mistral based on `providerPolicy`
- Supports provider failover
- Validates decision schema before returning
- Logs usage and estimated cost to D1

## Why this exists

- Keep provider API keys off-device
- Avoid lock-in with a stable app-facing contract
- Centralize guardrails and schema validation
- Track token usage and cost per user/surface

## Endpoints

- `GET /health`
- `POST /ai/nudges/decide`

## Required bindings/secrets

- `BROKER_API_KEY` (required)
- `ANTHROPIC_API_KEY` (optional, but needed for Anthropic route)
- `MISTRAL_API_KEY` (optional, but needed for Mistral route)
- `ANTHROPIC_MODEL` (optional)
- `MISTRAL_MODEL` (optional)
- `DB` D1 binding (recommended for analytics/cost logging)

## Local development

```bash
cd ai-broker-worker
npm install
npm run dev
```

Set secrets:

```bash
wrangler secret put BROKER_API_KEY
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put MISTRAL_API_KEY
```

## D1 setup

```bash
npm run db:create
# copy generated database_id into wrangler.toml
npm run db:init
```

## Deploy

```bash
npm run deploy
```

## Integration checklist (app side)

1. Set `ai.nudges.brokerBaseURL` in app runtime config/UserDefaults.
2. Add `X-API-Key` and user identity header in broker client.
3. Keep app fallback deterministic if broker returns error/timeouts.
4. Monitor D1 `ai_requests` table for call volume and cost.
