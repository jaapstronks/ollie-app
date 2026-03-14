# Brief: Sharing Infrastructure

> **Status:** Foundation
> **Priority:** High (Enables all sharing features)
> **Dependencies:** None
> **Estimated Effort:** Low-Medium

## Objective

Build a reusable sharing infrastructure that powers all shareable content in the app: recap cards, achievement cards, growth comparisons, and future shareable content. This is the foundation layer.

## Platform Capabilities & Limitations

### iOS Share Sheet (UIActivityViewController)

**What it supports:**
- Images (PNG, JPEG)
- Text (caption)
- URLs
- Works with any app that accepts these types

**Destinations:**
- iMessage ✅
- Mail ✅
- AirDrop ✅
- Save to Photos ✅
- Copy ✅
- Twitter/X ✅
- Facebook Feed ✅ (but not Stories)
- WhatsApp ✅
- Telegram ✅
- Other installed apps ✅

**Limitations:**
- No control over how content appears in destination app
- Can't directly post to Instagram feed
- Caption may not be included in all destinations

### Instagram Stories (Direct API)

**Requirements:**
- Instagram app installed
- URL scheme: `instagram-stories://share`
- Content passed via pasteboard

**Supported content:**
- Background image (required)
- Sticker image (optional overlay)
- Background color (if no image)
- Content URL (link back to app)

**Limitations:**
- Only for Stories, not feed posts
- User must still tap "Share" in Instagram
- No caption support (user types their own)

### Instagram Feed

**No direct API.** Options:
1. Save to Photos → User opens Instagram manually
2. Deep link to Instagram with photo ID (complex, undocumented)
3. Facebook SDK with Instagram publish permissions (requires app review)

**Recommendation:** For feed, save to Photos and show instructions.

### Facebook Stories (Direct API)

**Requirements:**
- Facebook app installed
- URL scheme: `facebook-stories://share`
- Content passed via pasteboard
- App ID from Facebook Developer Console

**Supported content:**
- Background image
- Sticker image
- App ID for attribution

**Limitations:**
- Requires Facebook App ID
- Only for Stories
- User must tap "Share" in Facebook

### Facebook Feed

**Options:**
1. Share sheet (works, but limited formatting)
2. Facebook SDK with `ShareDialog` (better control)

**Facebook SDK ShareDialog supports:**
- Photos
- Links with previews
- Hashtags

**Recommendation:** Start with share sheet; add SDK if needed.

### TikTok

**Requirements:**
- TikTok app installed
- TikTok SDK integration
- App registered in TikTok Developer Portal

**Supported content:**
- Videos (primary use case)
- Images (limited)

**Limitations:**
- SDK required for native sharing
- Video-focused platform
- Complex integration

**Recommendation:** Defer TikTok; use share sheet for now.

### WhatsApp

**Shares well via standard share sheet:**
- Images with captions ✅
- Links ✅

No special integration needed.

### Summary Table

| Platform | Feed | Stories | Method | Complexity |
|----------|------|---------|--------|------------|
| iMessage | ✅ | - | Share sheet | Low |
| Instagram | ⚠️ | ✅ | Stories API + Save | Medium |
| Facebook | ✅ | ✅ | Stories API + Share sheet | Medium |
| Twitter/X | ✅ | - | Share sheet | Low |
| WhatsApp | ✅ | ✅ | Share sheet | Low |
| TikTok | ⚠️ | - | SDK required | High |
| Save | ✅ | - | PHPhotoLibrary | Low |

## Architecture

### Core Services

