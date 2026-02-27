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
    @Environment(\.colorScheme) private var colorScheme

    private let size: CGFloat = 34

    var body: some View {
        Button(action: action) {
            ZStack {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    // Placeholder: gradient background with paw icon
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.ollieAccent, Color.ollieAccent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                Circle()
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.2)
                            : Color.black.opacity(0.08),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.3)
                    : Color.black.opacity(0.12),
                radius: 2,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(.plain)
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

#Preview("No Photo") {
    HStack(spacing: 20) {
        ProfilePhotoButton(profile: nil, action: {})
        Text("Settings")
    }
    .padding()
}

#Preview("No Photo - Dark") {
    HStack(spacing: 20) {
        ProfilePhotoButton(profile: nil, action: {})
        Text("Settings")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
