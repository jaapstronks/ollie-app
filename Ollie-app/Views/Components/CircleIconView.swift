//
//  CircleIconView.swift
//  Ollie-app
//
//  Reusable icon in circular background component
//

import SwiftUI
import OllieShared

/// Icon displayed in a circular background with optional border
struct CircleIconView: View {
    let icon: CircleIconContent
    let color: Color
    var size: CGFloat = 44
    var iconScale: CGFloat = 0.5
    var showBorder: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.15))

            iconContent
        }
        .frame(width: size, height: size)
        .overlay {
            if showBorder {
                Circle()
                    .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
            }
        }
        .accessibilityHidden(true)  // Decorative, parent provides accessibility
    }

    @ViewBuilder
    private var iconContent: some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: size * iconScale, weight: .semibold))
                .foregroundStyle(color)

        case .eventType(let type):
            EventIcon(type: type, size: size * 0.65)

        case .potty:
            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: size * 0.36, weight: .medium))
                    .foregroundStyle(Color.ollieInfo)
                Image(systemName: "circle.inset.filled")
                    .font(.system(size: size * 0.32, weight: .medium))
                    .foregroundStyle(Color.ollieWarning)
            }

        case .custom(let view):
            AnyView(view)
        }
    }
}

/// Content types for CircleIconView
enum CircleIconContent {
    case system(String)
    case eventType(EventType)
    case potty
    case custom(any View)
}

// MARK: - Preview

#Preview("Circle Icons") {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            CircleIconView(icon: .system("plus"), color: .ollieAccent, showBorder: true)
            CircleIconView(icon: .system("camera.fill"), color: .ollieAccent, showBorder: true)
            CircleIconView(icon: .potty, color: .ollieInfo)
        }

        HStack(spacing: 16) {
            CircleIconView(icon: .eventType(.eten), color: .ollieAccent)
            CircleIconView(icon: .eventType(.slapen), color: .ollieSleep)
            CircleIconView(icon: .eventType(.uitlaten), color: .ollieSuccess)
        }
    }
    .padding()
}
