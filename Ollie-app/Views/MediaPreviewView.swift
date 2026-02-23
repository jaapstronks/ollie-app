//
//  MediaPreviewView.swift
//  Ollie-app
//

import SwiftUI
import OllieShared
import UIKit

/// Full-screen photo viewer with pinch-to-zoom
struct MediaPreviewView: View {
    let event: PuppyEvent
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showControls: Bool = true
    @State private var showDeleteConfirmation: Bool = false

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                // Photo with gestures
                if let photoPath = event.photo,
                   let data = try? Data(contentsOf: documentsURL.appendingPathComponent(photoPath)),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = min(max(newScale, 1.0), 4.0)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale == 1.0 {
                                        withAnimation {
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showControls.toggle()
                            }
                        }
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                    lastScale = 2.0
                                }
                            }
                        }
                } else {
                    Text(Strings.MediaPreview.photoNotFound)
                        .foregroundColor(.white)
                }

                // Controls overlay
                if showControls {
                    VStack {
                        // Top bar
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }

                            Spacer()

                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                        }
                        .padding()

                        Spacer()

                        // Bottom info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                EventIcon(type: event.type, location: event.location, size: 28)
                                Text(event.type.label)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Spacer()

                                Text(event.time.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            if let note = event.note, !note.isEmpty {
                                Text(note)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            if let lat = event.latitude, let lon = event.longitude {
                                Label(String(format: "%.4f, %.4f", lat, lon), systemImage: "location")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
        }
        .confirmationDialog(Strings.MediaPreview.deleteTitle, isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button(Strings.MediaPreview.deletePhoto, role: .destructive) {
                HapticFeedback.warning()
                onDelete()
                dismiss()
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        } message: {
            Text(Strings.MediaPreview.deleteConfirmMessage)
        }
        .statusBarHidden(true)
    }
}

#Preview {
    MediaPreviewView(
        event: PuppyEvent(time: Date(), type: .moment, note: "Test moment"),
        onDelete: {}
    )
}
