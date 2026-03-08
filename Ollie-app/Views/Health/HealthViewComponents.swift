//
//  HealthViewComponents.swift
//  Otis-app
//
//  Supporting views for HealthView
//

import SwiftUI
import OtisShared

// MARK: - Assessment Due Card

struct AssessmentDueCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let lastDate: Date?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let date = lastDate {
                        Text("Last: \(date, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not yet completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.orange)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RRR Quick Card

struct RRRQuickCard: View {
    let latestReading: RespiratoryRateReading?
    let onLogTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "lungs.fill")
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.SeniorWellness.rrrTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let reading = latestReading {
                    HStack(spacing: 4) {
                        Text(reading.formattedBPM)
                            .font(.caption)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(reading.status.label)
                            .font(.caption)
                            .foregroundStyle(Color(reading.status.colorName))
                    }
                } else {
                    Text("No readings yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onLogTap) {
                Label("Log", systemImage: "plus.circle.fill")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
