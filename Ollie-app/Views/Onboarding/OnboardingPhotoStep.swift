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

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Photo preview
            Group {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.ollieAccent, lineWidth: 3))
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.ollieAccent)
                        }
                }
            }

            Text(Strings.Onboarding.photoQuestion(name: puppyName))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(Strings.Onboarding.photoSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Photo selection buttons
            VStack(spacing: 12) {
                Button {
                    selectedSource = .camera
                    showingMediaPicker = true
                } label: {
                    Label(Strings.MediaAttachment.camera, systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.ollieAccent)

                Button {
                    selectedSource = .library
                    showingMediaPicker = true
                } label: {
                    Label(Strings.MediaAttachment.photoLibrary, systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.ollieAccent)

                if selectedImage != nil {
                    Button(role: .destructive) {
                        selectedImage = nil
                    } label: {
                        Label(Strings.Profile.removePhoto, systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // Navigation buttons
            HStack {
                OnboardingBackButton(action: onBack)

                Button(action: onNext) {
                    Text(selectedImage != nil ? Strings.Common.next : Strings.Onboarding.skip)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(LayoutConstants.cornerRadiusM)
                }
            }
        }
        .padding()
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