```swift
// Services/Sharing/ShareService.swift
@MainActor
class ShareService: ObservableObject {

    // MARK: - Standard Share Sheet

    func share(
        image: UIImage,
        caption: String? = nil,
        from viewController: UIViewController
    ) {
        var items: [Any] = [image]
        if let caption = caption {
            items.append(caption)
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        activityVC.excludedActivityTypes = [
            .print,
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]

        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0, height: 0
            )
        }

        viewController.present(activityVC, animated: true)
    }

    // MARK: - Instagram Stories

    func shareToInstagramStories(
        backgroundImage: UIImage,
        stickerImage: UIImage? = nil
    ) async -> Bool {
        guard let url = URL(string: "instagram-stories://share"),
              UIApplication.shared.canOpenURL(url) else {
            return false
        }

        var pasteboardItems: [String: Any] = [:]

        if let imageData = backgroundImage.pngData() {
            pasteboardItems["com.instagram.sharedSticker.backgroundImage"] = imageData
        }

        if let sticker = stickerImage, let stickerData = sticker.pngData() {
            pasteboardItems["com.instagram.sharedSticker.stickerImage"] = stickerData
        }

        // App Store link
        pasteboardItems["com.instagram.sharedSticker.contentURL"] = "https://apps.apple.com/app/ollie-puppy-log/idXXXXXXXXX"

        UIPasteboard.general.setItems(
            [pasteboardItems],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )

        return await UIApplication.shared.open(url)
    }

    // MARK: - Facebook Stories

    func shareToFacebookStories(
        backgroundImage: UIImage
    ) async -> Bool {
        guard let url = URL(string: "facebook-stories://share"),
              UIApplication.shared.canOpenURL(url) else {
            return false
        }

        var pasteboardItems: [String: Any] = [:]

        if let imageData = backgroundImage.pngData() {
            pasteboardItems["com.facebook.sharedSticker.backgroundImage"] = imageData
        }

        pasteboardItems["com.facebook.sharedSticker.appID"] = "YOUR_FACEBOOK_APP_ID"

        UIPasteboard.general.setItems(
            [pasteboardItems],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )

        return await UIApplication.shared.open(url)
    }

    // MARK: - Save to Photos

    func saveToPhotos(_ image: UIImage) async throws {
        try await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    // MARK: - Platform Detection

    var isInstagramAvailable: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    var isFacebookAvailable: Bool {
        guard let url = URL(string: "facebook-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
```

### Card Renderer

```swift
// Services/Sharing/CardRenderer.swift
@MainActor
class CardRenderer {

    /// Render any SwiftUI view to an image
    func render<V: View>(
        _ view: V,
        size: CGSize = CGSize(width: 1080, height: 1920)
    ) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        // Force layout
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    /// Render with specific aspect ratio presets
    func render<V: View>(
        _ view: V,
        for format: ShareFormat
    ) -> UIImage? {
        render(view, size: format.size)
    }
}

enum ShareFormat {
    case story          // 9:16 (1080x1920) - Instagram/Facebook Stories
    case squarePost     // 1:1 (1080x1080) - Instagram/Facebook feed
    case portrait       // 4:5 (1080x1350) - Instagram feed optimal
    case landscape      // 16:9 (1920x1080) - Twitter/general

    var size: CGSize {
        switch self {
        case .story:
            return CGSize(width: 1080, height: 1920)
        case .squarePost:
            return CGSize(width: 1080, height: 1080)
        case .portrait:
            return CGSize(width: 1080, height: 1350)
        case .landscape:
            return CGSize(width: 1920, height: 1080)
        }
    }
}
```

### Shareable Card Protocol

```swift
// Models/ShareableCard.swift
protocol ShareableCard {
    associatedtype CardView: View

    var id: String { get }
    var type: ShareableCardType { get }
    var profile: PuppyProfile { get }
    var generatedDate: Date { get }

    func cardView(for format: ShareFormat) -> CardView
    func caption(for platform: SharePlatform) -> String
}

enum ShareableCardType: String {
    case weeklyRecap
    case monthlyRecap
    case yearRecap
    case achievement
    case thenVsNow
    case monthlyGrowth
    case growthChart
}

enum SharePlatform {
    case instagram
    case facebook
    case twitter
    case general

    var hashtagStyle: HashtagStyle {
        switch self {
        case .instagram: return .many      // Instagram loves hashtags
        case .twitter: return .few         // Twitter: 1-2 hashtags max
        case .facebook, .general: return .minimal
        }
    }

    enum HashtagStyle {
        case many       // Up to 5-10 hashtags
        case few        // 1-2 hashtags
        case minimal    // 0-1 hashtags
    }
}
```

