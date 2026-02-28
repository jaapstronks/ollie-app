//
//  MomentsViewMode.swift
//  Ollie-app
//
//  Segmented control for switching between Gallery and Diary view modes

import SwiftUI

/// View mode for the Moments gallery
enum MomentsViewMode: String, CaseIterable, RawRepresentable {
    case gallery  // Dense 3-column grid of thumbnails
    case diary    // Vertical scroll, one large photo per day with date and caption

    /// Localized label for the view mode
    var label: String {
        switch self {
        case .gallery:
            return Strings.MomentsGallery.galleryMode
        case .diary:
            return Strings.MomentsGallery.diaryMode
        }
    }

    /// SF Symbol icon for the view mode
    var icon: String {
        switch self {
        case .gallery:
            return "square.grid.3x3"
        case .diary:
            return "book.pages"
        }
    }
}

/// Segmented control for switching between Moments view modes
struct MomentsViewModeToggle: View {
    @Binding var mode: MomentsViewMode

    var body: some View {
        Picker(selection: $mode) {
            ForEach(MomentsViewMode.allCases, id: \.self) { viewMode in
                Label(viewMode.label, systemImage: viewMode.icon)
                    .tag(viewMode)
            }
        } label: {
            Text("View Mode")
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Moments view mode")
    }
}

#Preview {
    @Previewable @State var mode: MomentsViewMode = .gallery

    VStack(spacing: 20) {
        MomentsViewModeToggle(mode: $mode)
            .padding(.horizontal)

        Text("Selected: \(mode.label)")
            .foregroundStyle(.secondary)
    }
}
