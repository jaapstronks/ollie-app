//
//  CelebrationView.swift
//  Ollie-app
//
//  Dog-themed celebration animations for milestone moments.
//  Custom particle system with paw prints, bones, stars, and hearts.
//

import SwiftUI
import Combine

// MARK: - Celebration Particle

/// A single celebration particle with physics
struct CelebrationParticle: Identifiable {
    let id = UUID()
    let symbol: CelebrationSymbol
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let scale: CGFloat
    let delay: Double
    let duration: Double
}

/// Available celebration symbols
enum CelebrationSymbol: CaseIterable {
    case paw
    case bone
    case star
    case heart
    case sparkle

    var systemImage: String {
        switch self {
        case .paw: return "pawprint.fill"
        case .bone: return "dog.fill"
        case .star: return "star.fill"
        case .heart: return "heart.fill"
        case .sparkle: return "sparkle"
        }
    }

    var color: Color {
        switch self {
        case .paw: return .ollieAccent
        case .bone: return .olliePurple
        case .star: return .ollieAccent
        case .heart: return .ollieRose
        case .sparkle: return .ollieAccent
        }
    }
}

/// Celebration style presets
enum CelebrationStyle {
    /// Full celebration with all particle types - for major milestones
    case milestone
    /// Paw-focused burst - for outdoor potty success
    case pottySuccess
    /// Stars and sparkles - for streak achievements
    case streak
    /// Hearts and paws - for training completion
    case training
    /// Subtle sparkle burst - for quick log confirmation
    case quickLog

    var symbols: [CelebrationSymbol] {
        switch self {
        case .milestone:
            return [.paw, .paw, .bone, .star, .star, .heart, .sparkle, .sparkle]
        case .pottySuccess:
            return [.paw, .paw, .paw, .star, .sparkle]
        case .streak:
            return [.star, .star, .star, .sparkle, .sparkle, .paw]
        case .training:
            return [.heart, .paw, .star, .sparkle]
        case .quickLog:
            return [.sparkle, .sparkle, .paw]
        }
    }

    var particleCount: Int {
        switch self {
        case .milestone: return 24
        case .pottySuccess: return 16
        case .streak: return 20
        case .training: return 14
        case .quickLog: return 8
        }
    }

    var spread: CGFloat {
        switch self {
        case .milestone: return 200
        case .pottySuccess: return 150
        case .streak: return 180
        case .training: return 140
        case .quickLog: return 100
        }
    }
}

// MARK: - Celebration View

/// Animated celebration overlay with dog-themed particles
struct CelebrationView: View {
    let style: CelebrationStyle
    @Binding var isActive: Bool

    @State private var particles: [CelebrationParticle] = []
    @State private var animationProgress: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ParticleView(
                        particle: particle,
                        progress: animationProgress,
                        reduceMotion: reduceMotion
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    triggerCelebration(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func triggerCelebration(in size: CGSize) {
        // Generate particles
        particles = generateParticles(in: size)
        animationProgress = 0

        // Haptic feedback
        HapticFeedback.success()

        // Animate
        if reduceMotion {
            // Quick fade for reduced motion
            withAnimation(.easeOut(duration: 0.3)) {
                animationProgress = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isActive = false
                particles = []
            }
        } else {
            withAnimation(.easeOut(duration: 1.2)) {
                animationProgress = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                isActive = false
                particles = []
            }
        }
    }

    private func generateParticles(in size: CGSize) -> [CelebrationParticle] {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let symbols = style.symbols

        return (0..<style.particleCount).map { index in
            let symbol = symbols[index % symbols.count]
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: (style.spread * 0.4)...style.spread)

            return CelebrationParticle(
                symbol: symbol,
                startX: centerX,
                startY: centerY,
                endX: centerX + cos(angle) * distance,
                endY: centerY + sin(angle) * distance - 50, // Slight upward bias
                rotation: Double.random(in: -360...360),
                scale: CGFloat.random(in: 0.6...1.2),
                delay: Double.random(in: 0...0.15),
                duration: Double.random(in: 0.8...1.2)
            )
        }
    }
}

// MARK: - Particle View

private struct ParticleView: View {
    let particle: CelebrationParticle
    let progress: CGFloat
    let reduceMotion: Bool

