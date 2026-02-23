# TODO: Socialisatie-checklist

Socialisatie-checklist als onderdeel van de **Plan** tab (overzicht/roadmap) met bidirectionele koppeling naar **Today** (logging). Geen eigen tab, geen plek bij Train.

## Waarom

- Socialisatievenster sluit rond 16 weken — tijdgevoelig
- Zigzag's sterkste feature, maar achter paywall. Wij bieden het gratis.
- Past perfect bij Plan tab: het IS een roadmap van ervaringen
- Dubbele flow: spontaan loggen (Today) + bewust plannen (Plan)

## Architectuur: Plan + Today hybride

### Twee richtingen, één resultaat

**Route 1 — Spontaan (Today → Plan):**
1. Gebruiker logt een `sociaal` event via de normale Today flow
2. In het log-sheet verschijnt een extra veld: "Socialisatie-item?" met picker van open items
3. Bij selectie: socialisatie-item wordt afgevinkt + event verschijnt in timeline
4. Optioneel: als je geen item kiest, is het gewoon een los sociaal event (zoals nu)

**Route 2 — Bewust (Plan → Today):**
1. Gebruiker opent Plan tab, ziet socialisatie-sectie
2. Tikt op een open item (bijv. "Stofzuiger")
3. Sheet: reactie-picker + optionele notitie + "Afvinken"
4. Item wordt afgevinkt EN er wordt automatisch een `sociaal` event aangemaakt in de timeline

**Beide routes produceren:**
- Een afgevinkt socialisatie-item (met datum, reactie, notitie)
- Een `sociaal` event in de timeline (met `socialization_item` referentie)

## Data Model

### SocializationItem

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
    let description: String?        // Optionele tip/context
    var completed: Bool
    var completedDate: Date?
    var reaction: SocializationReaction?
    var note: String?
}

enum SocializationReaction: String, Codable, CaseIterable {
    case positief = "positief"      // 😊 Ontspannen, nieuwsgierig
    case neutraal = "neutraal"      // 😐 Geen reactie
    case onzeker = "onzeker"        // 😟 Terughoudend, vermijdend
    case angstig = "angstig"        // 😰 Bang, trillen, vluchten
    
