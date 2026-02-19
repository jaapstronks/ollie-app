# TODO: Weather at Walk Times

Show compact weather forecasts alongside upcoming walk/potty moments so you know what to expect before heading outside.

## Concept

On the timeline/home screen, near the potty prediction or next-walk suggestion:

```
┌─────────────────────────────────┐
│ 🚶 Volgende uitlaat ~15:30      │
│ ⛅ 12° · 30% 🌧️ · 💨 15 km/h   │
└─────────────────────────────────┘
```

And for the next few hours (scrollable):

```
14:00  ☀️  13°  10% 🌧️  💨 8
15:00  ⛅  12°  30% 🌧️  💨 15
16:00  🌧️  11°  80% 🌧️  💨 20  ← neem een handdoek mee
17:00  ⛅  10°  20% 🌧️  💨 12
```

## Data Source: Open-Meteo API (free, no key needed)

```
GET https://api.open-meteo.com/v1/forecast?latitude=51.92&longitude=4.48&hourly=temperature_2m,precipitation_probability,weathercode,windspeed_10m&timezone=Europe/Amsterdam&forecast_days=1
```

- **Free**, no API key, no account
- Hourly forecasts
- Weather codes map to icons (WMO standard)
- Rotterdam coords: `51.9225, 4.4792`

For generalized version: use device location (CoreLocation) or profile city.

## Step 1: Weather Service

Create `Services/WeatherService.swift`:

```swift
struct HourForecast: Codable {
    let time: Date
    let temperature: Double      // °C
    let precipProbability: Int   // 0-100%
    let weatherCode: Int         // WMO code
    let windSpeed: Double        // km/h
    
    var icon: String {
        // WMO weather codes → SF Symbols or emoji
        switch weatherCode {
        case 0: return "☀️"           // Clear
        case 1, 2: return "⛅"        // Partly cloudy
        case 3: return "☁️"           // Overcast
        case 45, 48: return "🌫️"     // Fog
        case 51, 53, 55: return "🌦️"  // Drizzle
        case 61, 63, 65: return "🌧️"  // Rain
        case 71, 73, 75: return "🌨️"  // Snow
        case 80, 81, 82: return "🌧️"  // Showers
        case 95, 96, 99: return "⛈️"  // Thunderstorm
        default: return "🌤️"
        }
    }
    
    var windWarning: Bool { windSpeed > 40 }
    var rainWarning: Bool { precipProbability > 60 }
}

class WeatherService {
    func fetchHourlyForecast(lat: Double, lon: Double) async throws -> [HourForecast]
    
    // Cache for 30 minutes (don't spam the API)
    private var cache: (forecasts: [HourForecast], fetched: Date)?
}
```

## Step 2: Weather Widget View

Create `Views/WeatherBar.swift`:

Compact horizontal strip, shows next 4-6 hours:

```swift
struct WeatherBar: View {
    let forecasts: [HourForecast]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(forecasts) { hour in
                    VStack(spacing: 4) {
                        Text(hour.time, format: .dateTime.hour())  // "15"
                            .font(.caption2)
                        Text(hour.icon)
                            .font(.title3)
                        Text("\(Int(hour.temperature))°")
                            .font(.caption)
                            .fontWeight(.medium)
                        if hour.precipProbability > 10 {
                            Text("\(hour.precipProbability)%🌧️")
                                .font(.caption2)
                                .foregroundStyle(hour.rainWarning ? .red : .secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
```

## Step 3: Integration with Timeline

Show the weather bar:
1. **Above the potty status card** — always visible context for "should I go outside now?"
2. **Next to potty predictions** — when the prediction says "~15:30", show that hour's weather
3. **Walk logging** — after logging an `uitlaten` event, show current conditions (auto-attach to note?)

## Step 4: Smart Alerts

Optional subtle hints:

```swift
// If rain is coming within predicted potty time:
"🌧️ Regen verwacht om 15:00 — misschien nu alvast even naar buiten?"

// If it's freezing:
"🥶 -2° buiten — kort tuinbezoek is genoeg"

// Good weather window:
"☀️ Droog tot 16:00 — goed moment voor een wandeling"
```

These show as a banner above the timeline when relevant.

## Step 5: Location

For now: hardcode Rotterdam coordinates.
After generalization (PuppyProfile): add a location field or use CoreLocation.

```swift
// Quick solution for now
let defaultLocation = (lat: 51.9225, lon: 4.4792) // Rotterdam

// Later: CoreLocation
func requestLocation() async -> CLLocationCoordinate2D?
```

## Caching & Network

- Cache forecasts for 30 minutes
- Show cached data immediately, refresh in background
- Graceful degradation: if offline, hide weather bar (don't show errors)
- Max 1 API call per 30 min (Open-Meteo is free but be respectful)

## Done Criteria
- [ ] Weather bar on home screen showing next 4-6 hours
- [ ] Emoji icons for weather conditions
- [ ] Temperature, rain probability, wind speed
- [ ] Rain/wind warnings highlighted
- [ ] Smart alerts when weather affects walk timing
- [ ] 30-min cache, works offline (shows last data)
- [ ] No API key needed

Delete this file when done.
