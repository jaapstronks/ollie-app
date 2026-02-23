# TODO: Clicker Tool

Ingebouwde clicker — simpel, verwachte baseline feature in elke training app. Dogo biedt het gratis, wij ook.

## Waarom

- Elke concurrent heeft dit (Dogo, Woofz, Pupford)
- Veel puppy-eigenaren hebben geen fysieke clicker
- Triviaal te bouwen, verwacht door gebruikers
- Mooi moment om training library te cross-promoten

## Implementatie

### Minimale versie (v1.0)

Eén scherm met een grote tap-knop die:
1. Een kort, scherp "click" geluid afspeelt (`AVAudioPlayer`)
2. Haptic feedback geeft (`UIImpactFeedbackGenerator`, `.medium`)
3. Onmiddellijk reageert (latency < 50ms — timing is cruciaal bij clicker training)

```
┌──────────────────────────────┐
│                              │
│                              │
│         🔘                   │
│      (grote cirkel)          │
│                              │
│        CLICK                 │
│                              │
│   Tap ergens op het scherm   │
│                              │
│                              │
│  ┌────────┐  ┌────────────┐ │
│  │🔇 Geluid│  │📳 Trilling │ │
│  └────────┘  └────────────┘ │
└──────────────────────────────┘
```

### Details

- **Geluid:** Kort, scherp geluid (~100ms). Bundel een `click.wav` of `click.caf` in de app. Gebruik `AVAudioPlayer` met `prepareToPlay()` voor zero-latency.
- **Haptic:** `UIImpactFeedbackGenerator(style: .medium)` — prepare on view appear.
- **Hele scherm is tap target** — niet alleen de knop. Bij training heb je geen tijd om te mikken.
- **Toggles:** Geluid aan/uit, trilling aan/uit (sommige honden schrikken van het telefoongeluid)
- **Geen counter nodig** — de clicker is een hulpmiddel, geen tracker. Keep it simple.

### Toegang

- Knop in de training library view (bovenaan of als floating action)
- Optioneel: snelkoppeling vanuit quick-log bar (via de "+" menu)
- Later: kan ook vanuit commando detail views ("Gebruik de clicker bij stap 2")

### Audio bestand

Gebruik een kort, helder klikgeluid. Kan gegenereerd worden met een simpele sine wave burst:
- Frequentie: ~2000 Hz
- Duur: 50-100ms
- Sharp attack, fast decay
- Bundel als `click.caf` (Core Audio Format, iOS native)

## Definition of Done

- [ ] Clicker view met full-screen tap target
- [ ] Click geluid met < 50ms latency
- [ ] Haptic feedback
- [ ] Geluid toggle (aan/uit)
- [ ] Trilling toggle (aan/uit)
- [ ] Toegankelijk vanuit training view

Delete this file when done.
