# TODO: Import Existing Data from Web App

Import Ollie's existing event data from the web app's GitHub repo into the iOS app.

## Approach

The web app stores data as public JSONL files at:
`https://raw.githubusercontent.com/jaapstronks/Ollie/main/data/YYYY-MM-DD.jsonl`

### Step 1: Data Import Service

Create `Services/DataImporter.swift`:

```swift
class DataImporter {
    /// Fetches all available JSONL files from the Ollie web repo
    /// 1. List files via GitHub API: GET /repos/jaapstronks/Ollie/contents/data
    /// 2. Filter for *.jsonl files
    /// 3. Download each raw file
    /// 4. Write to local documents/data/ directory
    /// 5. Skip files that already exist locally (don't overwrite)
    func importFromGitHub() async throws -> ImportResult
}

struct ImportResult {
    var filesImported: Int
    var eventsImported: Int
    var skipped: Int
}
```

### Step 2: Settings Screen Entry Point

Add to settings/profile screen:
- "Importeer data" button
- Shows progress ("12/14 dagen geïmporteerd...")
- Success message with count
- Only shown if GitHub repo URL is configured (hardcoded for now, configurable later)

### Step 3: Conflict Handling

Keep it simple:
- If local file exists for a date → skip (local wins)
- If local file doesn't exist → import
- Optional: "Overschrijf alles" toggle for full re-import

### Future: Two-Way GitHub Sync

Not for now, but the architecture should not block this later:
- App pushes new events to repo via GitHub API (needs PAT)
- Web app and iOS app share the same data
- Conflict resolution: merge by timestamp (events are append-only)

This is a separate TODO when the time comes.

## Done Criteria
- [ ] Can import all existing data from GitHub repo
- [ ] Import shows progress
- [ ] Doesn't overwrite existing local data
- [ ] Imported events show up in timeline immediately
- [ ] Works offline after initial import (data is local)

Delete this file when done.
