//
//  SpotRowView.swift
//  Ollie-app
//
//  Reusable row component for displaying a walk spot

import SwiftUI

/// Row view for displaying a saved walk spot in lists
struct SpotRowView: View {
    let spot: WalkSpot
    var showVisitCount: Bool = true
    var onFavoriteToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Pin icon
            Image(systemName: spot.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(spot.isFavorite ? .yellow : .ollieAccent)
                .frame(width: 32)

            // Spot info
            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.body)
                    .fontWeight(.medium)

                if showVisitCount {
                    Text(Strings.WalkLocations.visitCount(spot.visitCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let notes = spot.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Favorite button (if toggle provided)
            if let toggle = onFavoriteToggle {
                Button {
                    HapticFeedback.light()
                    toggle()
                } label: {
                    Image(systemName: spot.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(spot.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
    }
}

/// Compact version for picker sheets
struct SpotRowCompact: View {
    let spot: WalkSpot
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: spot.isFavorite ? "star.fill" : "mappin")
                .font(.caption)
                .foregroundStyle(spot.isFavorite ? .yellow : .secondary)
                .frame(width: 20)

            Text(spot.name)
                .font(.subheadline)
                .lineLimit(1)

            if spot.visitCount > 1 {
                Text("(\(spot.visitCount)x)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(Color.ollieAccent)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.ollieAccent.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        SpotRowView(
            spot: WalkSpot(
                name: "Kralingse Bos",
                latitude: 51.9225,
                longitude: 4.4792,
                isFavorite: true,
                visitCount: 12
            ),
            onFavoriteToggle: {}
        )
        .padding()

        Divider()

        SpotRowView(
            spot: WalkSpot(
                name: "Park nearby",
                latitude: 51.9225,
                longitude: 4.4792,
                notes: "Nice open field for training",
                visitCount: 3
            ),
            onFavoriteToggle: {}
        )
        .padding()

        Divider()

        SpotRowCompact(
            spot: WalkSpot(
                name: "Favorite Park",
                latitude: 51.9225,
                longitude: 4.4792,
                isFavorite: true,
                visitCount: 8
            ),
            isSelected: true
        )
        .padding()

        SpotRowCompact(
            spot: WalkSpot(
                name: "Corner spot",
                latitude: 51.9225,
                longitude: 4.4792,
                visitCount: 2
            ),
            isSelected: false
        )
        .padding()
    }
}
