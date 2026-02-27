//
//  ProfilePhotoPicker.swift
//  Ollie-app
//
//  Sheet for selecting or capturing a profile photo

import SwiftUI

/// Sheet for selecting or capturing a profile photo
struct ProfilePhotoPicker: View {
    let currentImage: UIImage?
    let onSave: (UIImage) -> Void
    let onRemove: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showingMediaPicker = false
    @State private var selectedSource: MediaPickerSource = .library

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                Group {
                    if let image = selectedImage ?? currentImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .overlay {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .padding(.top, 40)

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        selectedSource = .camera
                        showingMediaPicker = true
                    } label: {
                        Label(Strings.MediaAttachment.camera, systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        selectedSource = .library
                        showingMediaPicker = true
                    } label: {
                        Label(Strings.MediaAttachment.photoLibrary, systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if onRemove != nil && (currentImage != nil || selectedImage != nil) {
                        Button(role: .destructive) {
                            onRemove?()
                            dismiss()
                        } label: {
                            Label(Strings.Profile.removePhoto, systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle(Strings.Profile.photoTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        if let image = selectedImage {
                            onSave(image)
                        }
                        dismiss()
                    }
                    .disabled(selectedImage == nil)
                }
            }
            .fullScreenCover(isPresented: $showingMediaPicker) {
                MediaPicker(
                    source: selectedSource,
                    onImageSelected: { image, _ in
                        selectedImage = image
                        showingMediaPicker = false
                    },
                    onCancel: {
                        showingMediaPicker = false
                    }
                )
            }
        }
    }
}

#Preview {
    ProfilePhotoPicker(
        currentImage: nil,
        onSave: { _ in },
        onRemove: nil
    )
}
