//
//  EmptyStateView.swift
//  Otis-app
//
//  Reusable empty state component to consolidate duplicated patterns.
//  Replaces 25+ nearly identical empty state implementations across views.
//

import SwiftUI
import OtisShared

// MARK: - Empty State View

/// A reusable empty state view with icon, title, description, and optional action button.
///
/// Usage:
/// ```swift
/// EmptyStateView(
///     icon: "calendar",
///     title: "No Appointments",
///     description: "Schedule vet visits and other appointments",
///     actionTitle: "Add Appointment",
///     action: { showAddSheet = true }
/// )
/// ```
struct EmptyStateView: View {
    let icon: String
    let title: String
    var description: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var iconSize: CGFloat = 32
    var iconColor: Color = .secondary

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(iconColor)

            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Compact Empty State

/// A more compact empty state for use in cards and smaller containers.
struct CompactEmptyState: View {
    let icon: String
    let message: String
    var iconColor: Color = .secondary

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(iconColor)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}

// MARK: - Empty State Card

/// Empty state styled as a card, matching the app's card design patterns.
struct EmptyStateCard: View {
    let icon: String
    let title: String
    var description: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var tint: Color = .secondary

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(tint)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text(actionTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(tint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Empty state for no appointments
    static func noAppointments(onAdd: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "calendar",
            title: Strings.Calendar.noAppointments,
            description: Strings.Calendar.noAppointmentsHint,
            actionTitle: Strings.Calendar.addAppointment,
            action: onAdd
        )
    }

    /// Empty state for no documents
    static func noDocuments(onAdd: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "doc.text",
            title: Strings.Documents.noDocuments,
            description: Strings.Documents.noDocumentsHint,
            actionTitle: Strings.Documents.addDocument,
            action: onAdd
        )
    }

    /// Empty state for no contacts
    static func noContacts(onAdd: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "person.2",
            title: Strings.Contacts.noContacts,
            description: Strings.Contacts.noContactsHint,
            actionTitle: Strings.Contacts.addContact,
            action: onAdd
        )
    }

    /// Empty state for no contributions/activity
    static var noContributions: EmptyStateView {
        EmptyStateView(
            icon: "person.3",
            title: "No contributions yet"
        )
    }

    /// Empty state for no likes
    static var noLikes: EmptyStateView {
        EmptyStateView(
            icon: "heart",
            title: Strings.Likes.noLikesYet,
            description: Strings.Likes.beFirstToLike
        )
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Standard Empty State").font(.headline)
            EmptyStateView(
                icon: "calendar",
                title: "No Appointments",
                description: "Schedule vet visits and other appointments",
                actionTitle: "Add Appointment",
                action: {}
            )
            .background(Color(.systemBackground))
            .cornerRadius(12)

            Divider()

            Text("Compact Empty State").font(.headline)
            CompactEmptyState(
                icon: "person.3",
                message: "No contributions yet"
            )
            .background(Color(.systemBackground))
            .cornerRadius(12)

            Divider()

            Text("Empty State Card").font(.headline)
            EmptyStateCard(
                icon: "doc.text",
                title: "No Documents",
                description: "Store vaccination records, health certificates, and more",
                actionTitle: "Add Document",
                action: {},
                tint: .blue
            )

            Divider()

            Text("Preset Empty States").font(.headline)
            EmptyStateView.noLikes
                .background(Color(.systemBackground))
                .cornerRadius(12)
        }
        .padding()
    }
}
