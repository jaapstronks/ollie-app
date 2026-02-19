# TODO: Lucide Icon System + Color Palette

Replace emoji with Lucide icons for a consistent, branded visual style. Accent color: warm orange-gold.

## Color Palette

```swift
// Brand colors
static let accent = Color(hex: "#E8A855")        // Warm gold — primary accent
static let accentLight = Color(hex: "#F5D08E")    // Light gold — backgrounds, badges
static let accentDark = Color(hex: "#C4872E")     // Deep amber — pressed states

// Semantic colors (derived)
static let success = Color(hex: "#5BAA6E")        // Green — buiten, positive
static let warning = Color(hex: "#E8A855")        // Gold — caution, transitions
static let danger = Color(hex: "#D4594E")         // Red — binnen, alerts
static let info = Color(hex: "#5BA4B5")           // Teal — stats, neutral data
static let sleep = Color(hex: "#7B8CC2")          // Muted blue — sleep events
static let muted = Color(hex: "#9CA3AF")          // Gray — secondary text
```

## Lucide Integration

### Swift Package
Add via SPM: `https://github.com/lucide-icons/lucide` or use the SVG assets directly.

Alternative: download just the needed SVGs from https://lucide.dev and add to Assets.xcassets as template images (single color, tintable).

### Event Type → Lucide Icon Mapping

| Event Type | Emoji (old) | Lucide Icon | Name | Notes |
|-----------|-------------|-------------|------|-------|
| `plassen` | 🚽 | 💧 | `droplets` | Tinted success/danger based on location |
| `poepen` | 💩 | 💩 | `circle-dot` | Or custom; tinted success/danger |
| `eten` | 🍽️ | 🍽️ | `utensils` | Accent color |
| `drinken` | 💧 | 💧 | `glass-water` | Info/teal |
| `slapen` | 😴 | 🌙 | `moon` | Sleep blue |
| `ontwaken` | ☀️ | ☀️ | `sun` | Accent gold |
| `uitlaten` | 🚶 | 🐾 | `footprints` | Accent color |
| `tuin` | 🌿 | 🌱 | `sprout` | Success green |
| `training` | 🎓 | 🎯 | `target` | Accent color |
| `bench` | 🏠 | 🏠 | `house` | Sleep blue |
| `sociaal` | 🐕 | 🐕 | `dog` | Accent color |
| `milestone` | ⭐ | ⭐ | `star` | Accent gold |
| `gedrag` | 📝 | ⚡ | `zap` | Warning amber |
| `gewicht` | ⚖️ | ⚖️ | `scale` | Muted gray |

### Weather Icons (for weather feature)

| Condition | Lucide Icon | Name |
|-----------|-------------|------|
| Clear | `sun` | ☀️ |
| Partly cloudy | `cloud-sun` | ⛅ |
| Overcast | `cloud` | ☁️ |
| Fog | `cloud-fog` | 🌫️ |
| Drizzle | `cloud-drizzle` | 🌦️ |
| Rain | `cloud-rain` | 🌧️ |
| Heavy rain | `cloud-rain-wind` | 🌧️💨 |
| Snow | `cloud-snow` | 🌨️ |
| Thunderstorm | `cloud-lightning` | ⛈️ |
| Wind | `wind` | 💨 |

### UI Icons

| Usage | Lucide Icon | Name |
|-------|-------------|------|
| Settings | `settings` | ⚙️ |
| Chat/AI | `message-circle` | 💬 |
| Stats | `bar-chart-3` | 📊 |
| Timeline | `clock` | ⏱️ |
| Photos | `camera` | 📷 |
| Add event | `plus-circle` | ➕ |
| Calendar/date | `calendar` | 📅 |
| Timer/countdown | `timer` | ⏲️ |
| Share | `share` | 📤 |
| Import | `download` | 📥 |

## Implementation

### Step 1: Add Lucide SVGs to Assets

1. Download needed icons from https://lucide.dev/icons (SVG)
2. Set stroke width to 2px (Lucide default, clean at small sizes)
3. Add to `Assets.xcassets` as "Template Image" (renders in tint color)
4. Or use the Lucide Swift package for programmatic access

### Step 2: Create Icon Helper

```swift
enum OllieIcon {
    case plassen, poepen, eten, drinken, slapen, ontwaken
    case uitlaten, tuin, training, bench, sociaal
    case milestone, gedrag, gewicht
    
    var imageName: String {
        switch self {
        case .plassen: return "lucide.droplets"
        case .poepen: return "lucide.circle-dot"
        case .eten: return "lucide.utensils"
        // ... etc
        }
    }
    
    var color: Color {
        switch self {
        case .plassen, .poepen: return .muted  // Overridden by location
        case .eten: return .accent
        case .slapen, .bench: return .sleep
        case .ontwaken: return .accent
        // ... etc
        }
    }
    
    /// Color based on potty location
    func pottyColor(location: PottyLocation?) -> Color {
        guard let loc = location else { return .muted }
        return loc == .buiten ? .success : .danger
    }
}
```

### Step 3: Icon View Component

```swift
struct EventIcon: View {
    let type: EventType
    var location: PottyLocation?
    var size: CGFloat = 24
    
    var body: some View {
        Image(icon.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundStyle(effectiveColor)
    }
}
```

### Step 4: Replace Emoji Throughout

- `EventRow` — replace emoji Text with EventIcon
- `QuickLogBar` — replace emoji buttons with tinted icons
- `LocationPickerSheet` — use icons instead of 🌳/🏠
- Tab bar — use Lucide icons
- Stats module headers — replace emoji prefixes

### Step 5: Update Web App (optional, later)

The web app can use the same Lucide icons via the web package:
```html
<script src="https://unpkg.com/lucide@latest"></script>
```
Same icon names, same visual language across platforms.

## Design Guidelines

- **Icon size in lists:** 24×24pt
- **Icon size in quick-log bar:** 28×28pt  
- **Icon size in sheets/modals:** 48×48pt
- **Stroke width:** 2px (Lucide default)
- **Always tintable:** use template rendering, never hardcode colors in SVGs
- **Dark mode:** icons should work on both light and dark backgrounds (the tint colors handle this)

## Done Criteria
- [ ] All emoji replaced with Lucide icons in iOS app
- [ ] Consistent color palette applied
- [ ] Icons tinted based on context (buiten=green, binnen=red)
- [ ] Dark mode looks good
- [ ] Quick-log bar uses icons instead of emoji
- [ ] Tab bar uses Lucide icons
- [ ] EventIcon reusable component

Delete this file when done.
