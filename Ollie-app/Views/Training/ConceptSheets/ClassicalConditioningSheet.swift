//
//  ClassicalConditioningSheet.swift
//  Otis-app
//
//  Rich educational sheet explaining classical conditioning
//

import SwiftUI

/// Sheet explaining classical conditioning concept
struct ClassicalConditioningSheet: View {
    let onAcknowledge: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ConceptSheetView(
            icon: "hand.draw.fill",
            iconColor: .blue,
            title: Strings.Training.Concepts.Classical.title,
            subtitle: Strings.Training.Concepts.Classical.subtitle,
            explanation: Strings.Training.Concepts.Classical.explanation,
            keyPoints: [
                Strings.Training.Concepts.Classical.point1,
                Strings.Training.Concepts.Classical.point2,
                Strings.Training.Concepts.Classical.point3,
                Strings.Training.Concepts.Classical.point4
            ],
            exampleTitle: Strings.Training.Concepts.Classical.exampleTitle,
            exampleText: Strings.Training.Concepts.Classical.exampleText,
            onAcknowledge: onAcknowledge,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Preview

#Preview {
    ClassicalConditioningSheet(
        onAcknowledge: {},
        onDismiss: {}
    )
}
