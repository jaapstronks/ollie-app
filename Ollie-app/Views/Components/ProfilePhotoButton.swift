//
//  ProfilePhotoButton.swift
//  Ollie-app
//
//  Toolbar button showing profile photo (replaces gear icon)

import SwiftUI
import OllieShared

/// Toolbar button displaying the dog's profile photo or a paw placeholder
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
        .accessibilityLabel(Strings.Tabs.settings)
        .accessibilityIdentifier("settings_button")
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

#Preview {
    HStack {
        ProfilePhotoButton(profile: nil, action: {})
        Text("Settings")
    }
}
