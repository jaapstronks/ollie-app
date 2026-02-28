//
//  ViewModeToggle.swift
//  Ollie-app
//
//  Segmented control for switching between visual and list timeline modes

import SwiftUI

/// View mode for the timeline
enum TimelineViewMode: String, CaseIterable {
    case visual
    case list

    var icon: String {
        switch self {
        case .visual: return "chart.bar.fill"
        case .list: return "list.bullet"
        }
    }

    var label: String {
        switch self {
        case .visual: return Strings.VisualTimeline.visualMode
        case .list: return Strings.VisualTimeline.listMode
        }
    }
}

/// Compact toggle for switching between visual and list modes
struct ViewModeToggle: View {
    @Binding var mode: TimelineViewMode

    var body: some View {
        Picker("View Mode", selection: $mode) {
            ForEach(TimelineViewMode.allCases, id: \.self) { mode in
                Label(mode.label, systemImage: mode.icon)
                    .labelStyle(.iconOnly)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 80)
    }
}

/// Toolbar button for toggling view mode
struct ViewModeToolbarButton: View {
    @Binding var mode: TimelineViewMode

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = mode == .visual ? .list : .visual
            }
        } label: {
            Image(systemName: mode == .visual ? "list.bullet" : "chart.bar.fill")
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel(mode == .visual ? Strings.VisualTimeline.switchToList : Strings.VisualTimeline.switchToVisual)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var mode: TimelineViewMode = .visual

        var body: some View {
            VStack(spacing: 40) {
                ViewModeToggle(mode: $mode)

                HStack {
                    Text("Current: \(mode.label)")
                    Spacer()
                    ViewModeToolbarButton(mode: $mode)
                }
                .padding()
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
