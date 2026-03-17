//
//  ShareableWatermark.swift
//  Otis-app
//
//  Consistent branding watermark for shareable cards
//

import SwiftUI
import UIKit

/// Watermark component for shareable content
struct ShareableWatermark: View {
    var style: WatermarkStyle = .standard
    var alignment: HorizontalAlignment = .trailing

    enum WatermarkStyle {
        /// "Made with Ollie" + paw icon
        case standard
        /// Just the paw icon
        case minimal
        /// Icon + app name + URL
        case detailed
    }

    var body: some View {
        HStack(spacing: 6) {
            if alignment == .trailing {
                Spacer()
            }

            content

            if alignment == .leading {
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 6) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(iconColor)

            if style != .minimal {
                Text(Strings.Sharing.madeWithOllie)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            if style == .detailed {
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(Strings.App.websiteUrl)
                    .font(.system(size: fontSize))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var iconSize: CGFloat {
        switch style {
        case .minimal: return 16
        case .standard: return 14
        case .detailed: return 14
        }
    }

    private var fontSize: CGFloat {
        switch style {
        case .minimal: return 12
        case .standard: return 12
        case .detailed: return 11
        }
    }

    private var iconColor: Color {
        .otisAccent
    }
}

// MARK: - Modifiers

extension ShareableWatermark {
    func watermarkStyle(_ style: WatermarkStyle) -> ShareableWatermark {
        var copy = self
        copy.style = style
        return copy
    }

    func watermarkAlignment(_ alignment: HorizontalAlignment) -> ShareableWatermark {
        var copy = self
        copy.alignment = alignment
        return copy
    }
}

// MARK: - Preview

#Preview("Standard") {
    VStack(spacing: 20) {
        ShareableWatermark(style: .standard)
        ShareableWatermark(style: .minimal)
        ShareableWatermark(style: .detailed)
        ShareableWatermark(style: .standard, alignment: .leading)
        ShareableWatermark(style: .standard, alignment: .center)
    }
    .padding()
    .background(Color(.systemBackground))
}
