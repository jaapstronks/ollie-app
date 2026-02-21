//
//  PoopStatusCard.swift
//  Ollie-app
//
//  Status card showing daily poop slot tracking
//  Uses liquid glass design for iOS 26 aesthetic

import SwiftUI

/// Card showing poop slot status for the day
/// Uses liquid glass design with semantic tinting
struct PoopStatusCard: View {
    let status: PoopSlotStatus

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Hide during night hours or if hidden urgency
        if status.currentUrgency == .hidden {
            EmptyView()
        } else {
            cardContent
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with icon and status
            StatusCardHeader(
                iconName: PoopCalculations.iconName(for: status.currentUrgency),
                iconColor: PoopCalculations.iconColor(for: status.currentUrgency),
                tintColor: indicatorColor,
                title: mainText,
                titleColor: textColor,
                subtitle: subtitleText,
                statusLabel: statusLabel,
                iconSize: 40
            )

            // Slot indicators row
            slotIndicators
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassStatusCard(tintColor: indicatorColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.PoopStatus.accessibility)
        .accessibilityValue("\(mainText). \(statusLabel)")
    }

    // MARK: - Slot Indicators

    @ViewBuilder
    private var slotIndicators: some View {
        HStack(spacing: 16) {
            slotIndicator(
                label: PoopCalculations.morningSlot.label,
                filled: status.morningFilled
            )

            slotIndicator(
                label: PoopCalculations.afternoonSlot.label,
                filled: status.afternoonFilled
            )

            Spacer()
        }
        .padding(.leading, 54) // Align with text after icon
    }

    @ViewBuilder
    private func slotIndicator(label: String, filled: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: filled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(filled ? Color.ollieSuccess : .secondary)

            Text(label)
                .font(.caption)
                .foregroundStyle(filled ? .primary : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(filled ? Strings.PoopStatus.done : Strings.PoopStatus.notYet)")
    }

    // MARK: - Computed Properties

    private var mainText: String {
        if status.allDone {
            return Strings.PoopStatus.allDone
        }
        return status.alertMessage ?? Strings.PoopStatus.tracking
    }

    private var subtitleText: String? {
        PoopCalculations.formatTimeSince(status.lastPoopTime)
    }

    private var statusLabel: String {
        switch status.currentUrgency {
        case .hidden:
            return ""
        case .allDone:
            return Strings.PoopStatus.complete
        case .normal:
            return Strings.PoopStatus.normal
        case .attention:
            return Strings.PottyStatus.attention
        case .urgent:
            return Strings.PottyStatus.now
        }
    }

    private var indicatorColor: Color {
        PoopCalculations.iconColor(for: status.currentUrgency)
    }

    private var textColor: Color {
        switch status.currentUrgency {
        case .hidden, .normal:
            return .primary
        case .allDone:
            return .primary
        case .attention:
            return .ollieWarning
        case .urgent:
            return .ollieDanger
        }
    }
}

// MARK: - Previews

#Preview("All Done") {
    VStack {
        PoopStatusCard(
            status: PoopSlotStatus(
                morningFilled: true,
                afternoonFilled: true,
                lastPoopTime: Date().addingTimeInterval(-3600),
                currentUrgency: .allDone,
                alertMessage: nil
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Morning Done") {
    VStack {
        PoopStatusCard(
            status: PoopSlotStatus(
                morningFilled: true,
                afternoonFilled: false,
                lastPoopTime: Date().addingTimeInterval(-4 * 3600),
                currentUrgency: .normal,
                alertMessage: nil
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Afternoon Attention") {
    VStack {
        PoopStatusCard(
            status: PoopSlotStatus(
                morningFilled: true,
                afternoonFilled: false,
                lastPoopTime: Date().addingTimeInterval(-6 * 3600),
                currentUrgency: .attention,
                alertMessage: Strings.PoopStatus.afternoonExpected
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Afternoon Urgent") {
    VStack {
        PoopStatusCard(
            status: PoopSlotStatus(
                morningFilled: true,
                afternoonFilled: false,
                lastPoopTime: Date().addingTimeInterval(-8 * 3600),
                currentUrgency: .urgent,
                alertMessage: Strings.PoopStatus.afternoonUrgent
            )
        )
        Spacer()
    }
    .padding()
}

#Preview("Morning Not Yet") {
    VStack {
        PoopStatusCard(
            status: PoopSlotStatus(
                morningFilled: false,
                afternoonFilled: false,
                lastPoopTime: nil,
                currentUrgency: .normal,
                alertMessage: Strings.PoopStatus.morningNotYet
            )
        )
        Spacer()
    }
    .padding()
}
