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
    let onWakeUp: (() -> Void)?
    let onStartNap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(sleepState: SleepState, onWakeUp: (() -> Void)? = nil, onStartNap: (() -> Void)? = nil) {
        self.sleepState = sleepState
        self.onWakeUp = onWakeUp
        self.onStartNap = onStartNap
    }

    var body: some View {
        // Hide during night hours (23:00 - 06:00) or if no data
        if isNightTime || sleepState == .unknown {
            EmptyView()
        } else {
            cardContent
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: 12) {
            StatusCardHeader(
                iconName: iconName,
                iconColor: indicatorColor,
                tintColor: indicatorColor,
                title: mainText,
                titleColor: textColor,
                subtitle: subtitleText.isEmpty ? nil : subtitleText,
                statusLabel: statusLabel,
                iconSize: 40
            )

            // Show contextual action based on sleep state
            actionButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassStatusCard(tintColor: indicatorColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.SleepStatus.title)
        .accessibilityValue("\(mainText). \(statusLabel)")
    }

    @ViewBuilder
    private var actionButton: some View {
        switch sleepState {
        case .sleeping:
            if let onWakeUp {
                Button(action: onWakeUp) {
                    Label(Strings.SleepStatus.wakeUp, systemImage: "sun.max.fill")
                }
                .buttonStyle(.glassPill(tint: .custom(indicatorColor)))
            }
        case .awake(_, let durationMin):
            // Show nap button when awake >= 45 minutes
            if durationMin >= SleepCalculations.awakeWarningMinutes, let onStartNap {
                Button(action: onStartNap) {
                    Label(Strings.SleepStatus.startNap, systemImage: "moon.zzz.fill")
                }
                .buttonStyle(.glassPill(tint: .custom(indicatorColor)))
            }
        case .unknown:
            EmptyView()
        }
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
            return Strings.SleepStatus.sleeping
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return Strings.SleepStatus.napTime
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                return Strings.SleepStatus.attention
            }
            return Strings.SleepStatus.awake
        case .unknown:
            return Strings.PottyStatus.unknown
        }
    }

    private var mainText: String {
        switch sleepState {
        case .sleeping(_, let durationMin):
            return Strings.SleepStatus.sleepingFor(duration: formatDuration(durationMin))
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return Strings.SleepStatus.awakeTooLong(duration: formatDuration(durationMin))
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                let remaining = SleepCalculations.maxAwakeMinutes - durationMin
                return Strings.SleepStatus.awakeWithNapSuggestion(duration: formatDuration(durationMin), remaining: remaining)
            }
            return Strings.SleepStatus.awakeSince(duration: formatDuration(durationMin))
        case .unknown:
            return Strings.SleepStatus.noSleepData
        }
    }

    private var subtitleText: String {
        switch sleepState {
        case .sleeping(let since, _):
            return Strings.SleepStatus.started(time: since.timeString)
        case .awake(let since, _):
            return Strings.SleepStatus.awakeSinceTime(time: since.timeString)
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
        Constants.isNightTimeNow()
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
