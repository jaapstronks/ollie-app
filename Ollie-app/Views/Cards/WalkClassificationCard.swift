//
//  WalkClassificationCard.swift
//  Ollie-app
//
//  Card asking if an outdoor potty was part of a walk

import SwiftUI
import OtisShared

/// A card that asks if an outdoor potty event was part of a walk
struct WalkClassificationCard: View {
    let pottyEvent: PuppyEvent
    let onYes: () -> Void  // Log walk + optionally prompt leash sentiment
    let onNo: () -> Void   // Dismiss

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "figure.walk")
                    .font(.title3)
                    .foregroundStyle(Color.otisAccent)

                Text(Strings.Leash.wasThataWalk)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            HStack(spacing: 12) {
                Button {
                    onYes()
                } label: {
                    Text(Strings.Leash.yesLogWalk)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.otisAccent))
                }
                .buttonStyle(.plain)

                Button {
                    onNo()
                } label: {
                    Text(Strings.Common.no)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .glassStatusCard()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        WalkClassificationCard(
            pottyEvent: PuppyEvent(type: .plassen, location: .buiten),
            onYes: { print("Yes, log walk") },
            onNo: { print("No") }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
