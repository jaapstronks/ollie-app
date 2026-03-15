//
//  RecentMomentCard.swift
//  Ollie-app
//
//  Card showing the most recent moment on the Today tab.
//  Links to the Diary view in Explore tab. Dismissable until a new moment is posted.
//

import SwiftUI
import OtisShared

/// Card showing the most recent moment with thumbnail, author, and like button
struct RecentMomentCard: View {
    let event: PuppyEvent
    let onNavigateToDiary: () -> Void
    let onDismiss: () -> Void

    @Environment(EventStore.self) private var eventStore
    @State private var thumbnail: UIImage?

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Resolved author name from CloudKit participant info
    private var authorName: String? {
        guard let loggedBy = event.loggedBy else { return nil }
        let resolved = ParticipantResolver.shared.resolve(cloudKitRecordID: loggedBy)
        return resolved.displayName
    }

    /// Relative time string (e.g., "2h ago", "yesterday")
    private var relativeTime: String {
        event.time.relativeFormatted()
    }

    /// Caption text (truncated)
    private var caption: String? {
        event.note
    }

    /// Like summary text (e.g., "Liked by Emma" or "2 likes")
    private var likeSummary: String? {
        guard event.hasLikes else { return nil }
        let count = event.likeCount
        if count == 1 {
            return Strings.Likes.oneLike
        } else {
            return Strings.Likes.multipleLikes(count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with title and dismiss
            HStack {
                Label(Strings.Moments.latestMoment, systemImage: "photo.on.rectangle.angled")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemFill))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.Common.close)
            }

            // Main content row
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail (tappable)
                Button(action: onNavigateToDiary) {
                    thumbnailView
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Strings.Moments.viewInDiary)

                // Content (tappable)
                Button(action: onNavigateToDiary) {
                    contentView
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityContentLabel)

                Spacer(minLength: 0)

                // Like button (positioned at bottom right of content area)
                VStack {
                    Spacer()
                    LikeButton(
                        event: event,
                        onToggle: {
                            if let updated = eventStore.toggleLike(on: event) {
                                // Event store handles the update
                                _ = updated
                            }
                        }
                    )
                }
            }
        }
        .padding(14)
        .glassStatusCard(tintColor: .purple.opacity(0.1))
        .accessibilityElement(children: .contain)
        .task {
            await loadThumbnail()
        }
    }

    /// Combined accessibility label for the content area
    private var accessibilityContentLabel: String {
        var parts: [String] = []
        if let authorName = authorName {
            parts.append(authorName)
        }
        parts.append(relativeTime)
        if let caption = caption, !caption.isEmpty {
            parts.append(caption)
        }
        if let likeSummary = likeSummary {
            parts.append(likeSummary)
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Thumbnail View

    @ViewBuilder
    private var thumbnailView: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Author and relative time
            HStack(spacing: 4) {
                if let authorName = authorName {
                    Text(authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Caption (if any)
            if let caption = caption, !caption.isEmpty {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            // Like summary
            if let likeSummary = likeSummary {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)

                    Text(likeSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Image Loading

    private func loadThumbnail() async {
        // Prefer thumbnail, fall back to full photo
        let path = event.thumbnailPath ?? event.photo
        guard let path = path else { return }

        // Use ImageCache for async loading with caching and deduplication
        if let loaded = await ImageCache.shared.loadImage(relativePath: path, isThumbnail: true) {
            thumbnail = loaded
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // With caption and likes
        RecentMomentCard(
            event: PuppyEvent(
                time: Date().addingTimeInterval(-7200),
                type: .moment,
                note: "Playing in the backyard with his new toy!",
                likes: [
                    EventLike(likedBy: "user-1"),
                    EventLike(likedBy: "user-2")
                ]
            ),
            onNavigateToDiary: { print("Navigate to diary") },
            onDismiss: { print("Dismissed") }
        )

        // Without caption
        RecentMomentCard(
            event: PuppyEvent(
                time: Date().addingTimeInterval(-3600),
                type: .moment
            ),
            onNavigateToDiary: { print("Navigate to diary") },
            onDismiss: { print("Dismissed") }
        )

        // With long caption
        RecentMomentCard(
            event: PuppyEvent(
                time: Date().addingTimeInterval(-86400),
                type: .moment,
                note: "Such a good boy during our morning walk! He met a new friend at the park and they played together for almost an hour.",
                likes: [EventLike(likedBy: "user-1")]
            ),
            onNavigateToDiary: { print("Navigate to diary") },
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
    .environment(EventStore())
}
