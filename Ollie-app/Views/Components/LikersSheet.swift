//
//  LikersSheet.swift
//  Ollie-app
//
//  Sheet showing who liked an event.
//

import SwiftUI
import OtisShared

/// Sheet displaying who liked an event
struct LikersSheet: View {
    let event: PuppyEvent
    @Environment(\.dismiss) private var dismiss

    private var sortedLikes: [EventLike] {
        (event.likes ?? []).sorted { $0.likedAt > $1.likedAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedLikes.isEmpty {
                    emptyState
                } else {
                    likersList
                }
            }
            .navigationTitle(Strings.Likes.likedBy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var emptyState: some View {
        EmptyStateView.noLikes
    }

    @ViewBuilder
    private var likersList: some View {
        List {
            ForEach(sortedLikes, id: \.likedBy) { like in
                likerRow(like)
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func likerRow(_ like: EventLike) -> some View {
        let resolved = ParticipantResolver.shared.resolve(cloudKitRecordID: like.likedBy)
        let isCurrentUser = UserIdentityStore.shared.isCurrentUser(like.likedBy)

        HStack(spacing: 12) {
            UserAvatarFromRecordID(cloudKitRecordID: like.likedBy, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(resolved.displayName)
                        .font(.body)
                        .fontWeight(.medium)

                    if isCurrentUser {
                        Text("(\(Strings.UserProfile.me))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(like.likedAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    LikersSheet(
        event: PuppyEvent(
            type: .moment,
            likes: [
                EventLike(likedBy: "user-1", likedAt: Date().addingTimeInterval(-3600)),
                EventLike(likedBy: "user-2", likedAt: Date().addingTimeInterval(-7200))
            ]
        )
    )
}

#Preview("Empty") {
    LikersSheet(event: PuppyEvent(type: .moment))
}
