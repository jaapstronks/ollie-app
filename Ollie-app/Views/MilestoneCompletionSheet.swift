//
//  MilestoneCompletionSheet.swift
//  Ollie-app
//
//  Sheet for completing a milestone with optional notes and photo

import SwiftUI
import OllieShared

/// Sheet for marking a milestone as complete with optional details
struct MilestoneCompletionSheet: View {
    let milestone: Milestone
    @Binding var isPresented: Bool
    let onComplete: (String?, UUID?, String?) -> Void

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var notes: String = ""
    @State private var vetClinic: String = ""
    @State private var addToCalendar: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showPhotoSourcePicker: Bool = false
    @State private var selectedPhotoID: UUID? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var photoPickerSource: MediaPickerSource = .library
    @State private var showPhotoSaveError: Bool = false

    @StateObject private var mediaStore = MediaStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Milestone info header
                    milestoneHeader

                    // Completion options
                    VStack(alignment: .leading, spacing: 16) {
                        // Quick complete button
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
                            .padding()
                            .background(Color.ollieSuccess)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Divider()
                            .padding(.vertical, 8)

                        // Premium features section
                        Text(Strings.OlliePlus.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        // Notes field (Premium)
                        premiumField(
                            feature: .milestoneNotes,
                            icon: "note.text",
                            title: Strings.Health.addNotes
                        ) {
                            TextField(Strings.Health.notesPlaceholder, text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Vet clinic field (Premium)
                        if milestone.category == .health {
                            premiumField(
                                feature: .milestoneNotes,
                                icon: "cross.case",
                                title: Strings.Health.vetClinic
                            ) {
                                TextField(Strings.Health.vetClinicPlaceholder, text: $vetClinic)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        // Photo attachment (Premium)
                        premiumField(
                            feature: .photoVideoAttachments,
                            icon: "camera",
                            title: Strings.Health.addPhoto
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                // Photo preview if selected
                                if let image = selectedImage {
                                    HStack {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading) {
                                            Text(Strings.Health.photoAdded)
                                                .font(.subheadline)
                                                .foregroundStyle(Color.ollieSuccess)

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
                                        .foregroundStyle(Color.ollieAccent)
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
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .glassCard(tint: .accent)
                }
                .padding()
            }
            .navigationTitle(Strings.Health.completeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        completeAndDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
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
        VStack(spacing: 12) {
            // Icon (uses category color)
            ZStack {
                Circle()
                    .fill(milestone.category.color)
                    .frame(width: 56, height: 56)

                Image(systemName: milestone.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }

            // Title
            Text(milestone.localizedLabel)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Detail
            if let detail = milestone.localizedDetail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Category badge (uses category color)
            Text(milestone.category.displayName)
                .font(.caption)
                .foregroundStyle(milestone.category.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(milestone.category.tintColor)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCard(tint: .accent)
    }

    // MARK: - Premium Field

    @ViewBuilder
    private func premiumField<Content: View>(
        feature: PremiumFeature,
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if !subscriptionManager.hasAccess(to: feature) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if subscriptionManager.hasAccess(to: feature) {
                content()
            } else {
                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(subscriptionManager.hasAccess(to: feature) ? 1 : 0.6)
    }

    // MARK: - Actions

    private func completeAndDismiss() {
        let notesValue = subscriptionManager.hasAccess(to: .milestoneNotes) && !notes.isEmpty ? notes : nil
        let vetValue = subscriptionManager.hasAccess(to: .milestoneNotes) && !vetClinic.isEmpty ? vetClinic : nil
        let photoValue = subscriptionManager.hasAccess(to: .photoVideoAttachments) ? selectedPhotoID : nil

        // Track milestone completion
        Analytics.trackMilestoneCompleted(
            category: milestone.category.rawValue,
            isCustom: milestone.isCustom,
            hasNotes: notesValue != nil,
            hasPhoto: photoValue != nil
        )

        HapticFeedback.success()
        onComplete(notesValue, photoValue, vetValue)
        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isPresented = true

    let milestone = DefaultMilestones.create()[1]

    return MilestoneCompletionSheet(
        milestone: milestone,
        isPresented: $isPresented,
        onComplete: { notes, photoID, vetClinic in
            print("Completed with notes: \(notes ?? "none")")
        }
    )
    .environmentObject(SubscriptionManager.shared)
}
