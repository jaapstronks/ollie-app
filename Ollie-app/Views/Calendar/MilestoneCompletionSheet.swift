//
//  MilestoneCompletionSheet.swift
//  Otis-app
//
//  Sheet for completing a milestone with optional notes and photo

import SwiftUI
import OtisShared

/// Sheet for marking a milestone as complete with optional details
struct MilestoneCompletionSheet: View {
    let milestone: Milestone
    /// Called when user cancels (taps Cancel or swipes down)
    let onDismiss: () -> Void
    /// Callback with (notes, photoID, linkedContactID, completionDate)
    let onComplete: (String?, UUID?, UUID?, Date) -> Void

    @Environment(SubscriptionManager.self) var subscriptionManager
    @Environment(ContactStore.self) var contactStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var notes: String = ""
    @State private var linkedContactID: UUID? = nil
    @State private var completionDate: Date = Date()
    @State private var addToCalendar: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showPhotoSourcePicker: Bool = false
    @State private var selectedPhotoID: UUID? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var photoPickerSource: MediaPickerSource = .library
    @State private var showPhotoSaveError: Bool = false

    @State private var mediaStore = MediaStore()

    // Available vet contacts for picker
    private var vetContacts: [DogContact] {
        contactStore.contacts.filter { $0.contactType == .vet || $0.contactType == .emergencyVet }
    }

