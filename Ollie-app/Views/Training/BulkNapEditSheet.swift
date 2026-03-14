//
//  BulkNapEditSheet.swift
//  Otis-app
//
//  Sheet for bulk editing nap locations to support crate training tracking
//

import SwiftUI
import OtisShared

/// Sheet for bulk editing nap locations
struct BulkNapEditSheet: View {
    var eventStore: EventStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedEventIds: Set<UUID> = []
    @State private var targetLocation: NapLocation = .crate

    /// Recent naps from last 14 days, sorted by most recent first
    private var recentNaps: [PuppyEvent] {
        eventStore.events
            .sleeps()
            .lastDays(14)
            .sorted { $0.time > $1.time }
    }

    /// Naps that don't have a location set
    private var napsWithoutLocation: [PuppyEvent] {
        recentNaps.filter { $0.napLocation == nil }
    }

    /// Whether there are any naps to edit
    private var hasNapsToEdit: Bool {
        !napsWithoutLocation.isEmpty
    }

    /// Count of selected events
    private var selectedCount: Int {
        selectedEventIds.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if recentNaps.isEmpty {
                    emptyState
                } else {
                    napListContent
                }
            }
            .navigationTitle(Strings.Training.CrateTraining.bulkEditTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Views

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView {
            Label(Strings.Training.CrateTraining.noNapsYet, systemImage: "moon.zzz")
        } description: {
            Text(Strings.Training.CrateTraining.bulkEditEmptyDescription)
        }
    }

    @ViewBuilder
    private var napListContent: some View {
        List {
            // Header section explaining the feature
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(Strings.Training.CrateTraining.bulkEditExplanation, systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Target location picker
            Section(Strings.Training.CrateTraining.setLocationTo) {
                Picker(Strings.Training.CrateTraining.setLocationTo, selection: $targetLocation) {
                    ForEach(NapLocation.allCases, id: \.self) { location in
                        Label(location.label, systemImage: location.icon)
                            .tag(location)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Naps without location (priority section)
            if !napsWithoutLocation.isEmpty {
                Section {
                    ForEach(napsWithoutLocation) { nap in
                        NapEditRow(
                            event: nap,
                            isSelected: selectedEventIds.contains(nap.id),
                            onToggle: { toggleSelection(nap.id) }
                        )
                    }
                } header: {
                    HStack {
                        Text(Strings.Training.CrateTraining.napsWithoutLocation)
                        Spacer()
                        Button(selectAllNapsWithoutLocationLabel) {
                            toggleSelectAllWithoutLocation()
                        }
                        .font(.caption)
                    }
                } footer: {
                    Text(Strings.Training.CrateTraining.bulkEditFooter)
                }
            }

            // All other naps (already have location)
            let napsWithLocation = recentNaps.filter { $0.napLocation != nil }
            if !napsWithLocation.isEmpty {
                Section(Strings.Training.CrateTraining.napsWithLocation) {
                    ForEach(napsWithLocation) { nap in
                        NapEditRow(
                            event: nap,
                            isSelected: selectedEventIds.contains(nap.id),
                            onToggle: { toggleSelection(nap.id) }
                        )
                    }
                }
            }

            // Apply button
            if selectedCount > 0 {
                Section {
                    Button {
                        applyChanges()
                    } label: {
                        HStack {
                            Spacer()
                            Label(
                                Strings.Training.CrateTraining.applyToSelected(selectedCount),
                                systemImage: "checkmark.circle.fill"
                            )
                            .font(.headline)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.indigo)
                    .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var selectAllNapsWithoutLocationLabel: String {
        let allSelected = napsWithoutLocation.allSatisfy { selectedEventIds.contains($0.id) }
        return allSelected ? Strings.Common.deselectAll : Strings.Common.selectAll
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedEventIds.contains(id) {
            selectedEventIds.remove(id)
        } else {
            selectedEventIds.insert(id)
        }
        HapticFeedback.light()
    }

    private func toggleSelectAllWithoutLocation() {
        let allSelected = napsWithoutLocation.allSatisfy { selectedEventIds.contains($0.id) }
        if allSelected {
            // Deselect all without location
            for nap in napsWithoutLocation {
                selectedEventIds.remove(nap.id)
            }
        } else {
            // Select all without location
            for nap in napsWithoutLocation {
                selectedEventIds.insert(nap.id)
            }
        }
        HapticFeedback.light()
    }

    private func applyChanges() {
        // Update all selected events with the target location
        for id in selectedEventIds {
            if let nap = recentNaps.first(where: { $0.id == id }) {
                var updatedNap = nap
                updatedNap.napLocation = targetLocation
                eventStore.updateEvent(updatedNap)
            }
        }

        HapticFeedback.success()
        dismiss()
    }
}

// MARK: - Nap Edit Row

private struct NapEditRow: View {
    let event: PuppyEvent
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .indigo : .secondary)

                // Nap info
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.time.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        // Duration if available
                        if let duration = event.durationMin {
                            Label("\(duration) min", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Current location if set
                        if let location = event.napLocation {
                            Label(location.label, systemImage: location.icon)
                                .font(.caption)
                                .foregroundStyle(.indigo)
                        } else {
                            Text(Strings.Training.CrateTraining.noLocationSet)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    BulkNapEditSheet(eventStore: EventStore())
}
