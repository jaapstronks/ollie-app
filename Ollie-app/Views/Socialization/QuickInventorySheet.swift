//
//  QuickInventorySheet.swift
//  Otis-app
//
//  Quick check sheet for marking items as familiar on first visit

import SwiftUI
import OtisShared

/// Sheet for quickly marking items as comfortable
struct QuickInventorySheet: View {
    @Environment(SocializationStore.self) var socializationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategory: SocializationCategory?
    @State private var markedCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(Strings.Socialization.firstVisitTitle)
                        .font(.headline)

                    Text(Strings.Socialization.quickCheckModeDesc)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if markedCount > 0 {
                        Text("\(markedCount) marked comfortable")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.otisSuccess)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))

                // Category list or item list
                if let category = selectedCategory {
                    categoryItemsView(category)
                } else {
                    categoriesListView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if selectedCategory != nil {
                        Button {
                            withAnimation {
                                selectedCategory = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.caption)
                                Text(Strings.Common.back)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Categories List

    @ViewBuilder
    private var categoriesListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(socializationStore.categories) { category in
                    let comfortableCount = category.items.filter {
                        socializationStore.isComfortable(itemId: $0.id)
                    }.count

                    Button {
                        withAnimation {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.title3)
                                .foregroundStyle(Color.otisAccent)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.localizedName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)

                                Text("\(category.items.count) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if comfortableCount > 0 {
                                Text("\(comfortableCount)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.otisSuccess)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.otisSuccess.opacity(0.15))
                                    )
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Category Items View

    @ViewBuilder
    private func categoryItemsView(_ category: SocializationCategory) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Category header
                HStack {
                    Image(systemName: category.icon)
                        .foregroundStyle(Color.otisAccent)
                    Text(category.localizedName)
                        .font(.headline)

                    Spacer()

                    // Select all / Deselect all
                    let allComfortable = category.items.allSatisfy {
                        socializationStore.isComfortable(itemId: $0.id)
                    }

                    Button(allComfortable ? "Deselect All" : "Select All") {
                        withAnimation {
                            for item in category.items {
                                if allComfortable {
                                    socializationStore.unmarkComfortable(item.id)
                                    markedCount = max(0, markedCount - 1)
                                } else if !socializationStore.isComfortable(itemId: item.id) {
                                    socializationStore.markComfortable(item.id)
                                    markedCount += 1
                                }
                            }
                        }
                        HapticFeedback.selection()
                    }
                    .font(.caption)
                    .foregroundStyle(Color.otisAccent)
                }
                .padding()

                Divider()

                // Items
                LazyVStack(spacing: 0) {
                    ForEach(category.items, id: \.id) { item in
                        let isComfortable = socializationStore.isComfortable(itemId: item.id)

                        HStack(spacing: 12) {
                            Image(systemName: isComfortable ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isComfortable ? Color.otisSuccess : .secondary)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.localizedDisplayName)
                                    .font(.subheadline)
                                    .foregroundStyle(isComfortable ? .secondary : .primary)

                                if let description = item.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if isComfortable {
                                    socializationStore.unmarkComfortable(item.id)
                                    markedCount = max(0, markedCount - 1)
                                } else {
                                    socializationStore.markComfortable(item.id)
                                    markedCount += 1
                                }
                            }
                            HapticFeedback.selection()
                        }

                        if item.id != category.items.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuickInventorySheet()
        .environment(SocializationStore())
}
