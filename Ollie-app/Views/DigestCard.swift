//
//  DigestCard.swift
//  Ollie-app
//
//  Compact daily digest card for timeline header

import SwiftUI

/// Compact card showing daily summary at top of timeline
/// Uses liquid glass design for iOS 26 aesthetic
struct DigestCard: View {
    let digest: DailyDigest
    let puppyName: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if digest.hasData || digest.dayNumber != nil {
            VStack(alignment: .leading, spacing: 8) {
                // Day number header
                if let dayNumber = digest.dayNumber {
                    HStack(spacing: 8) {
                        // Day badge with glass effect
                        Text("Dag \(dayNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.ollieAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.12))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        Color.ollieAccent.opacity(0.2),
                                        lineWidth: 0.5
                                    )
                            )

                        Text("met \(puppyName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Summary parts as flowing text
                if !digest.parts.isEmpty {
                    FlowingDigestText(parts: digest.parts)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(glassOverlay)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.05)
            } else {
                Color.white.opacity(0.7)
            }

            // Subtle top highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                        Color.white.opacity(colorScheme == .dark ? 0.03 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

/// Flowing text display for digest parts
struct FlowingDigestText: View {
    let parts: [String]

    var body: some View {
        Text(formattedText)
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private var formattedText: String {
        parts.joined(separator: " · ")
    }
}

/// Alternative: chip-based display for digest parts
struct DigestChips: View {
    let parts: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(parts, id: \.self) { part in
                    Text(part)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                }
            }
        }
    }
}

#Preview("With Data") {
    VStack {
        DigestCard(
            digest: DailyDigest(
                dayNumber: 5,
                parts: ["5x plassen (100% buiten)", "3 maaltijden", "2 wandelingen"]
            ),
            puppyName: "Ollie"
        )

        Spacer()
    }
    .background(Color(.systemBackground))
}

#Preview("Day Number Only") {
    VStack {
        DigestCard(
            digest: DailyDigest(dayNumber: 1, parts: []),
            puppyName: "Ollie"
        )

        Spacer()
    }
    .background(Color(.systemBackground))
}

#Preview("Empty") {
    VStack {
        DigestCard(
            digest: .empty,
            puppyName: "Ollie"
        )

        Spacer()
    }
    .background(Color(.systemBackground))
}
