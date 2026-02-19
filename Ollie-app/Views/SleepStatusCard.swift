//
//  SleepStatusCard.swift
//  Ollie-app
//
//  Status card showing current sleep state

import SwiftUI

/// Card showing current sleep/awake state
struct SleepStatusCard: View {
    let sleepState: SleepState

    var body: some View {
        // Hide during night hours (23:00 - 06:00) or if no data
        if isNightTime || sleepState == .unknown {
            EmptyView()
        } else {
            cardContent
                .padding(.horizontal)
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack {
            // Emoji indicator
            Text(emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                // Main status text
                Text(mainText)
                    .font(.headline)
                    .foregroundColor(textColor)

                // Subtitle with time details
                Text(subtitleText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Color indicator dot
            Circle()
                .fill(indicatorColor)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    private var emoji: String {
        switch sleepState {
        case .sleeping:
            return "😴"
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return "⏰"
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                return "💡"
            }
            return "☀️"
        case .unknown:
            return "❓"
        }
    }

    private var mainText: String {
        switch sleepState {
        case .sleeping(_, let durationMin):
            return "Slaapt al \(formatDuration(durationMin))"
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return "Al \(formatDuration(durationMin)) wakker — tijd voor een dutje!"
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                let remaining = SleepCalculations.maxAwakeMinutes - durationMin
                return "\(formatDuration(durationMin)) wakker — over \(remaining) min een dutje?"
            }
            return "Wakker sinds \(formatDuration(durationMin))"
        case .unknown:
            return "Geen slaapdata"
        }
    }

    private var subtitleText: String {
        switch sleepState {
        case .sleeping(let since, _):
            return "Begonnen: \(since.timeString)"
        case .awake(let since, _):
            return "Wakker sinds: \(since.timeString)"
        case .unknown:
            return ""
        }
    }

    private var indicatorColor: Color {
        switch sleepState {
        case .sleeping:
            return .purple
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return .red
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                return .orange
            }
            return .green
        case .unknown:
            return .gray
        }
    }

    private var textColor: Color {
        switch sleepState {
        case .sleeping:
            return .primary
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return .red
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                return .orange
            }
            return .primary
        case .unknown:
            return .secondary
        }
    }

    private var backgroundColor: Color {
        switch sleepState {
        case .sleeping:
            return Color.purple.opacity(0.1)
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return Color.red.opacity(0.1)
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                return Color.orange.opacity(0.1)
            }
            return Color.green.opacity(0.1)
        case .unknown:
            return Color(.secondarySystemBackground)
        }
    }

    private var isNightTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 23 || hour < 6
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) uur"
            }
            return "\(hours)u\(mins)m"
        }
    }
}

// MARK: - Previews

#Preview("Sleeping") {
    VStack {
        SleepStatusCard(
            sleepState: .sleeping(
                since: Date().addingTimeInterval(-45 * 60),
                durationMin: 45
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Awake - Recent") {
    VStack {
        SleepStatusCard(
            sleepState: .awake(
                since: Date().addingTimeInterval(-20 * 60),
                durationMin: 20
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Awake - Warning") {
    VStack {
        SleepStatusCard(
            sleepState: .awake(
                since: Date().addingTimeInterval(-50 * 60),
                durationMin: 50
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Awake - Time for nap") {
    VStack {
        SleepStatusCard(
            sleepState: .awake(
                since: Date().addingTimeInterval(-75 * 60),
                durationMin: 75
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Unknown") {
    VStack {
        SleepStatusCard(sleepState: .unknown)
        Spacer()
    }
    .padding()
}
