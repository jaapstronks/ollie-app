# TODO: Smart Potty Reminders

Data-driven push notifications op basis van daadwerkelijke plaspatronen. Waar Dogo irritante streak-notificaties stuurt, stuurt Ollie nuttige herinneringen gebaseerd op echte data.

## Waarom

- Ollie heeft al potty gap analyse en patroonherkenning
- De logische volgende stap: gebruik die data voor proactieve reminders
- "Het is 2u15m geleden sinds de laatste plas — misschien tijd om naar buiten te gaan?"
- Geen concurrent doet dit data-driven (Dogo doet streaks, niet plasinterval-reminders)
- Enorm praktisch: puppy-eigenaren vergeten dit constant

## Implementatie

### Stap 1: Bereken gemiddeld plasinterval

Gebruik bestaande `calculations/` logica:
- Mediaan interval tussen `plassen` events (laatste 7 dagen)
- Aparte medianen voor dag (07:00-22:00) en nacht
- Minimaal 10 datapunten nodig voordat reminders actief worden

### Stap 2: Schedule local notification

Na elke gelogde `plassen` event:
1. Bereken mediaan daginterval (bijv. 2u15m)
2. Schedule een `UNNotificationRequest` op `laatstePlas + mediaanInterval`
3. Cancel vorige potty reminder (er is er altijd maar één actief)

```swift
let content = UNMutableNotificationContent()
content.title = "🚽 Plasherinnering"
content.body = "Het is \(intervalString) geleden sinds de laatste plas. Tijd voor een rondje?"
content.sound = .default

let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: medianInterval,
    repeats: false
)
```

### Stap 3: Respectvolle notificaties

- **Nachtmodus:** Geen reminders tussen 22:00 en 07:00 (configureerbaar)
- **Opt-in:** Gebruiker moet reminders expliciet aanzetten in Settings
- **Niet spammy:** Maximaal 1 reminder per interval. Geen "je bent je streak kwijt!" bullshit.
- **Nuttig:** Toon het daadwerkelijke interval en de data erachter
- **Snooze-optie:** "Herinner me over 15 min" action op de notificatie

### Stap 4: Notification actions

```swift
let logAction = UNNotificationAction(
    identifier: "LOG_PLAS",
    title: "✅ Geplast (buiten)",
    options: .foreground
)
let snoozeAction = UNNotificationAction(
    identifier: "SNOOZE_15",
    title: "⏰ +15 min",
    options: []
)
```

Tap op "Geplast (buiten)" → opent app en logt direct een `plassen` event met `location: "buiten"`.

### UI in Settings

```
┌──────────────────────────────┐
│ 🔔 Meldingen                 │
│                              │
│ Plasherinneringen    [🔵 aan]│
│ Op basis van [naam]'s        │
│ gemiddelde interval (2u15m)  │
│                              │
│ Stille uren                  │
│ Van  [22:00]  tot  [07:00]  │
│                              │
│ ℹ️ Reminders worden slimmer  │
│ naarmate je meer logt.       │
│ Minimaal 10 plasmomenten     │
│ nodig voor betrouwbare       │
│ voorspellingen.              │
└──────────────────────────────┘
```

## Toekomstige uitbreidingen (niet voor v1)

- Maaltijdreminders op basis van schema
- "Tijd voor een wandeling" op basis van activiteitspatronen
- Benchtraining timer-reminders
- Apple Watch notificatie

## Definition of Done

- [ ] Mediaan plasinterval berekening (laatste 7 dagen, dag-only)
- [ ] Local notification scheduled na elke plassen event
- [ ] Nachtmodus (geen notificaties in stille uren)
- [ ] Opt-in toggle in Settings
- [ ] Notification action: direct loggen vanuit notificatie
- [ ] Notification action: snooze 15 min
- [ ] Minimaal 10 datapunten check (geen reminders zonder data)
- [ ] Cancel vorige reminder bij nieuwe plas

Delete this file when done.
