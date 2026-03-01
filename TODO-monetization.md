# Monetization Implementation Plan

## Business Model

| Aspect | Decision |
|--------|----------|
| **Model** | Freemium + subscription (Otis+) |
| **Free tier** | Core logging forever, basic features |
| **Price** | €2.99/month or €24.99/year |
| **Scope** | Per Apple ID (all dogs included) |
| **Trial** | 7 days of Otis+ free for new users |

## Positioning

**"Otis is gratis. Otis+ geeft je superkrachten."**

Core puppy tracking is free forever — no time limits, no event limits. Otis+ unlocks smart insights, predictions, and advanced features for users who want more.

**Key message:**
> "Log alles over je puppy, helemaal gratis. Wil je slimme inzichten en voorspellingen? Probeer Otis+ 7 dagen gratis."

This framing:
- Core value is genuinely free (not a crippled trial)
- Premium feels like an upgrade, not a paywall
- Users build data dependency before seeing premium value
- Competitive advantage: "the only free puppy tracker"

## What's Free vs Otis+

### Free Forever
- **All event logging** (unlimited, all types)
- **Timeline view** with day navigation
- **Quick-log bar** (full functionality)
- **Basic daily stats** (today's summary, event counts)
- **Training library** (first 10 commands, browse only)
- **Socialization checklist** (view items, no progress tracking)
- **Clicker tool** (full functionality)
- **1 partner sharing** (via CloudKit)

### Otis+ (€2.99/mo or €24.99/yr)
- Everything in Free, plus:
- **Smart potty predictions** with trigger adjustments
- **Advanced analytics** (patterns, trends, gaps analysis)
- **Sleep insights** (night quality, nap tracking)
- **Week-in-review summaries**
- **Full training library** (30+ commands with progress tracking)
- **Socialization tracking** (mark complete, see progress %)
- **Photo/video attachments** on events
- **Unlimited partner sharing**
- **Export/PDF** for vet visits
- **Future premium features**

## Technical Implementation

### 1. Model Changes

**New file: Models/SubscriptionStatus.swift**
```swift
import Foundation

struct SubscriptionStatus: Codable {
    var isOtisPlus: Bool
    var expirationDate: Date?
    var isInTrialPeriod: Bool

    var isActive: Bool {
        isOtisPlus && (expirationDate == nil || expirationDate! > Date())
    }

    static let free = SubscriptionStatus(isOtisPlus: false, expirationDate: nil, isInTrialPeriod: false)
}
```

**No changes to PuppyProfile** — subscription is per Apple ID, not per dog.

### 2. StoreKit 2 Integration

**New file: Services/SubscriptionManager.swift**
```swift
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    static let monthlyProductID = "com.ollie.plus.monthly"    // €2.99/mo
    static let yearlyProductID = "com.ollie.plus.yearly"      // €24.99/yr

    @Published var products: [Product] = []
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var purchaseState: PurchaseState = .idle

    enum PurchaseState {
        case idle, purchasing, purchased, failed(Error)
    }

    // Check entitlement status on app launch
    func checkSubscriptionStatus() async { ... }

    // Load available products from App Store
    func loadProducts() async { ... }

    // Purchase a subscription
    func purchase(_ product: Product) async throws { ... }

    // Restore purchases (for new device / reinstall)
    func restorePurchases() async { ... }

    // Listen for transaction updates
    func listenForTransactions() async { ... }
}
```

**Note:** Auto-renewable subscriptions. StoreKit 2 handles trial eligibility automatically.

### 3. Subscription Tracking

StoreKit 2 manages subscription state via `Transaction.currentEntitlements`. No need to store locally — always check with StoreKit on app launch.

```swift
// On app launch:
for await result in Transaction.currentEntitlements {
    if case .verified(let transaction) = result {
        // User has active subscription
        subscriptionStatus = SubscriptionStatus(
            isOtisPlus: true,
            expirationDate: transaction.expirationDate,
            isInTrialPeriod: transaction.offerType == .introductory
        )
    }
}
```

### 4. UI Changes

#### Otis+ Upsell Points
Show upgrade prompts when users try to access premium features:

**Predictions card (InsightsView):**
```
┌─────────────────────────────────────────┐
│ 🔮 Slimme voorspellingen                │
│                                         │
│ Otis+ voorspelt wanneer je puppy       │
│ weer moet plassen op basis van          │
│ zijn patronen.                          │
│                                         │
│   [Probeer Otis+ gratis]               │
└─────────────────────────────────────────┘
```

**Training progress (locked commands):**
```
┌─────────────────────────────────────────┐
│ 🔒 20+ extra commando's                 │
│                                         │
│ Ontgrendel de volledige trainings-      │
│ bibliotheek met Otis+.                 │
│                                         │
│   [Bekijk Otis+]                       │
└─────────────────────────────────────────┘
```

#### Settings Screen
Add section:
```
Otis+
├─ Status: Gratis / Otis+ (maandelijks) / Otis+ (jaarlijks)
├─ [Upgrade naar Otis+]     (if free)
├─ [Beheer abonnement]       (if subscribed, opens App Store)
└─ [Herstel aankoop]         (always visible)
```

#### Subscription Sheet (OtisPlusSheet.swift)
Full-screen sheet showing:
- Feature comparison (free vs Otis+)
- Pricing options (monthly / yearly with savings badge)
- 7-day free trial callout
- Terms & restore link

### 5. Feature Gating Logic

**Create: Utils/FeatureGating.swift**
```swift
enum PremiumFeature {
    case predictions
    case advancedAnalytics
    case sleepInsights
    case weekReview
    case fullTrainingLibrary
    case socializationTracking
    case photoAttachments
    case unlimitedSharing
    case exportPDF
}

extension SubscriptionManager {
    func hasAccess(to feature: PremiumFeature) -> Bool {
        subscriptionStatus.isActive
    }
}
```

**Usage in views:**
```swift
// Show locked state for premium features
if subscriptionManager.hasAccess(to: .predictions) {
    PredictionsCard()
} else {
    PredictionsLockedCard(onUpgrade: { showOtisPlusSheet = true })
}

// Photo attachment button
Button("Add photo") { ... }
    .disabled(!subscriptionManager.hasAccess(to: .photoAttachments))
```

**Training library gating:**
```swift
// First 10 commands always visible
let freeCommands = trainingLibrary.prefix(10)
let premiumCommands = trainingLibrary.dropFirst(10)

ForEach(freeCommands) { command in
    CommandRow(command)
}

if subscriptionManager.hasAccess(to: .fullTrainingLibrary) {
    ForEach(premiumCommands) { command in
        CommandRow(command)
    }
} else {
    LockedCommandsRow(count: premiumCommands.count, onUpgrade: { ... })
}
```

## Dutch Copy

### Otis+ Sheet (main upsell)
- Title: "Otis+"
- Subtitle: "Haal meer uit je puppy-data"
- Trial callout: "Probeer 7 dagen gratis"
- Monthly: "€2,99/maand"
- Yearly: "€24,99/jaar" + badge "Bespaar 30%"
- CTA button: "Start gratis proefperiode"
- Footer: "Abonnement verlengt automatisch. Annuleer wanneer je wilt."

### Feature Locked States
- Predictions: "Ontgrendel slimme voorspellingen met Otis+"
- Analytics: "Bekijk patronen en trends met Otis+"
- Training: "Ontgrendel 20+ extra commando's met Otis+"
- Photos: "Voeg foto's toe met Otis+"
- Export: "Exporteer naar PDF met Otis+"

### Settings
- Section title: "Otis+"
- Status values: "Gratis" / "Otis+ (proefperiode)" / "Otis+ (maandelijks)" / "Otis+ (jaarlijks)"
- Upgrade button: "Upgrade naar Otis+"
- Manage button: "Beheer abonnement"
- Restore button: "Herstel aankoop"

### Purchase Success
- "Welkom bij Otis+! Je hebt nu toegang tot alle functies."

### Restore Success
- "Abonnement hersteld. Welkom terug!"

### Trial Ending (push notification, day 6)
- "Je Otis+ proefperiode eindigt morgen. Blijf genieten van slimme inzichten?"

### App Store Description (snippet)
- "Otis is gratis — log alles over je puppy zonder limiet. Upgrade naar Otis+ voor slimme voorspellingen, geavanceerde statistieken en meer."

## App Store Setup

### 1. Create Subscription Group
In App Store Connect → Subscriptions:
- Group name: "Otis+"
- Group ID: `ollie_plus`

### 2. Create Subscription Products

**Monthly:**
- Product ID: `com.ollie.plus.monthly`
- Reference Name: "Otis+ Monthly"
- Price: €2.99 (Tier 3)
- Duration: 1 month

**Yearly:**
- Product ID: `com.ollie.plus.yearly`
- Reference Name: "Otis+ Yearly"
- Price: €24.99 (Tier 25)
- Duration: 1 year

### 3. Configure Free Trial
- Introductory Offer: 7-day free trial
- Applies to: Both monthly and yearly
- Eligibility: New subscribers only (StoreKit handles this)

### 4. Localized Metadata (Dutch)

**Display Name:** "Otis+"

**Description:**
"Haal meer uit Otis met slimme voorspellingen, geavanceerde statistieken, de volledige trainingsbibliotheek, en meer."

**Subscription Group Display Name:** "Otis+ Abonnement"

### 5. Review Notes
```
Otis is a puppy tracking app. Core features (event logging, timeline,
basic stats) are free forever with no limits.

Otis+ subscription unlocks:
- Smart potty predictions
- Advanced analytics and patterns
- Full training library (30+ commands)
- Socialization progress tracking
- Photo/video attachments
- Export to PDF
- Unlimited partner sharing

Pricing:
- €2.99/month or €24.99/year
- 7-day free trial for new subscribers

The app is fully functional without a subscription. Otis+ adds
convenience features and insights for power users.
```

## Implementation Order

### Phase 1: Core Infrastructure
- [ ] Create `SubscriptionStatus` model
- [ ] Create `SubscriptionManager` service with StoreKit 2
- [ ] Implement `checkSubscriptionStatus()` on app launch
- [ ] Implement `listenForTransactions()` for real-time updates
- [ ] Add `@EnvironmentObject` for SubscriptionManager in app

### Phase 2: App Store Connect Setup
- [ ] Create subscription group "Otis+"
- [ ] Create monthly product (com.ollie.plus.monthly)
- [ ] Create yearly product (com.ollie.plus.yearly)
- [ ] Configure 7-day free trial as introductory offer
- [ ] Add localized metadata (Dutch)
- [ ] Create StoreKit configuration file for testing

### Phase 3: Feature Gating
- [ ] Create `PremiumFeature` enum and gating helper
- [ ] Gate predictions/analytics in InsightsView
- [ ] Gate training library (first 10 free, rest locked)
- [ ] Gate socialization progress tracking
- [ ] Gate photo/video attachments
- [ ] Gate export/PDF functionality
- [ ] Gate unlimited partner sharing (allow 1 free)

### Phase 4: Subscription UI
- [ ] Create `OtisPlusSheet` (main upsell screen)
- [ ] Create locked feature cards (predictions, training, etc.)
- [ ] Add Otis+ section to Settings
- [ ] Implement purchase flow with loading states
- [ ] Implement restore purchases
- [ ] Add "Manage subscription" link (opens App Store)

### Phase 5: Polish & Testing
- [ ] Test purchase flow in sandbox (monthly)
- [ ] Test purchase flow in sandbox (yearly)
- [ ] Test free trial flow
- [ ] Test restore purchases on new device
- [ ] Test subscription expiration handling
- [ ] Test offline behavior
- [ ] Add trial ending notification (day 6)
- [ ] Submit for App Review

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| App reinstalled | StoreKit restores subscription automatically |
| New device | Subscription transfers via Apple ID |
| Multiple dogs | One subscription covers all dogs |
| Subscription expires | Graceful downgrade to free (keep all data) |
| Subscription renews | Automatic, no user action needed |
| Trial ends, no purchase | Downgrade to free tier |
| Offline | Cache last known status, re-check when online |
| Family Sharing | Works automatically if enabled in ASC |
| Refund requested | Apple handles, app loses access on next check |

## Future Considerations

- **Promo codes:** Generate for reviewers, influencers, beta testers
- **Offer codes:** Time-limited discounts (e.g., 50% off first year)
- **Win-back offers:** Re-engage churned subscribers
- **Family Sharing:** Enable in App Store Connect (one sub = whole family)
- **Subscription upgrades:** Allow monthly → yearly upgrade with prorated credit

## Metrics to Track

- Trial start rate (% of users who start trial)
- Trial → paid conversion rate
- Monthly vs yearly split
- Churn rate (monthly, yearly)
- Revenue per user (ARPU)
- Feature-specific upgrade triggers (which locked feature drives most conversions?)

---

Delete this file when monetization is fully implemented and shipped.
