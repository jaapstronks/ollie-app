//
//  ShareButton.swift
//  Otis-app
//
//  Compact share button for use in cards and lists
//

import SwiftUI

/// A compact share button for inline use
struct ShareButton: View {
    let action: () -> Void

    var style: ShareButtonStyle = .bordered
    var size: ShareButtonSize = .regular

    enum ShareButtonStyle {
        case bordered
        case plain
        case filled
    }

    enum ShareButtonSize {
        case small
        case regular
        case large

        var iconFont: Font {
            switch self {
            case .small: return .footnote.weight(.medium)
            case .regular: return .body.weight(.medium)
            case .large: return .title3.weight(.medium)
            }
        }
    }

    var body: some View {
        switch style {
        case .bordered:
            Button(action: action) {
                Image(systemName: "square.and.arrow.up")
                    .font(size.iconFont)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)

        case .plain:
            Button(action: action) {
                Image(systemName: "square.and.arrow.up")
                    .font(size.iconFont)
            }
            .buttonStyle(.plain)

        case .filled:
            Button(action: action) {
                Image(systemName: "square.and.arrow.up")
                    .font(size.iconFont)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
        }
    }
}

// MARK: - Labeled Share Button

/// Share button with a text label
struct LabeledShareButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - Share Icon Button

/// Circular share button for toolbars
struct ShareIconButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
                .font(.body.weight(.medium))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ShareButton(action: {}, style: .bordered, size: .small)
            ShareButton(action: {}, style: .bordered, size: .regular)
            ShareButton(action: {}, style: .bordered, size: .large)
        }

        HStack(spacing: 20) {
            ShareButton(action: {}, style: .plain)
            ShareButton(action: {}, style: .filled)
        }

        LabeledShareButton(label: "Share", action: {})

        ShareIconButton(action: {})
    }
    .padding()
}
