//
//  DayHeroCard.swift
//  Ollie-app
//
//  Simple hero card showing the day number with puppy
//  Focused single purpose - no redundant stats

import SwiftUI

/// Hero card displaying "Day X with [Puppy]"
/// Clean, prominent display for the day counter
struct DayHeroCard: View {
    let dayNumber: Int?
    let puppyName: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let day = dayNumber {
            HStack(spacing: 12) {
                // Day number badge
                Text("\(day)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ollieAccent)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.ollieAccent.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.ollieAccent.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Digest.dayLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(Strings.Digest.withPuppy(name: puppyName))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassBackground(.card)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Strings.Digest.dayNumber(day)) \(Strings.Digest.withPuppy(name: puppyName))")
        }
    }
}

// MARK: - Previews

#Preview("Day 8") {
    VStack {
        DayHeroCard(dayNumber: 8, puppyName: "Ollie")
        Spacer()
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Day 1") {
    VStack {
        DayHeroCard(dayNumber: 1, puppyName: "Max")
        Spacer()
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Day 100") {
    VStack {
        DayHeroCard(dayNumber: 100, puppyName: "Bella")
        Spacer()
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("No Day Number") {
    VStack {
        DayHeroCard(dayNumber: nil, puppyName: "Ollie")
        Text("(Shows nothing when no day number)")
            .foregroundStyle(.secondary)
        Spacer()
    }
    .padding()
    .background(Color(.systemBackground))
}