### Caption Generator

```swift
// Services/Sharing/CaptionGenerator.swift
struct CaptionGenerator {

    func generate(
        for card: any ShareableCard,
        platform: SharePlatform
    ) -> String {
        var caption = card.caption(for: platform)

        // Add hashtags based on platform preference
        let hashtags = generateHashtags(for: card, style: platform.hashtagStyle)
        if !hashtags.isEmpty {
            caption += "\n\n" + hashtags.joined(separator: " ")
        }

        return caption
    }

    private func generateHashtags(
        for card: any ShareableCard,
        style: SharePlatform.HashtagStyle
    ) -> [String] {
        var tags = ["#OllieApp"]

        switch style {
        case .many:
            tags += [
                "#PuppyLife",
                "#DogMom", // or #DogDad
                "#\(card.profile.breed?.replacingOccurrences(of: " ", with: "") ?? "Dog")",
                "#PuppyLove",
                "#DogsOfInstagram"
            ]
        case .few:
            tags += ["#PuppyLife"]
        case .minimal:
            break
        }

        return tags
    }
}
```

## Share Options Sheet UI

### Standard Share Flow

```swift
// Views/Sharing/ShareOptionsSheet.swift
struct ShareOptionsSheet<Card: ShareableCard>: View {
    let card: Card
    @StateObject private var shareService = ShareService()
    @State private var selectedFormat: ShareFormat = .portrait
    @State private var renderedImage: UIImage?
    @State private var isRendering = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                cardPreview

                // Format picker
                formatPicker

                // Quick share buttons
                quickShareButtons

                // More options
                moreOptionsButton
            }
            .padding()
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await renderCard()
            }
            .onChange(of: selectedFormat) { _ in
                Task { await renderCard() }
            }
        }
    }

    private var cardPreview: some View {
        Group {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 8)
            } else {
                ProgressView("Generating...")
                    .frame(height: 400)
            }
        }
    }

    private var formatPicker: some View {
        Picker("Format", selection: $selectedFormat) {
            Text("Story").tag(ShareFormat.story)
            Text("Square").tag(ShareFormat.squarePost)
            Text("Portrait").tag(ShareFormat.portrait)
        }
        .pickerStyle(.segmented)
    }

    private var quickShareButtons: some View {
        HStack(spacing: 24) {
            // Instagram Stories
            if shareService.isInstagramAvailable {
                shareButton(
                    icon: "camera.fill",
                    label: "IG Story",
                    color: .purple
                ) {
                    await shareToInstagram()
                }
            }

            // Facebook Stories
            if shareService.isFacebookAvailable {
                shareButton(
                    icon: "book.fill",
                    label: "FB Story",
                    color: .blue
                ) {
                    await shareToFacebook()
                }
            }

            // Save to Photos
            shareButton(
                icon: "square.and.arrow.down",
                label: "Save",
                color: .green
            ) {
                await saveToPhotos()
            }

            // More (share sheet)
            shareButton(
                icon: "square.and.arrow.up",
                label: "More",
                color: .gray
            ) {
                await showShareSheet()
            }
        }
    }

    private func shareButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .foregroundStyle(.white)
                    .clipShape(Circle())

                Text(label)
                    .font(.caption)
            }
        }
    }

    @MainActor
    private func renderCard() async {
        isRendering = true
        renderedImage = CardRenderer().render(
            card.cardView(for: selectedFormat),
            for: selectedFormat
        )
        isRendering = false
    }

    private func shareToInstagram() async {
        guard let image = renderedImage else { return }
        _ = await shareService.shareToInstagramStories(backgroundImage: image)
        dismiss()
    }

    // ... other share methods
}
```

