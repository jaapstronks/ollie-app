//
//  CelebrationView.swift
//  Otis-app
//
//  Celebration visuals (new implementation).
//

import SwiftUI
import Combine

/// Celebration style presets
enum CelebrationPreset {
    case milestone
    case pottySuccess
    case streak
    case training
    case quickLog

    var tint: Color {
        switch self {
        case .milestone: return .otisAccent
        case .pottySuccess: return .otisSuccess
        case .streak: return .otisPurple
        case .training: return .otisRose
        case .quickLog: return .otisInfo
        }
    }

    var headline: String {
        switch self {
        case .milestone: return Strings.Celebrations.amazing
        case .pottySuccess: return Strings.Celebrations.greatJob
        case .streak: return Strings.Celebrations.onARoll
        case .training: return Strings.Celebrations.greatWork
        case .quickLog: return Strings.Celebrations.nice
        }
    }
}

/// Simple, high-visibility celebration overlay.
struct CelebrationView: View {
    let style: CelebrationPreset
    var streakCount: Int? = nil
    @Binding var isActive: Bool

    @State private var progress: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Custom headline that shows streak count for potty success
    private var headline: String {
        if let count = streakCount, style == .pottySuccess, count > 1 {
            return Strings.Celebration.streakInARow(count)
        }
        return style.headline
    }

    var body: some View {
        ZStack {
            if isActive {
                style.tint
                    .opacity(0.24 * (1 - progress))
                    .ignoresSafeArea()

                Circle()
                    .fill(style.tint.opacity(0.34))
                    .frame(width: 72, height: 72)
                    .scaleEffect(0.6 + progress * 3.8)
                    .opacity(0.92 - progress)

                Circle()
                    .stroke(style.tint.opacity(0.92), lineWidth: 4)
                    .frame(width: 30, height: 30)
                    .scaleEffect(0.8 + progress * 5.0)
                    .opacity(0.9 - progress)

                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 18, height: 18)
                    .scaleEffect(0.9 + progress * 1.1)
                    .opacity(0.95 - progress * 1.1)

                // Radial dots burst (new, robust replacement for old symbol particles).
                ForEach(0..<14, id: \.self) { index in
                    let angle = (Double(index) / 14.0) * (2.0 * .pi)
                    let radius = 30.0 + (160.0 * Double(progress))
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius
                    Circle()
                        .fill(style.tint)
                        .frame(width: 10, height: 10)
                        .offset(x: x, y: y)
                        .opacity(0.95 - progress)
                        .scaleEffect(1.15 - progress * 0.5)
                }

                Text(headline)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
                    .scaleEffect(CGFloat(2.0) * (CGFloat(0.86) + progress * CGFloat(0.22)))
                    .opacity(Double(CGFloat(1.0) - progress * CGFloat(1.15)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: isActive) { _, newValue in
            guard newValue else { return }
            playAnimation()
        }
    }

    private func playAnimation() {
        progress = 0
        HapticFeedback.success()

        let duration = reduceMotion ? 0.5 : 2.5
        withAnimation(.easeOut(duration: duration)) {
            progress = 1
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration + 0.15))
            isActive = false
        }
    }
}

struct CelebrationModifier: ViewModifier {
    let style: CelebrationPreset
    var streakCount: Int? = nil
    @Binding var trigger: Bool

    func body(content: Content) -> some View {
        content.overlay {
            CelebrationView(style: style, streakCount: streakCount, isActive: $trigger)
        }
    }
}

extension View {
    func celebration(style: CelebrationPreset = .milestone, streakCount: Int? = nil, trigger: Binding<Bool>) -> some View {
        modifier(CelebrationModifier(style: style, streakCount: streakCount, trigger: trigger))
    }
}

@MainActor
final class CelebrationTrigger: ObservableObject {
    @Published var isActive = false
    @Published var style: CelebrationPreset = .milestone
    @Published var streakCount: Int?

    func trigger(_ style: CelebrationPreset = .milestone, streakCount: Int? = nil) {
        self.style = style
        self.streakCount = streakCount
        isActive = true
    }
}
