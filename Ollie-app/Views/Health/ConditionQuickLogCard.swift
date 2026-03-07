//
//  ConditionQuickLogCard.swift
//  Ollie-app
//
//  Quick symptom log buttons for diagnosed conditions
//  Part of Brief 04: Health Logging
//

import SwiftUI
import OtisShared

struct ConditionQuickLogCard: View {
    let condition: HealthCondition
    let onLogSymptom: (SymptomType) -> Void
    let onLogGoodDay: () -> Void
    let onViewDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: condition.type.icon)
                    .foregroundStyle(.teal)
                Text(Strings.HealthLogging.quickLog)
                    .font(.headline)
                Spacer()
                Button(action: onViewDetails) {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }

            // Condition name
            Text(condition.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Quick log buttons
            FlowLayout(spacing: 8) {
                // Good day button
                QuickLogButton(
                    icon: "checkmark.circle.fill",
                    label: Strings.HealthLogging.goodDay,
                    color: .green
                ) {
                    onLogGoodDay()
                }

                // Common symptoms for this condition
                ForEach(commonSymptoms) { symptom in
                    QuickLogButton(
                        icon: symptom.icon,
                        label: symptom.label,
                        color: symptomColor(for: symptom)
                    ) {
                        onLogSymptom(symptom)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var commonSymptoms: [SymptomType] {
        Array(condition.type.commonSymptoms.prefix(4))
    }

    private func symptomColor(for symptom: SymptomType) -> Color {
        switch symptom.urgencyLevel {
        case .emergency: return .red
        case .soonIfPersists: return .orange
        case .monitor: return .blue
        }
    }
}

// MARK: - Quick Log Button

private struct QuickLogButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            action()
            HapticFeedback.selection()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.subheadline)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ConditionQuickLogCard(
            condition: HealthCondition(
                type: .arthritis,
                diagnosedDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                severity: .moderate
            ),
            onLogSymptom: { symptom in
                print("Logged: \(symptom.label)")
            },
            onLogGoodDay: {
                print("Good day logged")
            },
            onViewDetails: {
                print("View details")
            }
        )
        .padding()

        ConditionQuickLogCard(
            condition: HealthCondition(
                type: .foodAllergy,
                diagnosedDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                severity: .mild
            ),
            onLogSymptom: { _ in },
            onLogGoodDay: {},
            onViewDetails: {}
        )
        .padding()
    }
}
