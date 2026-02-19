//
//  DigestCard.swift
//  Ollie-app
//
//  Compact daily digest card for timeline header

import SwiftUI

/// Compact card showing daily summary at top of timeline
struct DigestCard: View {
    let digest: DailyDigest
    let puppyName: String

    var body: some View {
        if digest.hasData || digest.dayNumber != nil {
            VStack(alignment: .leading, spacing: 8) {
                // Day number header
                if let dayNumber = digest.dayNumber {
                    HStack {
                        Text("Dag \(dayNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("met \(puppyName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Summary parts as flowing text
                if !digest.parts.isEmpty {
                    FlowingDigestText(parts: digest.parts)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
        }
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
