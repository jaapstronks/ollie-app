//
//  ClickTimingSheet.swift
//  Otis-app
//
//  Rich educational sheet explaining click timing
//

import SwiftUI

/// Sheet explaining click timing concept
struct ClickTimingSheet: View {
    let onAcknowledge: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ConceptSheetView(
            icon: "timer",
            iconColor: .teal,
            title: Strings.Training.Concepts.Timing.title,
            subtitle: Strings.Training.Concepts.Timing.subtitle,
            explanation: Strings.Training.Concepts.Timing.explanation,
            keyPoints: [
                Strings.Training.Concepts.Timing.point1,
                Strings.Training.Concepts.Timing.point2,
                Strings.Training.Concepts.Timing.point3,
                Strings.Training.Concepts.Timing.point4
            ],
            exampleTitle: Strings.Training.Concepts.Timing.exampleTitle,
            exampleText: Strings.Training.Concepts.Timing.exampleText,
            onAcknowledge: onAcknowledge,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Preview

#Preview {
    ClickTimingSheet(
        onAcknowledge: {},
        onDismiss: {}
    )
}
