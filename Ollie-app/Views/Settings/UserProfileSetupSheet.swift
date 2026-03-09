//
//  UserProfileSetupSheet.swift
//  Ollie-app
//
//  Reusable user profile setup component for onboarding and share acceptance.
//  Allows users to set their name, photo (with crop), and avatar color.
//

import SwiftUI
import OtisShared

/// Reusable user profile setup view
/// Used in onboarding and after share acceptance
struct UserProfileSetupSheet: View {
    @ObservedObject var userIdentityStore: UserIdentityStore
    let onComplete: () -> Void
    let onSkip: (() -> Void)?

    @State private var name: String = ""
    @State private var selectedColorHex: String = ""
    @State private var avatarImage: UIImage?

    // Media picker state
    @State private var showingMediaPicker = false
    @State private var selectedSource: MediaPickerSource = .library
    @State private var imageToCrop: UIImage?
    @State private var showingCropView = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var photoPreviewSize: CGFloat {
        horizontalSizeClass == .regular ? 140 : 120
    }

    private var contentHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 40 : 24
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 32)

            // Avatar preview
            avatarView
                .padding(.bottom, 24)

            // Title
            Text(Strings.UserProfile.setupTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 8)

            Text(Strings.UserProfile.setupSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, contentHorizontalPadding)

            Spacer()
                .frame(height: 32)

            // Form content
            VStack(spacing: 16) {
                // Name field
                TextField(Strings.UserProfile.namePlaceholder, text: $name)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Photo buttons
                HStack(spacing: 12) {
                    PhotoOptionButton(
                        title: Strings.MediaAttachment.camera,
                        icon: "camera.fill"
                    ) {
                        selectedSource = .camera
                        showingMediaPicker = true
                    }

                    PhotoOptionButton(
                        title: Strings.MediaAttachment.photoLibrary,
                        icon: "photo.on.rectangle"
                    ) {
                        selectedSource = .library
                        showingMediaPicker = true
                    }
                }

                // Color picker
                colorPicker
            }
            .padding(.horizontal, contentHorizontalPadding)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    save()
                    onComplete()
                } label: {
                    Text(Strings.Common.done)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(canSave ? Color.otisAccent : Color.gray)
                        )
                        .foregroundStyle(.white)
                }
                .disabled(!canSave)

                if let onSkip = onSkip {
                    Button {
                        onSkip()
                    } label: {
                        Text(Strings.UserProfile.setupLater)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.bottom, 16)
        }
        .adaptiveContainer(maxWidth: iPadLayout.maxContentWidth)
        .onAppear {
            loadCurrentValues()
        }
        .fullScreenCover(isPresented: $showingMediaPicker) {
            MediaPicker(
                source: selectedSource,
                onImageSelected: { image, _ in
                    imageToCrop = image
                    showingMediaPicker = false
                },
                onCancel: {
                    showingMediaPicker = false
                }
            )
        }
        .onChange(of: imageToCrop) { _, newImage in
            // Show crop view when image is ready (after async PHPicker load completes)
            if newImage != nil && !showingMediaPicker {
                showingCropView = true
            }
        }
        .fullScreenCover(isPresented: $showingCropView) {
            if let image = imageToCrop {
                ImageCropView(
                    image: image,
                    onConfirm: { croppedImage in
                        avatarImage = croppedImage
                        showingCropView = false
                        imageToCrop = nil
                    },
                    onCancel: {
                        showingCropView = false
                        imageToCrop = nil
                    }
                )
            }
        }
    }

    // MARK: - Avatar View

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: photoPreviewSize, height: photoPreviewSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.otisAccent, lineWidth: 3))
                    .shadow(color: Color.otisAccent.opacity(0.2), radius: 12, x: 0, y: 4)
            } else {
                Circle()
                    .fill(Color(hex: selectedColorHex))
                    .frame(width: photoPreviewSize, height: photoPreviewSize)
                    .overlay {
                        if !name.isEmpty {
                            Text(String(name.prefix(1)).uppercased())
                                .font(.system(size: photoPreviewSize * 0.4, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: photoPreviewSize * 0.35))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
            }
        }
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.UserProfile.color)
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(UserIdentity.availableColors, id: \.self) { colorHex in
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 36, height: 36)
                        .overlay {
                            if colorHex == selectedColorHex {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture {
                            selectedColorHex = colorHex
                            HapticFeedback.light()
                        }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Logic

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadCurrentValues() {
        if let identity = userIdentityStore.currentIdentity {
            // Only pre-fill name if it's not the default "Me"
            name = identity.name == Strings.UserProfile.me ? "" : identity.name
            selectedColorHex = identity.colorHex

            if let avatarData = identity.avatarData {
                avatarImage = UIImage(data: avatarData)
            }
        } else {
            name = ""
            selectedColorHex = UserIdentity.randomColor()
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        userIdentityStore.updateName(trimmedName)
        userIdentityStore.updateColor(selectedColorHex)

        if let image = avatarImage {
            let resized = image.resizedToFit(maxDimension: 200)
            let data = resized.jpegData(compressionQuality: 0.7)
            userIdentityStore.updateAvatar(data)
        } else {
            userIdentityStore.updateAvatar(nil)
        }

        HapticFeedback.success()
    }
}

// MARK: - Photo Option Button

private struct PhotoOptionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.otisAccent)
    }
}

// MARK: - Helper Extension

private extension UIImage {
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        guard ratio < 1 else { return self }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Preview

#Preview("Setup Sheet") {
    UserProfileSetupSheet(
        userIdentityStore: .shared,
        onComplete: {},
        onSkip: {}
    )
}

#Preview("No Skip") {
    UserProfileSetupSheet(
        userIdentityStore: .shared,
        onComplete: {},
        onSkip: nil
    )
}
