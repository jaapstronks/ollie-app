//
//  PhaseProgressIndicator.swift
//  Otis-app
//
//  Horizontal capsule progress indicator for learning phases
//

import SwiftUI

/// Horizontal progress indicator showing current page in the learning flow
struct PhaseProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.otisAccent : Color.secondary.opacity(0.3))
                    .frame(width: index == currentPage ? 16 : 8, height: 4)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentPage + 1) of \(totalPages)")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PhaseProgressIndicator(currentPage: 0, totalPages: 4)
        PhaseProgressIndicator(currentPage: 1, totalPages: 4)
        PhaseProgressIndicator(currentPage: 2, totalPages: 4)
        PhaseProgressIndicator(currentPage: 3, totalPages: 4)
    }
    .padding()
}
