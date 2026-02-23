# TODO: Socialisatie-checklist

Socialisatie-checklist als onderdeel van de **Plan** tab (overzicht/roadmap) met bidirectionele koppeling naar **Today** (logging). Geen eigen tab, geen plek bij Train.

## Socialisatie-filosofie (BELANGRIJK)

> **"Het doel van socialisatie is NIET interactie; het is NEUTRALITEIT."**

De pup moet leren dat stimuli (honden, mensen, geluiden) gewoon onderdeel zijn van de wereld. Geen angst, maar ook geen overenthousiasme. Een goed gesocialiseerde pup ziet iets nieuws, denkt "oh dat hoort erbij", en kijkt terug naar de eigenaar.

### De Gouden Verhouding: 10:1
- Voor elke 1 **interactie** (aaien, spelen), 10 **exposures** (observeren, negeren)
- Dit voorkomt de "hyper-sociale hond" die naar elke hond en persoon wil

### Drie Niveaus van Socialisatie
1. **Ver observeren** — Pup ziet stimulus op afstand, blijft kalm → belonen
2. **Dichtbij passeren** — Stimulus passeert, pup negeert → belonen  
3. **Korte interactie** — Alleen bij stabiele, rustige stimulus

### Anti-patroon: De Hyper-Sociale Hond
Als pup leert dat "hond zien = hond spelen", bouwt hij enorme verwachtingen op. Wanneer hij aan de lijn staat en NIET kan spelen → frustratie → blaffen, trekken, bijten in de riem.

**Zigzag mist dit volledig** — zij loggen alleen "heeft X gezien ✓". Wij tracken HOE de ervaring was én op welke afstand.

## Waarom

- Socialisatievenster sluit rond 16 weken — tijdgevoelig
- Zigzag's sterkste feature, maar achter paywall én filosofisch zwak. Wij doen het beter.
- Past perfect bij Plan tab: het IS een roadmap van ervaringen
- Dubbele flow: spontaan loggen (Today) + bewust plannen (Plan)

## Architectuur: Plan + Today hybride

### Twee richtingen, één resultaat

**Route 1 — Spontaan (Today → Plan):**
1. Gebruiker logt een `sociaal` event via de normale Today flow
2. In het log-sheet verschijnt een extra veld: "Socialisatie-item?" met picker van open items
3. Bij selectie: exposure wordt gelogd + event verschijnt in timeline
4. Optioneel: als je geen item kiest, is het gewoon een los sociaal event

**Route 2 — Bewust (Plan → Today):**
1. Gebruiker opent Plan tab, ziet socialisatie-sectie
2. Tikt op een item (bijv. "Stofzuiger")
3. Sheet: afstand + reactie + optionele notitie
4. Exposure wordt gelogd EN er wordt automatisch een `sociaal` event aangemaakt

**Beide routes produceren:**
- Een exposure-log voor het socialisatie-item (met datum, afstand, reactie)
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
    let description: String?        // Korte tip (bijv. "Niet forceren, laat pup observeren")
    let targetExposures: Int        // Doel-aantal exposures voor "comfortabel"
    let isWalkable: Bool            // Kan tijdens wandeling
    var exposures: [Exposure]       // Alle gelogde exposures
    
    // Computed
    var isComfortable: Bool {
        // Comfortabel = voldoende exposures met positieve/neutrale reactie
        let goodExposures = exposures.filter { 
            $0.reaction == .positief || $0.reaction == .neutraal 
        }
        return goodExposures.count >= targetExposures
    }
    
    var progressFraction: Double {
        let goodCount = exposures.filter { 
            $0.reaction == .positief || $0.reaction == .neutraal 
        }.count
        return min(1.0, Double(goodCount) / Double(targetExposures))
    }
}

struct Exposure: Identifiable, Codable {
    let id: UUID
    let date: Date
    let distance: ExposureDistance
    let reaction: SocializationReaction
    let note: String?
}

enum ExposureDistance: String, Codable, CaseIterable {
    case far = "ver"                // 🔭 Observeren op afstand
    case near = "dichtbij"          // 👀 Dichtbij passeren
    case direct = "direct"          // 🤝 Directe interactie
    
    var emoji: String {
        switch self {
        case .far: return "🔭"
        case .near: return "👀"
        case .direct: return "🤝"
        }
    }
    
