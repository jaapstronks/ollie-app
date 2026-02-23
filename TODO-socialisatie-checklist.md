# TODO: Socialisatie-checklist

Simpele checklist van ervaringen die een puppy vóór ~16 weken moet meemaken. Zigzag's sterkste feature, maar te repliceren als lichtgewicht checklist zonder content-heavy programma.

## Waarom

- Socialisatievenster sluit rond 16 weken — dit is tijdgevoelig
- Zigzag is de enige concurrent die dit goed doet, maar het zit achter een paywall
- Lage effort, hoge waarde: het is in essentie een toggle-lijst met categorieën
- Past perfect bij Ollie's data-driven aanpak: "je puppy heeft 34/80 ervaringen gehad"

## Data Model

Nieuw bestand: `Ollie-app/Models/SocializationItem.swift`

```swift
struct SocializationCategory: Identifiable, Codable {
    let id: String                  // "mensen", "dieren", "geluiden", etc.
    let name: String                // "Mensen"
    let emoji: String               // "👥"
    let items: [SocializationItem]
}

struct SocializationItem: Identifiable, Codable {
    let id: String                  // "kind-0-5", "stofzuiger", etc.
    let name: String                // "Kind (0-5 jaar)"
    let description: String?        // Optionele tip
    var completed: Bool             // Toggle
    var completedDate: Date?        // Wanneer afgevinkt
    var reaction: Reaction?         // Hoe reageerde de puppy?
    var note: String?               // Vrije notitie
}

enum Reaction: String, Codable, CaseIterable {
    case positief = "😊"        // Ontspannen, nieuwsgierig
    case neutraal = "😐"        // Geen reactie
    case onzeker = "😟"         // Terughoudend, vermijdend
    case angstig = "😰"         // Bang, trillen, vluchten
}
```

## Checklist Categorieën & Items

### 👥 Mensen (~15 items)
- Kind (0-5 jaar)
- Kind (6-12 jaar)
- Tiener
- Man met baard
- Persoon met hoed/pet
- Persoon met zonnebril
- Persoon in uniform (politie, bezorger)
- Persoon met wandelstok/rollator
- Persoon in rolstoel
- Rennend persoon / jogger
- Persoon op fiets
- Groep mensen
- Baby/peuter (geluiden)
- Postbode / pakketbezorger
- Dierenarts / trimmer

### 🐾 Dieren (~8 items)
- Grote hond
- Kleine hond
- Puppy (leeftijdsgenoot)
- Kat
- Vogels (eenden, duiven)
- Paard / pony
- Koe / schaap
- Konijn / knaagdier

### 🔊 Geluiden (~12 items)
- Stofzuiger
- Wasmachine / droger
- Deurbel
- Telefoon / alarm
- Onweer / harde wind
- Vuurwerk
- Claxon / sirene
- Bouwgeluiden (boren, hameren)
- Muziek (luid)
- Blaffende honden
- Kerkklokken
- Vliegtuig / helikopter

### 🚗 Voertuigen & Transport (~8 items)
- Auto (meerijden)
- Fiets (erlangs)
- Bus / tram
- Trein (station)
- Scooter / brommer
- Skateboard / step
- Vrachtwagen / vuilniswagen
- Kinderwagen

### 🏠 Omgevingen (~10 items)
- Drukke winkelstraat
- Park / speeltuin
- Strand
- Bos / natuur
- Parkeergarage
- Lift
- Trap (boven/beneden)
- Dierenartspraktijk (niet voor behandeling)
- Terras / restaurant
- Markt / evenement

### 🦶 Ondergronden (~8 items)
- Gras
- Tegels / stoep
- Zand
- Modder
- Water (ondiep)
- Rooster / tralie
- Houten vloer (glad)
- Kiezels / grind

### ✋ Aanraking & Handling (~8 items)
- Poten aanraken
- Oren controleren
- Tanden/bek bekijken
- Nagels knippen (of aanraken)
- Borstelen / kammen
- Baden / afspoelen
- Handdoek afdrogen
- Optillen

