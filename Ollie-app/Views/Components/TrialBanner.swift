//
//  TrialBanner.swift
//  Ollie-app
//

import SwiftUI
import OllieShared

/// Compact trial banner shown during last 7 days of free period
struct TrialBanner: View {
    let daysRemaining: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(bannerColor)

                Text(Strings.Premium.trialDaysLeft(daysRemaining))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(Strings.Premium.tapToUpgrade)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(bannerBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private var bannerColor: Color {
        if daysRemaining <= 3 {
            return .ollieWarning
        }
        return .ollieAccent
    }

    private var bannerBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
        return AnyShapeStyle(Color.black.opacity(0.04))
    }
}

#Preview("Trial Banner") {
    VStack {
        TrialBanner(daysRemaining: 7, onTap: {})
        TrialBanner(daysRemaining: 3, onTap: {})
        TrialBanner(daysRemaining: 1, onTap: {})
    }
}
