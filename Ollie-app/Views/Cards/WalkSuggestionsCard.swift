//
//  WalkSuggestionsCard.swift
//  Ollie-app
//
//  Card showing suggested socialization items to watch for during walks

import SwiftUI
import OllieShared

/// Card displaying walkable socialization items to watch for
struct WalkSuggestionsCard: View {
    @EnvironmentObject var socializationStore: SocializationStore

    @State private var selectedItem: SocializationItem?
    @State private var showLogSheet = false
    @State private var showFearProtocol = false

    @Environment(\.colorScheme) private var colorScheme

    private var suggestedItems: [SocializationItem] {
        socializationStore.suggestedWalkItems(limit: 3)
    }

    var body: some View {
        if !suggestedItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(Color.ollieAccent)
                    Text(Strings.Socialization.walkSuggestionsTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                // Items
                VStack(spacing: 8) {
                    ForEach(suggestedItems) { item in
                        walkSuggestionRow(item)
                    }
                }

                // Tip
                Text(Strings.Socialization.walkSuggestionsTip)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .glassCard(tint: .accent)
            .sheet(isPresented: $showLogSheet) {
                if let item = selectedItem {
                    LogExposureSheet(item: item) { reaction in
                        if reaction.needsFearProtocol {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showFearProtocol = true
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showFearProtocol) {
                FearProtocolSheet()
            }
        }
    }

    // MARK: - Walk Suggestion Row

    @ViewBuilder
    private func walkSuggestionRow(_ item: SocializationItem) -> some View {
        Button {
            selectedItem = item
            showLogSheet = true
            HapticFeedback.light()
        } label: {
            HStack(spacing: 12) {
                // Category icon
                if let category = socializationStore.category(forItemId: item.id) {
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Item info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // Progress
                    let exposures = socializationStore.getExposures(for: item.id)
                    let positiveCount = exposures.filter { $0.reaction.isPositive }.count

                    if let last = socializationStore.lastExposure(for: item.id), !last.reaction.isPositive {
                        // Recent negative - show warning
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text("Needs practice")
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.ollieWarning)
                    } else {
                        Text("\(positiveCount)/\(item.targetExposures)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Tap indicator
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.ollieAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    WalkSuggestionsCard()
        .environmentObject(SocializationStore())
        .padding()
}
