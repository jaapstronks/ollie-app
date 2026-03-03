//
//  HouseholdMemberAvatar.swift
//  Otis-app
//
//  Avatar display for household members in timeline
//

import SwiftUI
import OtisShared

/// Displays a household member's avatar (image or colored initial)
struct HouseholdMemberAvatar: View {
    let member: HouseholdMember?
    var size: CGFloat = 20

    var body: some View {
        if let member = member {
            if let avatarData = member.avatarData,
               let uiImage = UIImage(data: avatarData) {
                // Show avatar image
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Show colored circle with initial
                ZStack {
                    Circle()
                        .fill(Color(hex: member.colorHex))

                    Text(member.initial)
                        .font(.system(size: size * 0.5, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: size, height: size)
            }
        }
    }
}

// MARK: - Preview

#Preview("With Avatar") {
    HStack(spacing: 16) {
        HouseholdMemberAvatar(
            member: HouseholdMember(
                name: "John",
                colorHex: "#FF6B6B"
            ),
            size: 20
        )

        HouseholdMemberAvatar(
            member: HouseholdMember(
                name: "Sarah",
                colorHex: "#4ECDC4"
            ),
            size: 28
        )

        HouseholdMemberAvatar(
            member: HouseholdMember(
                name: "Mike",
                colorHex: "#45B7D1"
            ),
            size: 36
        )
    }
    .padding()
}

#Preview("Nil Member") {
    HouseholdMemberAvatar(member: nil, size: 20)
        .padding()
}
