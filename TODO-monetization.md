# Monetization Implementation Plan

## Business Model

| Aspect | Decision |
|--------|----------|
| **Model** | Free intro period + one-time purchase |
| **Free period** | 21 days per dog profile |
| **Price** | €19 one-time (non-consumable IAP) |
| **Scope** | Per dog profile (multi-dog = multi-purchase) |
| **After free period** | View-only mode (all data preserved, no new logging) |

## Positioning

**Not a "trial" — a gift during the hardest weeks.**

New puppy owners are overwhelmed in the first 3 weeks. Ollie is free exactly when they need it most. If they're still using it after that, €19 is a no-brainer.

**Key message:**
> "De eerste weken met een nieuwe puppy zijn overweldigend. Daarom is Ollie gratis als je het het hardst nodig hebt."

This framing:
- Feels generous, not extractive
- Acknowledges the user's struggle
- Positions payment as fair exchange for ongoing value
- Avoids "trial" language that implies limited/crippled experience

## What's Free vs Premium

### Free (first 21 days)
- Full event logging (all types)
- Timeline view with day navigation
- All historical data access
- Basic stats visible
- Quick-log bar

### Free (after 21 days)
- View-only access to all existing data
- Timeline browsing (no new events)
- Day navigation
- Cannot log new events

### Premium (€19 unlocks)
- Unlimited logging (no time limit)
- Full stats dashboard (patterns, streaks, gaps)
- Potty predictions with trigger adjustments
- Photo/video attachments
- Data export functionality
- Future premium features

## Technical Implementation

### 1. Model Changes

**PuppyProfile.swift** — add fields:
```swift
struct PuppyProfile: Codable {
    // ... existing fields ...

    var freeStartDate: Date      // Set on profile creation
    var isPremiumUnlocked: Bool   // Set to true after purchase

    var freeDaysRemaining: Int {
        guard !isPremiumUnlocked else { return -1 } // -1 = unlimited
        let daysSinceStart = Calendar.current.dateComponents([.day], from: freeStartDate, to: Date()).day ?? 0
        return max(0, 21 - daysSinceStart)
    }

    var isFreePeriodExpired: Bool {
        !isPremiumUnlocked && freeDaysRemaining <= 0
    }

    var canLogEvents: Bool {
        isPremiumUnlocked || !isFreePeriodExpired
    }
}
```

### 2. StoreKit 2 Integration

**New file: Services/StoreKitManager.swift**
```swift
import StoreKit

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    static let premiumProductID = "com.ollie.premium.perdog"

    @Published var premiumProduct: Product?
    @Published var purchaseState: PurchaseState = .idle

    enum PurchaseState {
        case idle, purchasing, purchased, failed(Error)
    }

    func loadProducts() async { ... }
    func purchase() async throws { ... }
    func restorePurchases() async { ... }
}
```

**Note:** Non-consumable IAP. Each profile needs its own purchase record (store profile ID with transaction).

### 3. Purchase Tracking

Need to track which profiles have been unlocked. Options:

**Option A: Local UserDefaults**
```swift
// Store array of unlocked profile IDs
UserDefaults.standard.set(unlockedProfileIDs, forKey: "unlockedProfiles")
```

**Option B: Store in profile.json** (simpler)
```swift
// isPremiumUnlocked flag in PuppyProfile
// Risk: user could edit JSON, but low stakes
```

**Recommendation:** Option B (keep it simple). For a €19 app, elaborate anti-piracy isn't worth it.

### 4. UI Changes

#### Status Banner (during free period)
Subtle banner in TimelineView — don't nag during the hard weeks:
```
┌─────────────────────────────────────────┐
│ Nog 14 dagen gratis                     │
└─────────────────────────────────────────┘
```
Tappable → opens upgrade sheet (but keep it subtle).

#### Expired State
When free period ends, overlay on quick-log bar:
```
┌─────────────────────────────────────────┐
│ Je gratis periode is voorbij            │
│                                         │
│ De eerste 3 weken met een puppy zijn    │
│ het zwaarst — daarom was Ollie gratis.  │
│ Wil je blijven loggen?                  │
│                                         │
│   [Doorgaan met Ollie — €19]            │
│   [Herstel aankoop]                     │
└─────────────────────────────────────────┘
```

