//
//  DiaryCardView.swift
//  Otis-app
//
//  Social media-style photo card for diary view mode.
//  Shows author, relative time, photo, caption, likes, and like button.
//

import SwiftUI
import OtisShared

/// A social media-style photo card showing author, photo, caption, and likes
struct DiaryCardView: View {
    let event: PuppyEvent
    var onTap: (() -> Void)? = nil

    @Environment(EventStore.self) private var eventStore
    @State private var image: UIImage?

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Computed Properties

    /// Resolved author name from CloudKit participant info
    private var authorName: String? {
        guard let loggedBy = event.loggedBy else { return nil }
        let resolved = ParticipantResolver.shared.resolve(cloudKitRecordID: loggedBy)
        return resolved.displayName
    }

    /// Whether this was logged by the current user
    private var isCurrentUser: Bool {
        guard let loggedBy = event.loggedBy else { return true }
        return UserIdentityStore.shared.isCurrentUser(loggedBy)
    }

    /// Relative time string (e.g., "2h ago", "yesterday")
    private var relativeTime: String {
        event.time.relativeFormatted()
    }

    /// Formatted date string (e.g., "February 15, 2026")
    private var formattedDate: String {
        event.time.formatted(date: .long, time: .omitted)
    }

    /// Like summary text (e.g., "Liked by Emma and 2 others")
    private var likeSummaryText: String? {
        guard event.hasLikes else { return nil }
        let count = event.likeCount

        // Get the first liker's name (if not current user)
        if let firstLike = event.likes?.first {
            let likerName = ParticipantResolver.shared.resolve(cloudKitRecordID: firstLike.likedBy).displayName

            if count == 1 {
                // "Liked by Emma" or "You liked this"
                if UserIdentityStore.shared.isCurrentUser(firstLike.likedBy) {
                    return Strings.Likes.youLiked
                } else {
                    return Strings.Likes.likedByName(likerName)
                }
            } else if count == 2 {
                // "Liked by Emma and 1 other"
                return Strings.Likes.likedByNameAndOneOther(likerName)
            } else {
                // "Liked by Emma and X others"
                return Strings.Likes.likedByNameAndOthers(likerName, count: count - 1)
            }
        }

        // Fallback to simple count
        if count == 1 {
            return Strings.Likes.oneLike
        } else {
            return Strings.Likes.multipleLikes(count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Author + relative time
            headerView
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            // Photo
            photoView
                .onTapGesture {
                    onTap?()
                }

            // Footer: Actions + Caption + Likes
            footerView
                .padding(.horizontal, 4)
                .padding(.top, 10)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .task {
            await loadImage()
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header View

    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 10) {
            // Author avatar
            if let loggedBy = event.loggedBy {
                UserAvatarFromRecordID(cloudKitRecordID: loggedBy, size: 36)
            } else {
                // Default avatar for events without loggedBy
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.purple)
                    }
            }

            // Author name and time
            VStack(alignment: .leading, spacing: 2) {
                if let authorName = authorName {
                    Text(authorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 4) {
                    Text(relativeTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Photo View

    @ViewBuilder
    private var photoView: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width * 0.75)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay {
                            ProgressView()
                        }
                }
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
    }

    // MARK: - Footer View

    @ViewBuilder
    private var footerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Action row: Like button
            HStack {
                LikeButton(
                    event: event,
                    onToggle: {
                        if let _ = eventStore.toggleLike(on: event) {
                            // Event store handles the update
                        }
                    }
                )

                Spacer()

                // Photo icon indicator
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Like summary text
            if let likeSummary = likeSummaryText {
                Text(likeSummary)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // Caption
            if let note = event.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    // MARK: - Image Loading

    private func loadImage() async {
        // Load full photo for diary view (not thumbnail)
        guard let path = event.photo else { return }

        // Use ImageCache for async loading
        if let loaded = await ImageCache.shared.loadImage(relativePath: path, isThumbnail: false) {
            image = loaded
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            // With caption and likes
            DiaryCardView(
                event: PuppyEvent(
                    time: Date().addingTimeInterval(-7200),
                    type: .moment,
                    note: "First time at the dog park! He was so excited to meet other puppies and made a new friend.",
                    likes: [
                        EventLike(likedBy: "user-1"),
                        EventLike(likedBy: "user-2")
                    ]
                )
            )

            // Without caption, single like
            DiaryCardView(
                event: PuppyEvent(
                    time: Date().addingTimeInterval(-86400),
                    type: .moment,
                    likes: [EventLike(likedBy: "user-1")]
                )
            )

            // No likes, with caption
            DiaryCardView(
                event: PuppyEvent(
                    time: Date().addingTimeInterval(-172800),
                    type: .moment,
                    note: "Morning cuddles before the walk."
                )
            )

            // Minimal - no likes, no caption
            DiaryCardView(
                event: PuppyEvent(
                    time: Date().addingTimeInterval(-259200),
                    type: .moment
                )
            )
        }
        .padding()
    }
    .environment(EventStore())
}
