//
//  ProfilePhotoView.swift
//  Ollie-app
//
//  Reusable profile photo display component

import SwiftUI
import OllieShared

/// Displays the dog's profile photo or a paw placeholder
struct ProfilePhotoView: View {
    let profile: PuppyProfile?
    var size: CGFloat = 32
    var showBorder: Bool = true

    @State private var loadedImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
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
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .overlay {
            if showBorder {
                Circle()
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.15)
                            : Color.black.opacity(0.06),
                        lineWidth: size > 60 ? 2 : 1
                    )
            }
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

#Preview("Small") {
    ProfilePhotoView(profile: nil, size: 40)
        .padding()
}

#Preview("Medium") {
    ProfilePhotoView(profile: nil, size: 80)
        .padding()
}

#Preview("Large") {
    ProfilePhotoView(profile: nil, size: 120)
        .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        ProfilePhotoView(profile: nil, size: 60)
        ProfilePhotoView(profile: nil, size: 100)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
