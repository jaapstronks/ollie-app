//
//  PoopStatusCard.swift
//  Ollie-app
//
//  Status card showing poop tracking with pattern-based awareness
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI

/// Card showing poop status for the day
/// Uses liquid glass design with semantic tinting based on urgency
struct PoopStatusCard: View {
    let status: PoopStatus
    let onLogPoop: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(status: PoopStatus, onLogPoop: (() -> Void)? = nil) {
        self.status = status
        self.onLogPoop = onLogPoop
    }

    var body: some View {
        // Hide during night hours
        if status.urgency == .hidden {
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
                iconName: PoopCalculations.iconName(for: status.urgency),
                iconColor: PoopCalculations.iconColor(for: status.urgency),
                tintColor: indicatorColor,
                title: mainText,
                titleColor: textColor,
                subtitle: subtitleText,
                statusLabel: statusLabel,
                iconSize: 40
            )

            // Show action when urgency warrants it
            if let onLogPoop, shouldShowAction {
                Button(action: onLogPoop) {
                    Label(Strings.PoopStatus.logNow, systemImage: "leaf.fill")
                }
                .buttonStyle(.glassPill(tint: .custom(indicatorColor)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassStatusCard(tintColor: indicatorColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.PoopStatus.accessibility)
        .accessibilityValue("\(mainText). \(statusLabel)")
    }

    private var shouldShowAction: Bool {
        // Show button when no poops yet or when urgency warrants it
        if status.todayCount == 0 {
            return true
        }
        switch status.urgency {
        case .gentle, .attention:
            return true
        default:
            return false
        }
    }

    // MARK: - Computed Properties

    private var mainText: String {
        // Show count with expected range
        if status.hasPatternData {
            return Strings.PoopStatus.todayCount(
                status.todayCount,
                expectedLower: status.expectedRange.lowerBound,
                expectedUpper: status.expectedRange.upperBound
            )
        } else {
            return Strings.PoopStatus.todayCountSimple(status.todayCount)
        }
    }

    private var subtitleText: String? {
        // Show message if present, otherwise show time since last
        if let message = status.message {
            return message
        }
        return PoopCalculations.formatTimeSince(status.lastPoopTime)
    }

    private var statusLabel: String {
        switch status.urgency {
        case .hidden:
            return ""
        case .good:
            return Strings.PoopStatus.good
        case .info:
            return Strings.PoopStatus.info
        case .gentle, .attention:
            return Strings.PoopStatus.note
        }
    }

    private var indicatorColor: Color {
        PoopCalculations.iconColor(for: status.urgency)
    }

    private var textColor: Color {
        switch status.urgency {
        case .hidden, .good, .info:
            return .primary
        case .gentle:
            return .primary
        case .attention:
            return .ollieWarning
        }
    }
}

// MARK: - Previews

#Preview("Good - 2 poops") {
    VStack {
        PoopStatusCard(
            status: PoopStatus(
                todayCount: 2,
                expectedRange: 2...3,
                lastPoopTime: Date().addingTimeInterval(-3600),
                daytimeMinutesSinceLast: 60,
                recentWalkWithoutPoop: false,
                urgency: .good,
                message: nil,
                hasPatternData: true,
                patternDailyMedian: 2.5
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Info - No poop yet") {
    VStack {
        PoopStatusCard(
            status: PoopStatus(
                todayCount: 0,
                expectedRange: 2...4,
                lastPoopTime: nil,
                daytimeMinutesSinceLast: nil,
                recentWalkWithoutPoop: false,
                urgency: .info,
                message: Strings.PoopStatus.noPoopYet,
                hasPatternData: true,
                patternDailyMedian: 3.0
            ),
            onLogPoop: {}
        )
        Spacer()
    }
    .padding()
}

#Preview("Gentle - Walk without poop") {
    VStack {
        PoopStatusCard(
            status: PoopStatus(
                todayCount: 1,
                expectedRange: 2...3,
                lastPoopTime: Date().addingTimeInterval(-4 * 3600),
                daytimeMinutesSinceLast: 240,
                recentWalkWithoutPoop: true,
                urgency: .gentle,
                message: Strings.PoopStatus.walkCompletedNoPoop,
                hasPatternData: true,
                patternDailyMedian: 2.5
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Attention - Long gap") {
    VStack {
        PoopStatusCard(
            status: PoopStatus(
                todayCount: 1,
                expectedRange: 2...3,
                lastPoopTime: Date().addingTimeInterval(-6 * 3600),
                daytimeMinutesSinceLast: 360,
                recentWalkWithoutPoop: false,
                urgency: .attention,
                message: Strings.PoopStatus.longerThanUsual,
                hasPatternData: true,
                patternDailyMedian: 2.5
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("No pattern data yet") {
    VStack {
        PoopStatusCard(
            status: PoopStatus(
                todayCount: 1,
                expectedRange: 3...5,
                lastPoopTime: Date().addingTimeInterval(-2 * 3600),
                daytimeMinutesSinceLast: 120,
                recentWalkWithoutPoop: false,
                urgency: .good,
                message: nil,
                hasPatternData: false,
                patternDailyMedian: nil
            )
        )
        Spacer()
    }
    .padding()
}
