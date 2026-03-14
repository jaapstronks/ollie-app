//
//  CompactActivityBanner.swift
//  Otis-app
//
//  Slim banner shown above TabView when activity is in progress

import SwiftUI
import OtisShared

/// Compact banner for cross-tab activity visibility
struct CompactActivityBanner: View {
    let activity: InProgressActivity
    let onTap: () -> Void

    @State private var isPulsing = false
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            HapticFeedback.selection()
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Pulsing dot
                Circle()
                    .fill(iconColor)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.7 : 1.0)
                    .animation(
                        isAnimating
                            ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )

                // Activity type
                Image(systemName: activity.type.icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)

                // Label
                Text(activityLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Elapsed time
                Text(activity.elapsedTimeFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(iconColor)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(bannerBackground)
        }
        .buttonStyle(.plain)
        .onAppear {
            guard !reduceMotion else { return }
            isAnimating = true
            isPulsing = true
        }
        .onDisappear {
            // Stop animation by removing the repeatForever modifier
            isAnimating = false
            isPulsing = false
        }
    }

    // MARK: - Computed Properties

    private var activityLabel: String {
        switch activity.type {
        case .walk: return Strings.Activity.walkInProgress
        case .nap: return Strings.Activity.napInProgress
        }
    }

    private var iconColor: Color {
        switch activity.type {
        case .walk: return .green
        case .nap: return .purple
        }
    }

    @ViewBuilder
    private var bannerBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.1), iconColor.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }
}

#Preview {
    VStack(spacing: 0) {
        CompactActivityBanner(
            activity: InProgressActivity(type: .walk, startTime: Date().addingTimeInterval(-20 * 60)),
            onTap: { print("Banner tapped") }
        )

        Divider()

        CompactActivityBanner(
            activity: InProgressActivity(type: .nap, startTime: Date().addingTimeInterval(-35 * 60)),
            onTap: { print("Banner tapped") }
        )
    }
}
