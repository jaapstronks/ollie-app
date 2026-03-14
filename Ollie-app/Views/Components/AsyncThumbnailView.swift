//
//  AsyncThumbnailView.swift
//  Otis-app
//
//  Reusable async thumbnail loader with caching
//

import SwiftUI
import OtisShared

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
                    .clipped()
            } else if loadFailed && showErrorPlaceholder {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            } else {
                SkeletonView(cornerRadius: 0)
            }
        }
        .task(id: relativePath) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        // PERFORMANCE: Check debug toggle to disable photo loading
        guard !PerformanceDebug.disablePhotoLoading else {
            loadFailed = true
            return
        }

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
/// Supports on-demand cloud download for photos that exist in CloudKit but not locally
struct EventThumbnailView: View {
    let event: PuppyEvent
    var showErrorPlaceholder: Bool = true

    @State private var image: UIImage?
    @State private var loadFailed: Bool = false
    @State private var isDownloading: Bool = false
    @State private var downloadFailed: Bool = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else if isDownloading {
                // Show cloud download indicator
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundStyle(.secondary)
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
            } else if downloadFailed {
                // Cloud download failed - show retry button
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        Button {
                            Task {
                                await downloadFromCloud()
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise.icloud")
                                    .foregroundStyle(.secondary)
                                Text(Strings.Common.tryAgain)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
            } else if loadFailed {
                if showErrorPlaceholder {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                } else {
                    // Load failed but no placeholder requested - show empty
                    Color.clear
                }
            } else {
                SkeletonView(cornerRadius: 0)
            }
        }
        .task(id: event.id) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        // PERFORMANCE: Check debug toggle to disable photo loading
        guard !PerformanceDebug.disablePhotoLoading else {
            loadFailed = true
            return
        }

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

        // If local load failed but photo is synced to cloud, try downloading
        if event.cloudPhotoSynced == true && event.photo != nil {
            await downloadFromCloud()
        } else {
            loadFailed = true
        }
    }

    private func downloadFromCloud() async {
        isDownloading = true
        downloadFailed = false

        let success = await PhotoSyncService.shared.downloadPhoto(for: event)

        if !Task.isCancelled {
            isDownloading = false

            if success {
                // Reload the image after download
                await loadImageAfterDownload()
            } else {
                downloadFailed = true
            }
        }
    }

    private func loadImageAfterDownload() async {
        // Try thumbnail first (regenerated after download)
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

        // Still couldn't load after download
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
