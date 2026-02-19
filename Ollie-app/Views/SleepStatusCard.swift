//
//  SleepStatusCard.swift
//  Ollie-app
//
//  Status card showing current sleep state
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI

/// Card showing current sleep/awake state
/// Uses liquid glass design with semantic tinting
struct SleepStatusCard: View {
    let sleepState: SleepState

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Hide during night hours (23:00 - 06:00) or if no data
        if isNightTime || sleepState == .unknown {
            EmptyView()
        } else {
            cardContent
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack(spacing: 12) {
            // Icon with glass circle background
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(indicatorColor)
                .frame(width: 40, height: 40)
                .background(iconBackground)
                .clipShape(Circle())
                .overlay(iconOverlay)

            VStack(alignment: .leading, spacing: 3) {
                // Main status text
                Text(mainText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor)

                // Subtitle with time details
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Status pill
            statusPill
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(glassOverlay)
    }

    // MARK: - Glass Components

    @ViewBuilder
    private var iconBackground: some View {
        ZStack {
            indicatorColor.opacity(colorScheme == .dark ? 0.2 : 0.15)

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var iconOverlay: some View {
        Circle()
            .strokeBorder(
                indicatorColor.opacity(0.3),
                lineWidth: 0.5
            )
    }

    @ViewBuilder
    private var statusPill: some View {
        Text(statusLabel)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(indicatorColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(indicatorColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(indicatorColor.opacity(0.2), lineWidth: 0.5)
            )
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            if colorScheme == .dark {
                Color.white.opacity(0.05)
            } else {
                Color.white.opacity(0.7)
            }

            // Tint
            indicatorColor.opacity(colorScheme == .dark ? 0.06 : 0.04)

            // Top highlight
            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
        }
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                        indicatorColor.opacity(colorScheme == .dark ? 0.08 : 0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch sleepState {
        case .sleeping:
            return "moon.zzz.fill"
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return "alarm.fill"
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                return "lightbulb.fill"
            }
            return "sun.max.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var statusLabel: String {
        switch sleepState {
        case .sleeping:
            return "Slaapt"
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return "Dutje tijd!"
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                return "Let op"
            }
            return "Wakker"
        case .unknown:
            return "Onbekend"
        }
    }

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
