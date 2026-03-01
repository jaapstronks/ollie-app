//
//  ExploreViewMode.swift
//  Otis-app
//
//  Toggle between Map and Gallery views in the Explore tab

import SwiftUI

/// View mode for the Explore tab
enum ExploreViewMode: String, CaseIterable, RawRepresentable {
    case map      // Full-screen map with spots and photo pins
    case gallery  // Photo gallery/diary view

    /// Localized label for the view mode
    var label: String {
        switch self {
        case .map:
            return Strings.Places.mapMode
        case .gallery:
            return Strings.MomentsGallery.title
        }
    }

    /// SF Symbol icon for the view mode
    var icon: String {
        switch self {
        case .map:
            return "map.fill"
        case .gallery:
            return "photo.on.rectangle"
        }
    }
}

/// Segmented control for switching between Explore view modes
struct ExploreViewModeToggle: View {
    @Binding var mode: ExploreViewMode

    var body: some View {
        Picker(selection: $mode) {
            ForEach(ExploreViewMode.allCases, id: \.self) { viewMode in
                Label(viewMode.label, systemImage: viewMode.icon)
                    .tag(viewMode)
            }
        } label: {
            Text("View Mode")
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Explore view mode")
    }
}

#Preview {
    @Previewable @State var mode: ExploreViewMode = .map

    VStack(spacing: 20) {
        ExploreViewModeToggle(mode: $mode)
            .padding(.horizontal)

        Text("Selected: \(mode.label)")
            .foregroundStyle(.secondary)
    }
}
