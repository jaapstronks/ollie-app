//
//  MedicationDetailView.swift
//  Otis-app
//
//  Detail view for a single medication showing schedule and adherence
//

import SwiftUI
import OtisShared

/// Detail view showing a medication's full information and adherence
struct MedicationDetailView: View {
    let medication: Medication
    var profileStore: ProfileStore
    var medicationStore: MedicationStore
    var profileId: UUID? = nil

    @State private var showingEditSheet = false
    @Environment(\.dismiss) private var dismiss

    private var weekAdherence: Int {
        calculateAdherence(days: 7)
    }

    var body: some View {
        List {
            // Overview section
            Section {
                overviewCard
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

            // Schedule section
            Section {
                scheduleInfo
            } header: {
                Text(Strings.Medications.schedule)
            }

            // Times section
            Section {
                timesInfo
            } header: {
                Text(Strings.Medications.times)
            }

            // Duration section
            Section {
                durationInfo
            } header: {
                Text(Strings.Medications.duration)
            }

            // Adherence link
            Section {
                NavigationLink {
                    MedicationAdherenceView(
                        medication: medication,
                        medicationStore: medicationStore
                    )
                } label: {
                    HStack {
                        Label(Strings.Medications.Detail.viewAdherence, systemImage: "chart.bar.fill")

                        Spacer()

                        Text("\(weekAdherence)%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Actions section
            Section {
                Button {
                    profileStore.toggleMedicationActive(id: medication.id, for: profileId)
                    HapticFeedback.light()
                } label: {
                    Label(
                        medication.isActive ? Strings.Medications.Detail.pauseMedication : Strings.Medications.Detail.resumeMedication,
                        systemImage: medication.isActive ? "pause.circle" : "play.circle"
                    )
                }
            }
        }
        .navigationTitle(medication.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text(Strings.Common.edit)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditMedicationSheet(
                profileStore: profileStore,
                profileId: profileId,
                medication: medication
            )
        }
    }

    // MARK: - Overview Card

    @ViewBuilder
    private var overviewCard: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(medication.isActive ? Color.otisAccent.opacity(0.15) : Color.secondary.opacity(0.1))
                    .frame(width: 64, height: 64)

                Image(systemName: medication.icon)
                    .font(.title)
                    .foregroundStyle(medication.isActive ? Color.otisAccent : .secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.title2.weight(.semibold))

                if let instructions = medication.instructions, !instructions.isEmpty {
                    Text(instructions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(medication.isActive ? Color.otisSuccess : Color.secondary)
                        .frame(width: 8, height: 8)

                    Text(medication.isActive ? Strings.Medications.active : Strings.Medications.paused)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Schedule Info

    @ViewBuilder
    private var scheduleInfo: some View {
        HStack {
            Text(Strings.Medications.schedule)
            Spacer()
            Text(medication.recurrence.label)
                .foregroundStyle(.secondary)
        }

        if medication.recurrence == .weekly, let days = medication.daysOfWeek {
            HStack {
                Text(Strings.Medications.daysOfWeek)
                Spacer()
                Text(formatDays(days))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Times Info

    @ViewBuilder
    private var timesInfo: some View {
        ForEach(medication.times) { time in
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)

                Text(formatTime(time.targetTime))

                Spacer()

                if time.linkedMealId != nil {
                    Label(Strings.Medications.Detail.linkedToMeal, systemImage: "link")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Duration Info

    @ViewBuilder
    private var durationInfo: some View {
        HStack {
            Text(Strings.Medications.startDate)
            Spacer()
            Text(medication.startDate, style: .date)
                .foregroundStyle(.secondary)
        }

        if let endDate = medication.endDate {
            HStack {
                Text(Strings.Medications.endDate)
                Spacer()
                Text(endDate, style: .date)
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack {
                Text(Strings.Medications.duration)
                Spacer()
                Text(Strings.Medications.indefinitely)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func formatDays(_ days: [Int]) -> String {
        days.sorted().map { Strings.Medications.dayShort($0) }.joined(separator: ", ")
    }

    private func formatTime(_ timeString: String) -> String {
        guard let (hour, minute) = timeString.parseTimeComponents() else {
            return timeString
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return timeString
    }

    private func calculateAdherence(days: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var expected = 0
        var taken = 0

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            guard medication.isScheduledFor(date: date) else { continue }

            expected += medication.times.count

            for time in medication.times {
                if medicationStore.isComplete(medicationId: medication.id, timeId: time.id, for: date) {
                    taken += 1
                }
            }
        }

        return expected > 0 ? Int(Double(taken) / Double(expected) * 100) : 0
    }
}

// MARK: - Strings Extension

extension Strings.Medications {
    enum Detail {
        static let viewAdherence = String(localized: "View adherence history", table: "Medications")
        static let linkedToMeal = String(localized: "Linked to meal", table: "Medications")
        static let pauseMedication = String(localized: "Pause medication", table: "Medications")
        static let resumeMedication = String(localized: "Resume medication", table: "Medications")
    }
}

// MARK: - Preview

#Preview("MedicationDetailView") {
    NavigationStack {
        MedicationDetailView(
            medication: Medication(
                name: "Heartgard",
                instructions: "Give with food",
                icon: "pills.fill",
                times: [
                    MedicationTime(targetTime: "08:00"),
                    MedicationTime(targetTime: "20:00")
                ]
            ),
            profileStore: ProfileStore(),
            medicationStore: MedicationStore()
        )
    }
}
