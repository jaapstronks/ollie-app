# Design Briefing 6: Contextual Atmosphere — Time, Weather, and State Awareness

## Problem Statement

The Ollie app looks identical at 6 AM and 9 PM, on a rainy Tuesday and a sunny Saturday, whether Ollie is sleeping or mid-walk. The interface is static—a utility frozen in time.

The weather widget on the Today tab shows temperature and rain prediction, but this data doesn't influence the visual experience. The app tells you the weather; it doesn't feel like the weather.

This static quality reinforces the "task manager" feeling. A living companion app should feel alive—subtly aware of context, gently shifting with the rhythm of the day and the world outside.

---

## Design Direction

Introduce **subtle contextual shifts** that make the app feel alive and aware, without becoming gimmicky or distracting. The keyword is *subtle*—these should be felt more than noticed.

The atmosphere should respond to:
1. **Time of day:** Morning feels different from evening
2. **Ollie's state:** Sleeping feels calmer than active
3. **Weather conditions:** Rainy days have a different vibe than sunny ones
4. **Season (optional):** A light touch of seasonal awareness

---

## Time-of-Day Theming

### Concept

The app's color temperature and energy shift subtly throughout the day, creating an ambient connection to real-world time.

### Time Periods

| Period | Time Range | Mood | Color Shift |
|--------|------------|------|-------------|
| Early Morning | 5:00 - 7:00 | Quiet awakening | Cool blues, soft lavender, low saturation |
| Morning | 7:00 - 11:00 | Fresh energy | Warm yellows, increasing brightness |
| Midday | 11:00 - 14:00 | Peak activity | Neutral, full brightness, crisp |
| Afternoon | 14:00 - 17:00 | Sustained warmth | Golden undertones |
| Evening | 17:00 - 20:00 | Winding down | Warm oranges, amber tints |
| Night | 20:00 - 23:00 | Calm settling | Deep blues, reduced brightness |
| Late Night | 23:00 - 5:00 | Rest | Dark, muted, night-mode feel |

### Implementation

