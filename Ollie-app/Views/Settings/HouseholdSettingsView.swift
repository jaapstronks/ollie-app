//
//  HouseholdSettingsView.swift
//  Otis-app
//
//  List of household members with add/edit/delete
//

import SwiftUI
import OtisShared

/// Settings view for managing household members
struct HouseholdSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @State private var showingAddSheet = false
    @State private var memberToEdit: HouseholdMember?
    @State private var showingDeleteConfirmation = false
    @State private var memberToDelete: HouseholdMember?

    private var members: [HouseholdMember] {
        profileStore.householdMembers()
    }

    var body: some View {
        List {
            if members.isEmpty {
                emptyState
            } else {
                membersList
            }
        }
        .navigationTitle(Strings.Household.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Strings.Household.addMember)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditHouseholdMemberSheet(
                profileStore: profileStore,
                member: nil
            )
        }
        .sheet(item: $memberToEdit) { member in
            AddEditHouseholdMemberSheet(
                profileStore: profileStore,
                member: member
            )
        }
        .alert(Strings.Household.deleteConfirmTitle, isPresented: $showingDeleteConfirmation) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Common.delete, role: .destructive) {
                if let member = memberToDelete {
                    profileStore.deleteHouseholdMember(id: member.id)
                }
            }
        } message: {
            Text(Strings.Household.deleteConfirmMessage)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "person.2")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text(Strings.Household.noMembers)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(Strings.Household.noMembersHint)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                Button {
                    showingAddSheet = true
                } label: {
                    Label(Strings.Household.addMember, systemImage: "plus.circle.fill")
                }
                .buttonStyle(.glassPill(tint: .accent))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Members List

    @ViewBuilder
    private var membersList: some View {
        Section {
            ForEach(members) { member in
                MemberRow(
                    member: member,
                    onSetCurrentUser: {
                        profileStore.setCurrentUserMember(id: member.id)
                    },
                    onEdit: {
                        memberToEdit = member
                    }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        memberToDelete = member
                        showingDeleteConfirmation = true
                    } label: {
                        Label(Strings.Common.delete, systemImage: "trash")
                    }

                    Button {
                        memberToEdit = member
                    } label: {
                        Label(Strings.Common.edit, systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        } footer: {
            Text(Strings.Household.footerHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section {
            Button {
                showingAddSheet = true
            } label: {
                Label(Strings.Household.addMember, systemImage: "plus")
            }
        }
    }
}

// MARK: - Member Row

private struct MemberRow: View {
    let member: HouseholdMember
    let onSetCurrentUser: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Avatar
                HouseholdMemberAvatar(member: member, size: 36)

                // Name and status
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if member.isCurrentUser {
                        Text(Strings.Household.thisIsMe)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // "This is me" badge
                if member.isCurrentUser {
                    Text(Strings.Household.me)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.otisAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.otisAccent.opacity(0.15))
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("HouseholdSettingsView") {
    NavigationStack {
        HouseholdSettingsView(profileStore: ProfileStore())
    }
}
