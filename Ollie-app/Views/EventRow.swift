//
//  EventRow.swift
//  Ollie-app
//

import SwiftUI
import UIKit

/// Single event row in the timeline
struct EventRow: View {
    let event: PuppyEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time
            Text(event.time.timeString)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .trailing)

            // Event icon
            EventIcon(type: event.type, location: event.location, size: 28)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.type.label)
                        .font(.body)
                        .fontWeight(.medium)

                    if let location = event.location {
                        Text("(\(location.label.lowercased()))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let who = event.who, !who.isEmpty {
                    Label(who, systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let exercise = event.exercise {
                    Label(exercise, systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let result = event.result {
                    Label(result, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                if let duration = event.durationMin {
                    Label("\(duration) min", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Walk location
                if event.type == .uitlaten, let spotName = event.spotName {
                    Label(spotName, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ollieAccent)
                }
            }

            Spacer()

            // Thumbnail or media indicator
            if let thumbnailPath = event.thumbnailPath {
                HStack(spacing: 8) {
                    ThumbnailView(relativePath: thumbnailPath)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if event.photo != nil || event.video != nil {
                HStack(spacing: 8) {
                    Image(systemName: event.video != nil ? "video" : "photo")
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint(event.photo != nil || event.video != nil ? Strings.EventRow.tapToViewMedia : "")
        .accessibilityIdentifier("EVENT_ROW_\(event.type.rawValue)")
    }

    private var accessibilityDescription: String {
        var parts = [event.time.timeString, event.type.label]
        if let location = event.location {
            parts.append(location.label)
        }
        if let note = event.note, !note.isEmpty {
            parts.append(note)
        }
        if let who = event.who, !who.isEmpty {
            parts.append(Strings.EventRow.withPerson(who))
        }
        return parts.joined(separator: ", ")
    }
}

/// Async thumbnail loader view with caching
struct ThumbnailView: View {
    let relativePath: String
    @State private var image: UIImage?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
            }
        }
        .task(id: relativePath) {
            await loadImageAsync()
        }
        .onDisappear {
            // Cancel loading if view disappears (scrolled off screen)
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private func loadImageAsync() async {
        // Load from cache or disk on background thread
        if let loaded = await ImageCache.shared.loadImage(relativePath: relativePath, isThumbnail: true) {
            // Only update if task wasn't cancelled
            if !Task.isCancelled {
                image = loaded
            }
        }
    }
}

#Preview {
    VStack {
        EventRow(event: PuppyEvent(
            time: Date(),
            type: .plassen,
            location: .buiten,
            note: "After breakfast"
        ))

        Divider()

        EventRow(event: PuppyEvent(
            time: Date(),
            type: .training,
            exercise: "Sit",
            result: "Good job!"
        ))

        Divider()

        EventRow(event: PuppyEvent(
            time: Date(),
            type: .sociaal,
            who: "Neighbor's dog Sasha"
        ))
    }
}
