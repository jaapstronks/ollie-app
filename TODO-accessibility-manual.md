# Accessibility Manual Testing & Fixes

This document contains accessibility tasks that require manual testing or verification that couldn't be automated.

## What Was Fixed Automatically

The following accessibility improvements have been implemented:

### 1. Reduce Motion Support
- **ClickerButton.swift**: Added `@Environment(\.accessibilityReduceMotion)` and conditional animation
- **SwipeToCompleteSlider.swift**: All animations now respect reduce motion preference
- **MediaPreviewView.swift**: Zoom and toggle animations respect reduce motion

### 2. Accessibility Labels & Hints
- **MediaPreviewView.swift**: Added labels for close/delete buttons, photo description, zoom hints
- **MealEditView.swift**: Added labels and hints for all form fields (name, amount, time)
- **ClickerButton.swift**: Added dynamic click count accessibility label

### 3. Accessibility Identifiers (for UI testing)
- **MediaPreviewView.swift**: `MEDIA_CLOSE_BUTTON`, `MEDIA_DELETE_BUTTON`
- **MealEditView.swift**: `MEAL_PORTION_{id}` for each meal row

### 4. Grouped Content
- **MediaPreviewView.swift**: Bottom info panel now groups children for VoiceOver

### 5. Dynamic Type Support
- **ClickerButton.swift**: Changed hardcoded `size: 64` font to scalable `.largeTitle`

---

## Manual Testing Required

### 1. VoiceOver Testing
Test the app with VoiceOver enabled (Settings > Accessibility > VoiceOver):

- [ ] **Timeline View**: Navigate through events, verify all elements are announced clearly
- [ ] **Quick Log Bar**: Verify each button announces its action
- [ ] **Potty Sheet**: Verify location picker announces selected state
- [ ] **Media Preview**: Verify photo description is read, buttons are accessible
- [ ] **Settings**: Navigate through all settings sections
- [ ] **Training Session**: Verify clicker button and counter are accessible

### 2. Color Contrast Verification
Test colors meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text):

**Files to check:**
- [ ] `SleepStatusCard.swift` (lines 169, 173): Orange/red text colors
- [ ] `Utils/Colors.swift` or color definitions: Verify custom colors like `.ollieSuccess`, `.ollieDanger`, `.ollieInfo`

**Tools:**
- Use Xcode's Accessibility Inspector (Xcode > Open Developer Tool > Accessibility Inspector)
- Or use a contrast checker like [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

**Colors to verify:**
| Color | Usage | Minimum Ratio |
|-------|-------|---------------|
| `.orange` | Warning text | 4.5:1 |
| `.red` | Error/danger text | 4.5:1 |
| `.ollieSuccess` (green) | Success icons | 3:1 (icons) |
| `.ollieDanger` (red) | Indoor potty | 3:1 (icons) |
| `.secondary` | Subtitles | 4.5:1 |

### 3. High Contrast Mode Testing
Test with Increase Contrast enabled (Settings > Accessibility > Display & Text Size > Increase Contrast):

- [ ] Verify all text remains readable
- [ ] Verify icons remain distinguishable
- [ ] Check card backgrounds have sufficient contrast with content

### 4. Dynamic Type Testing
Test with various text sizes (Settings > Accessibility > Display & Text Size > Larger Text):

- [ ] Test with largest accessibility text size
- [ ] Verify no text gets cut off
- [ ] Verify layouts adapt properly (especially cards and rows)

**Known areas to check:**
- [ ] `TimelineView.swift`: Date header and navigation buttons
- [ ] `EventRow.swift`: Event details layout
- [ ] Status cards (PottyStatusCard, SleepStatusCard, StreakCard)

### 5. Reduce Motion Testing
Test with Reduce Motion enabled (Settings > Accessibility > Motion > Reduce Motion):

- [ ] FAB button animations
- [ ] SwipeToCompleteSlider
- [ ] ClickerButton press animation
- [ ] Timeline day navigation transitions
- [ ] Media preview zoom transitions

---

## Optional Enhancements (Low Priority)

These are nice-to-have improvements if time permits:

### Add Accessibility Identifiers for UI Testing
Add `.accessibilityIdentifier()` to these views for automated testing:

```swift
// SettingsView.swift - Navigation links
NavigationLink { ... }
    .accessibilityIdentifier("SETTINGS_MEDICATIONS_LINK")

// TimelineView.swift - Swipe action buttons
Button(role: .destructive) { ... }
    .accessibilityIdentifier("EVENT_DELETE_BUTTON")
```

### Consider Adding Custom Accessibility Actions
For complex gestures, add alternative actions:

```swift
// Example: Add zoom action to MediaPreviewView
.accessibilityAction(named: "Zoom in") {
    scale = min(scale * 1.5, 4.0)
}
.accessibilityAction(named: "Zoom out") {
    scale = max(scale / 1.5, 1.0)
}
```

### Form Field Content Types
Add content type hints for better autofill:

```swift
// OnboardingNameStep.swift
TextField(...)
    .textContentType(.givenName)
```

---

## Testing Checklist Summary

Before release, verify:

- [ ] VoiceOver navigation works throughout the app
- [ ] All interactive elements have labels
- [ ] Color contrast meets WCAG AA (4.5:1 text, 3:1 graphics)
- [ ] App works with largest Dynamic Type size
- [ ] Animations respect Reduce Motion setting
- [ ] High Contrast mode doesn't break layouts

---

## Resources

- [Apple Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [SwiftUI Accessibility Documentation](https://developer.apple.com/documentation/swiftui/accessibility)
