//
//  RoutineStatusCard.swift
//  Otis-app
//
//  Today's routine progress card
//

import SwiftUI
import OtisShared

/// Card showing today's routine status and next scheduled item
struct RoutineStatusCard: View {
    let items: [RoutineItem]
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var enabledItems: [RoutineItem] {
        items.filter(\.isEnabled)
    }

    private var nextItem: RoutineItem? {
        enabledItems.nextItem()
    }

    private var itemsByCategory: [RoutineCategory: [RoutineItem]] {
        Dictionary(grouping: enabledItems) { $0.category }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                if enabledItems.isEmpty {
                    emptyState
                } else {
                    // Next up section
                    if let next = nextItem {
                        nextUpSection(item: next)
                    } else {
                        allDoneSection
                    }

                    Divider()

                    // Category progress
                    categoryProgressSection
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(Strings.Routine.noItems)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Strings.Routine.noItemsDescription)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Next Up Section

    @ViewBuilder
    private func nextUpSection(item: RoutineItem) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.category.icon)
                .font(.system(size: 24))
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Routine.nextUp)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(item.label)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let time = item.formattedTime {
                    Text(time)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - All Done Section

    @ViewBuilder
    private var allDoneSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Routine.allDone)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(enabledItems.count) items in routine")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Category Progress

    @ViewBuilder
    private var categoryProgressSection: some View {
        HStack(spacing: 16) {
            ForEach(RoutineCategory.allCases, id: \.self) { category in
                let categoryItems = itemsByCategory[category] ?? []
                if !categoryItems.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(colorForCategory(category))

                        Text("\(categoryItems.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func colorForCategory(_ category: RoutineCategory) -> Color {
        switch category {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .purple
        case .anytime: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RoutineStatusCard(
            items: DailyRoutine.adultDogDefault().items,
            onTap: {}
        )

        RoutineStatusCard(
            items: [],
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
