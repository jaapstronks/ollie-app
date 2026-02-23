//
//  SocializationItemRow.swift
//  Ollie-app
//
//  Row showing a single socialization item with progress

import SwiftUI

/// Row displaying a socialization item with progress bar and last exposure info
struct SocializationItemRow: View {
    let item: SocializationItem
    @EnvironmentObject var socializationStore: SocializationStore

    @Environment(\.colorScheme) private var colorScheme

    private var exposures: [Exposure] {
        socializationStore.getExposures(for: item.id)
    }

    private var positiveCount: Int {
        exposures.filter { $0.reaction.isPositive }.count
    }

    private var progressFraction: Double {
        socializationStore.progressFraction(for: item.id)
    }

    private var isComfortable: Bool {
        socializationStore.isComfortable(itemId: item.id)
    }

    private var lastExposure: Exposure? {
        socializationStore.lastExposure(for: item.id)
    }

    private var statusText: String {
        if isComfortable {
            return Strings.Socialization.comfortableState
        } else if positiveCount > 0 {
            return Strings.Socialization.inProgress
        } else {
            return Strings.Socialization.notStarted
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name and status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let description = item.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Status indicator
                statusBadge
            }

            // Progress bar
            HStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * progressFraction, height: 6)
                    }
                }
                .frame(height: 6)

                // Count
                Text("\(positiveCount)/\(item.targetExposures)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }

            // Last exposure info
            if let last = lastExposure {
                lastExposureRow(last)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            if isComfortable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.ollieSuccess)
            } else if let last = lastExposure, !last.reaction.isPositive {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.ollieWarning)
            }
        }
        .font(.system(size: 14))
    }

    // MARK: - Last Exposure Row

    @ViewBuilder
    private func lastExposureRow(_ exposure: Exposure) -> some View {
        HStack(spacing: 8) {
            // Reaction icon
            Image(systemName: exposure.reaction.icon)
                .font(.caption)
                .foregroundStyle(exposure.reaction.isPositive ? Color.ollieSuccess : Color.ollieWarning)

            // Distance
            Text(exposure.distance.label)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Date
            Text(formattedDate(exposure.date))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(exposure.reaction.isPositive ?
                      Color.ollieSuccess.opacity(0.1) :
                      Color.ollieWarning.opacity(0.1))
        )
    }

    // MARK: - Helpers

    private var progressColor: Color {
        if isComfortable {
            return .ollieSuccess
        } else if let last = lastExposure, !last.reaction.isPositive {
            return .ollieWarning
        } else if positiveCount > 0 {
            return .ollieAccent
        } else {
            return .secondary
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    let store = SocializationStore()
    let item = SocializationItem(
        id: "kind",
        name: "Child (0-5 years)",
        description: "Toddlers and young children",
        targetExposures: 3,
        isWalkable: true
    )

    return List {
        SocializationItemRow(item: item)
            .environmentObject(store)
    }
}
