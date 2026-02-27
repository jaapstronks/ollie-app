# TODO: Profile Photo + Settings Icon

## Overview

Add a **profile photo** for the dog and replace the settings gear icon with a circular photo of the dog (or a paw placeholder if no photo is set).

Tapping the photo opens the existing settings hub (same behavior as the current gear icon).

## Design Decisions

### Icon Behavior

- **Tap → Settings hub** (same as current gear icon)
- Photo is a visual personalization element, not a new navigation paradigm
- Users have muscle memory for "icon in top-right → settings"
- Consistent with current behavior

### Photo During Onboarding

- **Optional step** after entering puppy name
- Users can skip and add later in Settings
- Some users want to explore the app first before committing a photo

## Architecture

### Data Layer

#### Update Core Data: `CDPuppyProfile`

Add attribute to `Ollie-app/Ollie.xcdatamodeld`:

```xml
CDPuppyProfile:
  + profilePhotoFilename: String?    // relative path in app documents dir
```

#### Update OllieShared: `PuppyProfile`

Add to `OllieShared/Sources/OllieShared/Models/PuppyProfile.swift`:

```swift
public struct PuppyProfile: Codable, Identifiable, Sendable {
    // ... existing properties ...
    public var profilePhotoFilename: String?   // NEW

    // Add to CodingKeys enum:
    case profilePhotoFilename

    // Update init, encode, decode accordingly
}
```

### Image Storage

Reuse the same pattern as event photos. Store in app's documents directory:

```
Documents/
├── DogDocuments/     (for document scans)
├── ProfilePhotos/    (for profile photo)
│   └── {uuid}.jpg
└── Photos/           (existing event photos)
```

Add helper to existing image storage or create simple dedicated store:

```swift
// ProfilePhotoStore.swift
import UIKit

final class ProfilePhotoStore {
    static let shared = ProfilePhotoStore()

    private let fileManager = FileManager.default
    private let directory: URL

    private init() {
        directory = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProfilePhotos", isDirectory: true)

        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(image: UIImage) throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ProfilePhotoError.imageConversionFailed
        }
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url)
        return filename
    }

    func load(filename: String) -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    func delete(filename: String) {
        let url = directory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }

    enum ProfilePhotoError: Error {
        case imageConversionFailed
    }
}
```

## Views

### Settings Icon Component

Replace the gear icon in `TodayView` (and other tab views) with a profile photo button:

```swift
// ProfilePhotoButton.swift
import SwiftUI
import OllieShared

struct ProfilePhotoButton: View {
    let profile: PuppyProfile?
    let action: () -> Void

    @State private var loadedImage: UIImage?

    var body: some View {
        Button(action: action) {
            Group {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Placeholder: paw icon
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.ollieAccent)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
        }
        .onAppear { loadImage() }
        .onChange(of: profile?.profilePhotoFilename) { _, _ in loadImage() }
    }

    private func loadImage() {
        guard let filename = profile?.profilePhotoFilename else {
            loadedImage = nil
            return
        }
        loadedImage = ProfilePhotoStore.shared.load(filename: filename)
    }
}
```

### Update TodayView Toolbar

Current code (approximately):
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            onSettingsTap()
        } label: {
            Image(systemName: "gearshape")
        }
    }
}
```

Replace with:
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        ProfilePhotoButton(profile: profile, action: onSettingsTap)
    }
}
```

### Profile Photo Picker in Settings

Add to `ProfileSection.swift`:

```swift
// ProfileSection.swift (updated)
struct ProfileSection: View {
    let profile: PuppyProfile
    @ObservedObject var profileStore: ProfileStore

    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        Section(Strings.Settings.profile) {
            // Profile photo row
            HStack {
                ProfilePhotoView(profile: profile, size: 60)

                Spacer()

                Button(profile.profilePhotoFilename == nil ? Strings.Profile.addPhoto : Strings.Profile.changePhoto) {
                    showingPhotoPicker = true
                }
            }
            .padding(.vertical, 8)

            // Existing rows...
            HStack {
                Text(Strings.Settings.name)
                Spacer()
                Text(profile.name)
                    .foregroundColor(.secondary)
            }
            // ... etc
        }
        .sheet(isPresented: $showingPhotoPicker) {
            ProfilePhotoPicker(
                currentImage: loadCurrentImage(),
                onSave: { image in
                    saveProfilePhoto(image)
                },
                onRemove: profile.profilePhotoFilename != nil ? {
                    removeProfilePhoto()
                } : nil
            )
        }
    }

    private func loadCurrentImage() -> UIImage? {
        guard let filename = profile.profilePhotoFilename else { return nil }
        return ProfilePhotoStore.shared.load(filename: filename)
    }

    private func saveProfilePhoto(_ image: UIImage) {
        do {
            // Delete old photo if exists
            if let oldFilename = profile.profilePhotoFilename {
                ProfilePhotoStore.shared.delete(filename: oldFilename)
            }

            let filename = try ProfilePhotoStore.shared.save(image: image)
            profileStore.updateProfilePhoto(filename)
        } catch {
            print("Failed to save profile photo: \(error)")
        }
    }

    private func removeProfilePhoto() {
        if let filename = profile.profilePhotoFilename {
            ProfilePhotoStore.shared.delete(filename: filename)
        }
        profileStore.updateProfilePhoto(nil)
    }
}
```

### Profile Photo Picker Sheet

