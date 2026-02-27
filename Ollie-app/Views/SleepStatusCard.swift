//
//  SleepStatusCard.swift
//  Ollie-app
//
//  Status card showing current sleep state
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI
import OllieShared

/// Card showing current sleep/awake state
/// Uses liquid glass design with semantic tinting
struct SleepStatusCard: View {
    let sleepState: SleepState
    let pendingActionable: ActionableItem?
    let onWakeUp: (() -> Void)?
    let onStartNap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(
        sleepState: SleepState,
        pendingActionable: ActionableItem? = nil,
        onWakeUp: (() -> Void)? = nil,
        onStartNap: (() -> Void)? = nil
    ) {
        self.sleepState = sleepState
        self.pendingActionable = pendingActionable
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
        StatusCardHeader(
            iconName: iconName,
            iconColor: indicatorColor,
            tintColor: indicatorColor,
            title: mainText,
            titleColor: textColor,
            subtitle: subtitleText.isEmpty ? nil : subtitleText,
            iconSize: 40
        ) {
            // Show contextual action based on sleep state
            actionButton
        }
        .statusCardPadding()
        .glassStatusCard(tintColor: indicatorColor, cornerRadius: LayoutConstants.cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.SleepStatus.title)
        .accessibilityValue(mainText)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch sleepState {
        case .sleeping:
            if let onWakeUp {
                Button(action: onWakeUp) {
                    Label(Strings.SleepStatus.wakeUp, systemImage: "sun.max.fill")
                }
                .buttonStyle(.glassPillCompact(tint: .custom(indicatorColor)))
            }
        case .awake(_, let durationMin):
            // Show nap button when awake >= 45 minutes
            if durationMin >= SleepCalculations.awakeWarningMinutes, let onStartNap {
                Button(action: onStartNap) {
                    Label(Strings.SleepStatus.startNap, systemImage: "moon.zzz.fill")
                }
                .buttonStyle(.glassPillCompact(tint: .custom(indicatorColor)))
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

    private var mainText: String {
        switch sleepState {
        case .sleeping(_, let durationMin):
            // Different text based on sleep duration
            if durationMin <= 1 {
                return Strings.SleepStatus.justFellAsleep
            } else if durationMin <= 15 {
                return Strings.SleepStatus.sleepingBriefly(duration: durationMin.formatAsDuration())
            }
            return Strings.SleepStatus.sleepingFor(duration: durationMin.formatAsDuration())
        case .awake(_, let durationMin):
            if durationMin >= SleepCalculations.maxAwakeMinutes {
                return Strings.SleepStatus.awakeTooLong(duration: durationMin.formatAsDuration())
            } else if durationMin >= SleepCalculations.awakeWarningMinutes {
                let remaining = SleepCalculations.maxAwakeMinutes - durationMin
                return Strings.SleepStatus.awakeWithNapSuggestion(duration: durationMin.formatAsDuration(), remaining: remaining)
            }
            return Strings.SleepStatus.awakeSince(duration: durationMin.formatAsDuration())
        case .unknown:
            return Strings.SleepStatus.noSleepData
        }
    }

    private var subtitleText: String {
        switch sleepState {
        case .sleeping(let since, _):
            // When sleeping with pending actionable, show what's due after waking
            if let actionable = pendingActionable {
                return pendingActionableSubtitle(actionable)
            }
            return Strings.SleepStatus.started(time: since.timeString)
        case .awake(let since, _):
            return Strings.SleepStatus.awakeSinceTime(time: since.timeString)
        case .unknown:
            return ""
        }
    }

    /// Subtitle text for pending walk/meal when sleeping
    private func pendingActionableSubtitle(_ actionable: ActionableItem) -> String {
        switch actionable.item.itemType {
        case .walk:
            return Strings.SleepStatus.afterWakeTimeForWalk
        case .meal:
            return Strings.SleepStatus.afterWakeTimeForMeal
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
