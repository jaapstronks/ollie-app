//
//  OperantConditioningSheet.swift
//  Otis-app
//
//  Rich educational sheet explaining operant conditioning
//

import SwiftUI

/// Sheet explaining operant conditioning concept
struct OperantConditioningSheet: View {
    let onAcknowledge: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ConceptSheetView(
            icon: "brain.head.profile",
            iconColor: .purple,
            title: Strings.Training.Concepts.Operant.title,
            subtitle: Strings.Training.Concepts.Operant.subtitle,
            explanation: Strings.Training.Concepts.Operant.explanation,
            keyPoints: [
                Strings.Training.Concepts.Operant.point1,
                Strings.Training.Concepts.Operant.point2,
                Strings.Training.Concepts.Operant.point3,
                Strings.Training.Concepts.Operant.point4
            ],
            exampleTitle: Strings.Training.Concepts.Operant.exampleTitle,
            exampleText: Strings.Training.Concepts.Operant.exampleText,
            onAcknowledge: onAcknowledge,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Preview

#Preview {
    OperantConditioningSheet(
        onAcknowledge: {},
        onDismiss: {}
    )
}
