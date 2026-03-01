# Puppy Tracker App — Navigation & Settings Restructuring Briefing

## Context

The app currently has **four main tabs** (Vandaag/Today, Train, Plekken/Places, Inzichten/Insights) and a **Settings screen** accessible via the paw icon. The settings screen has two sections: one for the dog profile ("Puppy Name") and one for app settings.

After reviewing the full app structure, two key problems emerged:

1. **The Otis settings page is overloaded** — it mixes configuration (walk schedule, meal plan) with reference data (contacts, documents, appointments) and health tracking (milestones, medication) in a single scrollable list.
2. **The Insights tab is a grab bag** — it combines pure statistics (potty success rate, sleep, weight) with actionable alerts ("vaccination overdue"), planning items (socialization window), and duplicates content from Train (socialization checklist) and Places (map).

There is also a **missing concept**: there's no dedicated space for forward-looking planning — vet appointments, puppy classes, daycare visits, vaccination schedules, and milestone tracking. These currently live partly in Insights (as "overdue" alerts) and partly in Settings (Appointments), but neither is the right home.

---

## Proposal: 5 Tabs + Simplified Settings

### Tab Structure

| #   | Tab          | Purpose                               | Content                                                                                                                                                                         |
| --- | ------------ | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Today**    | Daily cockpit                         | Timeline (potty/sleep/eat/walk logging), weather, "coming up" schedule, **urgent alerts moved here** (e.g. "vaccination 13d overdue")                                           |
| 2   | **Train**    | Learning & development                | Potty training stats & triggers, skills/commands by week, socialization checklist                                                                                               |
| 3   | **Places**   | Locations & contacts                  | Map with favorite spots, recent moments/photos, place logging, **contacts** (vet, trainer, daycare, etc.). Prominent filter system by place type. See separate workstream below |
| 4   | **Calendar** | **New tab** — planning & appointments | See detailed breakdown below                                                                                                                                                    |
| 5   | **Insights** | Pure statistics & trends              | Potty success graphs, sleep tracking, weight curve, walk history, pee intervals, pattern analysis (premium). No action items, no duplicates                                     |

### New: Calendar Tab

This tab answers the question _"What's coming up this week and beyond?"_ — something the app currently doesn't have a home for.

**Suggested sections:**

- **Milestone timeline** — visual overview of the socialization window, vaccination schedule, deworming schedule, mapped against the puppy's age in weeks. Shows what's completed, current, and upcoming.
- **Appointments** — vet visits, puppy training classes, daycare bookings, grooming. With date, time, location, and optional reminders. Can deep-link to the relevant contact in the Places tab.

This tab absorbs content currently scattered across:

- Settings → Appointments
- Insights → "Te laat" (overdue) alerts (the milestone source data; the _urgent_ alerts themselves should surface on the Today tab)
- Insights → Socialisatievenster (the timeline visualization)

### Redesigned: Places Tab (separate workstream)

The Places tab expands from a simple map + favorites view into the central hub for **all locations and contacts** related to the dog. This is a significant enough change to warrant its own design workstream.

**Core concept:** Every contact is also a place. Your vet has an address, your dog walker has a service area, the daycare has a location. By merging contacts into Places, you get a single answer to "where do I go / who do I call?"

**Prominent filter system** — the tab should open with clearly visible, easily tappable filter chips or a segmented control at the top. Suggested place types:

- 🌳 **Walk spots** — parks, fields, beaches, forests, off-leash areas
- 🏥 **Vet** — veterinary clinics, emergency vet
- 🐕 **Daycare** — dog daycare, boarding facilities
- 🚶 **Dog walker** — walking services, pet sitters
- 🎓 **Training** — puppy classes, training schools
- 📸 **Moments** — places where photos/memories were logged
- ⭐ **Favorites** — cross-cutting filter across all types

**Per-place detail view** should support:

- Address + map pin
- Contact info (phone, email, website) where applicable
- Opening hours
- Notes (e.g., "closed on Mondays", "off-leash allowed after 18:00")
- Photos/moments linked to this place
- Quick actions: call, navigate, share

