# Localization Architecture Cleanup

Track progress on cleaning up the localization infrastructure. Work in small batches with verification after each.

## Current Status

| Metric | Start | Current | Target |
|--------|-------|---------|--------|
| Localizable.xcstrings | 3,744 | **959** | <100 |
| Duplicate strings | ~2,600 | **0** | 0 |
| String(localized:) without table | ~40 | 0 | 0 |

**Last updated:** 2026-03-10

---

## How to Work on This

### Before Starting Any Task
1. Pull latest changes
2. Run build to confirm clean state: `xcodebuild -scheme Ollie-app -destination 'platform=iOS Simulator,name=iPhone 17' build`

### After Completing Any Task
1. Run build to verify no errors
2. Update the checkbox in this file
3. Update "Current" numbers in the status table above
4. Update "Last updated" date
5. Commit changes with message: `chore(i18n): [task description]`

### If You Get Interrupted
- Commit whatever is complete
- Add a note under the task about what's left
- Don't leave uncommitted localization changes

---

## Batch 1: Fix Strings+Memories.swift (7 strings) ✅
**Estimate: 15-20 minutes**

### Steps
- [x] Create `Ollie-app/Memories.xcstrings` with these strings (copy from Localizable.xcstrings):
  - "1 week ago"
  - "1 month ago"
  - "1 year ago"
  - "On this day"
  - "No events recorded"
  - "Syncing..."
  - "+%lld more"

- [x] Update `Ollie-app/Utils/Strings/Strings+Memories.swift`:
  - Add `private let table = "Memories"` at top
  - Add `table: table` to all String(localized:) calls

- [x] Remove the 7 strings from Localizable.xcstrings

- [x] Build and verify

### Verification
```bash
# Should show 0 results for this file
grep -n 'String(localized:' Ollie-app/Utils/Strings/Strings+Memories.swift | grep -v 'table:'
```

---

## Batch 2: Fix Strings+AppointmentNudge.swift (12 strings) ✅
**Estimate: 20-25 minutes**

### Steps
- [x] Create `Ollie-app/AppointmentNudge.xcstrings` with these strings (copy from Localizable.xcstrings):
  - "While %@ naps..."
  - "%@ is overdue"
  - "Time to schedule %@"
  - "%lld day(s) overdue — schedule soon"
  - "Due tomorrow — book an appointment"
  - "Due in %lld days — book an appointment"
  - "Due in %lld days — good time to schedule"
  - "Due in ~%lld weeks — plan ahead"
  - "Schedule"
  - "Remind me later"
  - "Already done"
  - "Call %@"

- [x] Update `Ollie-app/Utils/Strings/Strings+AppointmentNudge.swift`:
  - Add `private let table = "AppointmentNudge"` at top
  - Add `table: table` to all String(localized:) calls

- [x] Remove these strings from Localizable.xcstrings

- [x] Build and verify

### Verification
```bash
grep -n 'String(localized:' Ollie-app/Utils/Strings/Strings+AppointmentNudge.swift | grep -v 'table:'
```

---

## Batch 3: Fix CalendarService.swift (4 strings) ✅
**Estimate: 15 minutes**

These are error messages that should go in an existing domain.

### Steps
- [x] Add these strings to `Ollie-app/Calendar.xcstrings`:
  - "Calendar access denied. Please enable calendar access in Settings."
  - "Invalid milestone date."
  - "Failed to save event: %@"
  - "Failed to remove event: %@"

- [x] Add constants to `Ollie-app/Utils/Strings/Strings+Calendar.swift`:
  ```swift
  // Errors
  static let errorAccessDenied = String(localized: "Calendar access denied. Please enable calendar access in Settings.", table: table)
  static let errorInvalidDate = String(localized: "Invalid milestone date.", table: table)
  static func errorSaveFailed(_ error: String) -> String {
      String(localized: "Failed to save event: \(error)", table: table)
  }
  static func errorRemoveFailed(_ error: String) -> String {
      String(localized: "Failed to remove event: \(error)", table: table)
  }
  ```

- [x] Update `Ollie-app/Services/CalendarService.swift` to use Strings.Calendar constants

- [x] Remove these strings from Localizable.xcstrings

- [x] Build and verify

---

## Batch 4: Create Behavior.xcstrings Domain ⏭️ SKIPPED
**Reason:** After analysis, the "behavior" related strings are all training content (training tips, mistakes to avoid, etc.) and would fit better in Training.xcstrings rather than a separate Behavior domain. The strings found are long descriptive texts about training behaviors, not UI elements.

**Decision:** No new Behavior domain needed. If these strings need migration, they should go to Training.xcstrings.

---

## Batch 5: Audit Remaining Localizable.xcstrings ✅
**Estimate: 30 minutes** (analysis only)

### Results (2026-03-10)

**Remaining strings: 1,351**

Category breakdown:
- **Training:** 278 strings (training tips, skill descriptions, common mistakes)
- **Misc Short (<50 chars):** 845 strings (many format strings like "%@", UI labels)
- **Timeline:** 79 strings
- **Misc Long (≥50 chars):** 69 strings
- **Health:** 64 strings
- **Socialization:** 16 strings

**Key finding:** Zero duplicates between Localizable.xcstrings and domain files. All 1,351 strings are unique.

**Core goal achieved:** `String(localized:) without table` is now **0** ✅

---

## Future Work (Optional)

The remaining 959 strings in Localizable.xcstrings work fine but aren't organized by domain. This is **lower priority** since the core architecture goal is achieved.

### Batch 6: Migrate Training Strings (245 strings) ✅
The largest category. Training tips, skill descriptions, and common mistakes.

