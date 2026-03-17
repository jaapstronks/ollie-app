//
//  SocializationFullListView.swift
//  Otis-app
//
//  Full list of all socialization categories

import SwiftUI
import OtisShared

/// Full list view showing all socialization categories
struct SocializationFullListView: View {
    @Environment(SocializationStore.self) var socializationStore
    @Environment(ProfileStore.self) var profileStore

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress summary at top
                SocializationProgressCard()
                    .padding(.horizontal)

                // All categories
                VStack(spacing: 0) {
                    ForEach(socializationStore.categories) { category in
                        NavigationLink {
                            SocializationCategoryDetailView(category: category)
                        } label: {
                            SocializationCategoryRow(category: category)
                        }
                        .buttonStyle(.plain)

                        if category.id != socializationStore.categories.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .glassCard(tint: .accent)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(Strings.Train.socialization)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SocializationFullListView()
            .environment(SocializationStore())
            .environment(ProfileStore())
    }
}