    var label: String {
        switch self {
        case .far: return "Op afstand"
        case .near: return "Dichtbij"
        case .direct: return "Direct contact"
        }
    }
}

enum SocializationReaction: String, Codable, CaseIterable {
    case positief = "positief"      // 🌟 Ontspannen, nieuwsgierig
    case neutraal = "neutraal"      // ✅ Negeert, kijkt terug naar baas (DIT IS HET DOEL!)
    case onzeker = "onzeker"        // 😟 Terughoudend, vermijdend
    case angstig = "angstig"        // 😰 Bang, trillen, vluchten
    
    var emoji: String {
        switch self {
        case .positief: return "🌟"
        case .neutraal: return "✅"
        case .onzeker: return "😟"
        case .angstig: return "😰"
        }
    }
    
    var description: String {
        switch self {
        case .positief: return "Ontspannen, nieuwsgierig"
        case .neutraal: return "Negeert het, kijkt naar jou" // GOAL!
        case .onzeker: return "Terughoudend, vermijdend"
        case .angstig: return "Bang, trilt, wil vluchten"
        }
    }
}
```

**Let op:** `neutraal` is het DOEL, niet een middelmatige score. De UI moet dit duidelijk maken.

### Koppeling met PuppyEvent

Voeg toe aan het bestaande `PuppyEvent` model:

```swift
var socializationItemId: String?
var exposureDistance: ExposureDistance?
```

In JSONL:
```json
{"time":"2026-02-23T14:30+01:00","type":"sociaal","who":"Kind op straat","note":"Keek even en ging verder","socialization_item":"kind-0-5","distance":"near"}
```

## Checklist Categorieën & Items

### Exposure-doelen
Items hebben verschillende target exposures gebaseerd op frequentie en belang:
- **Hoge frequentie** (auto's, fietsers): 10-15x neutraal/positief
- **Gemiddelde frequentie** (honden, kinderen): 5-8x
- **Lage frequentie** (vuurwerk, lift): 2-3x

### 👥 Mensen (16 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Kind (0-5 jaar) | 5x | ✓ | Altijd onder toezicht, niet forceren |
| Kind (6-12 jaar) | 5x | ✓ | Kunnen onvoorspelbaar bewegen |
| Tiener | 3x | ✓ | |
| Man met baard | 5x | ✓ | Sommige pups vinden dit eng |
| Persoon met hoed/pet | 5x | ✓ | Verandert silhouet |
| Persoon met zonnebril | 3x | ✓ | Verbergt ogen |
| Persoon in uniform | 5x | ✓ | Bezorger, politie, bouwvakker |
| Persoon met wandelstok/rollator | 3x | ✓ | Ander bewegingspatroon |
| Persoon in rolstoel | 3x | ✓ | |
| Jogger/hardloper | 8x | ✓ | Snelle beweging, vaak passeren |
| Fietser | 10x | ✓ | Zeer frequent, moet neutraal worden |
| Groep mensen | 5x | ✓ | Drukte, stemmen |
| Baby/peuter (geluiden) | 3x | ✓ | Hoge, onvoorspelbare geluiden |
| Postbode/bezorger | 5x | ✓ | Komt regelmatig, voorkom territorium-gedrag |
| Persoon met paraplu | 5x | ✓ | Openen is eng voor veel pups |
| Mensen van diverse achtergrond | 5x | ✓ | Verschillende verschijningen |

### 🐾 Andere dieren (8 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Grote hond (rustig, bekend) | 3x | Geregeld | Kwaliteit > kwantiteit. Alleen stabiele honden! |
| Kleine hond (op afstand) | 5x | ✓ | Passeren zonder contact |
| Hond aan de lijn (passeren) | 10x | ✓ | NIET laten groeten aan de lijn |
| Kat | 3x | Sometimes | Op afstand observeren |
| Vogels (eenden, duiven) | 5x | ✓ | Niet najagen, negeren |
| Paard/pony | 2x | Rural | Groot, anders ruikend |
| Koe/schaap | 2x | Rural | Als relevant voor omgeving |
| Klein dier (konijn, eekhoorn) | 3x | ✓ | Leren niet te achtervolgen |

### 🚗 Voertuigen & Transport (10 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Passerende auto's | 15x | ✓ | Moet volledig neutraal worden |
| Vrachtwagen/bus | 8x | ✓ | Groter, luider |
| Motor/scooter | 8x | ✓ | Ander geluid |
| Fiets (erlangs) | 10x | ✓ | Snelle beweging |
| Skateboard/step | 5x | ✓ | Vreemd geluid + beweging |
| Kinderwagen | 5x | ✓ | |
| Vuilniswagen | 3x | ✓ | Luid, grote bewegingen |
| Autorijden (kort) | 8x | — | Begin met 5 min, bouw op |
| Autorijden (langer) | 5x | — | 15+ minuten |
| Openbaar vervoer | 2x | — | Als relevant |

### 🔊 Geluiden (14 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Stofzuiger | 5x | — | Start op afstand, beloon kalmte |
| Wasmachine/droger | 3x | — | |
| Deurbel | 8x | — | Voorkom blaffen, kalmte belonen |
| Telefoon/alarm | 5x | — | Onverwacht geluid |
| Onweer (opname) | 5x | — | Begin zacht, bouw volume op |
| Vuurwerk (opname) | 5x | — | Maanden voor seizoen beginnen |
| Claxon/sirene | 5x | ✓ | |
| Bouwgeluiden | 5x | ✓ | Boren, hameren |
| Luide muziek | 3x | — | |
| Blaffende honden | 8x | ✓ | Moet neutraal blijven |
| Föhn | 3x | — | Voorbereiden op trimmer |
| Kerkklokken | 3x | ✓ | |
| Vliegtuig/helikopter | 3x | ✓ | |
| Stemverheffing/ruzie | 2x | — | TV-geluiden zijn veilig |

### 🏠 Omgevingen (12 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Drukke straat | 8x | ✓ | Observeer eerst vanaf bankje |
| Rustig park | 5x | ✓ | Basis buitenervaring |
| Druk park | 5x | ✓ | Meer prikkels |
| Terras/restaurant | 5x | ✓ | Settelen en observeren |
| Winkelcentrum (buiten) | 3x | ✓ | Drukte, geluiden |
| Parkeergarage | 3x | ✓ | Echo's, auto's |
| Lift | 3x | — | Beweging, klein |
| Trap (open) | 5x | ✓ | Kan eng zijn |
| Trap (dicht) | 3x | ✓ | |
| Dierenarts (happy visit) | 3x | — | Zonder behandeling, alleen kennismaken |
| Strand/water | 3x | ✓ | Golven, zand, meeuwen |
| Bos/natuur | 5x | ✓ | Wildlife, texturen |

### 🦶 Ondergronden (10 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Gras (droog) | 5x | ✓ | |
| Gras (nat) | 3x | ✓ | |
| Tegels/stoep | 5x | ✓ | |
| Kiezels/grind | 5x | ✓ | |
| Zand | 3x | ✓ | |
| Modder | 3x | ✓ | |
| Water (ondiep) | 3x | ✓ | Pootje baden |
| Metalen rooster | 5x | ✓ | Vaak eng, beloon bravery |
| Gladde vloer (binnen) | 5x | — | Tegels, parket |
| Houten vlonder/brug | 3x | ✓ | Kan wiebelen |

### ✋ Handling (10 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Poten aanraken | 10x | — | Elke poot, regelmatig |
| Nagels knippen (aanraken) | 8x | — | Eerst alleen aanraken/geluid |
| Oren bekijken | 8x | — | Binnenkant |
| Tanden/bek bekijken | 8x | — | Voorbereiding dierenarts |
| Borstelen/kammen | 8x | — | |
| Optillen | 5x | — | |
| Handdoek afdrogen | 5x | — | Na wandeling |
| Poten schoonmaken | 8x | — | Routine na wandeling |
| Halsband pakken | 5x | — | Noodgeval-handling |
| Tuig/harnas aan/uit | 8x | — | |

### 🎪 Objecten (10 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Paraplu (openen) | 5x | ✓ | Plotse beweging |
| Ballon | 3x | — | Beweging, kan knappen |
| Plastic tas (wapperend) | 5x | ✓ | Onvoorspelbare beweging |
| Vuilnisbak/kliko | 5x | ✓ | Rijden, geluid |
| Bezem/stofzuiger (object) | 3x | — | Bewegend object |
| Rolgordijn/gordijn | 3x | — | Beweging |
| Spiegel | 2x | — | Eigen reflectie |
| Kerstversiering | 2x | — | Lichtjes, beweging |
| Robot (stofzuiger etc) | 3x | — | Zelfstandig bewegend |
| Kinderspeelgoed | 3x | ✓ | Geluid, beweging |

### 🌦 Weersomstandigheden (6 items)
| Item | Target | Walkable | Tip |
|------|--------|----------|-----|
| Lichte regen | 5x | ✓ | Korte blootstelling |
| Wind | 5x | ✓ | Geluiden, bewegende objecten |
| Donker/avondwandeling | 5x | ✓ | Andere schaduwen, geluiden |
| Koude | 3x | ✓ | Gepaste duur |
| Sneeuw/vorst | 2x | ✓ | Als seizoensgebonden |
| Plassen/modderpoelen | 3x | ✓ | |

**Totaal: ~96 items in 10 categorieën**

## Opslag

Checklist-state als JSON in app documents: `socialization.json`

```json
{
    "startedDate": "2026-02-14",
    "items": {
        "kind-0-5": {
            "exposures": [
                {
                    "id": "uuid-1",
                    "date": "2026-02-20T14:30:00+01:00",
                    "distance": "near",
                    "reaction": "neutraal",
                    "note": "Buurmeisje, pup keek even en ging verder"
                },
                {
                    "id": "uuid-2",
                    "date": "2026-02-22T10:15:00+01:00",
                    "distance": "far",
                    "reaction": "positief",
                    "note": "Kinderen op speelplein, observeerde rustig"
                }
            ]
        }
    }
}
```

Seed data (de categorieën + items template) als bundled JSON: `Ollie-app/SeedData/socialization-items.json`

## UI Design

### Plan tab — Socialisatie sectie

```
┌──────────────────────────────┐
│ Plan                         │
│ 10 weeks old                 │
│                              │
│ 🐾 Socialisatie              │
│ ┌──────────────────────────┐ │
│ │ 34 / 96 comfortabel ████░│ │
│ │ ⏰ Nog 6 weken in het      │ │
│ │    socialisatievenster    │ │
│ └──────────────────────────┘ │
│                              │
│ 👥 Mensen           8/16   ▸│
│ 🐾 Dieren           2/8    ▸│
│ 🚗 Voertuigen       4/10   ▸│
│ 🔊 Geluiden         6/14   ▸│
│ 🏠 Omgevingen       5/12   ▸│
│ 🦶 Ondergronden     4/10   ▸│
│ ✋ Handling          2/10   ▸│
│ 🎪 Objecten         2/10   ▸│
│ 🌦 Weer             1/6    ▸│
│                              │
└──────────────────────────────┘
```

### Categorie detail view

```
┌──────────────────────────────┐
│ ← 👥 Mensen           8/16  │
│                              │
│ ✅ Kind (0-5 jaar)    2/5   │
│    ████░░░░░░░░░░░░         │
│    Laatste: 20 feb — ✅      │
│                              │
│ ✅ Fietser            8/10  │
│    ████████████████░░       │
│    Laatste: vandaag — ✅     │
│                              │
│ 🔄 Man met baard      1/5   │
│    ███░░░░░░░░░░░░░░        │
│    Laatste: 19 feb — 😟     │
│    ⚠️ Laatste was onzeker    │
│                              │
│ ○  Persoon met hoed   0/5   │
│ ○  Persoon in rolstoel 0/3  │
│ ...                          │
└──────────────────────────────┘
```

Tap op item → exposure-log sheet:

```
┌──────────────────────────────┐
│ Kind (0-5 jaar)              │
│                              │
│ Hoe dichtbij?                │
│ ┌────┐ ┌────┐ ┌────┐        │
│ │ 🔭 │ │ 👀 │ │ 🤝 │        │
│ │Ver │ │Nabij│ │Direct│       │
│ └────┘ └────┘ └────┘        │
│                              │
│ Reactie van [puppy naam]?    │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ │
│ │ 🌟 │ │ ✅ │ │ 😟 │ │ 😰 │ │
│ │Blij│ │Kalm│ │Onzeker│ │Bang││
│ └────┘ └────┘ └────┘ └────┘ │
│                              │
│ 💡 Tip: "Kalm" (✅) is het   │
│ doel — pup ziet het en       │
│ negeert het.                 │
│                              │
│ Notitie (optioneel)          │
│ ┌──────────────────────────┐ │
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│       [Opslaan]              │
└──────────────────────────────┘
```

### Angst-protocol popup

Als gebruiker `angstig` of `onzeker` selecteert:

```
┌──────────────────────────────┐
│ 💡 Tips bij angst            │
│                              │
│ • Niet forceren — trek pup   │
│   niet dichterbij            │
│ • Maak afstand — ga verder   │
│   weg tot pup ontspant       │
│ • Laat observeren — pup mag  │
│   kijken vanaf veilige plek  │
│ • Beloon moed — treats voor  │
│   kalmte en nieuwsgierigheid │
│                              │
│ Volgende keer: begin verder  │
│ weg (🔭) en bouw langzaam op.│
│                              │
│           [Begrepen]         │
└──────────────────────────────┘
```

### Today view — Social event koppeling

Bij loggen van `sociaal` event:

```
┌──────────────────────────────┐
│ Cancel          Log event    │
│                              │
│ 🐾 Social — 13:22           │
│                              │
│ Wie/wat?                     │
│ ┌──────────────────────────┐ │
│ │ Kind op speelplein       │ │
│ └──────────────────────────┘ │
│                              │
│ 📋 Socialisatie-item?        │
│ ┌──────────────────────────┐ │
│ │ Kind (0-5 jaar)        ▾ │ │
│ └──────────────────────────┘ │
│                              │
│ Afstand: 🔭 Ver  👀 Nabij  🤝│
│ Reactie: 🌟  ✅  😟  😰      │
│                              │
│       [Log]                  │
└──────────────────────────────┘
```

### Walk Suggestions (Today view)

Subtiele kaart op Today wanneer wandeling gepland staat:

```
┌──────────────────────────────┐
│ 🚶 Wandeling om 15:00        │
│                              │
│ 💡 Let tijdens de wandeling  │
│    op deze items:            │
│                              │
│ • Fietser (8/10) — bijna!    │
│ • Man met baard (1/5)        │
│ • Metalen rooster (2/5)      │
│                              │
│ Tip: Observeer op afstand,   │
│ beloon kalmte.               │
│                      [Later] │
└──────────────────────────────┘
```

Suggesties gebaseerd op:
- Items met `isWalkable: true`
- Nog niet comfortabel
- Recent negatieve ervaring → prioriteit voor retry op grotere afstand
- Items waar progressie bijna compleet is

## Leeftijdslogica

- `PuppyProfile.ageInWeeks` bepaalt urgentie
- < 10 weken: groene banner "Midden in het socialisatievenster — ideale tijd!"
- 10-14 weken: blauwe banner "Socialisatievenster — nog X weken optimaal"
- 14-16 weken: oranje banner "Venster sluit bijna — focus op de belangrijkste items"
- 16-20 weken: gele banner "Na het venster — socialisatie blijft waardevol maar lastiger"
- > 20 weken: geen banner, checklist blijft beschikbaar

## Definition of Done

### Models
- [ ] `SocializationCategory`, `SocializationItem` models
- [ ] `Exposure`, `ExposureDistance`, `SocializationReaction` models
- [ ] `targetExposures` en `isWalkable` per item
- [ ] Computed properties: `isComfortable`, `progressFraction`

### Data
- [ ] JSON seed data met alle ~96 items in 10 categorieën
- [ ] `SocializationStore` service (laden, opslaan, exposure toevoegen)
- [ ] Migratie van oud formaat (single completed) naar exposures array

### UI — Plan
- [ ] Socialisatie-sectie in Plan view met voortgangsbalk
- [ ] Categorieën met progress indicators
- [ ] Categorie detail view met items en voortgang per item
- [ ] Exposure-log sheet met afstand + reactie picker
- [ ] Progress bars per item (niet binary checkmarks)

### UI — Feedback
- [ ] "Kalm is het doel" uitleg in UI
- [ ] Angst-protocol popup bij negatieve reactie
- [ ] Tips per item (description veld)

### UI — Today integratie
- [ ] `socialization_item` + `distance` velden in PuppyEvent
- [ ] Social event log-sheet uitgebreid met socialisatie-koppeling
- [ ] Log vanuit Plan creëert automatisch `sociaal` event

### UI — Suggesties
- [ ] Walk suggestions kaart op Today view
- [ ] Prioritering: bijna-compleet, recent negatief, walkable

Delete this file when done.
