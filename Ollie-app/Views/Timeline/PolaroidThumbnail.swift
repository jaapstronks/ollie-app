//
//  PolaroidThumbnail.swift
//  Ollie-app
//
//  Polaroid-style photo thumbnail for timeline items

import SwiftUI
import UIKit

/// Polaroid-style photo thumbnail with white border and slight rotation
struct PolaroidThumbnail: View {
    let relativePath: String
    var size: CGFloat = 48
    var rotation: Double = 3 // degrees

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            // White polaroid frame
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: size + 8, height: size + 12)
                .shadow(color: .black.opacity(0.15), radius: 3, x: 1, y: 2)

            // Photo content
            VStack(spacing: 0) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: size, height: size)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                }

                Spacer()
                    .frame(height: 4)
            }
            .padding(.top, 4)
        }
        .rotationEffect(.degrees(rotation))
        .task(id: relativePath) {
            await loadImageAsync()
        }
    }

    private func loadImageAsync() async {
        if let loaded = await ImageCache.shared.loadImage(relativePath: relativePath, isThumbnail: true) {
            if !Task.isCancelled {
                image = loaded
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PolaroidThumbnail(relativePath: "test.jpg", size: 48, rotation: 3)
        PolaroidThumbnail(relativePath: "test.jpg", size: 60, rotation: -2)
        PolaroidThumbnail(relativePath: "test.jpg", size: 40, rotation: 5)
    }
    .padding()
    .background(Color(.systemGray5))
}