**Completed:** Moved 245 strings to Training.xcstrings. Removed 1 duplicate ("sessions" conflicted with "Sessions").

### Batch 7: Migrate Timeline Strings (76 strings) ✅
Event logging, import/export, and history strings.

**Completed:** Moved 76 strings to Timeline.xcstrings. Removed 3 symbol collisions.

### Batch 8: Migrate Health Strings (71 strings) ✅
Vet, medication, and wellness strings.

**Completed:** Moved 71 strings to Health.xcstrings. Removed 1 symbol collision.

### Batch 9: Migrate Socialization Strings (16 strings)
Social exposure and confidence tracking strings.

### Batch 10: Clean Up Misc Strings (845 short + 69 long)
Review remaining strings and either:
- Migrate to appropriate domains
- Keep in Localizable.xcstrings if truly generic (like "%@")
- Remove if unused

---

## Completed Batches

### ✅ Batches 6-8 (2026-03-10)
- **Batch 6:** Migrated 245 training strings to Training.xcstrings (353 → 597)
- **Batch 7:** Migrated 76 timeline strings to Timeline.xcstrings (202 → 275)
- **Batch 8:** Migrated 71 health strings to Health.xcstrings (44 → 114)
- Removed 5 symbol collisions (case variants like "sessions" vs "Sessions")
- **Result:** Localizable.xcstrings reduced from 1,351 → **959** strings

### ✅ Batches 1-3, 5 (2026-03-10)
- **Batch 1:** Created Memories.xcstrings (7 strings), fixed Strings+Memories.swift
- **Batch 2:** Created AppointmentNudge.xcstrings (12 strings), fixed Strings+AppointmentNudge.swift
- **Batch 3:** Moved 4 error strings to Calendar.xcstrings, fixed CalendarService.swift
- **Batch 5:** Audited remaining 1,351 strings, documented categories and next steps
- **Result:** `String(localized:) without table` reduced from 24 → **0** ✅

### ✅ Initial Cleanup (2026-03-10)
- Fixed Strings+Misc.swift table references (29 strings)
- Created Likes.xcstrings domain (10 strings)
- Fixed inline String(localized:) in 7 view files (16 strings)
- Removed 2,323 duplicate strings from Localizable.xcstrings

---

## Reference

### Python Script: Move Strings Between xcstrings Files

```python
import json

def move_strings(strings_to_move, source_file, dest_file):
    """Move strings from source to destination xcstrings file."""
    with open(source_file, 'r') as f:
        source = json.load(f)

    with open(dest_file, 'r') as f:
        dest = json.load(f)

    moved = 0
    for s in strings_to_move:
        if s in source['strings']:
            dest['strings'][s] = source['strings'][s]
            del source['strings'][s]
            moved += 1

    dest['strings'] = dict(sorted(dest['strings'].items()))
    source['strings'] = dict(sorted(source['strings'].items()))

    with open(source_file, 'w') as f:
        json.dump(source, f, indent=2, ensure_ascii=False)

    with open(dest_file, 'w') as f:
        json.dump(dest, f, indent=2, ensure_ascii=False)

    print(f"Moved {moved} strings")

# Example usage:
# move_strings(
#     ["String 1", "String 2"],
#     "Ollie-app/Localizable.xcstrings",
#     "Ollie-app/NewDomain.xcstrings"
# )
```

### Python Script: Create New xcstrings File

```python
import json

def create_xcstrings(filename, strings_from_localizable):
    """Create new xcstrings file with strings from Localizable.

    IMPORTANT: This preserves translations! The localizations dict
    is copied along with each string.
    """
    with open('Ollie-app/Localizable.xcstrings', 'r') as f:
        localizable = json.load(f)

    new_file = {
        "sourceLanguage": "en",
        "strings": {},
        "version": "1.0"
    }

    for s in strings_from_localizable:
        if s in localizable['strings']:
            # Copy the entire string entry INCLUDING localizations
            new_file['strings'][s] = localizable['strings'][s]
            new_file['strings'][s]['extractionState'] = 'manual'

    new_file['strings'] = dict(sorted(new_file['strings'].items()))

    with open(f'Ollie-app/{filename}.xcstrings', 'w') as f:
        json.dump(new_file, f, indent=2, ensure_ascii=False)

    # Verify translations were preserved
    for s, data in new_file['strings'].items():
        langs = list(data.get('localizations', {}).keys())
        if not langs:
            print(f"  WARNING: '{s}' has no translations!")
        else:
            print(f"  '{s}': {langs}")

    print(f"\nCreated {filename}.xcstrings with {len(new_file['strings'])} strings")

# Example:
# create_xcstrings("Memories", ["1 week ago", "1 month ago", ...])
```

> **Note:** Always verify translations are present after creating a new xcstrings file.
> The `localizations` dict must be copied, not just the string key.

### Quick Check Commands

```bash
# Count strings in Localizable.xcstrings
jq '.strings | keys | length' Ollie-app/Localizable.xcstrings

# Find String(localized:) without table parameter
grep -rn 'String(localized:' Ollie-app --include="*.swift" | grep -v 'table:' | grep -v '\.build/'

# Check for duplicates between Localizable and a domain file
python3 -c "
import json
with open('Ollie-app/Localizable.xcstrings') as f: loc = set(json.load(f)['strings'].keys())
with open('Ollie-app/DOMAIN.xcstrings') as f: dom = set(json.load(f)['strings'].keys())
print(f'Duplicates: {len(loc & dom)}')"

# Build verification
xcodebuild -scheme Ollie-app -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -5
```
