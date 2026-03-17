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
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 80))
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
                .frame(height: 40)

            // Instructions
            VStack(alignment: .leading, spacing: 24) {
                // Primary instruction
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "1.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.otisAccent)

                    Text(Strings.Onboarding.awaitingInviteDescription)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(hasAppeared ? 1.0 : 0.0)
                .offset(y: hasAppeared ? 0 : 10)

                // Secondary hint
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text(Strings.Onboarding.awaitingInviteHint)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(hasAppeared ? 1.0 : 0.0)
                .offset(y: hasAppeared ? 0 : 10)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Waiting indicator - subtle
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)

                Text(Strings.Onboarding.waiting)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 16)
            .opacity(hasAppeared ? 1.0 : 0.0)

            Spacer()
                .frame(height: 20)

            // Create own profile button
            Button {
                onCreateOwnProfile()
            } label: {
                Text(Strings.Onboarding.createOwnProfile)
                    .font(.subheadline)
                    .foregroundStyle(Color.otisAccent)
            }
            .padding(.bottom, 40)
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

#Preview {
    AwaitingInviteView {
        print("Create own profile tapped")
    }
}