    private var selectedVetContact: DogContact? {
        linkedContactID.flatMap { contactStore.contact(withId: $0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Compact milestone info header
                    milestoneHeader

                    // Completion options
                    VStack(alignment: .leading, spacing: 10) {
                        // Completion date picker - inline with label
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Text(Strings.Health.completionDate)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            DatePicker(
                                "",
                                selection: $completionDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        // Notes field (Premium)
                        premiumField(
                            feature: .milestoneNotes,
                            icon: "note.text",
                            title: Strings.Health.addNotes
                        ) {
                            TextField(Strings.Health.notesPlaceholder, text: $notes, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Vet contact picker (Premium)
                        if milestone.category == .health {
                            premiumField(
                                feature: .milestoneNotes,
                                icon: "cross.case",
                                title: Strings.Health.selectVet
                            ) {
                                vetContactPickerContent
                            }
                        }

                        // Photo attachment (Premium)
                        premiumField(
                            feature: .photoVideoAttachments,
                            icon: "camera",
                            title: Strings.Health.addPhoto
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Photo preview if selected
                                if let image = selectedImage {
                                    HStack {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(Strings.Health.photoAdded)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.otisSuccess)

                                            Button {
                                                selectedImage = nil
                                                selectedPhotoID = nil
                                            } label: {
                                                Text(Strings.Common.remove)
                                                    .font(.caption)
                                                    .foregroundStyle(.red)
                                            }
                                        }

                                        Spacer()
                                    }
                                } else {
                                    // Add photo button
                                    Button {
                                        showPhotoSourcePicker = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle")
                                            Text(Strings.Health.addPhotoButton)
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(Color.otisAccent)
                                    }
                                }
                            }
                        }

                        // Calendar integration (Premium)
                        premiumField(
                            feature: .calendarIntegration,
                            icon: "calendar.badge.plus",
                            title: Strings.Health.addToCalendar
                        ) {
                            Toggle(isOn: $addToCalendar) {
                                Text(Strings.Health.reminderNextOccurrence)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(12)
                    .glassCard(tint: .accent)

                    // Complete button at bottom
                    Button {
                        completeAndDismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(Strings.Health.completeMilestone)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.otisSuccess)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .navigationTitle(Strings.Health.completeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            // Track feature gating if premium features are locked
            if !subscriptionManager.hasAccess(to: .milestoneNotes) {
                Analytics.trackFeatureGated(feature: "milestone_notes", action: "shown_locked")
            }
            if !subscriptionManager.hasAccess(to: .photoVideoAttachments) {
                Analytics.trackFeatureGated(feature: "photo_attachments", action: "shown_locked")
            }
            if !subscriptionManager.hasAccess(to: .calendarIntegration) {
                Analytics.trackFeatureGated(feature: "calendar_integration", action: "shown_locked")
            }
        }
        // Photo source picker (camera vs library)
        .confirmationDialog(Strings.Health.addPhoto, isPresented: $showPhotoSourcePicker) {
            Button {
                photoPickerSource = .camera
                showPhotoPicker = true
            } label: {
                Label(Strings.Common.takePhoto, systemImage: "camera")
            }

            Button {
                photoPickerSource = .library
                showPhotoPicker = true
            } label: {
                Label(Strings.Common.chooseFromLibrary, systemImage: "photo.on.rectangle")
            }

            Button(Strings.Common.cancel, role: .cancel) {}
        }
        // Photo picker sheet
        .fullScreenCover(isPresented: $showPhotoPicker) {
            MediaPicker(
                source: photoPickerSource,
                onImageSelected: { image, _ in
                    // Save the photo and get its ID
                    if let result = mediaStore.savePhoto(image) {
                        selectedImage = image
                        selectedPhotoID = UUID(uuidString: result.photoPath.replacingOccurrences(of: "media/", with: "").replacingOccurrences(of: ".jpg", with: ""))
                    } else {
                        // Photo save failed - show error and don't set selectedImage
                        showPhotoSaveError = true
                    }
                    showPhotoPicker = false
                },
                onCancel: {
                    showPhotoPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .alert(Strings.Common.error, isPresented: $showPhotoSaveError) {
            Button(Strings.Common.ok) { }
        } message: {
            Text(Strings.Common.saveFailed)
        }
    }

    // MARK: - Milestone Header

    @ViewBuilder
    private var milestoneHeader: some View {
        HStack(spacing: 12) {
            // Icon (uses category color)
            ZStack {
                Circle()
                    .fill(milestone.category.color)
                    .frame(width: 44, height: 44)

                Image(systemName: milestone.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(milestone.localizedLabel)
                    .font(.headline)
                    .fontWeight(.semibold)

                // Detail
                if let detail = milestone.localizedDetail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Category badge (uses category color)
            Text(milestone.category.displayName)
                .font(.caption2)
                .foregroundStyle(milestone.category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(milestone.category.tintColor)
                .clipShape(Capsule())
        }
        .padding(12)
        .glassCard(tint: .accent)
    }

    // MARK: - Vet Contact Picker

    @ViewBuilder
    private var vetContactPickerContent: some View {
        if vetContacts.isEmpty {
            HStack {
                Text(Strings.Health.noVetContactsHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // Selected contact display
                if let contact = selectedVetContact {
                    selectedContactRow(contact)
                }

                // Contact picker
                Picker(Strings.Health.selectVet, selection: $linkedContactID) {
                    Text(Strings.Common.none).tag(nil as UUID?)
                    ForEach(vetContacts) { contact in
                        Text(contactPickerLabel(for: contact)).tag(contact.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    @ViewBuilder
    private func selectedContactRow(_ contact: DogContact) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.otisSuccess)
            Text(contact.name)
                .font(.subheadline)
            Spacer()
            Button {
                linkedContactID = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.otisSuccess.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func contactPickerLabel(for contact: DogContact) -> String {
        if contact.contactType == .emergencyVet {
            return "\(contact.name) (\(Strings.Contacts.emergencyVet))"
        }
        return contact.name
    }

    // MARK: - Premium Field

    @ViewBuilder
    private func premiumField<Content: View>(
        feature: PremiumFeature,
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if !subscriptionManager.hasAccess(to: feature) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if subscriptionManager.hasAccess(to: feature) {
                content()
            } else {
                Text(feature.description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(subscriptionManager.hasAccess(to: feature) ? 1 : 0.6)
    }

    // MARK: - Actions

    private func completeAndDismiss() {
        let notesValue = subscriptionManager.hasAccess(to: .milestoneNotes) && !notes.isEmpty ? notes : nil
        let contactValue = subscriptionManager.hasAccess(to: .milestoneNotes) ? linkedContactID : nil
        let photoValue = subscriptionManager.hasAccess(to: .photoVideoAttachments) ? selectedPhotoID : nil

        // Track milestone completion
        Analytics.trackMilestoneCompleted(
            category: milestone.category.rawValue,
            isCustom: milestone.isCustom,
            hasNotes: notesValue != nil,
            hasPhoto: photoValue != nil
        )

        HapticFeedback.success()
        onComplete(notesValue, photoValue, contactValue, completionDate)
    }
}

// MARK: - Preview

#Preview {
    let milestone = DefaultMilestones.create()[1]
    let contactStore = ContactStore()

    return MilestoneCompletionSheet(
        milestone: milestone,
        onDismiss: {
            print("Dismissed")
        },
        onComplete: { notes, photoID, linkedContactID, completionDate in
            print("Completed with notes: \(notes ?? "none"), contactID: \(linkedContactID?.uuidString ?? "none"), date: \(completionDate)")
        }
    )
    .environment(SubscriptionManager.shared)
    .environment(contactStore)
}
