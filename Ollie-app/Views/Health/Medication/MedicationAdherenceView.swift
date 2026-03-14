//
//  MedicationAdherenceView.swift
//  Otis-app
//
//  Track medication compliance over time
//

import SwiftUI
import OtisShared

/// View showing medication adherence history and statistics
struct MedicationAdherenceView: View {
    let medication: Medication
    var medicationStore: MedicationStore

    @State private var selectedPeriod: AdherencePeriod = .last30Days

    enum AdherencePeriod: String, CaseIterable {
        case last7Days = "7 days"
        case last30Days = "30 days"
        case last90Days = "90 days"

        var days: Int {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            }
        }

        var label: String {
            switch self {
            case .last7Days: return Strings.Medications.Adherence.last7Days
            case .last30Days: return Strings.Medications.Adherence.last30Days
            case .last90Days: return Strings.Medications.Adherence.last90Days
            }
        }
    }

    private var adherenceStats: AdherenceStats {
        calculateAdherence(days: selectedPeriod.days)
    }

    private var recentCompletions: [MedicationCompletion] {
        medicationStore.completions
            .filter { $0.medicationId == medication.id }
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        List {
            // Overall stats section
            Section {
                overallStatsCard
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

            // Period selector
            Section {
                Picker(Strings.Medications.Adherence.period, selection: $selectedPeriod) {
                    ForEach(AdherencePeriod.allCases, id: \.self) { period in
                        Text(period.label).tag(period)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Monthly breakdown
            Section {
                monthlyBreakdown
            } header: {
                Text(Strings.Medications.Adherence.monthlyBreakdown)
            }

            // Recent history
            Section {
                if recentCompletions.isEmpty {
                    Text(Strings.Medications.Adherence.noHistory)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentCompletions) { completion in
                        completionRow(completion)
                    }
                }
            } header: {
                Text(Strings.Medications.Adherence.recentHistory)
            }
        }
        .navigationTitle(medication.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overall Stats Card

    @ViewBuilder
    private var overallStatsCard: some View {
        VStack(spacing: 16) {
            // Big percentage
            VStack(spacing: 4) {
                Text("\(adherenceStats.percentage)%")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(adherenceColorGradient)

                Text(Strings.Medications.Adherence.adherenceRate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(adherenceColor)
                        .frame(width: geometry.size.width * CGFloat(adherenceStats.percentage) / 100)
                }
            }
            .frame(height: 12)

            // Stats row
            HStack(spacing: 24) {
                AdherenceStatItem(
                    value: "\(adherenceStats.taken)",
                    label: Strings.Medications.Adherence.taken,
                    color: Color.otisSuccess
                )

                AdherenceStatItem(
                    value: "\(adherenceStats.missed)",
                    label: Strings.Medications.Adherence.missed,
                    color: Color.otisWarning
                )

                AdherenceStatItem(
                    value: "\(adherenceStats.expected)",
                    label: Strings.Medications.Adherence.expected,
                    color: Color.secondary
                )
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Monthly Breakdown

    @ViewBuilder
    private var monthlyBreakdown: some View {
        let months = calculateMonthlyAdherence()

        ForEach(months, id: \.month) { monthData in
            HStack {
                Text(monthData.monthName)
                    .font(.body)

                Spacer()

                // Mini progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.2))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorForPercentage(monthData.percentage))
                            .frame(width: geometry.size.width * CGFloat(monthData.percentage) / 100)
                    }
                }
                .frame(width: 80, height: 8)

                Text("\(monthData.percentage)%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    // MARK: - Completion Row

    @ViewBuilder
    private func completionRow(_ completion: MedicationCompletion) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.otisSuccess)

            VStack(alignment: .leading, spacing: 2) {
                Text(completion.completedAt, style: .date)
                    .font(.body)

                Text(completion.completedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private var adherenceColor: Color {
        colorForPercentage(adherenceStats.percentage)
    }

    private var adherenceColorGradient: LinearGradient {
        LinearGradient(
            colors: [adherenceColor, adherenceColor.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func colorForPercentage(_ percentage: Int) -> Color {
        switch percentage {
        case 90...100: return .otisSuccess
        case 70..<90: return .otisAccent
        case 50..<70: return .orange
        default: return .otisWarning
        }
    }

    private func calculateAdherence(days: Int) -> AdherenceStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var expected = 0
        var taken = 0

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Check if medication was scheduled for this day
            guard medication.isScheduledFor(date: date) else { continue }

            // Count expected doses
            expected += medication.times.count

            // Count actual completions
            for time in medication.times {
                if medicationStore.isComplete(medicationId: medication.id, timeId: time.id, for: date) {
                    taken += 1
                }
            }
        }

        let percentage = expected > 0 ? Int(Double(taken) / Double(expected) * 100) : 0
        return AdherenceStats(taken: taken, missed: expected - taken, expected: expected, percentage: percentage)
    }

    private func calculateMonthlyAdherence() -> [MonthlyAdherence] {
        let calendar = Calendar.current
        var months: [MonthlyAdherence] = []

        // Last 3 months
        for monthOffset in 0..<3 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) else { continue }

            let components = calendar.dateComponents([.year, .month], from: monthDate)
            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { continue }

            let daysInMonth = calendar.dateComponents([.day], from: startOfMonth, to: endOfMonth).day ?? 30
            var expected = 0
            var taken = 0

            for dayOffset in 0...daysInMonth {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth),
                      date <= Date() else { continue }

                guard medication.isScheduledFor(date: date) else { continue }

                expected += medication.times.count

                for time in medication.times {
                    if medicationStore.isComplete(medicationId: medication.id, timeId: time.id, for: date) {
                        taken += 1
                    }
                }
            }

            let percentage = expected > 0 ? Int(Double(taken) / Double(expected) * 100) : 0
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"

            months.append(MonthlyAdherence(
                month: startOfMonth,
                monthName: formatter.string(from: startOfMonth),
                percentage: percentage
            ))
        }

        return months
    }
}

// MARK: - Supporting Types

private struct AdherenceStats {
    let taken: Int
    let missed: Int
    let expected: Int
    let percentage: Int
}

private struct MonthlyAdherence {
    let month: Date
    let monthName: String
    let percentage: Int
}

private struct AdherenceStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Strings Extension

extension Strings.Medications {
    enum Adherence {
        static let adherenceRate = String(localized: "adherence rate", table: "Medications")
        static let taken = String(localized: "Taken", table: "Medications")
        static let missed = String(localized: "Missed", table: "Medications")
        static let expected = String(localized: "Expected", table: "Medications")
        static let period = String(localized: "Period", table: "Medications")
        static let last7Days = String(localized: "7 days", table: "Medications")
        static let last30Days = String(localized: "30 days", table: "Medications")
        static let last90Days = String(localized: "90 days", table: "Medications")
        static let monthlyBreakdown = String(localized: "Monthly Breakdown", table: "Medications")
        static let recentHistory = String(localized: "Recent History", table: "Medications")
        static let noHistory = String(localized: "No completion history yet", table: "Medications")
    }
}

// MARK: - Preview

#Preview("MedicationAdherenceView") {
    NavigationStack {
        MedicationAdherenceView(
            medication: Medication(
                name: "Heartgard",
                instructions: "Give with food",
                icon: "pills.fill",
                times: [MedicationTime(targetTime: "08:00")]
            ),
            medicationStore: MedicationStore()
        )
    }
}
