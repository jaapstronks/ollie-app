//
//  FoundationsModuleCard.swift
//  Ollie-app
//
//  Card displaying a foundations module in the training view.
//  Shows completion state, progress, and action button.
//

import SwiftUI

/// Card for displaying a foundations module
struct FoundationsModuleCard: View {
    let module: FoundationsModule
    let progress: FoundationsModuleProgress
    let isRequired: Bool
    let isSuggested: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isComplete: Bool {
        progress.isComplete || progress.skipped
    }

    private var statusText: String {
        if progress.skipped {
            return Strings.Training.Foundations.skippedStatus
        } else if progress.isComplete {
            return Strings.Training.Foundations.completedStatus
        } else if progress.pagesViewed.isEmpty {
            return Strings.Training.Foundations.notStartedStatus
        } else {
            return Strings.Training.Foundations.inProgressStatus
        }
    }

    private var statusColor: Color {
        if isComplete {
            return .otisSuccess
        } else if !progress.pagesViewed.isEmpty {
            return .orange
        } else {
            return .secondary
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isComplete
                            ? Color.otisSuccess.opacity(0.15)
                            : Color.otisAccent.opacity(0.1))
                        .frame(width: 48, height: 48)

                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.otisSuccess)
                    } else {
                        Image(systemName: module.icon)
                            .font(.title3)
                            .foregroundStyle(Color.otisAccent)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(module.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if isRequired && !isComplete {
                            Text(Strings.Training.Foundations.requiredBadge)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange))
                        } else if isSuggested && !isComplete {
                            Text(Strings.Training.Foundations.suggestedBadge)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue.opacity(0.15)))
                        }
                    }

                    Text(module.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    // Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)

                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }
                }

                Spacer()

                // Arrow
                if !isComplete {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isRequired && !isComplete
                            ? Color.orange.opacity(0.3)
                            : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .opacity(isComplete ? 0.7 : 1.0)
    }
}

// MARK: - Strings Extension

private let foundationsTable = "Training"

extension Strings.Training.Foundations {
    static let requiredBadge = String(localized: "Required", table: foundationsTable)
    static let suggestedBadge = String(localized: "Suggested", table: foundationsTable)
    static let completedStatus = String(localized: "Completed", table: foundationsTable)
    static let skippedStatus = String(localized: "Skipped", table: foundationsTable)
    static let notStartedStatus = String(localized: "Not started", table: foundationsTable)
    static let inProgressStatus = String(localized: "In progress", table: foundationsTable)
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FoundationsModuleCard(
            module: FoundationsContentProvider.gettingStartedModule(),
            progress: FoundationsModuleProgress(moduleId: "gettingStarted"),
            isRequired: true,
            isSuggested: false,
            onTap: {}
        )

        FoundationsModuleCard(
            module: FoundationsContentProvider.howDogsLearnModule(),
            progress: {
                var p = FoundationsModuleProgress(moduleId: "howDogsLearn")
                p.isComplete = true
                return p
            }(),
            isRequired: false,
            isSuggested: true,
            onTap: {}
        )
    }
    .padding()
}
