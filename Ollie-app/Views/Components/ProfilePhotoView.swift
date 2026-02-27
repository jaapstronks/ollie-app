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

#Preview("With Photo") {
    // Preview with placeholder
    ProfilePhotoView(profile: nil, size: 60)
}

#Preview("Large") {
    ProfilePhotoView(profile: nil, size: 120)
}
