//
//  ImageCache.swift
//  Ollie-app
//
//  High-performance image caching with async loading for thumbnails and photos

import OllieShared
import UIKit
import os

/// Thread-safe image cache using NSCache for automatic memory management
actor ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let logger = Logger.ollie(category: "ImageCache")

    /// In-flight loading tasks to prevent duplicate loads
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]

    init() {
        // Configure cache limits
        cache.countLimit = 100 // Max 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB max
    }

    // MARK: - Public API

    /// Load image from cache or disk asynchronously
    /// - Parameters:
    ///   - relativePath: Path relative to documents directory
    ///   - isThumbnail: If true, applies thumbnail optimizations
    /// - Returns: UIImage if found, nil otherwise
    func loadImage(relativePath: String, isThumbnail: Bool = true) async -> UIImage? {
        let cacheKey = NSString(string: relativePath)

        // Check cache first (fast path)
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        // Check if already loading
        if let existingTask = loadingTasks[relativePath] {
            return await existingTask.value
        }

        // Create new loading task
        let task = Task<UIImage?, Never> { [weak self] in
            guard let self = self else { return nil }
            return await self.loadFromDisk(relativePath: relativePath, isThumbnail: isThumbnail)
        }

        loadingTasks[relativePath] = task
        let result = await task.value
        loadingTasks[relativePath] = nil

        return result
    }

    /// Preload images for upcoming cells (call during scroll)
    func preloadImages(relativePaths: [String]) {
        for path in relativePaths {
            Task {
                _ = await loadImage(relativePath: path, isThumbnail: true)
            }
        }
    }

    /// Clear all cached images (call on memory warning)
    func clearCache() {
        cache.removeAllObjects()
        logger.info("Image cache cleared")
    }

    /// Remove specific image from cache
    func removeImage(relativePath: String) {
        let cacheKey = NSString(string: relativePath)
        cache.removeObject(forKey: cacheKey)
    }

    // MARK: - Private

    private func loadFromDisk(relativePath: String, isThumbnail: Bool) async -> UIImage? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsURL.appendingPathComponent(relativePath)

        // Load and process on background thread
        let loadedImage: UIImage? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }

                // For thumbnails, ensure reasonable size
                let finalImage: UIImage
                if isThumbnail {
                    finalImage = self?.downsampleIfNeeded(image, maxSize: 200) ?? image
                } else {
                    finalImage = image
                }

                continuation.resume(returning: finalImage)
            }
        }

        // Cache on actor-isolated context
        if let image = loadedImage {
            let cacheKey = NSString(string: relativePath)
            let cost = Int(image.size.width * image.size.height * 4) // Approximate bytes
            cache.setObject(image, forKey: cacheKey, cost: cost)
        }

        return loadedImage
    }

    /// Downsample large images to save memory
    private nonisolated func downsampleIfNeeded(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let scale = image.scale
        let actualWidth = size.width * scale
        let actualHeight = size.height * scale

        // If already small enough, return as-is
        if actualWidth <= maxSize && actualHeight <= maxSize {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxSize / actualWidth, maxSize / actualHeight)
        let newSize = CGSize(width: actualWidth * ratio, height: actualHeight * ratio)

        // Render at new size
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Memory Warning Handler

extension ImageCache {
    /// Call this from AppDelegate/SceneDelegate on memory warning
    nonisolated func handleMemoryWarning() {
        Task {
            await clearCache()
        }
    }
}
