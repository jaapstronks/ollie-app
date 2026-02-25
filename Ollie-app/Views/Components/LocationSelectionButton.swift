//
//  LocationSelectionButton.swift
//  Ollie-app
//
//  Reusable location selection button for binnen/buiten picker
//

import SwiftUI
import OllieShared

/// Button for selecting indoor/outdoor location with accessibility support
struct LocationSelectionButton: View {
    let location: EventLocation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 6) {
                LocationIcon(location: location, size: 32)
                    .accessibilityHidden(true)

                Text(location.label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? location.iconColor : .primary)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? location.iconColor.opacity(0.15) : Color(.secondarySystemBackground))
            .cornerRadius(LayoutConstants.cornerRadiusM)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? location.iconColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.QuickLogSheet.locationAccessibility(location.label))
        .accessibilityHint(Strings.LocationSelection.accessibilityHint(location.label))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityValue(isSelected ? Strings.QuickLogSheet.selected : "")
        .accessibilityIdentifier("LOCATION_\(location.rawValue.uppercased())")
    }
}

#Preview {
    @Previewable @State var selected: EventLocation? = .buiten

    HStack(spacing: 16) {
        LocationSelectionButton(
            location: .buiten,
            isSelected: selected == .buiten,
            action: { selected = .buiten }
        )

        LocationSelectionButton(
            location: .binnen,
            isSelected: selected == .binnen,
            action: { selected = .binnen }
        )
    }
    .padding()
}
