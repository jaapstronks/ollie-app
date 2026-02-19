//
//  LocationPickerSheet.swift
//  Ollie-app
//

import SwiftUI

/// Quick picker for potty location (binnen/buiten)
struct LocationPickerSheet: View {
    let eventType: EventType
    let onSelect: (EventLocation) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("\(eventType.emoji) \(eventType.label)")
                .font(.headline)

            Text("Waar?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                LocationButton(
                    location: .buiten,
                    emoji: "🌳",
                    action: { onSelect(.buiten) }
                )

                LocationButton(
                    location: .binnen,
                    emoji: "🏠",
                    action: { onSelect(.binnen) }
                )
            }

            Button("Annuleren", role: .cancel) {
                onCancel()
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct LocationButton: View {
    let location: EventLocation
    let emoji: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.success()
            action()
        } label: {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 40))

                Text(location.label)
                    .font(.headline)
            }
            .frame(width: 100, height: 100)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LocationPickerSheet(
        eventType: .plassen,
        onSelect: { _ in },
        onCancel: {}
    )
}
