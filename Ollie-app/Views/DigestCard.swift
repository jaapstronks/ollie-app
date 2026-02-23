//
//  DigestCard.swift
//  Ollie-app
//
//  Compact daily digest card for timeline header

import SwiftUI
import OllieShared

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
                        Text(Strings.Digest.dayNumber(dayNumber))
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

                        Text(Strings.Digest.withPuppy(name: puppyName))
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
            .glassBackground(.card)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    private var accessibilityLabel: String {
        var parts: [String] = []
        if let dayNumber = digest.dayNumber {
            parts.append("\(Strings.Digest.dayNumber(dayNumber)) \(Strings.Digest.withPuppy(name: puppyName))")
        }
        parts.append(contentsOf: digest.parts)
        return parts.joined(separator: ". ")
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