    var body: some View {
        let adjustedProgress = max(0, min(1, (Double(progress) - particle.delay) / particle.duration))
        let easedProgress = easeOutQuart(adjustedProgress)

        Image(systemName: particle.symbol.systemImage)
            .font(.system(size: 20 * particle.scale))
            .foregroundStyle(particle.symbol.color)
            .position(
                x: particle.startX + (particle.endX - particle.startX) * easedProgress,
                y: particle.startY + (particle.endY - particle.startY) * easedProgress
            )
            .rotationEffect(.degrees(reduceMotion ? 0 : particle.rotation * easedProgress))
            .scaleEffect(scaleForProgress(easedProgress))
            .opacity(opacityForProgress(easedProgress))
    }

    private func easeOutQuart(_ t: Double) -> CGFloat {
        CGFloat(1 - pow(1 - t, 4))
    }

    private func scaleForProgress(_ progress: CGFloat) -> CGFloat {
        if progress < 0.2 {
            // Pop in
            return progress / 0.2 * 1.2
        } else if progress < 0.4 {
            // Settle to normal
            return 1.2 - (progress - 0.2) / 0.2 * 0.2
        } else {
            // Normal size until fade
            return 1.0
        }
    }

    private func opacityForProgress(_ progress: CGFloat) -> CGFloat {
        if progress < 0.1 {
            // Fade in
            return progress / 0.1
        } else if progress > 0.7 {
            // Fade out
            return 1 - (progress - 0.7) / 0.3
        } else {
            return 1
        }
    }
}

// MARK: - View Modifier

/// Modifier to add celebration capability to any view
struct CelebrationModifier: ViewModifier {
    let style: CelebrationStyle
    @Binding var trigger: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                CelebrationView(style: style, isActive: $trigger)
            }
    }
}

extension View {
    /// Adds a celebration animation overlay triggered by the binding
    func celebration(style: CelebrationStyle = .milestone, trigger: Binding<Bool>) -> some View {
        modifier(CelebrationModifier(style: style, trigger: trigger))
    }
}

// MARK: - Celebration Trigger Helper

/// Observable object for triggering celebrations from ViewModels
@MainActor
final class CelebrationTrigger: ObservableObject {
    @Published var isActive = false
    @Published var style: CelebrationStyle = .milestone

    func trigger(_ style: CelebrationStyle = .milestone) {
        self.style = style
        self.isActive = true
    }
}

// MARK: - Preview

#Preview("Celebration Styles") {
    struct PreviewContainer: View {
        @State private var milestoneActive = false
        @State private var pottyActive = false
        @State private var streakActive = false
        @State private var trainingActive = false
        @State private var quickLogActive = false

        var body: some View {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Celebration Styles")
                        .font(.headline)

                    Button("Milestone (Full)") {
                        milestoneActive = true
                    }
                    .buttonStyle(.glassPrimary)

                    Button("Potty Success") {
                        pottyActive = true
                    }
                    .buttonStyle(.glassPill(tint: .success))

                    Button("Streak Achievement") {
                        streakActive = true
                    }
                    .buttonStyle(.glassPill(tint: .accent))

                    Button("Training Complete") {
                        trainingActive = true
                    }
                    .buttonStyle(.glassPill(tint: .custom(.olliePurple)))

                    Button("Quick Log") {
                        quickLogActive = true
                    }
                    .buttonStyle(.glassSecondary)
                }
                .padding()

                CelebrationView(style: .milestone, isActive: $milestoneActive)
                CelebrationView(style: .pottySuccess, isActive: $pottyActive)
                CelebrationView(style: .streak, isActive: $streakActive)
                CelebrationView(style: .training, isActive: $trainingActive)
                CelebrationView(style: .quickLog, isActive: $quickLogActive)
            }
        }
    }

    return PreviewContainer()
}

#Preview("Celebration on Card") {
    struct CardPreview: View {
        @State private var showCelebration = false

        var body: some View {
            VStack {
                VStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    Text("7-Day Streak!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("You're on fire!")
                        .foregroundStyle(.secondary)

                    Button("Celebrate!") {
                        showCelebration = true
                    }
                    .buttonStyle(.glassPrimary(tint: .accent))
                }
                .padding(24)
                .glassBackground(.card)
                .celebration(style: .streak, trigger: $showCelebration)
            }
            .padding()
        }
    }

    return CardPreview()
}
