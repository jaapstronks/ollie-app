//
//  GroomingSettingsView.swift
//  Otis-app
//
//  Settings view for configuring coat type and grooming schedules
//

import SwiftUI
import OtisShared

/// Settings view for managing grooming schedule and coat type
struct GroomingSettingsView: View {
    @ObservedObject var profileStore: ProfileStore
    @EnvironmentObject var routineStore: RoutineStore
    var profileId: UUID? = nil

    @State private var showingCoatTypePicker = false
    @State private var showingResetConfirmation = false
    @State private var selectedCoatType: CoatType?

    /// The profile being edited (looked up by ID or falls back to active)
    private var targetProfile: PuppyProfile? {
        if let id = profileId {
            return profileStore.profile(for: id)
        }
        return profileStore.profile
    }

    private var groomingActivities: [GroomingActivity] {
        routineStore.groomingActivities
    }

    var body: some View {
        List {
            coatTypeSection
            groomingScheduleSection
            tipsSection
        }
        .navigationTitle(Strings.Grooming.schedule)
        .sheet(isPresented: $showingCoatTypePicker) {
            CoatTypePickerSheet(
                selectedCoatType: $selectedCoatType,
                suggestedCoatType: targetProfile?.suggestedCoatType,
                onSelect: { coatType in
                    saveCoatType(coatType)
                    showingCoatTypePicker = false
                }
            )
        }
        .alert(Strings.Grooming.resetToDefaultsTitle, isPresented: $showingResetConfirmation) {
            Button(Strings.Common.cancel, role: .cancel) {}
            Button(Strings.Grooming.resetToDefaults, role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text(Strings.Grooming.resetToDefaultsMessage)
        }
        .onAppear {
            selectedCoatType = targetProfile?.coatType
        }
    }

    // MARK: - Coat Type Section

    @ViewBuilder
    private var coatTypeSection: some View {
        Section {
            Button {
                showingCoatTypePicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.Grooming.coatType)
                            .foregroundStyle(.primary)

                        if let coatType = targetProfile?.coatType {
                            Text(coatType.label)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if let suggested = targetProfile?.suggestedCoatType {
                            Text("\(suggested.label) (suggested)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(Strings.Grooming.notSet)
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    ChevronIcon(style: .small)
                }
            }
            .accessibilityLabel(Strings.Grooming.coatType)

            if let coatType = targetProfile?.effectiveCoatType {
                Text(coatType.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(Strings.Grooming.coatType)
        } footer: {
            if targetProfile?.coatType == nil, let suggested = targetProfile?.suggestedCoatType {
                Text(Strings.Grooming.coatTypeSuggestion(suggested.label))
            }
        }
    }

    // MARK: - Grooming Schedule Section

    @ViewBuilder
    private var groomingScheduleSection: some View {
        Section {
            if groomingActivities.isEmpty {
                emptyState
            } else {
                ForEach(sortedActivities) { activity in
                    GroomingActivityRow(
                        activity: activity,
                        onToggle: { enabled in
                            toggleActivity(activity, enabled: enabled)
                        },
                        onUpdateInterval: { interval in
                            updateInterval(activity, interval: interval)
                        }
                    )
                }
            }
        } header: {
            Text(Strings.Grooming.schedule)
        } footer: {
            HStack {
                Spacer()
                Button {
                    showingResetConfirmation = true
                } label: {
                    Text(Strings.Grooming.resetToDefaults)
                        .font(.caption)
                }
                .disabled(targetProfile?.effectiveCoatType == nil)
            }
        }
    }

    private var sortedActivities: [GroomingActivity] {
        groomingActivities.sorted { a, b in
            // Enabled first, then by urgency
            if a.isEnabled != b.isEnabled {
                return a.isEnabled
            }
            return (a.daysUntilDue ?? 999) < (b.daysUntilDue ?? 999)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "comb.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(Strings.Grooming.noActivities)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if targetProfile?.effectiveCoatType != nil {
                Button {
                    routineStore.seedDefaultGroomingActivitiesIfNeeded()
                } label: {
                    Text(Strings.Grooming.setupDefaults)
                        .font(.subheadline.weight(.medium))
                }
            } else {
                Text(Strings.Grooming.setCoatTypeFirst)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Tips Section

    @ViewBuilder
    private var tipsSection: some View {
        if let coatType = targetProfile?.effectiveCoatType, !coatType.careTips.isEmpty {
            Section {
                ForEach(coatType.careTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(Strings.Grooming.careTips)
            }
        }
    }

    // MARK: - Actions

    private func saveCoatType(_ coatType: CoatType) {
        guard var profile = targetProfile else { return }
        profile.coatType = coatType
        profile.modifiedAt = Date()

        if let id = profileId {
            profileStore.updateProfile(profile, for: id)
        } else {
            profileStore.save(profile)
        }

        selectedCoatType = coatType

        // If no grooming activities exist, seed defaults for this coat type
        if groomingActivities.isEmpty {
            routineStore.seedDefaultGroomingActivitiesIfNeeded()
        }
    }

    private func toggleActivity(_ activity: GroomingActivity, enabled: Bool) {
        var updated = activity
        updated.isEnabled = enabled
        updated.modifiedAt = Date()
        routineStore.updateGroomingActivity(updated)
    }

    private func updateInterval(_ activity: GroomingActivity, interval: Int) {
        var updated = activity
        updated.intervalDays = interval
        updated.modifiedAt = Date()
        routineStore.updateGroomingActivity(updated)
    }

    private func resetToDefaults() {
        guard let coatType = targetProfile?.effectiveCoatType else { return }
        routineStore.resetGroomingActivitiesToDefaults(for: coatType)
    }
}

// MARK: - Grooming Activity Row

private struct GroomingActivityRow: View {
    let activity: GroomingActivity
    let onToggle: (Bool) -> Void
    let onUpdateInterval: (Int) -> Void

    @State private var isExpanded = false
    @State private var intervalValue: Int

    init(activity: GroomingActivity, onToggle: @escaping (Bool) -> Void, onUpdateInterval: @escaping (Int) -> Void) {
        self.activity = activity
        self.onToggle = onToggle
        self.onUpdateInterval = onUpdateInterval
        self._intervalValue = State(initialValue: activity.intervalDays)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                Image(systemName: activity.type.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(activity.isEnabled ? .otisAccent : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.type.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(activity.isEnabled ? .primary : .secondary)

                    if activity.isEnabled {
                        Text(activity.statusLabel)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { activity.isEnabled },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            // Expanded content
            if isExpanded && activity.isEnabled {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.vertical, 8)

                    // Interval picker
                    HStack {
                        Text(Strings.Grooming.interval)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Stepper(
                            value: $intervalValue,
                            in: 1...90,
                            step: activity.type == .teethBrushing ? 1 : (intervalValue < 14 ? 1 : 7)
                        ) {
                            Text(Strings.Grooming.everyDays(intervalValue))
                                .font(.subheadline)
                        }
                        .onChange(of: intervalValue) { _, newValue in
                            onUpdateInterval(newValue)
                        }
                    }

                    // Description
                    Text(activity.type.description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        if activity.isOverdue {
            return .otisDanger
        } else if activity.isDue {
            return .otisWarning
        } else {
            return .secondary
        }
    }
}

// MARK: - Coat Type Picker Sheet

private struct CoatTypePickerSheet: View {
    @Binding var selectedCoatType: CoatType?
    let suggestedCoatType: CoatType?
    let onSelect: (CoatType) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(CoatType.allCases) { coatType in
                    Button {
                        onSelect(coatType)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: coatType.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(.otisAccent)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(coatType.label)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)

                                    if coatType == suggestedCoatType {
                                        Text(Strings.Grooming.suggested)
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.otisAccent)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(coatType.examples)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedCoatType == coatType {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.otisAccent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(Strings.Grooming.selectCoatType)
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
}

// MARK: - Strings Extension

extension Strings.Grooming {
    static let coatType = String(localized: "Coat Type", table: "Routines")
    static let selectCoatType = String(localized: "Select Coat Type", table: "Routines")
    static let notSet = String(localized: "Not set", table: "Routines")
    static let suggested = String(localized: "Suggested", table: "Routines")
    static let careTips = String(localized: "Care Tips", table: "Routines")
    static let noActivities = String(localized: "No grooming activities", table: "Routines")
    static let setupDefaults = String(localized: "Set Up Defaults", table: "Routines")
    static let setCoatTypeFirst = String(localized: "Set a coat type to see recommended schedule", table: "Routines")
    static let resetToDefaults = String(localized: "Reset to Defaults", table: "Routines")
    static let resetToDefaultsTitle = String(localized: "Reset Grooming Schedule?", table: "Routines")
    static let resetToDefaultsMessage = String(localized: "This will replace your current grooming schedule with the defaults for your dog's coat type.", table: "Routines")

    static func coatTypeSuggestion(_ coatType: String) -> String {
        String(localized: "Based on your dog's breed, we suggest \"\(coatType)\" as the coat type.", table: "Routines")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroomingSettingsView(profileStore: ProfileStore())
            .environmentObject(RoutineStore())
    }
}
