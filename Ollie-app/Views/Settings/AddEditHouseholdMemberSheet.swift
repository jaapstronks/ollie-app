//
//  AddEditHouseholdMemberSheet.swift
//  Otis-app
//
//  Form for creating/editing household members
//

import SwiftUI
import OtisShared
import PhotosUI

/// Sheet for adding or editing a household member
struct AddEditHouseholdMemberSheet: View {
    let profileStore: ProfileStore
    let member: HouseholdMember?

    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name: String = ""
    @State private var colorHex: String = HouseholdMember.randomColor()
    @State private var isCurrentUser: Bool = false
    @State private var avatarData: Data?
    @State private var selectedPhoto: PhotosPickerItem?

    private var isEditing: Bool { member != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                avatarSection
                nameSection
                colorSection
                currentUserSection
            }
            .navigationTitle(isEditing ? Strings.Household.editMember : Strings.Household.addMember)
            .navigationBarTitleDisplayMode(.inline)
            .sheetToolbar(canSave: isValid) {
                save()
            }
            .onAppear {
                loadExisting()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                loadPhoto(from: newValue)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var avatarSection: some View {
        Section {
            VStack(spacing: 16) {
                // Avatar preview
                if let avatarData = avatarData,
                   let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    // Colored circle with initial
                    ZStack {
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 80, height: 80)

                        Text(name.isEmpty ? "?" : String(name.prefix(1)).uppercased())
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                // Photo picker
                let hasAvatar = avatarData != nil
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(
                        hasAvatar ? Strings.Household.changePhoto : Strings.Household.addPhoto,
                        systemImage: "camera"
                    )
                }
                .buttonStyle(.bordered)

                // Remove photo button
                if avatarData != nil {
                    Button(role: .destructive) {
                        avatarData = nil
                        selectedPhoto = nil
                    } label: {
                        Text(Strings.Household.removePhoto)
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var nameSection: some View {
        Section {
            TextField(Strings.Household.name, text: $name)
                .textContentType(.name)
                .autocapitalization(.words)
        } header: {
            Text(Strings.Household.name)
        }
    }

    @ViewBuilder
    private var colorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Household.color)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Color swatches
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                    ForEach(HouseholdMember.availableColors, id: \.self) { color in
                        Button {
                            colorHex = color
                            HapticFeedback.selection()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 36, height: 36)

                                if colorHex == color {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 2)
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        } footer: {
            Text(Strings.Household.colorHint)
        }
    }

    @ViewBuilder
    private var currentUserSection: some View {
        Section {
            Toggle(Strings.Household.thisIsMe, isOn: $isCurrentUser)
        } footer: {
            Text(Strings.Household.thisIsMeHint)
        }
    }

    // MARK: - Actions

    private func loadExisting() {
        guard let member = member else { return }
        name = member.name
        colorHex = member.colorHex
        isCurrentUser = member.isCurrentUser
        avatarData = member.avatarData
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Resize image to reduce storage
                if let image = UIImage(data: data),
                   let resized = image.resized(toMaxDimension: 200),
                   let compressed = resized.jpegData(compressionQuality: 0.8) {
                    await MainActor.run {
                        avatarData = compressed
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if var existingMember = member {
            // Update existing
            existingMember.name = trimmedName
            existingMember.colorHex = colorHex
            existingMember.isCurrentUser = isCurrentUser
            existingMember.avatarData = avatarData
            profileStore.updateHouseholdMember(existingMember)
        } else {
            // Create new
            let newMember = HouseholdMember(
                name: trimmedName,
                avatarData: avatarData,
                colorHex: colorHex,
                isCurrentUser: isCurrentUser
            )
            profileStore.addHouseholdMember(newMember)
        }

        HapticFeedback.success()
        dismiss()
    }
}

// MARK: - Image Resizing Helper

private extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        var newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }
}

// MARK: - Preview

#Preview("Add Member") {
    AddEditHouseholdMemberSheet(
        profileStore: ProfileStore(),
        member: nil
    )
}

#Preview("Edit Member") {
    AddEditHouseholdMemberSheet(
        profileStore: ProfileStore(),
        member: HouseholdMember(
            name: "John",
            colorHex: "#FF6B6B",
            isCurrentUser: true
        )
    )
}
