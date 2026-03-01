# Otis Analytics Worker

Minimal, privacy-respecting analytics backend using Cloudflare Workers + D1 (SQLite).

## Setup

### 1. Install Wrangler CLI

```bash
npm install -g wrangler
wrangler login
```

### 2. Create D1 Database

```bash
cd analytics-worker
npm install
npm run db:create
```

Copy the `database_id` from the output and paste it into `wrangler.toml`.

### 3. Initialize Database Schema

```bash
npm run db:init
```

### 4. Set API Key

```bash
wrangler secret put API_KEY
# Enter a random key like: otis_ak_xxxxxxxxxxxxxx
```

### 5. Deploy

```bash
npm run deploy
```

Note the deployed URL (e.g., `https://otis-analytics.YOUR_SUBDOMAIN.workers.dev`)

### 6. Update iOS App

Edit `Otis-app/Services/OtisAnalytics.swift`:

```swift
private let endpoint = URL(string: "https://otis-analytics.YOUR_SUBDOMAIN.workers.dev/events")!
private let apiKey = "YOUR_API_KEY"
```

## Usage

### Tracked Events

| Event | Properties | When |
|-------|------------|------|
| `app_launch` | - | App opened |
| `event_logged` | `event_type`, `has_location`, `has_note`, `has_photo` | User logs puppy event |

### Query Stats

```bash
# Via CLI
wrangler d1 execute otis-analytics --command "SELECT COUNT(*) FROM events"

# Via API
curl -H "X-API-Key: YOUR_KEY" https://otis-analytics.YOUR_SUBDOMAIN.workers.dev/stats?period=7d
```

### Common Queries

```sql
-- Daily Active Users
SELECT date(created_at) as day, COUNT(DISTINCT device_id) as dau
FROM events
WHERE event_name = 'app_launch'
  AND created_at >= datetime('now', '-30 days')
GROUP BY day ORDER BY day;

-- Events by type
SELECT json_extract(event_data, '$.event_type') as type, COUNT(*) as count
FROM events
WHERE event_name = 'event_logged'
GROUP BY type ORDER BY count DESC;

-- App version distribution
SELECT app_version, COUNT(DISTINCT device_id) as users
FROM events
WHERE event_name = 'app_launch'
  AND created_at >= datetime('now', '-7 days')
GROUP BY app_version ORDER BY users DESC;
```

## Cost

All within Cloudflare's free tier:
- Workers: 100k req/day (expected: ~100/day)
- D1: 5GB storage, 5M reads/day (expected: <100MB, ~1k/day)