### Compact Share Button (Inline)

For use in cards/lists:

```swift
// Views/Components/ShareButton.swift
struct ShareButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
                .font(.body.weight(.medium))
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
    }
}
```

## Info.plist Configuration

Add URL schemes for platform detection:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram-stories</string>
    <string>instagram</string>
    <string>facebook-stories</string>
    <string>fb</string>
    <string>twitter</string>
    <string>tweetbot</string>
    <string>whatsapp</string>
</array>
```

## Photo Library Permission

For saving to Photos:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save shareable cards to your photo library</string>
```

## Watermark Component

Consistent branding across all cards:

```swift
// Views/Sharing/Components/ShareableWatermark.swift
struct ShareableWatermark: View {
    var style: WatermarkStyle = .standard

    enum WatermarkStyle {
        case standard   // "Made with Ollie 🐾"
        case minimal    // Just icon
        case detailed   // Icon + app name + URL
    }

    var body: some View {
        HStack(spacing: 8) {
            Image("OllieIcon")
                .resizable()
                .frame(width: 24, height: 24)

            if style != .minimal {
                Text("Made with Ollie")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if style == .detailed {
                Text("• ollie.app")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
```

## Analytics / Tracking

Track sharing behavior for optimization:

```swift
// Services/Sharing/ShareAnalytics.swift
struct ShareAnalytics {

    func trackShareAttempt(
        cardType: ShareableCardType,
        platform: SharePlatform,
        format: ShareFormat
    ) {
        // Log to analytics service
        Analytics.log("share_attempt", parameters: [
            "card_type": cardType.rawValue,
            "platform": platform.rawValue,
            "format": format.rawValue
        ])
    }

    func trackShareCompleted(
        cardType: ShareableCardType,
        platform: SharePlatform
    ) {
        Analytics.log("share_completed", parameters: [
            "card_type": cardType.rawValue,
            "platform": platform.rawValue
        ])
    }
}
```

## Implementation

### Files to Create

```
Ollie-app/Services/Sharing/ShareService.swift
Ollie-app/Services/Sharing/CardRenderer.swift
Ollie-app/Services/Sharing/CaptionGenerator.swift
Ollie-app/Services/Sharing/ShareAnalytics.swift
Ollie-app/Models/ShareableCard.swift
Ollie-app/Views/Sharing/ShareOptionsSheet.swift
Ollie-app/Views/Sharing/Components/ShareableWatermark.swift
Ollie-app/Views/Components/ShareButton.swift
```

### Files to Modify

```
Ollie-app/Info.plist
  - Add LSApplicationQueriesSchemes
  - Add NSPhotoLibraryAddUsageDescription (if not present)
```

## Testing Checklist

- [ ] Share sheet opens on all iOS versions (15+)
- [ ] Instagram Stories sharing works when Instagram installed
- [ ] Graceful fallback when Instagram not installed
- [ ] Facebook Stories sharing works when Facebook installed
- [ ] Save to Photos works with permission granted
- [ ] Save to Photos prompts for permission when needed
- [ ] Card renders correctly at all format sizes
- [ ] Watermark is visible but not intrusive
- [ ] Caption is included in share sheet
- [ ] iPad popover presentation works

## Error Handling

```swift
enum ShareError: LocalizedError {
    case renderFailed
    case platformNotAvailable
    case photoLibraryDenied
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Unable to create shareable image"
        case .platformNotAvailable:
            return "This app is not installed"
        case .photoLibraryDenied:
            return "Photo library access is required to save"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
```

## Notes

- Start with share sheet + Instagram Stories (highest ROI)
- Facebook requires App ID from developer console
- TikTok integration can be deferred (video-focused)
- Always provide "Save to Photos" as fallback
- Test on real devices (simulator doesn't have social apps)
- Consider adding share tutorials for first-time users
