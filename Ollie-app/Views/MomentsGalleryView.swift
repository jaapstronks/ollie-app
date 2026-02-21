//
//  MomentsGalleryView.swift
//  Ollie-app
//

import SwiftUI
import UIKit

/// Grid gallery view of all photo moments
struct MomentsGalleryView: View {
    @ObservedObject var viewModel: MomentsViewModel
    @State private var selectedEvent: PuppyEvent?
    @State private var showPreview: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.events.isEmpty {
                    EmptyMomentsView()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(viewModel.eventsByMonth, id: \.month) { section in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(section.month)
                                        .font(.headline)
                                        .padding(.horizontal)

                                    LazyVGrid(columns: columns, spacing: 2) {
                                        ForEach(section.events) { event in
                                            GalleryThumbnail(event: event)
                                                .aspectRatio(1, contentMode: .fill)
                                                .onTapGesture {
                                                    selectedEvent = event
                                                    showPreview = true
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(Strings.MomentsGallery.title)
            .fullScreenCover(isPresented: $showPreview) {
                if let event = selectedEvent {
                    MediaPreviewView(
                        event: event,
                        onDelete: {
                            viewModel.deleteEvent(event)
                            selectedEvent = nil
                        }
                    )
                }
            }
            .onAppear {
                viewModel.loadEventsWithMedia()
            }
            .refreshable {
                viewModel.loadEventsWithMedia()
            }
        }
    }
}

/// Single thumbnail in the gallery grid
struct GalleryThumbnail: View {
    let event: PuppyEvent
    @State private var image: UIImage?

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }
            }
        }
        .task {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        // Try thumbnail first, fall back to full photo
        let path = event.thumbnailPath ?? event.photo
        guard let path = path else { return }

        let url = documentsURL.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url),
              let loaded = UIImage(data: data) else { return }
        image = loaded
    }
}

/// Empty state for moments gallery
struct EmptyMomentsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(Strings.MomentsGallery.noPhotos)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(Strings.MomentsGallery.makePhotosHint)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MomentsGalleryView(viewModel: MomentsViewModel(eventStore: EventStore()))
}
