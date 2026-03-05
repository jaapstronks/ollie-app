# AI Broker Server (VPS/Docker)

Self-hosted AI broker for Ollie paid nudges.

## Why this exists

- Keep Anthropic/Mistral API keys off-device
- Route and fail over between providers
- Enforce schema/policy centrally
- Log token usage and estimated cost for pricing analytics

## Endpoints

- `GET /health`
- `POST /ai/nudges/decide`

## Auth

- Require `X-API-Key` header to match `BROKER_API_KEY`
- Optional `X-User-Id` header is captured in logs for analytics

## Quick start (local)

```bash
cd ai-broker-server
cp .env.example .env
npm install
npm run dev
```

## Docker (recommended on Scaleway VPS)

```bash
cd ai-broker-server
cp .env.example .env
# Fill secrets in .env first
docker compose up -d --build
```

Health check:

```bash
curl http://localhost:8787/health
```

## Key storage guidance

- Keep secrets in `ai-broker-server/.env` on the VPS only.
- Do not commit real `.env` files to git.
- Commit `.env.example` only (already included).
- For production hardening, use Docker secrets or your VPS secret manager.

## App wiring

In the iOS app runtime config (`UserDefaults` or remote config), set:

- `ai.nudges.brokerBaseURL=https://your-domain-or-ip`
- `ai.nudges.brokerApiKey=<BROKER_API_KEY>`

The app already sends this key in `X-API-Key`.

## Reverse proxy and TLS

You should put Nginx/Caddy in front of this container and terminate TLS there.
Then expose only `443` publicly.

## Logs and cost estimation

- Logs are JSONL at `/var/log/ollie-ai-broker/requests.jsonl`
- Includes:
  - provider/model used
  - input/output tokens
  - estimated cost
  - latency
  - status/failure reason
