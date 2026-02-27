//
//  SocializationCategoryDetailView.swift
//  Ollie-app
//
//  Detail view showing all items in a socialization category

import SwiftUI
import OllieShared

/// Detail view for a socialization category, showing all items
struct SocializationCategoryDetailView: View {
    let category: SocializationCategory
    @EnvironmentObject var socializationStore: SocializationStore
    @EnvironmentObject var profileStore: ProfileStore

    @State private var selectedItem: SocializationItem?
    @State private var showFearProtocol = false
    @State private var lastLoggedReaction: SocializationReaction?

    var body: some View {
        List {
            // Progress header
            Section {
                categoryProgressHeader
            }

            // Items grouped by status
            Section {
                ForEach(sortedItems) { item in
                    SocializationItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = item
                        }
                }
            } header: {
                Text(Strings.Socialization.title)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(category.localizedDisplayName)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedItem) { item in
            LogExposureSheet(item: item) { reaction in
                lastLoggedReaction = reaction
                if reaction.needsFearProtocol {
                    // Show fear protocol after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showFearProtocol = true
                    }
                }
            }
        }
        .sheet(isPresented: $showFearProtocol) {
            FearProtocolSheet()
        }
    }

    // MARK: - Progress Header

    @ViewBuilder
    private var categoryProgressHeader: some View {
        let progress = socializationStore.categoryProgress(for: category.id)

        HStack(spacing: 16) {
            // Category icon
            Image(systemName: category.icon)
                .font(.system(size: 32))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Socialization.categoryProgress(
                    completed: progress.completed,
                    total: progress.total
                ))
                .font(.headline)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor(for: progress))
                            .frame(
                                width: geometry.size.width * progressFraction(for: progress),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var sortedItems: [SocializationItem] {
        // Sort: needs attention first, then in progress, then complete
        category.items.sorted { item1, item2 in
            let score1 = itemSortScore(item1)
            let score2 = itemSortScore(item2)
            return score1 > score2
        }
    }

    private func itemSortScore(_ item: SocializationItem) -> Int {
        let exposures = socializationStore.getExposures(for: item.id)
        let positiveCount = exposures.filter { $0.reaction.isPositive }.count
        let lastExposure = exposures.sorted { $0.date > $1.date }.first

        var score = 0

        // Recent negative reaction - highest priority
        if let last = lastExposure, !last.reaction.isPositive {
            score += 100
        }

        // Not started
        if exposures.isEmpty {
            score += 50
        }

        // Almost complete
        let remaining = item.targetExposures - positiveCount
        if remaining > 0 && remaining <= 1 {
            score += 25
        }

        // Already complete - lowest priority
        if positiveCount >= item.targetExposures {
            score -= 100
        }

        return score
    }

    private func progressFraction(for progress: (completed: Int, total: Int)) -> Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.completed) / Double(progress.total)
    }

    private func progressColor(for progress: (completed: Int, total: Int)) -> Color {
        let fraction = progressFraction(for: progress)
        switch fraction {
        case 1.0: return .ollieSuccess
        case 0.5...: return .ollieAccent
        default: return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SocializationCategoryDetailView(
            category: SocializationCategory(
                id: "mensen",
                name: "People",
                icon: "person.2.fill",
                items: [
                    SocializationItem(id: "kind", name: "Child", description: nil, targetExposures: 3, isWalkable: true),
                    SocializationItem(id: "adult", name: "Adult", description: nil, targetExposures: 3, isWalkable: true)
                ]
            )
        )
        .environmentObject(SocializationStore())
        .environmentObject(ProfileStore())
    }
}
