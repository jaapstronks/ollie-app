//
//  ArrivalPhotoPromptSheet.swift
//  Otis-app
//
//  Prompts user to take a photo when their expected puppy arrives
//

import SwiftUI
import OtisShared

/// Sheet shown when an expected puppy's home date arrives and no profile photo exists
struct ArrivalPhotoPromptSheet: View {
    let puppyName: String
    let onTakePhoto: () -> Void
    let onDismiss: () -> Void

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.otisAccent)
                .scaleEffect(hasAppeared ? 1.0 : 0.8)
                .opacity(hasAppeared ? 1.0 : 0.0)

            // Title
            Text(Strings.Onboarding.arrivalPhotoQuestion(name: puppyName))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.1), value: hasAppeared)

            // Subtitle
            Text(Strings.Onboarding.arrivalPhotoSubtitle)
                .font(.title2)
                .foregroundStyle(.secondary)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.2), value: hasAppeared)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: onTakePhoto) {
                    HStack {
                        Image(systemName: "camera")
                        Text(Strings.Onboarding.arrivalPhotoSubtitle)
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.otisAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onDismiss) {
                    Text(Strings.Onboarding.arrivalPhotoLater)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.3), value: hasAppeared)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
}

#Preview {
    ArrivalPhotoPromptSheet(
        puppyName: "Luna",
        onTakePhoto: {},
        onDismiss: {}
    )
}
