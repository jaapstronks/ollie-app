//
//  WeightLogSheet.swift
//  Otis-app
//
//  Quick weight entry sheet - supports both adding new and editing existing measurements

import SwiftUI
import OtisShared

/// Sheet for logging or editing a weight measurement
struct WeightLogSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var weightStore: WeightStore

    /// Optional measurement to edit. If nil, creates a new measurement.
    var measurementToEdit: WeightMeasurement?

    @State private var weightText: String = ""
    @State private var selectedDate: Date = Date()
    @FocusState private var isWeightFocused: Bool

    @EnvironmentObject var unitPreferences: UnitPreferences
    @Environment(\.colorScheme) private var colorScheme

    private var isEditing: Bool {
        measurementToEdit != nil
    }

    private var weightUnit: WeightUnit {
        unitPreferences.weightUnit
    }

    private var weightLabel: String {
        weightUnit == .kg ? Strings.Health.weightKg : Strings.Health.weightLbs
    }

    private var weightPlaceholder: String {
        weightUnit == .kg ? Strings.Health.weightPlaceholder : Strings.Health.weightPlaceholderLbs
    }

    private var navigationTitle: String {
        isEditing ? Strings.Growth.editMeasurement : Strings.Health.logWeight
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Weight input
                VStack(alignment: .leading, spacing: 8) {
                    Text(weightLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField(weightPlaceholder, text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .focused($isWeightFocused)

                        Text(weightUnit.symbol)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .glassCard(tint: .accent)
                }

                // Date picker (date only - weight is logged once per day)
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Health.measurementDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .glassCard(tint: .none)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveWeight()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidWeight)
                }
            }
            .onAppear {
                setupInitialValues()
                isWeightFocused = true
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func setupInitialValues() {
        if let measurement = measurementToEdit {
            // Convert stored kg to display unit
            let displayWeight = weightUnit.convert(fromKg: measurement.weightKg)
            weightText = String(format: "%.1f", displayWeight)
            selectedDate = measurement.date
        }
    }

    private var isValidWeight: Bool {
        guard let weight = parseWeight() else { return false }
        // Convert to kg for validation
        let weightInKg = weightUnit.toKg(weight)
        return weightInKg > 0 && weightInKg < 100  // Reasonable range for dogs in kg
    }

    private func parseWeight() -> Double? {
        let cleaned = weightText.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    private func saveWeight() {
        guard let weight = parseWeight() else { return }
        // Convert to kg for storage
        let weightInKg = weightUnit.toKg(weight)
        // Normalize to noon on the selected date (avoids timezone edge cases)
        let calendar = Calendar.current
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate

        if let existingMeasurement = measurementToEdit {
            // Update existing measurement
            let updatedMeasurement = WeightMeasurement(
                id: existingMeasurement.id,
                date: noon,
                weightKg: weightInKg,
                note: existingMeasurement.note,
                createdAt: existingMeasurement.createdAt,
                modifiedAt: Date()
            )
            weightStore.updateMeasurement(updatedMeasurement)
        } else {
            // Add new measurement
            weightStore.addWeight(weightInKg, date: noon)
        }
        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    WeightLogSheet(isPresented: .constant(true))
        .environmentObject(WeightStore())
}