**Design considerations for this workstream:**

- Filter UX: chips vs. segmented control vs. dropdown — needs to be fast and prominent, not hidden behind a menu
- How to handle places that span multiple types (e.g., a vet clinic that also offers puppy training)
- Whether walk spots should have sub-categories (off-leash, on-leash, beach, forest, urban)
- Search/sort: by distance, by type, by most visited, alphabetical
- How contacts without a fixed address (e.g., a mobile dog walker) are represented on the map

### Simplified Settings

With the Calendar tab handling planning, contacts, and milestones, Settings becomes a true "configure once, revisit rarely" screen.

**Proposed structure (4 sections):**

#### 1. Puppy's Profile

- Name, breed, size, photo, date of birth
- Static identity information only

#### 2. Schedule & Preferences

- Walk schedule (times, frequency, max duration)
- Meal plan (times, portions, number of meals per day)
- Module toggles: enable/disable tracking for potty, sleep, meals, walks, training
- Notification preferences per module

#### 3. Health & Documents

- Medication settings (active medications, dosing schedule)
- Documents (vaccination booklet, pedigree, insurance policy, microchip info)
- This is the _configuration_ side of health — the _tracking and viewing_ happens in Calendar (milestones) and Insights (weight/trends)

#### 4. App Settings

- Sharing (manage partner access)
- Appearance (system/light/dark)
- Siri & Shortcuts
- Sound feedback toggle
- Advanced (GitHub import, data management, debug)

---

## Key Design Principles Behind This Restructuring

### "View daily" vs. "Configure once"

Everything you check regularly belongs in a tab. Everything you set up once belongs in Settings. The current app mixes these two modes, especially in Insights and the Otis settings page.

### No duplicates across tabs

The current Insights tab duplicates the socialization checklist from Train and the places map from Places. Each piece of information should have exactly one home — other tabs can _link_ to it, but not replicate it.

### Urgent items surface automatically

Overdue vaccinations and upcoming milestones shouldn't require navigating to Insights. The Today tab should surface these as alerts, while the Calendar tab holds the full schedule.

### Settings should be scannable

The current Otis settings page has ~10 different categories behind a single tap. The proposed 4-section structure means each section has 3–5 items max, and the mental model matches how you think about the information: "who is my dog" / "what's the daily routine" / "health paperwork" / "app config."

---

## Insights Tab Cleanup

The Insights tab currently mixes pure statistics with action items, planning content, and duplicates from other tabs. After the restructuring, several items move out. What remains should be reviewed with fresh eyes to ensure the cleaned-up page tells a coherent story.

### What leaves Insights

| Item                                           | Action     | Destination                                                | Reason                                   |
| ---------------------------------------------- | ---------- | ---------------------------------------------------------- | ---------------------------------------- |
| Socialisatie Checklist (0/96)                  | **Remove** | —                                                          | Duplicate of Train tab                   |
| Plekken map                                    | **Remove** | —                                                          | Duplicate of Places tab                  |
| Socialisatievenster timeline                   | **Move**   | Calendar tab → Milestone timeline                          | This is planning, not a statistic        |
| "Te laat" alerts (vaccination, vet, deworming) | **Move**   | Today tab (urgent alerts) + Calendar tab (source schedule) | These are action items, not statistics   |
| Age / days home header                         | **Move**   | Today tab header                                           | Dashboard identity info, not a statistic |

### What stays in Insights

| Item                          | Content type              |
| ----------------------------- | ------------------------- |
| Succes buiten plassen (graph) | Trend over time           |
| Buiten-reeks (streak)         | Motivational stat         |
| Plasintervallen (7 days)      | Interval analysis         |
| Slaap vandaag                 | Daily sleep summary       |
| Gewicht                       | Growth tracking           |
| Wandelgeschiedenis            | Walk frequency & duration |
| Weekoverzicht (table)         | Weekly activity matrix    |
| Patroonanalyse (Otis+)       | Premium trend analysis    |

### Design review request