**Background tints:**
- The app's background isn't pure white (#FFFFFF) but shifts slightly:
  - Morning: `#FFFEF8` (warm white)
  - Evening: `#FFF8F0` (amber white)
  - Night: System dark mode or `#F5F5F5` with warm undertone

**Accent intensity:**
- Colors become slightly more saturated in morning/midday
- Colors soften and warm in evening
- Night: reduced saturation, calmer palette

**Transition:**
- Changes happen gradually (not sudden at exact times)
- Use 30-60 minute transition windows
- Never jarring—user shouldn't consciously notice the shift

### Dark Mode Integration

- Time-of-day theming works within both light and dark modes
- In dark mode: background shifts from neutral dark to warmer dark in evening
- Early morning in dark mode: cooler dark tones
- Evening in dark mode: slightly warmer dark tones

---

## State Awareness

### Concept

When Ollie is sleeping, the app should feel calmer. When Ollie is awake and active, the app should feel more energetic.

### Sleeping State

Visual indicators:
- **Reduced saturation:** Colors become slightly muted
- **Softer contrasts:** Sharp edges feel softer
- **Hero section:** Blue/purple tints, moon/stars subtle iconography
- **Activity level:** Less visual "noise," calmer layout

Messaging:
- "Ollie is sleeping" displayed prominently
- "Shhh..." micro-copy where appropriate
- De-emphasized action buttons (don't encourage interruption)

### Awake/Active State

Visual indicators:
- **Full saturation:** Colors at normal vibrancy
- **Higher energy:** Standard contrast, crisp elements
- **Hero section:** Warmer tones, sun iconography
- **Prominent actions:** Walk, potty, meal buttons highlighted

### On Walk State

When Ollie is currently on a walk:
- **Green/outdoor tints:** Subtle green wash on hero
- **Activity indicators:** Steps, duration, route (if tracking)
- **Quick actions:** Potty logging prominently available
- **Map preview:** Could show current location

### Transition Animations

State changes should animate smoothly:
- User logs "woke up" → screen subtly brightens (0.5s)
- User logs "started nap" → colors soften (0.5s)
- Transitions should feel natural, not dramatic

---

## Weather Integration

### Beyond Data Display

Currently, weather is displayed as text/numbers. The goal is to let weather influence atmosphere.

### Weather-Atmosphere Mapping

| Condition | Atmospheric Effect |
|-----------|-------------------|
| Sunny/Clear | Warm golden tint, bright feel |
| Cloudy | Neutral, slightly cooler tones |
| Rainy | Cool blue-gray tint, subdued brightness |
| Stormy | Darker overlay, muted colors |
| Snowy | Cool white/blue tint, soft feel |
| Hot (>25°C) | Very warm tones, high brightness |
| Cold (<5°C) | Cool tones, crisp feel |

### Implementation

**Hero section background:**
- Gradient that reflects current conditions
- Sunny: warm yellow-to-white gradient
- Rainy: soft blue-gray gradient
- Evening + rainy: deep blue-purple gradient

**Weather-aware messaging:**
- Sunny: "Perfect walking weather!" on walk suggestions
- Rainy: "Indoor play day?" with training suggestions
- Cold: "Bundle up!" reminder

**Subtlety requirement:**
- These effects should be background, not foreground
- User should never think "why is my app blue?"
- More of a mood than a statement

---

## Seasonal Touches (Optional)

### Concept

Very light seasonal elements that change over months, adding to the sense that the app is a living companion.

### Implementation Ideas

**Subtle only:**
- Spring: Slightly fresher greens in the outdoor palette
- Summer: Warmer, more vibrant overall
- Autumn: Amber/orange undertones
- Winter: Cooler, crisper feel

**Decorative elements (opt-in):**
- Small seasonal icons in corners (falling leaves, snowflakes)
- Holiday-specific celebration enhancements
- Must be toggleable/disableable

**Avoid:**
- Heavy-handed theming
- Mandatory decorations
- Cultural assumptions about holidays

---

## Technical Implementation

### Atmosphere Engine

Create an `AtmosphereProvider` that calculates current atmospheric state:

```swift
struct AtmosphereState {
    let timeOfDay: TimeOfDayPeriod
    let puppyState: PuppyActivityState
    let weather: WeatherCondition?
    let season: Season

    var backgroundColor: Color { /* calculated */ }
    var accentModifier: Double { /* saturation adjustment */ }
    var mood: AtmosphereMood { /* calm, neutral, energetic */ }
}

class AtmosphereProvider: ObservableObject {
    @Published var currentAtmosphere: AtmosphereState

    func update(time: Date, puppyState: PuppyActivityState, weather: WeatherCondition?)
}
```

### Color Token System

Define atmosphere-aware color tokens:

```swift
extension Color {
    static func adaptiveBackground(for atmosphere: AtmosphereState) -> Color
    static func adaptiveAccent(for atmosphere: AtmosphereState) -> Color
    // etc.
}
```

### Performance Considerations

- Atmosphere updates should be throttled (max once per minute)
- Color transitions use GPU-accelerated animation
- No heavy computation in render path
- Cache atmosphere state, don't recalculate per view

### Weather Data Source

- Use existing weather API integration
- Cache weather data (update every 30 min max)
- Handle offline gracefully (use last known or time-only atmosphere)

---

## User Preferences

### Settings Options

```
Atmosphere Settings
├─ Time-of-day effects: [On] / Off
├─ Weather atmosphere: [On] / Off
├─ State awareness: [On] / Off
└─ Seasonal touches: On / [Off]
```

Default: Time and state on, weather on, seasonal off (opt-in).

### Accessibility

- Reduced Motion: Disable all atmospheric animations
- High Contrast: Atmospheric effects reduce intensity significantly
- VoiceOver: No impact (atmosphere is purely visual)

---

## Edge Cases

### Traveling Across Time Zones

- App respects device local time
- Smooth transition as clock changes
- No jarring shift when landing in new timezone

### Extreme Weather

- Don't make the app unusable in extreme conditions
- Cap the intensity of atmospheric effects
- Example: Severe storm warning shouldn't make the app dark and gloomy to the point of unusability

### Device Battery/Performance

- Detect low power mode → reduce atmospheric effects
- Older devices → simpler/no atmospheric animations
- Background refresh affects weather data availability

### No Weather Data

- If weather data unavailable, use time-of-day only
- Never show error state for missing atmosphere data
- Degrade gracefully

---

## Animation Specifications

### Time Transitions

- Duration: 30-60 minute gradual shift
- Easing: linear (imperceptible change rate)
- No visible animation, just slow evolution

### State Transitions

- Duration: 0.5-1 second
- Easing: ease-in-out
- Smooth color temperature shift

### Weather Updates

- When weather data updates with different conditions:
- Duration: 3-5 second transition
- Crossfade between atmospheric states

---

## Integration with Other Features

### Hero Section (Briefing 1)

- Hero background is the primary canvas for atmospheric effects
- Photo overlay gradient adapts to atmosphere
- State display colors reflect current mood

### Visual Timeline (Briefing 2)

- Timeline blocks could subtly reflect time-of-day when event occurred
- Morning events slightly warmer tint
- Evening events slightly cooler tint
- (Very subtle, not required)

### Celebrations (Briefing 3)

- Celebration animations could incorporate current atmosphere
- Evening celebration: warmer confetti colors
- Morning celebration: brighter, more energetic

---

## Testing Considerations

### Manual Testing Scenarios

1. Open app at 6 AM, 12 PM, 6 PM, 10 PM—verify distinct feels
2. Log sleep event—verify calming shift
3. Log wake event—verify energizing shift
4. Test in sunny vs. rainy conditions
5. Test with weather data unavailable
6. Test dark mode + atmospheric effects

### User Testing Questions

- "Does the app feel different at different times?"
- "Did you notice any changes based on weather?"
- "Do these effects feel natural or distracting?"
- "Would you want to turn these effects off?"

---

## Open Questions

1. **Weather API dependency:** How to handle API costs/rate limits? Is this a premium feature?

2. **Regional weather:** Weather varies by microclimate. How precise should location be?

3. **Intensity dial:** Should there be a slider for "how much atmosphere" rather than on/off?

4. **Dark mode interaction:** Should atmospheric effects be stronger or weaker in dark mode?

5. **Watch app (future):** If Ollie gets a watch complication, should it also have atmospheric awareness?

6. **Widget atmosphere:** Should home screen widgets reflect atmospheric state?

---

## Reference Apps

- **Apple Weather:** Full atmospheric design—the gold standard for weather-as-environment
- **Calm:** Time-of-day backgrounds that shift morning to night
- **Oura Ring:** Daytime vs. nighttime view distinction
- **iOS Lock Screen:** Time-based wallpaper tinting, subtle and effective
- **Headspace:** Session visuals that shift with time and content
- **Sky Guide:** Time-aware interface showing current sky conditions

---

## Success Criteria

1. Users describe the app as "warm" or "alive" without knowing why
2. The atmosphere is noticed when pointed out but not consciously before
3. Zero complaints about atmosphere being distracting
4. Performance benchmarks show no degradation from atmospheric effects
5. Atmosphere enhances emotional connection without getting in the way
6. User preference settings have low "off" rate (most keep defaults)