    var emoji: String {
        switch self {
        case .positief: return "😊"
        case .neutraal: return "😐"
        case .onzeker: return "😟"
        case .angstig: return "😰"
        }
    }
}
```

### Koppeling met PuppyEvent

Voeg een optioneel veld toe aan het bestaande `PuppyEvent` model:

```swift
// In PuppyEvent, voeg toe:
var socializationItemId: String?    // Referentie naar socialisatie-item
```

In JSONL:
```json
{"time":"2026-02-23T14:30+01:00","type":"sociaal","who":"Kind op straat","note":"Heel nieuwsgierig","socialization_item":"kind-0-5"}
```

## Checklist Categorieën & Items (~77 items)

### 👥 Mensen (~15 items)
- Kind (0-5 jaar)
- Kind (6-12 jaar)
- Tiener
- Man met baard
- Persoon met hoed/pet
- Persoon met zonnebril
- Persoon in uniform (bezorger, politie)
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
- Dierenartspraktijk (kennismaking)
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

Checklist-state als JSON in app documents: `socialization.json`

```json
{
    "startedDate": "2026-02-14",
    "items": {
        "kind-0-5": {
            "completed": true,
            "completedDate": "2026-02-20T14:30:00+01:00",
            "reaction": "positief",
            "note": "Buurmeisje, heel lief"
        }
    }
}
```

Seed data (de categorieën + items template) als bundled JSON: `Ollie-app/SeedData/socialization-items.json`

Later syncen via CloudKit wanneer dat gebouwd is.

## UI Design

### Plan tab — Socialisatie sectie

Voeg toe als prominente sectie in de bestaande Plan view, boven of onder "Upcoming milestones":

```
┌──────────────────────────────┐
│ Plan                         │
│ 2 months old                 │
│                              │
│ 🐾 Socialisatie              │
│ ┌──────────────────────────┐ │
│ │ 34 / 77            ████░ │ │
│ │ ⏰ Nog 3 weken tot venster│ │
│ │    sluit (~16 weken)      │ │
│ └──────────────────────────┘ │
│                              │
│ 👥 Mensen            8/15  ▸│
│ 🐾 Dieren            3/8   ▸│
│ 🔊 Geluiden          6/12  ▸│
│ 🚗 Voertuigen        4/8   ▸│
│ 🏠 Omgevingen        5/10  ▸│
│ 🦶 Ondergronden      4/8   ▸│
│ ✋ Handling           2/8   ▸│
│ 🎪 Objecten          2/8   ▸│
│                              │
│ ⚠️ Upcoming milestones       │
│ ...bestaande content...      │
└──────────────────────────────┘
```

De urgentie-banner ("Nog X weken") verdwijnt na ~20 weken. Checklist blijft beschikbaar maar zonder countdown.

### Categorie detail (vanuit Plan)

```
┌──────────────────────────────┐
│ ← 👥 Mensen           8/15  │
│                              │
│ ✅ Kind (0-5 jaar)     😊    │
│    20 feb — "Buurmeisje"     │
│                              │
│ ✅ Kind (6-12 jaar)    😐    │
│    19 feb                    │
│                              │
│ ☐  Man met baard             │
│ ☐  Persoon met hoed          │
│ ☐  Persoon in uniform        │
│ ...                          │
└──────────────────────────────┘
```

Tap op een open item → afvink-sheet (Route 2):

```
┌──────────────────────────────┐
│ Stofzuiger ✓                 │
│                              │
│ Hoe reageerde [puppy naam]?  │
│ 😊  😐  😟  😰               │
│                              │
│ Notitie (optioneel)          │
│ ┌──────────────────────────┐ │
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│       [Opslaan]              │
└──────────────────────────────┘
```

Reactie en notitie zijn optioneel — snelle één-tap afvinken is ook prima.

### Today view — Social event koppeling (Route 1)

Wanneer de gebruiker een `sociaal` event logt via de bestaande "Log event" → "Social" flow, voeg een optioneel veld toe aan het log-sheet:

```
┌──────────────────────────────┐
│ Cancel          Log event    │
│                              │
│ 🐾 Social — 13:22           │
│ [-5] [-10] [-15] [⏰]       │
│                              │
│ Wie/wat?                     │
│ ┌──────────────────────────┐ │
│ │ Kind op straat           │ │
│ └──────────────────────────┘ │
│                              │
│ 📋 Socialisatie-item?        │
│ ┌──────────────────────────┐ │
│ │ Kind (0-5 jaar)        ▾ │ │
│ └──────────────────────────┘ │
│ (optioneel — alleen open     │
│  items getoond)              │
│                              │
│ Notitie (optioneel)          │
│ ┌──────────────────────────┐ │
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│       [Log]                  │
└──────────────────────────────┘
```

De socialisatie-picker is optioneel en toont alleen nog-niet-afgevinkte items. Als je er één selecteert, wordt dat item automatisch afgevinkt.

### Today view — Compacte suggestie (optioneel, nice-to-have)

Op de Today view, in de "Coming up" sectie of als subtiele kaart:

```
┌──────────────────────────────┐
│ 💡 Socialisatie-tip           │
│ Jullie hebben nog geen       │
│ ervaring met een lift.       │
│                      [Later] │
└──────────────────────────────┘
```

Eén suggestie per dag, random uit onafgevinkte items. Niet opdringerig — kan weggetikt worden. Dit is nice-to-have voor v1.1.

## Leeftijdslogica

- `PuppyProfile.ageInWeeks` bepaalt urgentie
- < 12 weken: groene banner "Volop in het socialisatievenster"
- 12-16 weken: oranje banner "Nog X weken — maak er gebruik van!"
- 16-20 weken: rode banner "Venster sluit — focus op de belangrijkste items"
- > 20 weken: geen banner meer, checklist blijft gewoon beschikbaar

## Definition of Done

- [ ] `SocializationCategory`, `SocializationItem`, `SocializationReaction` models
- [ ] JSON seed data met alle ~77 items in 8 categorieën
- [ ] `SocializationStore` service (laden, opslaan, afvinken)
- [ ] Socialisatie-sectie in Plan view met voortgangsbalk en categorieën
- [ ] Categorie detail view met items en afvink-sheet
- [ ] Reactie-picker (emoji) bij afvinken
- [ ] Optionele notitie bij items
- [ ] Socialisatievenster countdown op basis van puppy leeftijd
- [ ] `socialization_item` veld toegevoegd aan PuppyEvent model
- [ ] Social event log-sheet uitgebreid met socialisatie-item picker
- [ ] Afvinken vanuit Plan creëert automatisch `sociaal` event in timeline
- [ ] Koppelen vanuit Today Social event vinkt automatisch socialisatie-item af

Delete this file when done.
