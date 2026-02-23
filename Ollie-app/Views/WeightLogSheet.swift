//
//  WeightLogSheet.swift
//  Ollie-app
//
//  Quick weight entry sheet

import SwiftUI

/// Sheet for logging a weight measurement
struct WeightLogSheet: View {
    @Binding var isPresented: Bool
    let onSave: (Double) -> Void

    @State private var weightText: String = ""
    @State private var selectedDate: Date = Date()
    @FocusState private var isWeightFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Weight input
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.Health.weightKg)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField(Strings.Health.weightPlaceholder, text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .focused($isWeightFocused)

                        Text(Strings.Health.kg)
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
        return weight > 0 && weight < 100  // Reasonable range for dogs
    }

    private func parseWeight() -> Double? {
        let cleaned = weightText.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    private func saveWeight() {
        guard let weight = parseWeight() else { return }
        onSave(weight)
        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    WeightLogSheet(isPresented: .constant(true)) { weight in
        print("Logged weight: \(weight)")
    }
}
