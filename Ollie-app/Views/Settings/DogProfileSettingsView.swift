//
//  DogProfileSettingsView.swift
//  Ollie-app
//
//  Dog profile settings: walks, meals, meds, spots, health

import SwiftUI
import OllieShared

/// Settings screen for all dog-related configuration
struct DogProfileSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var spotStore: SpotStore
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var milestoneStore: MilestoneStore
    @ObservedObject var documentStore: DocumentStore
    @ObservedObject var contactStore: ContactStore
    @ObservedObject var appointmentStore: AppointmentStore

    @State private var showingMealEdit = false
    @State private var showingWalkScheduleEdit = false
    @State private var showingPhotoPicker = false

    var body: some View {
        Form {
            if let profile = profileStore.profile {
                // Profile basics
                ProfileSection(
                    profile: profile,
                    profileStore: profileStore,
                    showingPhotoPicker: $showingPhotoPicker
                )
                StatsSection(profile: profile)

                // Schedules
                WalkSection(
                    profile: profile,
                    profileStore: profileStore,
                    showingWalkScheduleEdit: $showingWalkScheduleEdit
                )

                MealSection(
                    profile: profile,
                    profileStore: profileStore,
                    showingMealEdit: $showingMealEdit
                )

                // Medications
                medicationsSection

                // Walk spots
                walkSpotsSection

                // Health milestones
                healthSection

                // Documents
                documentsSection

                // Contacts
                contactsSection

                // Appointments
                appointmentsSection
            }
        }
        .navigationTitle(profileStore.profile?.name ?? Strings.Settings.profile)
        .sheet(isPresented: $showingMealEdit) {
            if let profile = profileStore.profile {
                MealScheduleEditorWrapper(
                    initialSchedule: profile.mealSchedule,
                    onSave: { updatedSchedule in
                        profileStore.updateMealSchedule(updatedSchedule)
                    }
                )
            }
        }
        .sheet(isPresented: $showingWalkScheduleEdit) {
            if let profile = profileStore.profile {
                WalkScheduleEditorWrapper(
                    initialSchedule: profile.walkSchedule,
                    ageInMonths: profile.ageInMonths,
                    onSave: { updatedSchedule in
                        profileStore.updateWalkSchedule(updatedSchedule)
                    }
                )
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            if let profile = profileStore.profile {
                ProfilePhotoPicker(
                    currentImage: loadCurrentProfileImage(for: profile),
                    onSave: { image in
                        saveProfilePhoto(image)
                    },
                    onRemove: profile.profilePhotoFilename != nil ? {
                        removeProfilePhoto()
                    } : nil
                )
            }
        }
    }

    // MARK: - Profile Photo Helpers

    private func loadCurrentProfileImage(for profile: PuppyProfile) -> UIImage? {
        guard let filename = profile.profilePhotoFilename else { return nil }
        return ProfilePhotoStore.shared.load(filename: filename)
    }

    private func saveProfilePhoto(_ image: UIImage) {
        guard let profile = profileStore.profile else { return }
        do {
            // Delete old photo if exists
            if let oldFilename = profile.profilePhotoFilename {
                ProfilePhotoStore.shared.delete(filename: oldFilename)
            }

            let filename = try ProfilePhotoStore.shared.save(image: image)
            profileStore.updateProfilePhoto(filename)
        } catch {
            print("Failed to save profile photo: \(error)")
        }
    }

    private func removeProfilePhoto() {
        if let filename = profileStore.profile?.profilePhotoFilename {
            ProfilePhotoStore.shared.delete(filename: filename)
        }
        profileStore.updateProfilePhoto(nil)
    }

    // MARK: - Sections

    @ViewBuilder
    private var medicationsSection: some View {
        Section(Strings.Medications.title) {
            NavigationLink {
                MedicationSettingsView(profileStore: profileStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Medications.title)
                    } icon: {
                        Image(systemName: "pills.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    let count = profileStore.profile?.medicationSchedule.medications.count ?? 0
                    if count > 0 {
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var walkSpotsSection: some View {
        Section(Strings.WalkLocations.walkLocation) {
            NavigationLink {
                FavoriteSpotsView(spotStore: spotStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.WalkLocations.favoriteSpots)
                    } icon: {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    Text("\(spotStore.spots.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var healthSection: some View {
        Section(Strings.Health.title) {
            NavigationLink {
                HealthView(viewModel: viewModel, milestoneStore: milestoneStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Health.milestones)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.ollieDanger)
                    }
                    Spacer()
                    Text(Strings.Insights.healthDescription)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }

    @ViewBuilder
    private var documentsSection: some View {
        Section(Strings.Documents.title) {
            NavigationLink {
                DocumentsView(documentStore: documentStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Documents.title)
                    } icon: {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    let count = documentStore.documentCount
                    if count > 0 {
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contactsSection: some View {
        Section(Strings.Contacts.title) {
            NavigationLink {
                ContactsView(contactStore: contactStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Contacts.title)
                    } icon: {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    let count = contactStore.contactCount
                    if count > 0 {
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var appointmentsSection: some View {
        Section(Strings.Appointments.title) {
            NavigationLink {
                AppointmentsView(appointmentStore: appointmentStore)
            } label: {
                HStack {
                    Label {
                        Text(Strings.Appointments.title)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.ollieAccent)
                    }
                    Spacer()
                    let count = appointmentStore.upcomingCount
                    if count > 0 {
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    let profileStore = ProfileStore()
    let eventStore = EventStore()
    let milestoneStore = MilestoneStore()
    let documentStore = DocumentStore()
    let contactStore = ContactStore()
    let appointmentStore = AppointmentStore()
    let viewModel = TimelineViewModel(eventStore: eventStore, profileStore: profileStore)

    NavigationStack {
        DogProfileSettingsView(
            profileStore: profileStore,
            spotStore: SpotStore(),
            viewModel: viewModel,
            milestoneStore: milestoneStore,
            documentStore: documentStore,
            contactStore: contactStore,
            appointmentStore: appointmentStore
        )
    }
}
