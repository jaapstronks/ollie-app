# AI Broker Setup Briefing

Date: 2026-03-05  
Project: Ollie iOS app (AI nudges backend relay)  
Prepared for: resume-later handoff

## 1) Goal

Stand up a production-ready, self-hosted AI broker for subtle paid-user AI nudges (no chat UI), with:

- Vendor interoperability (`Anthropic`, `Mistral`)
- Broker-mediated provider access (provider keys stay server-side)
- HTTPS domain endpoint for app use
- Request validation, structured JSON decisions, and logging

---

## 2) Current Live Environment

- VPS provider: Hetzner
- Server public IP: `204.168.144.71`
- Broker domain: `ai.otis.pet`
- TLS: active via Let's Encrypt (Caddy)
- Health endpoint: `https://ai.otis.pet/health` returns OK

Verified successful response:

```json
{"ok":true,"service":"ollie-ai-broker"}
```

---

## 3) Architecture Implemented So Far

### App side (iOS)

- App prepares compact context/payload for two AI surfaces:
  - `insight_bundle`
  - `notification_policy`
- App sends request to broker over HTTPS with broker auth header.
- App consumes structured JSON decisions and falls back deterministically on failures.
- AI controls are exposed in `DebugSection` for testing:
  - enable/disable
  - shadow mode
  - rollout %
  - broker URL
  - broker API key
  - health test button

### Broker side (VPS)

- Stack: Node.js + Fastify + TypeScript + Zod
- Endpoint: `POST /ai/nudges/decide`
- Health: `GET /health`
- Provider routing and failover logic
- Strict request schema validation
- Structured response validation
- Usage/cost logging to JSONL

### Edge/proxy

- Caddy in front of broker
- Auto TLS cert management
- HTTP to HTTPS redirect
- Security headers enabled

---

## 4) Repository Changes Added

### New/updated broker deployment files

- `ai-broker-server/Caddyfile`
- `ai-broker-server/docker-compose.prod.yml`
- `ai-broker-server/README.md` (production HTTPS instructions)
- `ai-broker-server/.env.example` updated with `BROKER_DOMAIN=ai.otis.pet`

### App defaults improvements

- `Ollie-app/Services/AINudgesModels.swift`
  - Added `AINudgeRollout.registerDefaults()`
  - Default broker URL: `https://ai.otis.pet`
  - Default caps + rollout/shadow defaults
- `Ollie-app/Otis_appApp.swift`
  - Calls `AINudgeRollout.registerDefaults()` at startup
- `Ollie-app/Views/Settings/DebugSection.swift`
  - Broker URL field prefilled with `https://ai.otis.pet`

---

## 5) Deployment Steps Completed

1. DNS record created for `ai.otis.pet` -> `204.168.144.71`
2. Repo pulled on VPS
3. Broker + Caddy started via:
   - `docker compose -f docker-compose.prod.yml up -d --build`
4. HTTPS certificate issued automatically by Caddy/Let's Encrypt
5. Health check validated over HTTPS
6. Functional broker requests validated

---

## 6) Key Issues Encountered and Resolved

1. Unauthorized broker calls
   - Cause: placeholder/incorrect `BROKER_API_KEY` in `.env`
   - Fix: set real key in VPS `.env`, recreate containers

2. `.env.example` missing in one VPS state
   - Cause: file mismatch on server state vs local expectation
   - Fix: manually created `.env` and proceeded

3. Localhost broker curl confusion (`127.0.0.1:8787`)
   - Cause: prod compose exposes broker only to internal Docker network (`expose`, not host `ports`)
   - Fix: test via HTTPS domain through Caddy

4. Anthropic model not found (404)
   - Cause: invalid model id (`claude-3-5-haiku-latest`) for account
   - Fix: switched to account-available model id:
     - `claude-haiku-4-5-20251001`

5. Payload validation errors during manual curl
   - Cause: malformed test JSON / wrong schema fields
   - Fix: used request body matching broker Zod schema

---

## 7) Verified Working State

- Domain + TLS: working
- Broker service: running
- Caddy reverse proxy: running
- Anthropic path: confirmed successful through broker
- Example successful response included:
  - `providerUsed: "anthropic"`
  - `modelUsed: "claude-haiku-4-5-20251001"`
  - valid `notificationPolicyDecision` payload

---

## 8) Security Notes

Important:

- Any API keys shown in terminal/chat history should be rotated.
- Keep all real secrets only in VPS `ai-broker-server/.env`.
- Never commit real `.env`.

Recommended immediate hygiene:

1. Rotate `BROKER_API_KEY`
2. Rotate provider keys if exposed during debugging
3. Recreate containers after key rotation:
   - `docker compose -f docker-compose.prod.yml up -d --build --force-recreate`

---

## 9) What Is Debug-Only vs Production

Current debug menu key entry is intentional for testing.  
This is not the final production authentication model.

### Production direction

- End users should never manually enter broker keys.
- Do not ship a static long-lived broker secret in app binary.
- Move to short-lived server-issued auth tokens (JWT/session-backed).
- Keep debug controls behind `#if DEBUG` only.

---

## 10) Next Steps (Resume Checklist)

### A. Finish production auth hardening

- Add token issuance flow (backend-authenticated short-lived token)
- Broker validates token instead of static shared app key
- Optional: add App Attest / DeviceCheck

### B. Improve broker robustness ✅ DONE

- ✅ Added tolerant normalization layer for slightly malformed LLM JSON before strict validation
  - Handles: trailing commas, single quotes, unquoted keys, JS comments, NaN/Infinity, control chars
  - Normalizes field types: string→number, string→boolean, null→defaults
  - Logs `wasNormalized` flag for observability
  - Adds `output_normalized` tag to response reasoningTags when normalization was applied
- ✅ Strict outbound schema validation preserved (Zod validation after normalization)
- ✅ Unit tests added (`npm test` - 16 passing tests)

### C. Add observability endpoint

- Implement simple broker `/stats` endpoint (daily per-user calls/tokens/cost summary)

### D. App rollout

- Keep `shadowMode` on initially
- Start with low rollout % for paid users
- Evaluate decision quality + cost
- Gradually increase rollout and then disable shadow mode

---

## 11) Useful Commands (Quick Runbook)

From VPS broker folder:

```bash
cd ~/apps/ollie-app/ai-broker-server
```

Check services:

```bash
docker compose -f docker-compose.prod.yml ps
```

Restart with latest env/code:

```bash
docker compose -f docker-compose.prod.yml up -d --build --force-recreate
```

Health check:

```bash
curl -sS https://ai.otis.pet/health
```

Tail logs:

```bash
docker logs --tail 120 ollie-ai-broker
docker logs --tail 120 ollie-ai-broker-caddy
```

Check key variables exist (do not share values):

```bash
rg '^(BROKER_API_KEY|ANTHROPIC_API_KEY|MISTRAL_API_KEY|ANTHROPIC_MODEL|MISTRAL_MODEL)=' .env
```

---

## 12) One-Line Status

Infrastructure and Anthropic-backed broker path are live and verified at `https://ai.otis.pet`; remaining work is production auth hardening and staged rollout polish.
