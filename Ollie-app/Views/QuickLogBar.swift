//
//  QuickLogBar.swift
//  Ollie-app
//

import SwiftUI

/// Bottom bar with quick-log buttons for common events
/// Uses liquid glass design for iOS 26 aesthetic
struct QuickLogBar: View {
    let onQuickLog: (EventType) -> Void
    let onShowAllEvents: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Floating glass bar
            HStack(spacing: 8) {
                ForEach(Constants.quickLogTypes) { type in
                    QuickLogButton(type: type, action: { onQuickLog(type) })
                }

                // V2: "+" button to show all event types
                MoreEventsButton(action: onShowAllEvents)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(glassOverlay)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 16, y: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Base layer
            if colorScheme == .dark {
                Color.white.opacity(0.08)
            } else {
                Color.white.opacity(0.75)
            }

            // Top highlight gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.4),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

/// Button to open the all-events sheet
struct MoreEventsButton: View {
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.ollieAccent)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.ollieAccent.opacity(0.3),
                                lineWidth: 0.5
                            )
                    )

                Text("Meer")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(GlassQuickLogButtonStyle())
        .accessibilityLabel("Meer event types")
        .accessibilityHint("Dubbeltik om alle event types te zien")
    }
}

struct QuickLogButton: View {
    let type: EventType
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                EventIcon(type: type, size: 28)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(iconBackgroundColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    )

                Text(type.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(GlassQuickLogButtonStyle())
        .accessibilityLabel("\(type.label) loggen")
        .accessibilityHint("Dubbeltik om \(type.label.lowercased()) te registreren")
    }

    private var iconBackgroundColor: Color {
        switch type {
        case .plassen, .poepen: return .ollieInfo
        case .eten, .drinken: return .ollieAccent
        case .slapen, .ontwaken: return .ollieSleep
        case .uitlaten, .tuin: return .ollieSuccess
        default: return .ollieMuted
        }
    }
}

/// Interactive button style for quick log buttons
struct GlassQuickLogButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    VStack {
        Spacer()
        QuickLogBar(
            onQuickLog: { type in
                print("Quick log: \(type)")
            },
            onShowAllEvents: {
                print("Show all events")
            }
        )
    }
}
