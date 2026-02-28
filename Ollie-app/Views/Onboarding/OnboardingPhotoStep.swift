//
//  OnboardingPhotoStep.swift
//  Ollie-app
//
//  Optional photo selection step for onboarding
//

import SwiftUI
import UIKit

/// Optional photo selection step during onboarding
struct OnboardingPhotoStep: View {
    let puppyName: String
    @Binding var selectedImage: UIImage?
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var showingMediaPicker = false
    @State private var selectedSource: MediaPickerSource = .library
    @State private var imageToCrop: UIImage?
    @State private var showingCropView = false
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 32)

            // Photo preview
            Group {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.ollieAccent, lineWidth: 3))
                        .shadow(color: Color.ollieAccent.opacity(0.2), radius: 12, x: 0, y: 4)
                } else {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 160, height: 160)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.ollieAccent)
                        }
                }
            }
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 24)

            Text(Strings.Onboarding.photoQuestion(name: puppyName))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 8)

            Text(Strings.Onboarding.photoSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 32)

            // Photo selection buttons
            VStack(spacing: 12) {
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

                if selectedImage != nil {
                    Button(role: .destructive) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedImage = nil
                        }
                    } label: {
                        Label(Strings.Profile.removePhoto, systemImage: "trash")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(.horizontal, 24)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()

            // Navigation buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)

                Button(action: onNext) {
                    Text(selectedImage != nil ? Strings.Common.next : Strings.Onboarding.skip)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.ollieAccent)
                        )
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
        .fullScreenCover(isPresented: $showingMediaPicker) {
            MediaPicker(
                source: selectedSource,
                onImageSelected: { image, _ in
                    showingMediaPicker = false
                    // Show crop view after selecting an image
                    imageToCrop = image
                    showingCropView = true
                },
                onCancel: {
                    showingMediaPicker = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingCropView) {
            if let image = imageToCrop {
                ImageCropView(
                    image: image,
                    onConfirm: { croppedImage in
                        selectedImage = croppedImage
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
}

// MARK: - Photo Option Button

private struct PhotoOptionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.ollieAccent)
    }
}

#Preview("No Photo") {
    OnboardingPhotoStep(
        puppyName: "Max",
        selectedImage: .constant(nil),
        onNext: {},
        onBack: {}
    )
}

#Preview("With Photo") {
    OnboardingPhotoStep(
        puppyName: "Max",
        selectedImage: .constant(UIImage(systemName: "dog")!),
        onNext: {},
        onBack: {}
    )
}
