CREATE TABLE IF NOT EXISTS ai_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  request_id TEXT NOT NULL,
  user_id TEXT,
  profile_id TEXT NOT NULL,
  surface TEXT NOT NULL,
  provider_used TEXT,
  model_used TEXT,
  status TEXT NOT NULL,
  failure_reason TEXT,
  latency_ms INTEGER,
  input_tokens INTEGER,
  output_tokens INTEGER,
  estimated_cost_usd REAL,
  shadow_mode INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_ai_requests_created_at ON ai_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_requests_surface ON ai_requests(surface);
CREATE INDEX IF NOT EXISTS idx_ai_requests_profile ON ai_requests(profile_id);
