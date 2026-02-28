//
//  MediaAttachmentButton.swift
//  Ollie-app
//

import SwiftUI
import OllieShared
import UIKit
import UniformTypeIdentifiers

/// Reusable button for attaching photos or documents to events
struct MediaAttachmentButton: View {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage, Data?) -> Void
    var onFileSelected: ((Data, UTType) -> Void)?
    var showFilesOption: Bool = false
    var buttonLabel: String = Strings.MediaAttachment.addPhoto
    var buttonIcon: String = "photo.badge.plus"
    var dialogTitle: String = Strings.MediaAttachment.addPhotoTitle

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
                // Show add button
                Button {
                    showingSourcePicker = true
                } label: {
                    HStack {
                        Image(systemName: buttonIcon)
                        Text(buttonLabel)
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .confirmationDialog(dialogTitle, isPresented: $showingSourcePicker, titleVisibility: .visible) {
            Button(Strings.MediaAttachment.camera) {
                selectedSource = .camera
                showingMediaPicker = true
            }
            Button(Strings.MediaAttachment.photoLibrary) {
                selectedSource = .library
                showingMediaPicker = true
            }
            if showFilesOption {
                Button(Strings.Documents.chooseFromFiles) {
                    selectedSource = .files
                    showingMediaPicker = true
                }
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
                onFileSelected: { data, fileType in
                    onFileSelected?(data, fileType)
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
