//
//  AwaitingInviteView.swift
//  Ollie-app
//
//  View shown when a user chooses to join an existing profile
//  and is waiting for a share invite from the owner.

import SwiftUI
import OtisShared

/// View shown when user is waiting for a share invite
struct AwaitingInviteView: View {
    let onCreateOwnProfile: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon and title
            VStack(spacing: 20) {
                Image(systemName: "person.2.badge.gearshape.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.otisAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.awaitingInviteTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }

            Spacer()
                .frame(height: 32)

            // Instructions
            VStack(spacing: 16) {
                InstructionRow(
                    number: 1,
                    text: Strings.Onboarding.awaitingInviteDescription
                )
                .opacity(hasAppeared ? 1.0 : 0.0)
                .offset(y: hasAppeared ? 0 : 10)

                InstructionRow(
                    number: 2,
                    text: Strings.Onboarding.awaitingInviteHint
                )
                .opacity(hasAppeared ? 1.0 : 0.0)
                .offset(y: hasAppeared ? 0 : 10)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Waiting indicator
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)

                Text(Strings.Onboarding.waiting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 24)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()

            // Create own profile button
            Button {
                onCreateOwnProfile()
            } label: {
                Text(Strings.Onboarding.createOwnProfile)
                    .font(.subheadline)
                    .foregroundStyle(Color.otisAccent)
            }
            .padding(.bottom, 32)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
}

/// Row showing an instruction step
private struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.otisAccent)
                .clipShape(Circle())

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

#Preview {
    AwaitingInviteView {
        print("Create own profile tapped")
    }
}
