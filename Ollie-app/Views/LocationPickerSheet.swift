//
//  LocationPickerSheet.swift
//  Ollie-app
//

import SwiftUI
import OllieShared

/// Quick picker for potty location (binnen/buiten)
struct LocationPickerSheet: View {
    let eventType: EventType
    let onSelect: (EventLocation) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                EventIcon(type: eventType, size: 28)
                Text(eventType.label)
                    .font(.headline)
            }

            Text(Strings.LocationPicker.title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                LocationButtonIcon(
                    location: .buiten,
                    action: { onSelect(.buiten) }
                )

                LocationButtonIcon(
                    location: .binnen,
                    action: { onSelect(.binnen) }
                )
            }

            Button(Strings.Common.cancel, role: .cancel) {
                onCancel()
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct LocationButtonIcon: View {
    let location: EventLocation
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.success()
            action()
        } label: {
            VStack(spacing: 8) {
                LocationIcon(location: location, size: 40)

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
