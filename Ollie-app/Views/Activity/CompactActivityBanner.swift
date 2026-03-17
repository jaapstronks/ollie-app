//
//  CompactActivityBanner.swift
//  Otis-app
//
//  Banner shown above TabView when activity is in progress
//  Expanded for walks with quick potty logging buttons

import SwiftUI
import OtisShared

/// Banner for cross-tab activity visibility with quick potty logging during walks
struct CompactActivityBanner: View {
    let activity: InProgressActivity
    let onTap: () -> Void
    var onLogPee: (() -> Void)?
    var onLogPoop: (() -> Void)?
    var onShowMap: (() -> Void)?

    @State private var isPulsing = false
    @State private var isAnimating = false
    @State private var peeLoggedTimes: [Date] = []
    @State private var poopLoggedTimes: [Date] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if activity.type == .walk {
            walkBanner
        } else {
            napBanner
        }
    }

    // MARK: - Walk Banner (Expanded)

    private var walkBanner: some View {
        VStack(spacing: 0) {
            // Top row: status info with map and end buttons
            HStack(spacing: 12) {
                // Pulsing dot
                pulsingDot

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

                // Show map button
                if onShowMap != nil {
                    Button {
                        HapticFeedback.selection()
                        onShowMap?()
                    } label: {
                        Image(systemName: "map")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(iconColor)
                            .frame(width: 36, height: 28)
                            .background(iconColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }

                // End walk button
                Button {
                    HapticFeedback.selection()
                    onTap()
                } label: {
                    Text(Strings.Activity.end)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(iconColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Bottom row: quick potty buttons
            HStack(spacing: 16) {
                // Pee button
                pottyButton(
                    icon: EventType.plassen.icon,
                    label: EventType.plassen.label,
                    color: .blue,
                    loggedTimes: peeLoggedTimes,
                    action: {
                        peeLoggedTimes.append(Date())
                        onLogPee?()
                        HapticFeedback.success()
                    }
                )

                // Poop button
                pottyButton(
                    icon: EventType.poepen.icon,
                    label: EventType.poepen.label,
                    color: .brown,
                    loggedTimes: poopLoggedTimes,
                    action: {
                        poopLoggedTimes.append(Date())
                        onLogPoop?()
                        HapticFeedback.success()
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .padding(.top, 4)
        }
        .background(bannerBackground)
        .onAppear {
            guard !reduceMotion else { return }
            isAnimating = true
            isPulsing = true
        }
        .onDisappear {
            isAnimating = false
            isPulsing = false
        }
    }

    // MARK: - Nap Banner (Compact)

    private var napBanner: some View {
        Button {
            HapticFeedback.selection()
            onTap()
        } label: {
            HStack(spacing: 12) {
                pulsingDot

                Image(systemName: activity.type.icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)

                Text(activityLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(activity.elapsedTimeFormatted)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(iconColor)

                Spacer()

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
            isAnimating = false
            isPulsing = false
        }
    }

    // MARK: - Shared Components

    private var pulsingDot: some View {
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
    }

    @ViewBuilder
    private func pottyButton(
        icon: String,
        label: String,
        color: Color,
        loggedTimes: [Date],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let lastTime = loggedTimes.last {
                        Text(lastTime.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Show count if logged multiple times
                if loggedTimes.count > 0 {
                    Text("\(loggedTimes.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(color)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
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
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 4) {
            Text("Walk (expanded with potty buttons)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            CompactActivityBanner(
                activity: InProgressActivity(type: .walk, startTime: Date().addingTimeInterval(-20 * 60)),
                onTap: { print("End tapped") },
                onLogPee: { print("Pee logged") },
                onLogPoop: { print("Poop logged") },
                onShowMap: { print("Show map") }
            )
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Nap (compact)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            CompactActivityBanner(
                activity: InProgressActivity(type: .nap, startTime: Date().addingTimeInterval(-35 * 60)),
                onTap: { print("Banner tapped") }
            )
        }
    }
}
