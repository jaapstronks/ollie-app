//
//  TrialBanner.swift
//  Otis-app
//

import SwiftUI
import OtisShared

/// Compact trial banner shown during the 14-day trial period
/// Urgency styling: Days 14-8 calm, 7-4 attention, 3-1 urgent
struct TrialBanner: View {
    let daysRemaining: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: bannerIcon)
                    .font(.subheadline)
                    .foregroundStyle(bannerColor)

                Text(Strings.Trial.trialDaysRemaining(daysRemaining))
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

    /// Urgency level based on days remaining
    private var urgencyLevel: TrialUrgencyLevel {
        if daysRemaining > 7 {
            return .calm       // Days 14-8
        } else if daysRemaining > 3 {
            return .attention  // Days 7-4
        } else {
            return .urgent     // Days 3-1
        }
    }

    private var bannerIcon: String {
        switch urgencyLevel {
        case .calm:
            return "sparkles"
        case .attention:
            return "clock.fill"
        case .urgent:
            return "exclamationmark.triangle.fill"
        }
    }

    private var bannerColor: Color {
        switch urgencyLevel {
        case .calm:
            return .otisAccent
        case .attention:
            return .orange
        case .urgent:
            return .otisWarning
        }
    }

    private var bannerBackground: some ShapeStyle {
        let baseOpacity: Double
        switch urgencyLevel {
        case .calm:
            baseOpacity = colorScheme == .dark ? 0.08 : 0.04
        case .attention:
            baseOpacity = colorScheme == .dark ? 0.12 : 0.06
        case .urgent:
            baseOpacity = colorScheme == .dark ? 0.15 : 0.08
        }

        if colorScheme == .dark {
            return AnyShapeStyle(Color.white.opacity(baseOpacity))
        }
        return AnyShapeStyle(Color.black.opacity(baseOpacity))
    }
}

#Preview("Trial Banner") {
    VStack(spacing: 8) {
        TrialBanner(daysRemaining: 14, onTap: {})
        TrialBanner(daysRemaining: 10, onTap: {})
        TrialBanner(daysRemaining: 7, onTap: {})
        TrialBanner(daysRemaining: 5, onTap: {})
        TrialBanner(daysRemaining: 3, onTap: {})
        TrialBanner(daysRemaining: 1, onTap: {})
    }
}
