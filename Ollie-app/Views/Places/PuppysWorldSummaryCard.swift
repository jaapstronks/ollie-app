//
//  PuppysWorldSummaryCard.swift
//  Otis-app
//
//  Summary card showing exploration stats: places discovered, moments captured, contacts saved
//

import SwiftUI

/// Summary card for the Places tab showing exploration statistics
struct PuppysWorldSummaryCard: View {
    let puppyName: String
    let placesCount: Int
    let momentsCount: Int
    let contactsCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with puppy name
            HStack {
                Image(systemName: "globe.europe.africa.fill")
                    .foregroundStyle(Color.otisAccent)
                Text(Strings.Places.puppysWorld(name: puppyName))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Stats row
            HStack(spacing: 0) {
                // Places discovered
                statItem(
                    value: placesCount,
                    label: Strings.Places.placesLabel,
                    icon: "mappin.circle.fill",
                    color: .otisAccent
                )

                Spacer()

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)

                Spacer()

                // Moments captured
                statItem(
                    value: momentsCount,
                    label: Strings.Places.momentsLabel,
                    icon: "camera.fill",
                    color: .pink
                )

                Spacer()

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)

                Spacer()

                // Contacts saved
                statItem(
                    value: contactsCount,
                    label: Strings.Places.contactsLabel,
                    icon: "person.2.fill",
                    color: .otisInfo
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Stat Item

    @ViewBuilder
    private func statItem(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PuppysWorldSummaryCard(
            puppyName: "Max",
            placesCount: 12,
            momentsCount: 234,
            contactsCount: 8
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
