//
//  DogSettingsCard.swift
//  Otis-app
//
//  Card component showing a dog profile with per-dog settings links
//

import SwiftUI
import OtisShared

/// Card showing a dog profile with links to Profile, Schedule, and Health settings
struct DogSettingsCard: View {
    let profile: PuppyProfile
    let isActive: Bool
    let onActivate: () -> Void
    let profileStore: ProfileStore
    let notificationService: NotificationService
    let documentStore: DocumentStore
    let foodRecallService: FoodRecallService
    let cloudKit: CloudKitService

    @State private var loadedImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header: Photo, Name, Breed, Badge
            headerSection

            Divider()
                .padding(.horizontal)

            // Navigation links
            navigationLinks
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isActive ? Color.otisAccent.opacity(0.4) : Color.clear,
                    lineWidth: 2
                )
        )
        .task(id: profile.profilePhotoFilename) {
            await loadImageAsync()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Profile photo
            profilePhoto

            // Name and breed
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(profile.name)
                        .font(.headline)

                    // Active indicator
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.otisAccent)
                            .accessibilityLabel(Strings.Profile.activeProfile)
                    }
                }

                if let breed = profile.breed, !breed.isEmpty {
                    Text(breed)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                ownershipBadge

                if !isActive {
                    Button {
                        HapticFeedback.selection()
                        onActivate()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 11, weight: .bold))
                            Text(Strings.Profile.switchProfile)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.otisAccent)
                        )
                        .overlay {
                            Capsule()
                                .stroke(Color.otisAccent.opacity(0.35), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Strings.Profile.switchProfile)
                    .accessibilityHint(Strings.Profile.switchingTo(profile.name))
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private var profilePhoto: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.otisAccent, Color.otisAccent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text(String(profile.name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .overlay {
            Circle()
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.15)
                        : Color.black.opacity(0.05),
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var ownershipBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: profile.ownership == .owned ? "person.fill" : "person.2.fill")
                .font(.caption2)
            Text(profile.ownership == .owned ? Strings.Profile.owner : Strings.Profile.shared)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(profile.ownership == .owned ? Color.otisAccent : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(profile.ownership == .owned
                    ? Color.otisAccent.opacity(0.15)
                    : Color(.tertiarySystemFill))
        )
    }

    // MARK: - Navigation Links

    private var navigationLinks: some View {
        VStack(spacing: 0) {
            // Profile link
            NavigationLink {
                DogProfileSettingsView(profileStore: profileStore, profileId: profile.id)
            } label: {
                settingsRow(
                    icon: "pawprint.fill",
                    iconColor: .otisAccent,
                    title: Strings.Settings.dogProfile
                )
            }

            Divider()
                .padding(.leading, 52)

            // Schedule & Preferences link
            NavigationLink {
                SchedulePreferencesView(
                    profileStore: profileStore,
                    notificationService: notificationService,
                    profileId: profile.id
                )
            } label: {
                settingsRow(
                    icon: "calendar.badge.clock",
                    iconColor: .blue,
                    title: Strings.Settings.schedulePreferences
                )
            }

            Divider()
                .padding(.leading, 52)

            // Health & Documents link
            NavigationLink {
                HealthDocumentsView(
                    profileStore: profileStore,
                    documentStore: documentStore,
                    foodRecallService: foodRecallService,
                    profileId: profile.id
                )
            } label: {
                settingsRow(
                    icon: "heart.text.square.fill",
                    iconColor: .red,
                    title: Strings.Settings.healthDocuments
                )
            }

            // Household Members link (only for active profile)
            if isActive {
                Divider()
                    .padding(.leading, 52)

                NavigationLink {
                    HouseholdSettingsView(profileStore: profileStore)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                            .frame(width: 28)

                        Text(Strings.Household.title)
                            .font(.subheadline)

                        Spacer()

                        if let memberCount = profileStore.profile?.householdMembers.members.count, memberCount > 0 {
                            Text("\(memberCount)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
            }

            // Sharing link (only for active + owned profiles)
            if isActive && profile.ownership == .owned {
                Divider()
                    .padding(.leading, 52)

                NavigationLink {
                    DogSharingSettingsView(cloudKit: cloudKit)
                } label: {
                    settingsRow(
                        icon: "person.badge.plus",
                        iconColor: .blue,
                        title: Strings.CloudSharing.sharing
                    )
                }
            }
        }
    }

    private func settingsRow(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Image Loading

    private func loadImageAsync() async {
        guard let filename = profile.profilePhotoFilename else {
            loadedImage = nil
            return
        }
        loadedImage = await ProfilePhotoStore.shared.loadAsync(filename: filename)
    }
}

// MARK: - Add Dog Button

/// Button to add a new dog profile
struct AddDogButton: View {
    let canAdd: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.otisAccent.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.otisAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Profile.addDog)
                        .font(.headline)
                        .foregroundStyle(canAdd ? .primary : .secondary)

                    if !canAdd {
                        Text(Strings.Profile.upgradeForMoreDogs)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if !canAdd {
                    Text("Otis+")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.otisAccent)
                        .foregroundStyle(.white)
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.otisAccent.opacity(canAdd ? 0.3 : 0),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canAdd)
        .accessibilityLabel(Strings.Profile.addDog)
        .accessibilityHint(canAdd ? "" : Strings.Profile.upgradeForMoreDogs)
    }
}

// MARK: - Preview

#Preview("Single Dog") {
    NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                DogSettingsCard(
                    profile: PuppyProfile.defaultProfile(
                        name: "Max",
                        birthDate: Date(),
                        homeDate: Date(),
                        size: .medium
                    ),
                    isActive: true,
                    onActivate: {},
                    profileStore: ProfileStore(),
                    notificationService: NotificationService(),
                    documentStore: DocumentStore(),
                    foodRecallService: FoodRecallService(),
                    cloudKit: CloudKitService.shared
                )

                AddDogButton(canAdd: true, action: {})
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    .environmentObject(SubscriptionManager.shared)
}

#Preview("Multiple Dogs") {
    NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                DogSettingsCard(
                    profile: PuppyProfile.defaultProfile(
                        name: "Max",
                        birthDate: Date(),
                        homeDate: Date(),
                        size: .medium
                    ),
                    isActive: true,
                    onActivate: {},
                    profileStore: ProfileStore(),
                    notificationService: NotificationService(),
                    documentStore: DocumentStore(),
                    foodRecallService: FoodRecallService(),
                    cloudKit: CloudKitService.shared
                )

                DogSettingsCard(
                    profile: {
                        var p = PuppyProfile.defaultProfile(
                            name: "Luna",
                            birthDate: Date(),
                            homeDate: Date(),
                            size: .large
                        )
                        p.ownership = .shared
                        return p
                    }(),
                    isActive: false,
                    onActivate: {},
                    profileStore: ProfileStore(),
                    notificationService: NotificationService(),
                    documentStore: DocumentStore(),
                    foodRecallService: FoodRecallService(),
                    cloudKit: CloudKitService.shared
                )

                AddDogButton(canAdd: false, action: {})
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    .environmentObject(SubscriptionManager.shared)
}
