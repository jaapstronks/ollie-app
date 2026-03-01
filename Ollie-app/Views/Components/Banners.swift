//
//  Banners.swift
//  Otis-app
//
//  Reusable banner components for undo and celebration feedback

import SwiftUI

// MARK: - Undo Banner

/// A banner that allows users to undo a delete action
struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .foregroundColor(.white)

            Spacer()

            Button(Strings.Common.undo) {
                onUndo()
            }
            .fontWeight(.semibold)
            .foregroundColor(.yellow)
            .frame(minWidth: 44, minHeight: 44)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(LayoutConstants.cornerRadiusM)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Timeline.eventDeleted)
        .accessibilityHint(Strings.Timeline.undoAccessibility)
    }
}

// MARK: - Celebration Banner

/// Celebration banner shown when achieving outdoor potty streak
struct CelebrationBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pawprint.fill")
                .font(.title2)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.otisSuccess, Color.otisSuccess.opacity(0.85)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(LayoutConstants.cornerRadiusM)
        .padding(.horizontal)
        .shadow(color: Color.otisSuccess.opacity(0.3), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Previews

#Preview("Undo Banner") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            Spacer()
            UndoBanner(
                message: "Event deleted",
                onUndo: {},
                onDismiss: {}
            )
        }
    }
}

#Preview("Celebration Banner") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            CelebrationBanner(
                message: "5 outdoor potty events in a row!",
                onDismiss: {}
            )
            Spacer()
        }
    }
}
