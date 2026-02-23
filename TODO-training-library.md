# TODO: Training Library — Basis Commando's

Tekst-gebaseerde training library met 10-15 puppy commando's. Geen video's, geen paywall. Dit is wat 80% van puppy-eigenaren zoekt en wat Dogo achter een paywall zet.

## Waarom

- #1 reden waarom mensen een hondenapp downloaden is training content
- Dogo/Woofz: alles behalve basics achter paywall. Wij bieden het gratis.
- Tekst + illustratie is goedkoop te maken, makkelijk te updaten, werkt offline
- Positionering: "Ollie leert je ook trainen" — tracking + training in één

## Scope: 15 commando's

### Basis (launch)
1. **Zit** — het eerste commando
2. **Af/Liggen** — vanuit zit naar liggen
3. **Hier/Kom** — recall, essentieel voor veiligheid
4. **Blijf** — wachten op commando
5. **Lijnlopen** — niet trekken aan de lijn
6. **Naam herkenning** — reageren op naam
7. **Los/Laat** — iets loslaten uit bek
8. **Nee/Foei** — afremmen/stoppen

### Puppy-specifiek (launch)
9. **Zindelijkheidstraining** — routine, signalen herkennen
10. **Benchtraining** — bench als veilige plek
11. **Bijtremming** — puppy leert zachte bek
12. **Alleen thuis** — opbouwen in stappen

### Vervolg (v1.1)
13. **Pootje** — eerste trick
14. **Wacht** — bij de deur, voor eten
15. **Mand/Plaats** — naar vaste plek gaan

## Data Model

Nieuw bestand: `Ollie-app/Models/TrainingCommand.swift`

```swift
struct TrainingCommand: Identifiable, Codable {
    let id: String              // "zit", "af", "hier", etc.
    let name: String            // "Zit"
    let emoji: String           // "🐕"
    let category: CommandCategory // .basis, .puppySpecifiek, .tricks
    let difficulty: Int         // 1-3
    let ageWeeksMin: Int        // Minimale leeftijd in weken
    let summary: String         // Eén zin: wat het is
    let why: String             // Waarom dit belangrijk is
    let steps: [TrainingStep]   // Stap-voor-stap instructies
    let tips: [String]          // Do's
    let mistakes: [String]      // Don'ts
    let duration: String        // "3-5 minuten, 2-3x per dag"
    let prerequisite: String?   // Welk commando eerst? (nil = geen)
}

struct TrainingStep: Identifiable, Codable {
    let id: Int
    let instruction: String     // Wat de eigenaar moet doen
    let dogResponse: String     // Wat je van de hond verwacht
    let tip: String?            // Optionele extra tip bij deze stap
}

enum CommandCategory: String, Codable, CaseIterable {
    case basis = "Basis"
    case puppySpecifiek = "Puppy"
    case tricks = "Tricks"
}
```

## Content opslag

Commando's als JSON bundled in de app: `Ollie-app/SeedData/training-commands.json`

Voordelen:
- Geen server nodig
- Werkt offline
- Makkelijk te updaten via app update
- Kan later dynamisch worden (CloudKit) als we meer content toevoegen

## UI Design

### Nieuwe tab/view: Training (📚)

Twee secties op het training-scherm:

**1. Commando-bibliotheek**
```
┌──────────────────────────────┐
│ 📚 Training                  │
│                              │
│ BASIS                        │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │ 🐕   │ │ 🐕   │ │ 🐕   │ │
│ │ Zit  │ │ Af   │ │ Hier │ │
│ │ ⭐⭐⭐ │ │ ⭐⭐  │ │ ⭐   │ │
│ └──────┘ └──────┘ └──────┘ │
│                              │
│ PUPPY                        │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │ 🏠   │ │ 🚽   │ │ 🦷   │ │
│ │ Bench│ │Zinde-│ │ Bijt-│ │
│ │      │ │lijk  │ │ rem  │ │
│ └──────┘ └──────┘ └──────┘ │
└──────────────────────────────┘
```

Grid van kaarten, 3 breed. Elke kaart toont:
- Emoji
- Naam
- Moeilijkheidssterren
- Eventueel: voortgangsindicator als er training-events voor gelogd zijn

**2. Commando detail view**
```
┌──────────────────────────────┐
│ ← Zit                       │
│                              │
│ 🐕 Het eerste en belangrijkste│
│ commando. Basis voor alles.  │
│                              │
│ ⏱ 3-5 min, 2-3x per dag     │
│ 📅 Vanaf 8 weken             │
│                              │
│ STAPPEN                      │
│ ① Houd een snoepje boven de │
│   neus van je puppy...       │
│ ② Beweeg het snoepje langzaam│
│   naar achteren over het hoofd│
│ ③ Zodra de billen de grond   │
│   raken: "Zit!" + beloning   │
│                              │
│ 💡 TIPS                      │
│ • Korte sessies (max 5 min)  │
│ • Altijd eindigen met succes │
│                              │
│ ⚠️ VEELGEMAAKTE FOUTEN       │
│ • Te vaak herhalen zonder    │
│   beloning                   │
│                              │
│ ┌──────────────────────────┐ │
│ │ 🎓 Log trainingssessie   │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

**3. Koppeling met timeline**
- Onderaan detail view: knop "Log trainingssessie" → logt een `training` event met `exercise: "zit"` in de timeline
- In de commando-kaart: toon hoeveel keer je dit commando hebt geoefend (uit bestaande training events)
- Dit is Ollie's unique angle: geen concurrent koppelt training content aan daadwerkelijke logging data

## Navigatie

Twee opties:
1. **Tab bar item** — voeg "Training" toe als 3e/4e tab (naast Timeline, Stats, etc.)
2. **Sectie in bestaande view** — "Training tips" kaart op home met link naar library

Voorkeur: **tab bar item**. Training is belangrijk genoeg voor eigen plek.

## Koppeling met leeftijd

Gebruik `PuppyProfile.ageInWeeks` om:
- Commando's te filteren/sorteren op leeftijd
- Een "Aanbevolen voor [naam]" sectie te tonen bovenaan
- Commando's die te vroeg zijn te dimmen met "Vanaf X weken"

## Definition of Done

- [ ] `TrainingCommand` model met alle velden
- [ ] JSON seed data voor 12 commando's (basis + puppy-specifiek)
- [ ] Training overview view met grid van commando-kaarten
- [ ] Command detail view met stappen, tips, fouten
- [ ] "Log trainingssessie" knop die training event logt
- [ ] Training count per commando (uit bestaande events)
- [ ] Leeftijdsfiltering op basis van puppy profiel
- [ ] Tab bar navigatie naar training view

Delete this file when done.
