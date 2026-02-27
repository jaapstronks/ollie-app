//
//  LogExposureSheet.swift
//  Ollie-app
//
//  Sheet for logging a socialization exposure

import SwiftUI
import OllieShared

/// Sheet for logging an exposure to a socialization item
struct LogExposureSheet: View {
    let item: SocializationItem
    var onLogged: ((SocializationReaction) -> Void)?

    @EnvironmentObject var socializationStore: SocializationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDistance: ExposureDistance?
    @State private var selectedReaction: SocializationReaction?
    @State private var note: String = ""

    private var canSave: Bool {
        selectedDistance != nil && selectedReaction != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Item header
                    itemHeader

                    // Distance picker
                    distanceSection

                    // Reaction picker
                    reactionSection

                    // Tip callout
                    tipCallout

                    // Note field
                    noteSection
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
        .presentationDetents([.medium, .large])
    }

    // MARK: - Item Header

    @ViewBuilder
    private var itemHeader: some View {
        VStack(spacing: 8) {
            if let category = socializationStore.category(forItemId: item.id) {
                Image(systemName: category.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.primary)
            }

            Text(item.localizedDisplayName)
                .font(.title3)
                .fontWeight(.semibold)

            if let description = item.localizedDescription {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Distance Section

    @ViewBuilder
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Socialization.distance)
                .font(.headline)

            HStack(spacing: 12) {
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
            VStack(spacing: 6) {
                Image(systemName: distance.icon)
                    .font(.title2)

                Text(distance.label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.ollieAccent.opacity(0.2) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.ollieAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reaction Section

    @ViewBuilder
    private var reactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Socialization.reaction)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
            VStack(spacing: 6) {
                Image(systemName: reaction.icon)
                    .font(.title2)
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
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor(for: reaction, isSelected: isSelected))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor(for: reaction, isSelected: isSelected), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func backgroundColor(for reaction: SocializationReaction, isSelected: Bool) -> Color {
        if isSelected {
            return reaction.isPositive ?
                Color.ollieSuccess.opacity(0.2) :
                Color.ollieWarning.opacity(0.2)
        }
        return Color.secondary.opacity(0.1)
    }

    private func borderColor(for reaction: SocializationReaction, isSelected: Bool) -> Color {
        if isSelected {
            return reaction.isPositive ? .ollieSuccess : .ollieWarning
        }
        return .clear
    }

    private func reactionIconColor(for reaction: SocializationReaction) -> Color {
        switch reaction {
        case .positief: return .ollieSuccess
        case .neutraal: return .ollieAccent
        case .onzeker: return .orange
        case .angstig: return .ollieWarning
        }
    }

    // MARK: - Tip Callout

    @ViewBuilder
    private var tipCallout: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)

            Text(Strings.Socialization.calmIsGoal)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(colorScheme == .dark ? 0.1 : 0.15))
        )
    }

    // MARK: - Note Section

    @ViewBuilder
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Socialization.noteOptional)
                .font(.headline)

            TextField(Strings.Socialization.notePlaceholder, text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    // MARK: - Actions

    private func saveExposure() {
        guard let distance = selectedDistance,
              let reaction = selectedReaction else { return }

        socializationStore.addExposure(
            itemId: item.id,
            distance: distance,
            reaction: reaction,
            note: note.isEmpty ? nil : note
        )

        HapticFeedback.success()
        onLogged?(reaction)
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
    .environmentObject(SocializationStore())
}
