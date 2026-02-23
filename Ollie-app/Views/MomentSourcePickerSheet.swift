//
//  MomentSourcePickerSheet.swift
//  Ollie-app
//
//  Sheet for choosing camera or photo library when logging a moment

import SwiftUI

/// Simple sheet to choose between camera and photo library for moments
struct MomentSourcePickerSheet: View {
    let onCamera: () -> Void
    let onLibrary: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button {
                    HapticFeedback.medium()
                    onCamera()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .frame(width: 32)
                        Text(Strings.MediaAttachment.camera)
                            .font(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    HapticFeedback.medium()
                    onLibrary()
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .frame(width: 32)
                        Text(Strings.MediaAttachment.photoLibrary)
                            .font(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
            .navigationTitle(Strings.LogMoment.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }
            }
        }
    }
}

#Preview {
    MomentSourcePickerSheet(
        onCamera: {},
        onLibrary: {},
        onCancel: {}
    )
}
