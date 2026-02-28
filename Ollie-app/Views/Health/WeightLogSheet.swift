//
//  WeightLogSheet.swift
//  Ollie-app
//
//  Quick weight entry sheet

import SwiftUI
import OllieShared

/// Sheet for logging a weight measurement
struct WeightLogSheet: View {
    @Binding var isPresented: Bool
    let onSave: (Double) -> Void

    @State private var weightText: String = ""
    @State private var selectedDate: Date = Date()
    @FocusState private var isWeightFocused: Bool
    @AppStorage(UserPreferences.Key.weightUnit.rawValue) private var weightUnitRaw = WeightUnit.kg.rawValue

    @Environment(\.colorScheme) private var colorScheme

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    private var weightLabel: String {
        weightUnit == .kg ? Strings.Health.weightKg : Strings.Health.weightLbs
    }

    private var weightPlaceholder: String {
        weightUnit == .kg ? Strings.Health.weightPlaceholder : Strings.Health.weightPlaceholderLbs
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

                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.QuickLogSheet.time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .glassCard(tint: .none)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(Strings.Health.logWeight)
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
                isWeightFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
        onSave(weightInKg)
        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    WeightLogSheet(isPresented: .constant(true)) { weight in
        print("Logged weight: \(weight)")
    }
}
