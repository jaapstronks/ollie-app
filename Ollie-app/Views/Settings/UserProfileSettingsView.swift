//
//  UserProfileSettingsView.swift
//  Ollie-app
//
//  Settings view for editing the current user's identity.
//  Uses CloudKit-based identity (UserIdentityStore) instead of profile-embedded HouseholdMembers.
//

import SwiftUI
import OtisShared
import PhotosUI

struct UserProfileSettingsView: View {
    @ObservedObject var userIdentityStore: UserIdentityStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColorHex: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var showRemovePhotoConfirmation = false

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
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(
                        avatarImage != nil ? Strings.UserProfile.changePhoto : Strings.UserProfile.addPhoto,
                        systemImage: "camera"
                    )
                }

                if avatarImage != nil {
                    Button(role: .destructive) {
                        showRemovePhotoConfirmation = true
                    } label: {
                        Label(Strings.UserProfile.removePhoto, systemImage: "trash")
                    }
                }
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadSelectedPhoto(newItem)
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
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
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

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Resize and compress for storage
                let resized = image.resizedToFit(maxDimension: 200)
                await MainActor.run {
                    avatarImage = resized
                }
            }
        } catch {
            // Silently fail - user can try again
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        userIdentityStore.updateName(trimmedName)
        userIdentityStore.updateColor(selectedColorHex)

        if let image = avatarImage {
            let data = image.jpegData(compressionQuality: 0.7)
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
