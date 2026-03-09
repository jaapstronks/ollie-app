//
//  FamilyInvitePromptCard.swift
//  Ollie-app
//
//  First-week nudge to encourage inviting family members.
//  Appears on Day 3+ after 10+ events logged.
//

import SwiftUI

/// Card prompting user to invite a family member
struct FamilyInvitePromptCard: View {
    let puppyName: String
    let onInvite: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.FirstWeek.invitePromptTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(Strings.FirstWeek.invitePromptSubtitle(name: puppyName))
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
                onInvite()
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text(Strings.FirstWeek.inviteSomeone)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
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
        FamilyInvitePromptCard(
            puppyName: "Max",
            onInvite: {},
            onDismiss: {}
        )
        .padding()
    }
    .background(Color(.systemBackground))
}