#### Settings Screen
Add section:
```
Ollie Premium
├─ Status: Gratis (nog 7 dagen) / Premium / Gratis periode voorbij
├─ [Doorgaan met Ollie — €19]  (if not premium)
└─ [Herstel aankoop]           (if not premium)
```

### 5. Gating Logic

**QuickLogBar.swift / LogEventSheet.swift:**
```swift
if !profile.canLogEvents {
    // Show upgrade prompt instead of log UI
    UpgradePromptView()
} else {
    // Normal logging UI
}
```

**TimelineView.swift:**
```swift
// Always allow viewing, just disable add button
Button("Log event") { ... }
    .disabled(!profile.canLogEvents)
```

## Dutch Copy

### During Free Period
- Banner: "Nog X dagen gratis"
- Subtle, non-intrusive — user is in the overwhelming phase

### Free Period Ended
- Title: "Je gratis periode is voorbij"
- Body: "De eerste 3 weken met een puppy zijn het zwaarst — daarom was Ollie gratis. Wil je blijven loggen? Dat kan voor eenmalig €19."
- Button: "Doorgaan met Ollie — €19"
- Secondary: "Herstel aankoop"

### Settings
- Section title: "Ollie Premium"
- Status label: "Status"
- Values: "Gratis (nog X dagen)" / "Premium" / "Gratis periode voorbij"

### Purchase Success
- "Gelukt! Je kunt nu onbeperkt blijven loggen voor [puppyname]."

### Restore Success
- "Aankoop hersteld voor [puppyname]."

### App Store Description (snippet)
- "Ollie is gratis voor de eerste 3 weken — precies wanneer je het het hardst nodig hebt. Daarna eenmalig €19 om te blijven loggen."

## App Store Setup

1. **Create non-consumable IAP** in App Store Connect
   - Product ID: `com.ollie.premium.perdog`
   - Reference Name: "Ollie Premium (per dog)"
   - Price: Tier 15 (€19.99) or custom €19.00

2. **Localized metadata (Dutch)**
   - Display Name: "Ollie Premium"
   - Description: "Ontgrendel onbeperkt loggen voor je puppy, plus statistieken, voorspellingen en meer."

3. **Review notes**
   - Explain per-dog model
   - Free period details (21 days full access, then view-only)

## Implementation Order

### Phase 1: Core Infrastructure
- [ ] Add `freeStartDate` and `isPremiumUnlocked` to PuppyProfile
- [ ] Add computed properties (`freeDaysRemaining`, `isFreePeriodExpired`, `canLogEvents`)
- [ ] Migration: set `freeStartDate = Date()` for existing profiles
- [ ] Create StoreKitManager service

### Phase 2: Gating
- [ ] Disable logging UI when `!canLogEvents`
- [ ] Show upgrade prompt when trying to log after free period
- [ ] Keep all read/view functionality working

### Phase 3: Purchase Flow
- [ ] Implement purchase flow in StoreKitManager
- [ ] Create UpgradePromptView
- [ ] Add upgrade button to Settings
- [ ] Handle restore purchases
- [ ] Update `isPremiumUnlocked` on successful purchase

### Phase 4: Status UI
- [ ] Add "Nog X dagen gratis" banner to TimelineView
- [ ] Show days remaining
- [ ] Add Premium section to Settings

### Phase 5: Polish
- [ ] Test purchase flow in sandbox
- [ ] Test free period expiration edge cases
- [ ] Test restore purchases
- [ ] Test new profile creation (fresh free period)
- [ ] Submit IAP for review

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| New profile created | Free period starts at creation date |
| Profile deleted & recreated | New free period (it's a new profile) |
| App reinstalled | Profile restored from file, free period continues from original date |
| Multiple dogs | Each profile has own free/premium status |
| Clock manipulation | Accept it — not worth fighting for €19 |
| Offline purchase | StoreKit handles this |

## Future Considerations

- **Family Sharing:** Could enable for IAP (one purchase = whole family)
- **Promo codes:** Generate for reviewers, influencers
- **Sale pricing:** Occasional €14.99 promotions
- **Bundle:** If we add more apps, bundle discount

---

Delete this file when monetization is fully implemented and shipped.
