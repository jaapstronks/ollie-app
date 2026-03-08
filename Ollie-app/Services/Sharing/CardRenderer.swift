//
//  CardRenderer.swift
//  Otis-app
//
//  Renders SwiftUI views to UIImage for sharing
//

import SwiftUI
import UIKit
import os
import OtisShared

/// Renders SwiftUI views to images for sharing
@MainActor
final class CardRenderer {

    private let logger = Logger.otis(category: "CardRenderer")

    // MARK: - Singleton

    static let shared = CardRenderer()

    private init() {}

    // MARK: - Rendering

    /// Render any SwiftUI view to an image
    /// - Parameters:
    ///   - view: The SwiftUI view to render
    ///   - size: The output size in points
    ///   - scale: The render scale (default 2.0 for retina)
    /// - Returns: A UIImage of the rendered view, or nil if rendering fails
    func render<V: View>(
        _ view: V,
        size: CGSize,
        scale: CGFloat = 2.0
    ) -> UIImage? {
        // Use ImageRenderer for iOS 16+
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = scale
        renderer.isOpaque = true

        guard let image = renderer.uiImage else {
            logger.error("Failed to render view to image")
            return nil
        }

        logger.debug("Rendered image: \(Int(size.width))x\(Int(size.height)) @ \(scale)x")
        return image
    }

    /// Render a view with a specific share format preset
    /// - Parameters:
    ///   - view: The SwiftUI view to render
    ///   - format: The share format defining size and scale
    /// - Returns: A UIImage of the rendered view, or nil if rendering fails
    func render<V: View>(
        _ view: V,
        for format: ShareFormat
    ) -> UIImage? {
        render(view, size: format.size, scale: format.renderScale)
    }

    /// Render a shareable card for all formats
    /// - Parameter card: The shareable card to render
    /// - Returns: Dictionary of format to rendered image
    func renderAllFormats<Card: ShareableCard>(
        _ card: Card
    ) -> [ShareFormat: UIImage] {
        var results: [ShareFormat: UIImage] = [:]

        for format in ShareFormat.allCases {
            if let image = render(card.cardView(for: format), for: format) {
                results[format] = image
            }
        }

        logger.debug("Rendered \(results.count) format variants")
        return results
    }

    // MARK: - Convenience Methods

    /// Render a view at story format (9:16)
    func renderStory<V: View>(_ view: V) -> UIImage? {
        render(view, for: .story)
    }

    /// Render a view at square format (1:1)
    func renderSquare<V: View>(_ view: V) -> UIImage? {
        render(view, for: .squarePost)
    }

    /// Render a view at portrait format (4:5)
    func renderPortrait<V: View>(_ view: V) -> UIImage? {
        render(view, for: .portrait)
    }

    /// Render a view at landscape format (16:9)
    func renderLandscape<V: View>(_ view: V) -> UIImage? {
        render(view, for: .landscape)
    }
}