```swift
// ProfilePhotoPicker.swift
import SwiftUI

struct ProfilePhotoPicker: View {
    let currentImage: UIImage?
    let onSave: (UIImage) -> Void
    let onRemove: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showingMediaPicker = false
    @State private var selectedSource: MediaPickerSource = .library

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                Group {
                    if let image = selectedImage ?? currentImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .overlay {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .padding(.top, 40)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        selectedSource = .camera
                        showingMediaPicker = true
                    } label: {
                        Label(Strings.MediaAttachment.camera, systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        selectedSource = .library
                        showingMediaPicker = true
                    } label: {
                        Label(Strings.MediaAttachment.photoLibrary, systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if onRemove != nil && (currentImage != nil || selectedImage != nil) {
                        Button(role: .destructive) {
                            onRemove?()
                            dismiss()
                        } label: {
                            Label(Strings.Profile.removePhoto, systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle(Strings.Profile.photoTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        if let image = selectedImage {
                            onSave(image)
                        }
                        dismiss()
                    }
                    .disabled(selectedImage == nil)
                }
            }
            .fullScreenCover(isPresented: $showingMediaPicker) {
                MediaPicker(
                    source: selectedSource,
                    onImageSelected: { image, _ in
                        selectedImage = image
                        showingMediaPicker = false
                    },
                    onCancel: {
                        showingMediaPicker = false
                    }
                )
            }
        }
    }
}
```

### Reusable Profile Photo View

```swift
// ProfilePhotoView.swift
import SwiftUI
import OllieShared

struct ProfilePhotoView: View {
    let profile: PuppyProfile?
    var size: CGFloat = 32

    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(Color.ollieAccent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear { loadImage() }
        .onChange(of: profile?.profilePhotoFilename) { _, _ in loadImage() }
    }

    private func loadImage() {
        guard let filename = profile?.profilePhotoFilename else {
            loadedImage = nil
            return
        }
        loadedImage = ProfilePhotoStore.shared.load(filename: filename)
    }
}
```

### Optional Onboarding Step

Add after the name step in `OnboardingView.swift`:

```swift
// In OnboardingView step cases, add optional photo step:

case photoStep:
    VStack(spacing: 24) {
        Text(Strings.Onboarding.addPhotoTitle)
            .font(.title2)
            .fontWeight(.semibold)

        Text(Strings.Onboarding.addPhotoSubtitle)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

        // Photo picker UI
        ProfilePhotoView(profile: nil, size: 150)
            .overlay {
                if selectedProfilePhoto == nil {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 150, height: 150)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .font(.largeTitle)
                            }
                    }
                }
            }

        Button(Strings.Onboarding.skipPhoto) {
            // Continue without photo
            currentStep += 1
        }
        .foregroundStyle(.secondary)
    }
```

## File List

### New Files

| File | Location |
|------|----------|
| `ProfilePhotoStore.swift` | `Ollie-app/Services/` |
| `ProfilePhotoButton.swift` | `Ollie-app/Views/Components/` |
| `ProfilePhotoView.swift` | `Ollie-app/Views/Components/` |
| `ProfilePhotoPicker.swift` | `Ollie-app/Views/Settings/` |

### Modified Files

| File | Change |
|------|--------|
| `Ollie-app/Ollie.xcdatamodeld` | Add `profilePhotoFilename` attribute to `CDPuppyProfile` |
| `OllieShared/.../PuppyProfile.swift` | Add `profilePhotoFilename` property |
| `Ollie-app/Views/TodayView.swift` | Replace gear icon with `ProfilePhotoButton` |
| `Ollie-app/Views/Settings/ProfileSection.swift` | Add photo picker UI |
| `Ollie-app/Services/ProfileStore.swift` | Add `updateProfilePhoto(_:)` method |
| `OllieShared/Utils/Strings.swift` | Add `Strings.Profile.*` constants |
| `Ollie-app/Localizable.xcstrings` | Add profile photo keys |

## Localization Keys

Add to `Strings.swift`:

```swift
public enum Profile {
    public static let addPhoto = String(localized: "profile.addPhoto")
    public static let changePhoto = String(localized: "profile.changePhoto")
    public static let removePhoto = String(localized: "profile.removePhoto")
    public static let photoTitle = String(localized: "profile.photo.title")
}

public enum Onboarding {
    // ... existing ...
    public static let addPhotoTitle = String(localized: "onboarding.photo.title")
    public static let addPhotoSubtitle = String(localized: "onboarding.photo.subtitle")
    public static let skipPhoto = String(localized: "onboarding.photo.skip")
}
```

Translations (en / nl):

```
profile.addPhoto = "Add Photo" / "Foto toevoegen"
profile.changePhoto = "Change Photo" / "Foto wijzigen"
profile.removePhoto = "Remove Photo" / "Foto verwijderen"
profile.photo.title = "Profile Photo" / "Profielfoto"
onboarding.photo.title = "Add a photo" / "Voeg een foto toe"
onboarding.photo.subtitle = "Add a photo of your puppy (you can always do this later)" / "Voeg een foto van je puppy toe (dit kan ook later)"
onboarding.photo.skip = "Skip for now" / "Sla over"
```

## Implementation Order

1. **Core Data** - Add `profilePhotoFilename` to `CDPuppyProfile`
2. **PuppyProfile model** - Add `profilePhotoFilename` property
3. **ProfilePhotoStore** - Image storage service
4. **ProfileStore** - Add `updateProfilePhoto(_:)` method
5. **ProfilePhotoView** - Reusable photo display component
6. **ProfilePhotoButton** - Toolbar button component
7. **ProfilePhotoPicker** - Photo selection sheet
8. **Update ProfileSection** - Add photo picker row
9. **Update TodayView** - Replace gear icon
10. **Optional: Onboarding step** - Add photo step after name
11. **Localization** - Add all string keys

## CloudKit Considerations

- `profilePhotoFilename` syncs via Core Data + CloudKit
- The `ProfilePhotos/` directory should be included in iCloud container
- Alternatively, store photo data as Binary Data with "Allows External Storage" on Core Data attribute
