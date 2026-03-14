//
//  RecentMomentsPreviewCard.swift
//  Ollie-app
//
//  Shows the 3 most recent photo moments as a compact preview card
//

import SwiftUI
import OtisShared

/// Card showing the 3 most recent photos with larger thumbnails
struct RecentMomentsPreviewCard: View {
    let photoEvents: [PuppyEvent]
    var onPhotoTap: (PuppyEvent, Int) -> Void
    var onViewAll: (() -> Void)?

    private var recentThree: [PuppyEvent] {
        Array(photoEvents.prefix(3))
    }

    var body: some View {
        if !recentThree.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Label(Strings.Sharing.recentMoments, systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    if photoEvents.count > 3, let onViewAll {
                        Button {
                            onViewAll()
                        } label: {
                            Text(Strings.Common.seeAll)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.accent)
                        }
                    }
                }

                // Photo thumbnails row
                HStack(spacing: 10) {
                    ForEach(Array(recentThree.enumerated()), id: \.element.id) { index, event in
                        MomentPreviewThumbnail(event: event)
                            .onTapGesture {
                                HapticFeedback.light()
                                onPhotoTap(event, index)
                            }
                    }

                    // Placeholder slots for empty spaces
                    ForEach(0..<(3 - recentThree.count), id: \.self) { _ in
                        EmptyThumbnailSlot()
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM))
        }
    }
}

// MARK: - Moment Preview Thumbnail

private struct MomentPreviewThumbnail: View {
    let event: PuppyEvent

    var body: some View {
        EventThumbnailView(event: event)
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .bottomTrailing) {
                if event.hasLikes {
                    SmallLikeIndicator()
                }
            }
            .overlay(alignment: .bottomLeading) {
                // Time label
                Text(event.time.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(6)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var parts = [Strings.Sharing.momentCard]
        parts.append(event.time.formatted(date: .abbreviated, time: .shortened))
        if let note = event.note, !note.isEmpty {
            parts.append(note)
        }
        if event.hasLikes {
            parts.append(Strings.Likes.multipleLikes(event.likeCount))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Empty Thumbnail Slot

private struct EmptyThumbnailSlot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.tertiarySystemFill))
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.quaternary)
            }
    }
}

// MARK: - Small Like Indicator

private struct SmallLikeIndicator: View {
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 10))
            .foregroundStyle(.white)
            .padding(5)
            .background(Color.red)
            .clipShape(Circle())
            .offset(x: 4, y: 4)
    }
}

// MARK: - Preview

#Preview("Recent Moments Preview Card") {
    VStack {
        RecentMomentsPreviewCard(
            photoEvents: [
                PuppyEvent(
                    type: .moment,
                    note: "Playing in the park",
                    photo: "test/photo1.jpg"
                ),
                PuppyEvent(
                    type: .moment,
                    note: "Morning cuddles",
                    photo: "test/photo2.jpg",
                    likes: [EventLike(likedBy: "user-1")]
                ),
                PuppyEvent(
                    type: .uitlaten,
                    note: "Evening walk",
                    photo: "test/photo3.jpg"
                )
            ],
            onPhotoTap: { event, index in
                print("Tapped photo at index \(index): \(event.id)")
            },
            onViewAll: {
                print("View all tapped")
            }
        )
        .padding()

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Photo") {
    RecentMomentsPreviewCard(
        photoEvents: [
            PuppyEvent(
                type: .moment,
                note: "Just one photo",
                photo: "test/photo1.jpg"
            )
        ],
        onPhotoTap: { _, _ in }
    )
    .padding()
}

#Preview("Empty") {
    RecentMomentsPreviewCard(
        photoEvents: [],
        onPhotoTap: { _, _ in }
    )
    .padding()
}
