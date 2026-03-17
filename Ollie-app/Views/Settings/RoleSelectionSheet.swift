//
//  RoleSelectionSheet.swift
//  Ollie-app
//
//  Role selection view shown when accepting a share invitation.
//  Users select their involvement level with the shared dog.
//

import SwiftUI
import OtisShared

/// Sheet for selecting the user's role with a shared dog
struct RoleSelectionSheet: View {
    let dogName: String
    let profileId: UUID
    var onComplete: () -> Void

    @State private var selectedRole: ResponsibilityLevel = .helper
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.otisAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.RoleSelection.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.RoleSelection.subtitle(name: dogName))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            Spacer()
                .frame(height: 32)

            // Role options
            VStack(spacing: 12) {
                ForEach(ResponsibilityLevel.allCases, id: \.self) { level in
                    RoleOptionCard(
                        level: level,
                        isSelected: selectedRole == level,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedRole = level
                            }
                            HapticFeedback.light()
                        }
                    )
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            Button {
                UserIdentityStore.shared.updateResponsibilityLevel(selectedRole, for: profileId)
                HapticFeedback.success()
                onComplete()
            } label: {
                Text(Strings.Common.continue_)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.otisAccent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Role Option Card

private struct RoleOptionCard: View {
    let level: ResponsibilityLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: level.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? Color.otisAccent : .secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.label)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(level.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.otisAccent : Color(.tertiaryLabel))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.otisAccent : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Strings

extension Strings {
    enum RoleSelection {
        private static let table = "Settings"

        static let title = String(localized: "How involved are you?", table: table)
        static func subtitle(name: String) -> String {
            String(localized: "Choose your role with \(name). This affects which reminders you'll see.", table: table)
        }
    }
}

// MARK: - Preview

#Preview {
    RoleSelectionSheet(
        dogName: "Max",
        profileId: UUID(),
        onComplete: { print("Complete") }
    )
}
