//
//  SocializationCategoryRow.swift
//  Ollie-app
//
//  Row displaying a socialization category with progress

import SwiftUI
import OllieShared

/// Row showing a category with emoji, name, and progress indicator
struct SocializationCategoryRow: View {
    let category: SocializationCategory
    @EnvironmentObject var socializationStore: SocializationStore

    @Environment(\.colorScheme) private var colorScheme

    private var progress: (completed: Int, total: Int) {
        socializationStore.categoryProgress(for: category.id)
    }

    private var progressFraction: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.completed) / Double(progress.total)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.1))
                )

            // Name and progress text
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(Strings.Socialization.categoryProgress(
                    completed: progress.completed,
                    total: progress.total
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: progressFraction)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                if progress.completed == progress.total {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.ollieSuccess)
                }
            }
            .frame(width: 32, height: 32)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var progressColor: Color {
        switch progressFraction {
        case 1.0: return .ollieSuccess
        case 0.5...: return .ollieAccent
        case 0.25...: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    let store = SocializationStore()
    let category = SocializationCategory(
        id: "mensen",
        name: "People",
        icon: "person.2.fill",
        items: [
            SocializationItem(id: "test", name: "Test", description: nil, targetExposures: 3, isWalkable: true)
        ]
    )

    return SocializationCategoryRow(category: category)
        .environmentObject(store)
        .padding()
}
