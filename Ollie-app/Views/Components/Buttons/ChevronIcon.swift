//
//  ChevronIcon.swift
//  Otis-app
//
//  Reusable chevron disclosure indicator for navigation rows

import SwiftUI

/// Standard chevron disclosure indicator for navigation rows
struct ChevronIcon: View {
    enum Style {
        /// Small chevron with caption font (default)
        case caption
        /// Small chevron with semibold weight
        case small
        /// Medium chevron with larger semibold weight
        case medium
    }

    enum ColorStyle {
        case secondary
        case tertiary
        case custom(Color)

        var shapeStyle: AnyShapeStyle {
            switch self {
            case .secondary:
                return AnyShapeStyle(.secondary)
            case .tertiary:
                return AnyShapeStyle(.tertiary)
            case .custom(let color):
                return AnyShapeStyle(color)
            }
        }
    }

    let style: Style
    let colorStyle: ColorStyle

    init(style: Style = .caption, color: ColorStyle = .tertiary) {
        self.style = style
        self.colorStyle = color
    }

    var body: some View {
        Image(systemName: "chevron.right")
            .font(font)
            .foregroundStyle(colorStyle.shapeStyle)
    }

    private var font: Font {
        switch style {
        case .caption:
            return .caption
        case .small:
            return .system(size: 12, weight: .semibold)
        case .medium:
            return .system(size: 14, weight: .semibold)
        }
    }
}

// MARK: - Previews

#Preview("Chevron Styles") {
    VStack(spacing: 20) {
        HStack {
            Text("Caption + tertiary (default)")
            Spacer()
            ChevronIcon()
        }

        HStack {
            Text("Small + tertiary")
            Spacer()
            ChevronIcon(style: .small)
        }

        HStack {
            Text("Medium + tertiary")
            Spacer()
            ChevronIcon(style: .medium)
        }

        HStack {
            Text("Caption + secondary")
            Spacer()
            ChevronIcon(color: .secondary)
        }
    }
    .padding()
}