### 🎪 Objecten (~8 items)
- Paraplu (openen)
- Ballon
- Vuilniszak (wapperend)
- Bezem / dweil
- Plastic tas (geluid)
- Fietsbel
- Kinderspeelgoed (bewegend/geluid)
- Kerstversiering / Halloween

**Totaal: ~77 items in 8 categorieën**

## Opslag

Checklist-state in een JSON bestand: `socialization.json` in app documents directory.

```json
{
    "startedDate": "2026-02-14",
    "items": {
        "kind-0-5": {
            "completed": true,
            "completedDate": "2026-02-20",
            "reaction": "positief",
            "note": "Buurmeisje, heel lief"
        },
        "stofzuiger": {
            "completed": true,
            "completedDate": "2026-02-18",
            "reaction": "onzeker"
        }
    }
}
```

Later syncen via CloudKit (als dat gebouwd is).

## UI Design

### Socialisatie tab/sectie

```
┌──────────────────────────────┐
│ 🐾 Socialisatie              │
│                              │
│ ┌──────────────────────────┐ │
│ │  34 / 77 ervaringen  ████░│ │
│ │  44% — Goed bezig!       │ │
│ │  📅 Venster sluit ~16 wkn │ │
│ └──────────────────────────┘ │
│                              │
│ 👥 Mensen           8/15  ▸ │
│ 🐾 Dieren           3/8   ▸ │
│ 🔊 Geluiden         6/12  ▸ │
│ 🚗 Voertuigen       4/8   ▸ │
│ 🏠 Omgevingen       5/10  ▸ │
│ 🦶 Ondergronden     4/8   ▸ │
│ ✋ Handling          2/8   ▸ │
│ 🎪 Objecten         2/8   ▸ │
└──────────────────────────────┘
```

### Categorie detail

```
┌──────────────────────────────┐
│ ← 👥 Mensen          8/15   │
│                              │
│ ✅ Kind (0-5 jaar)    😊     │
│    20 feb — "Buurmeisje"     │
│                              │
│ ✅ Kind (6-12 jaar)   😐     │
│    19 feb                    │
│                              │
│ ☐  Man met baard             │
│ ☐  Persoon met hoed          │
│ ☐  Persoon in uniform        │
│ ...                          │
└──────────────────────────────┘
```

### Item afvinken

Tap op een item → compact sheet:

```
┌──────────────────────────────┐
│ Stofzuiger ✓                 │
│                              │
│ Hoe reageerde [naam]?        │
│ 😊  😐  😟  😰               │
│                              │
│ Notitie (optioneel)          │
│ ┌──────────────────────────┐ │
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│ [Opslaan]                    │
└──────────────────────────────┘
```

Reactie en notitie zijn optioneel — één tap op de checkbox is genoeg voor snelle logging.

## Koppeling met puppy profiel

- Bereken `PuppyProfile.ageInWeeks` → toon countdown: "Nog X weken in het socialisatievenster"
- Na 16 weken: checklist blijft beschikbaar maar urgentie-banner verdwijnt
- Op home view: compact kaartje "Socialisatie: 34/77 — nog 3 weken"

## Koppeling met timeline

Optioneel: als een item wordt afgevinkt, log automatisch een `sociaal` event in de timeline met de details. Dit verrijkt de timeline en de stats.

## Seed Data

Categorieën en items als JSON bundled in de app: `Ollie-app/SeedData/socialization-items.json`

## Definition of Done

- [ ] `SocializationCategory` en `SocializationItem` models
- [ ] JSON seed data met alle ~77 items in 8 categorieën
- [ ] Socialisatie overview met voortgangsbalk en categorieën
- [ ] Categorie detail view met toggle-items
- [ ] Reactie-picker (emoji) bij afvinken
- [ ] Optionele notitie bij items
- [ ] Voortgangspercentage op home view
- [ ] Socialisatievenster countdown op basis van puppy leeftijd
- [ ] Persistentie in JSON bestand (lokaal)

Delete this file when done.