After removing the items listed above, the Insights tab should be reviewed as a fresh page. Specifically:

1. **Coherent ordering** — the remaining items should follow a logical flow. Suggested grouping: _daily snapshot_ (today's stats: potty, sleep, meals, walks) → _weekly trends_ (week overview table, potty success graph, walk history) → _long-term tracking_ (weight curve, pee intervals over time, streak) → _premium_ (pattern analysis). The current page jumps between timeframes; the cleaned-up version should progress from short-term to long-term.
2. **No orphaned sections** — verify that removing the socialization checklist, milestone timeline, and alerts doesn't leave awkward gaps or empty headers.
3. **Consistent card hierarchy** — with fewer items, the visual weight of each card matters more. Ensure the most glanceable stats (today's summary, week overview) are prominent at the top, and deeper analysis (interval stats, weight history) sits below.
4. **Cross-linking, not duplicating** — where Insights shows data that relates to another tab (e.g., walk stats → Places, potty success → Train), consider subtle links or "See details" affordances rather than replicating content.

---

## Migration Summary

| Current Location                       | Content                       | New Location                                                  |
| -------------------------------------- | ----------------------------- | ------------------------------------------------------------- |
| Settings → Profile → Wandelschema        | Walk schedule config          | Settings → Schedule & Preferences                             |
| Settings → Profile → Meals               | Meal plan config              | Settings → Schedule & Preferences                             |
| Settings → Profile → Medicatie           | Medication settings           | Settings → Health & Documents                                 |
| Settings → Profile → Favoriete plekken   | Favorite places               | Places tab (already exists there)                             |
| Settings → Profile → Mijlpalen           | Milestones                    | Calendar tab → Milestone timeline                             |
| Settings → Profile → Documenten          | Documents                     | Settings → Health & Documents                                 |
| Settings → Profile → Contacten           | Contacts (vet, etc.)          | Places tab → Contacts (as place entries with contact details) |
| Settings → Profile → Appointments        | Appointments                  | Calendar tab → Appointments                                   |
| Settings → Profile → Profiel             | Name, breed, size             | Settings → Profile's Profile                                    |
| Settings → Profile → Statistieken        | Age, days home                | Today tab header (dashboard info)                             |
| Insights → Socialisatievenster         | Socialization window timeline | Calendar tab → Milestone timeline                             |
| Insights → "Te laat" alerts            | Overdue vaccinations etc.     | Today tab (urgent alerts) + Calendar (source schedule)        |
| Insights → Socialisatie Checklist      | Checklist duplicate           | Remove (lives in Train)                                       |
| Insights → Plekken map                 | Map duplicate                 | Remove (lives in Places)                                      |
| Insights → Weekoverzicht table         | Weekly activity summary       | Insights (keep — this is a statistic)                         |
| Insights → Sleep, weight, potty graphs | Trend data                    | Insights (keep — core purpose)                                |

---

## Open Questions

1. **Calendar tab naming** — "Calendar" / "Agenda" / "Plan" / "Schedule"? Should align with the app's existing naming convention (Dutch primary or bilingual).
2. **Places tab redesign scope** — This is flagged as a separate workstream. Key question: should the filter system be the _primary_ navigation (open tab → pick a filter → see results) or secondary (open tab → see map with everything → filter to narrow down)?
3. **Module toggles granularity** — How granular should "enable/disable tracking" be? Per-module (potty on/off) or per-feature (potty logging on, potty reminders off, potty insights off)?
4. **Statistics on Today vs. Insights** — The "age: 9 weeks / days home: 13" info currently sits in Settings. It makes more sense as Today tab header info or a persistent app-wide element. Where does it feel most natural?
5. **Premium (Otis+) features** — Pattern analysis is currently in Insights behind a paywall. Should other proposed features (e.g., advanced milestone tracking, multi-dog support) also be gated here, or distributed across tabs?
6. **Calendar ↔ Places linking** — Appointments in the Calendar tab should link to the relevant place/contact in Places. What does this interaction look like? Tap vet appointment → opens place detail with call button?
