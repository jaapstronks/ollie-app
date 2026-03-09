//
//  UserProfileSettingsView.swift
//  Ollie-app
//
//  Settings view for editing the current user's identity.
//  Uses CloudKit-based identity (UserIdentityStore) instead of profile-embedded HouseholdMembers.
//

import SwiftUI
import OtisShared

struct UserProfileSettingsView: View {
    @ObservedObject var userIdentityStore: UserIdentityStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColorHex: String = ""
    @State private var avatarImage: UIImage?
    @State private var showRemovePhotoConfirmation = false

    // Media picker state for ImageCropView flow
    @State private var showingMediaPicker = false
    @State private var selectedSource: MediaPickerSource = .library
    @State private var imageToCrop: UIImage?
    @State private var showingCropView = false

    var body: some View {
        Form {
            // Avatar section
            Section {
                HStack {
                    Spacer()
                    avatarView
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // Name section
            Section {
                TextField(Strings.UserProfile.namePlaceholder, text: $name)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            } header: {
                Text(Strings.UserProfile.name)
            }

            // Color section
            Section {
                colorPicker
            } header: {
                Text(Strings.UserProfile.color)
            } footer: {
                Text(Strings.UserProfile.colorHint)
            }

            // Photo section
            Section {
                Button {
                    selectedSource = .camera
                    showingMediaPicker = true
                } label: {
                    Label(Strings.MediaAttachment.camera, systemImage: "camera")
                }

                Button {
                    selectedSource = .library
                    showingMediaPicker = true
                } label: {
                    Label(Strings.MediaAttachment.photoLibrary, systemImage: "photo.on.rectangle")
                }

                if avatarImage != nil {
                    Button(role: .destructive) {
                        showRemovePhotoConfirmation = true
                    } label: {
                        Label(Strings.UserProfile.removePhoto, systemImage: "trash")
                    }
                }
            } header: {
                Text(avatarImage != nil ? Strings.UserProfile.changePhoto : Strings.UserProfile.addPhoto)
            }

            // iCloud identity info
            Section {
                if let identity = userIdentityStore.currentIdentity {
                    if identity.cloudKitUserRecordID.hasPrefix("local-") {
                        Label(Strings.UserProfile.notSignedIn, systemImage: "exclamationmark.icloud")
                            .foregroundStyle(.secondary)
                    } else {
                        Label(Strings.UserProfile.iCloudIdentityDescription, systemImage: "checkmark.icloud")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(Strings.UserProfile.iCloudIdentity)
            }
        }
        .navigationTitle(Strings.UserProfile.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Strings.Common.save) {
                    save()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            loadCurrentValues()
        }
        .fullScreenCover(isPresented: $showingMediaPicker) {
            MediaPicker(
                source: selectedSource,
                onImageSelected: { image, _ in
                    imageToCrop = image
                    showingMediaPicker = false
                },
                onCancel: {
                    showingMediaPicker = false
                }
            )
        }
        .onChange(of: imageToCrop) { _, newImage in
            // Show crop view when image is ready (after async PHPicker load completes)
            if newImage != nil && !showingMediaPicker {
                showingCropView = true
            }
        }
        .fullScreenCover(isPresented: $showingCropView) {
            if let image = imageToCrop {
                ImageCropView(
                    image: image,
                    onConfirm: { croppedImage in
                        avatarImage = croppedImage
                        showingCropView = false
                        imageToCrop = nil
                    },
                    onCancel: {
                        showingCropView = false
                        imageToCrop = nil
                    }
                )
            }
        }
        .confirmationDialog(
            Strings.UserProfile.removePhoto,
            isPresented: $showRemovePhotoConfirmation,
            titleVisibility: .hidden
        ) {
            Button(Strings.Common.remove, role: .destructive) {
                avatarImage = nil
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        }
    }

    // MARK: - Avatar View

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(hex: selectedColorHex))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 40, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                    }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Menu {
                Button {
                    selectedSource = .camera
                    showingMediaPicker = true
                } label: {
                    Label(Strings.MediaAttachment.camera, systemImage: "camera")
                }

                Button {
                    selectedSource = .library
                    showingMediaPicker = true
                } label: {
                    Label(Strings.MediaAttachment.photoLibrary, systemImage: "photo.on.rectangle")
                }
            } label: {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(UserIdentity.availableColors, id: \.self) { colorHex in
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 36, height: 36)
                    .overlay {
                        if colorHex == selectedColorHex {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        selectedColorHex = colorHex
                        HapticFeedback.light()
                    }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func loadCurrentValues() {
        if let identity = userIdentityStore.currentIdentity {
            name = identity.name
            selectedColorHex = identity.colorHex

            if let avatarData = identity.avatarData {
                avatarImage = UIImage(data: avatarData)
            }
        } else {
            name = Strings.UserProfile.me
            selectedColorHex = UserIdentity.randomColor()
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        userIdentityStore.updateName(trimmedName)
        userIdentityStore.updateColor(selectedColorHex)

        if let image = avatarImage {
            let resized = image.resizedToFit(maxDimension: 200)
            let data = resized.jpegData(compressionQuality: 0.7)
            userIdentityStore.updateAvatar(data)
        } else {
            userIdentityStore.updateAvatar(nil)
        }

        HapticFeedback.success()
    }
}

// MARK: - Helper Extensions

private extension UIImage {
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        guard ratio < 1 else { return self }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileSettingsView(userIdentityStore: .shared)
    }
}
