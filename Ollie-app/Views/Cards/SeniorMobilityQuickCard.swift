//
//  SeniorMobilityQuickCard.swift
//  Otis-app
//
//  Quick mobility rating card for senior dogs.
//

import SwiftUI

struct SeniorMobilityQuickCard: View {
    let puppyName: String
    let onRate: (Int) -> Void
    let onDetailedLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.blue)
                Text(Strings.SeniorWellness.howIsMobility(name: puppyName))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Quick 1-5 rating buttons
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        onRate(score)
                    } label: {
                        Text("\(score)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(colorForScore(score).opacity(0.2))
                            .foregroundStyle(colorForScore(score))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Add details button
            Button(action: onDetailedLog) {
                HStack {
                    Text("Add observations")
                        .font(.caption)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadiusM))
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .gray
        }
    }
}
