//
//  LogExposureSheet.swift
//  Otis-app
//
//  Sheet for logging a socialization exposure

import SwiftUI
import OtisShared

/// Sheet for logging an exposure to a socialization item
struct LogExposureSheet: View {
    let item: SocializationItem
    var onLogged: ((SocializationReaction) -> Void)?

    @Environment(SocializationStore.self) var socializationStore
    @Environment(ProfileStore.self) var profileStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDistance: ExposureDistance?
    @State private var selectedReaction: SocializationReaction?
    @State private var note: String = ""
    @State private var isNoteExpanded: Bool = false

    private var canSave: Bool {
        selectedDistance != nil && selectedReaction != nil
    }

    private var isAlreadyComfortable: Bool {
        socializationStore.isComfortable(itemId: item.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Item header
                    itemHeader

                    // Distance picker
                    distanceSection

                    // Reaction picker
                    reactionSection

                    // Note field (expandable)
                    noteSection

                    // Quick mark as done (only show if not already comfortable)
                    if !isAlreadyComfortable {
                        markAsDoneSection
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Socialization.logExposure)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveExposure()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Item Header

    @ViewBuilder
    private var itemHeader: some View {
        HStack(spacing: 12) {
            if let category = socializationStore.category(forItemId: item.id) {
                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.localizedDisplayName)
                    .font(.headline)

                if let description = item.localizedDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Distance Section

    @ViewBuilder
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Socialization.distance)
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                ForEach(ExposureDistance.allCases) { distance in
                    distanceButton(distance)
                }
            }
        }
    }

    @ViewBuilder
    private func distanceButton(_ distance: ExposureDistance) -> some View {
        let isSelected = selectedDistance == distance

        Button {
            selectedDistance = distance
            HapticFeedback.light()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: distance.icon)
                    .font(.title3)

                Text(distance.label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.otisAccent.opacity(0.2) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.otisAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reaction Section

    @ViewBuilder
    private var reactionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Socialization.reaction)
                .font(.subheadline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(SocializationReaction.allCases) { reaction in
                    reactionButton(reaction)
                }
            }
        }
    }

    @ViewBuilder
    private func reactionButton(_ reaction: SocializationReaction) -> some View {
        let isSelected = selectedReaction == reaction

        Button {
            selectedReaction = reaction
            HapticFeedback.light()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: reaction.icon)
                    .font(.title3)
                    .foregroundStyle(reactionIconColor(for: reaction))

                Text(reaction.label)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(reaction.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor(for: reaction, isSelected: isSelected))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor(for: reaction, isSelected: isSelected), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func backgroundColor(for reaction: SocializationReaction, isSelected: Bool) -> Color {
        if isSelected {
            return reaction.isPositive ?
                Color.otisSuccess.opacity(0.2) :
                Color.otisWarning.opacity(0.2)
        }
        return Color.secondary.opacity(0.1)
    }

    private func borderColor(for reaction: SocializationReaction, isSelected: Bool) -> Color {
        if isSelected {
            return reaction.isPositive ? .otisSuccess : .otisWarning
        }
        return .clear
    }

    private func reactionIconColor(for reaction: SocializationReaction) -> Color {
        switch reaction {
        case .positief: return .otisSuccess
        case .neutraal: return .otisAccent
        case .onzeker: return .orange
        case .angstig: return .otisWarning
        }
    }

    // MARK: - Note Section

    @ViewBuilder
    private var noteSection: some View {
        DisclosureGroup(isExpanded: $isNoteExpanded) {
            TextField(Strings.Socialization.notePlaceholder, text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.secondary)
                Text(Strings.Socialization.noteOptional)
                    .font(.subheadline)
            }
        }
        .tint(.primary)
    }

    // MARK: - Mark as Done Section

    @ViewBuilder
    private var markAsDoneSection: some View {
        VStack(spacing: 8) {
            Divider()

            HStack {
                Text(Strings.Socialization.alreadyComfortable)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    markAsDone()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(Strings.Socialization.markAsDone)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.otisAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.otisAccent.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func saveExposure() {
        guard let distance = selectedDistance,
              let reaction = selectedReaction else { return }

        // Track analytics
        if let category = socializationStore.category(forItemId: item.id) {
            Analytics.trackExposureLogged(
                category: category.id,
                reaction: reaction.rawValue,
                weekNumber: profileStore.profile?.ageInWeeks ?? 0
            )
        }

        socializationStore.addExposure(
            itemId: item.id,
            distance: distance,
            reaction: reaction,
            note: note.nilIfBlank
        )

        HapticFeedback.success()
        onLogged?(reaction)
        dismiss()
    }

    private func markAsDone() {
        // Track analytics
        if let category = socializationStore.category(forItemId: item.id) {
            Analytics.trackExposureLogged(
                category: category.id,
                reaction: "marked_comfortable",
                weekNumber: profileStore.profile?.ageInWeeks ?? 0
            )
        }

        socializationStore.markComfortable(item.id, method: .quickCheck)

        HapticFeedback.success()
        onLogged?(.positief) // Treat as positive for callback purposes
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    LogExposureSheet(
        item: SocializationItem(
            id: "kind",
            name: "Child (0-5 years)",
            description: "Toddlers and young children",
            targetExposures: 3,
            isWalkable: true
        )
    )
    .environment(SocializationStore())
    .environment(ProfileStore())
}
