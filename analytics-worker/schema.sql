-- Otis Analytics Database Schema
-- Cloudflare D1 (SQLite)

-- events table
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    event_name TEXT NOT NULL,
    event_data TEXT,  -- JSON for flexible properties
    app_version TEXT,
    ios_version TEXT,
    device_model TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_events_device ON events(device_id);
CREATE INDEX IF NOT EXISTS idx_events_name ON events(event_name);
CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at);
CREATE INDEX IF NOT EXISTS idx_events_device_name ON events(device_id, event_name);
