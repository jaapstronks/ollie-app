# TODO: Training Enhancements

Uitbreidingen op de bestaande Training tab. De basis is gebouwd — dit zijn de ontbrekende onderdelen.

## 1. Mistakes/Fouten Sectie

Voeg een `mistakes` array toe aan elke skill, naast de bestaande `tips`.

**Model wijziging in `TrainingPlan.swift`:**
```swift
// Add to SkillContent:
static func mistakes(for skillId: String) -> [String]
```

**UI wijziging in `SkillCard.swift`:**
- Nieuwe sectie "Veelgemaakte fouten" met ⚠️ icoon
- Rode/oranje tint om te onderscheiden van tips

**Voorbeeld content voor "sit":**
- Te snel het commando herhalen zonder te wachten
- Naar beneden duwen in plaats van lokken
- Beloning geven voordat de billen de grond raken

## 2. Ontbrekende Puppy-Specifieke Skills

Drie belangrijke skills die niet in de huidige `training-plan.json` staan:

### Zindelijkheidstraining (pottyTraining)
- **Category:** care
- **Week:** 1 (hoogste prioriteit voor nieuwe puppy's)
- **Requires:** []
- **Content:** Schema opbouwen, signalen herkennen, accident-vrij protocol

### Bijtremming (biteInhibition)
- **Category:** care
- **Week:** 1-2
- **Requires:** []
- **Content:** Zachte bek aanleren, ouch-methode, speelgoed redirecten

### Alleen Thuis (separationTraining)
- **Category:** impulseControl
- **Week:** 2-3
- **Requires:** ["place"]
- **Content:** Opbouwen in kleine stappen, vertrek-ritueel vermijden, rustig terugkomen

## 3. Duration Info

Voeg `duration` toe aan Skill model voor aanbevolen sessieduur.

**Model wijziging:**
```swift
struct Skill {
    // ... existing fields
    let durationMinutes: Int?      // Aanbevolen sessieduur (nil = n.v.t.)
    let sessionsPerDay: Int?       // Aanbevolen sessies per dag
}
```

**UI:** Toon in collapsed header of expanded content: "⏱ 3-5 min, 2-3x per dag"

## 4. Difficulty Indicators

Voeg `difficulty: Int` (1-3) toe aan Skill model.

**UI opties:**
- Sterren (⭐⭐⭐) in de card header
- Tekstlabel: "Makkelijk" / "Gemiddeld" / "Uitdagend"
- Kleurcodering

## Prioriteit

1. **Puppy-specifieke skills** — Grootste content gap, direct waardevol
2. **Mistakes sectie** — Differentieert van concurrenten
3. **Duration info** — Nice-to-have, helpt bij verwachtingen
4. **Difficulty indicators** — Nice-to-have, visuele polish

## Definition of Done

- [ ] `mistakes` array toegevoegd aan SkillContent
- [ ] Mistakes sectie in SkillCard UI
- [ ] 3 nieuwe skills in training-plan.json (pottyTraining, biteInhibition, separationTraining)
- [ ] Strings voor nieuwe skills in Strings.swift + Localizable.xcstrings
- [ ] Duration velden in Skill model (optioneel)
- [ ] Difficulty velden in Skill model (optioneel)

Delete this file when done.
