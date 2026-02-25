//
//  PlacesTimelineView.swift
//  Ollie-app
//
//  Timeline view showing moments and walks chronologically
//

import SwiftUI
import OllieShared

/// Timeline entry type for Places tab
enum PlacesTimelineEntryType {
    case moment(PuppyEvent)
    case walk(PuppyEvent)

    var date: Date {
        switch self {
        case .moment(let event), .walk(let event):
            return event.time
        }
    }

    var id: UUID {
        switch self {
        case .moment(let event), .walk(let event):
            return event.id
        }
    }
}

/// Timeline view showing photos and walks in chronological order
struct PlacesTimelineView: View {
    @ObservedObject var momentsViewModel: MomentsViewModel
    @ObservedObject var viewModel: TimelineViewModel
    let onSelectPhoto: (PuppyEvent) -> Void

    private var timelineEntries: [(month: String, entries: [PlacesTimelineEntryType])] {
        // Combine moments and walks
        var allEntries: [PlacesTimelineEntryType] = []

        // Add moments
        for event in momentsViewModel.events {
            allEntries.append(.moment(event))
        }

        // Add walks from the last 365 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -365, to: endDate)!

        let walks = viewModel.eventStore.getEvents(from: startDate, to: endDate)
            .filter { $0.type == .uitlaten }

        for walk in walks {
            allEntries.append(.walk(walk))
        }

        // Sort by date (most recent first)
        allEntries.sort { $0.date > $1.date }

        // Group by month
        let grouped = Dictionary(grouping: allEntries) { entry -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: entry.date)
        }

        return grouped.map { (month: $0.key, entries: $0.value) }
            .sorted { lhs, rhs in
                guard let lhsDate = lhs.entries.first?.date,
                      let rhsDate = rhs.entries.first?.date else { return false }
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        Group {
            if timelineEntries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(timelineEntries, id: \.month) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                // Month header
                                Text(section.month)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)

                                // Entries
                                ForEach(section.entries, id: \.id) { entry in
                                    switch entry {
                                    case .moment(let event):
                                        MomentTimelineCard(event: event)
                                            .onTapGesture {
                                                onSelectPhoto(event)
                                            }
                                    case .walk(let event):
                                        WalkTimelineCard(event: event)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(Strings.Places.noMomentsYet)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(Strings.Places.noMomentsHint)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Moment Timeline Card

/// Card showing a photo moment in the timeline
struct MomentTimelineCard: View {
    let event: PuppyEvent
    @State private var image: UIImage?

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var locationText: String {
        if let spotName = event.spotName {
            return spotName
        } else if event.latitude != nil {
            // Has coordinates but no spot name
            return Strings.WalkLocations.location
        } else {
            return Strings.Places.noLocationData
        }
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: event.time)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Details
            VStack(alignment: .leading, spacing: 4) {
                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }

                HStack(spacing: 4) {
                    Image(systemName: event.latitude != nil ? "mappin" : "mappin.slash")
                        .font(.caption2)
                    Text(locationText)
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                Text(timeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .task {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let path = event.thumbnailPath ?? event.photo
        guard let path = path else { return }

        let url = documentsURL.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url),
              let loaded = UIImage(data: data) else { return }
        image = loaded
    }
}

// MARK: - Walk Timeline Card

/// Card showing a walk in the timeline
struct WalkTimelineCard: View {
    let event: PuppyEvent

    private var locationText: String {
        event.spotName ?? Strings.WalkLocations.location
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: event.time)
    }

    private var durationText: String? {
        guard let duration = event.durationMin else { return nil }
        return "\(duration) \(Strings.Common.minutes)"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Walk icon
            ZStack {
                Circle()
                    .fill(Color.ollieAccent.opacity(0.15))

                Image(systemName: "figure.walk")
                    .font(.title3)
                    .foregroundColor(.ollieAccent)
            }
            .frame(width: 50, height: 50)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(Strings.EventType.walk)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let duration = durationText {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(duration)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(locationText)
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                Text(timeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    let eventStore = EventStore()
    let profileStore = ProfileStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)
    let momentsViewModel = MomentsViewModel(eventStore: eventStore)

    return NavigationStack {
        PlacesTimelineView(
            momentsViewModel: momentsViewModel,
            viewModel: viewModel,
            onSelectPhoto: { _ in }
        )
        .navigationTitle("Timeline")
    }
}
