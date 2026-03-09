//
//  PhotoPromptCard.swift
//  Ollie-app
//
//  First-week nudge to encourage adding a first photo.
//  Appears on Day 2+ if no photos have been added yet.
//

import SwiftUI

/// Card prompting user to add their first photo
struct PhotoPromptCard: View {
    let puppyName: String
    let onAddPhoto: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.FirstWeek.photoPromptTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.FirstWeek.photoPromptSubtitle(name: puppyName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            Button {
                onAddPhoto()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(Strings.FirstWeek.addFirstPhoto)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack {
        PhotoPromptCard(
            puppyName: "Max",
            onAddPhoto: {},
            onDismiss: {}
        )
        .padding()
    }
    .background(Color(.systemBackground))
}
