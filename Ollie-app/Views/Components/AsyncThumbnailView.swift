//
//  AsyncThumbnailView.swift
//  Ollie-app
//
//  Reusable async thumbnail loader with caching
//

import SwiftUI
import OllieShared

/// Async thumbnail loader with loading, error, and success states
struct AsyncThumbnailView: View {
    let relativePath: String
    var showErrorPlaceholder: Bool = true

    @State private var image: UIImage?
    @State private var loadFailed: Bool = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loadFailed && showErrorPlaceholder {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
            }
        }
        .task(id: relativePath) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        if let loaded = await ImageCache.shared.loadImage(relativePath: relativePath, isThumbnail: true) {
            if !Task.isCancelled {
                image = loaded
            }
        } else {
            loadFailed = true
        }
    }
}

/// Thumbnail view that loads from a PuppyEvent, with fallback from thumbnail to photo
struct EventThumbnailView: View {
    let event: PuppyEvent
    var showErrorPlaceholder: Bool = true

    @State private var image: UIImage?
    @State private var loadFailed: Bool = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loadFailed && showErrorPlaceholder {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
            }
        }
        .task(id: event.id) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        // Try thumbnail first
        if let thumbnailPath = event.thumbnailPath {
            if let loaded = await ImageCache.shared.loadImage(relativePath: thumbnailPath, isThumbnail: true) {
                if !Task.isCancelled {
                    image = loaded
                    return
                }
            }
        }

        // Fall back to full photo
        if let photoPath = event.photo {
            if let loaded = await ImageCache.shared.loadImage(relativePath: photoPath, isThumbnail: true) {
                if !Task.isCancelled {
                    image = loaded
                    return
                }
            }
        }

        loadFailed = true
    }
}

// MARK: - Preview

#Preview("Async Thumbnails") {
    VStack(spacing: 20) {
        AsyncThumbnailView(relativePath: "test/photo.jpg")
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

        AsyncThumbnailView(relativePath: "missing.jpg", showErrorPlaceholder: true)
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding()
}
