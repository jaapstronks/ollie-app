//
//  MediaAttachmentButton.swift
//  Ollie-app
//

import SwiftUI
import OllieShared
import UIKit

/// Reusable button for attaching photos to events
struct MediaAttachmentButton: View {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage, Data?) -> Void

    @State private var showingSourcePicker = false
    @State private var showingMediaPicker = false
    @State private var selectedSource: MediaPickerSource = .library

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = selectedImage {
                // Show preview with remove option
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Button {
                        withAnimation {
                            selectedImage = nil
                        }
                    } label: {
                        Label(Strings.MediaAttachment.remove, systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            } else {
                // Show add photo button
                Button {
                    showingSourcePicker = true
                } label: {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text(Strings.MediaAttachment.addPhoto)
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .confirmationDialog(Strings.MediaAttachment.addPhotoTitle, isPresented: $showingSourcePicker, titleVisibility: .visible) {
            Button(Strings.MediaAttachment.camera) {
                selectedSource = .camera
                showingMediaPicker = true
            }
            Button(Strings.MediaAttachment.photoLibrary) {
                selectedSource = .library
                showingMediaPicker = true
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showingMediaPicker) {
            MediaPicker(
                source: selectedSource,
                onImageSelected: { image, data in
                    selectedImage = image
                    onImageSelected(image, data)
                    showingMediaPicker = false
                },
                onCancel: {
                    showingMediaPicker = false
                }
            )
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var image: UIImage?

        var body: some View {
            Form {
                Section(Strings.QuickLog.photo) {
                    MediaAttachmentButton(
                        selectedImage: $image,
                        onImageSelected: { _, _ in }
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}
