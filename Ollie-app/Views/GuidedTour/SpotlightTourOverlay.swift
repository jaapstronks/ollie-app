//
//  SpotlightTourOverlay.swift
//  Ollie-app
//
//  Lightweight spotlight-style tour that highlights UI elements

import SwiftUI

// MARK: - Spotlight Target Preference

/// Preference key to collect spotlight target frames
struct SpotlightTargetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [SpotlightTargetID: CGRect] = [:]

    static func reduce(value: inout [SpotlightTargetID: CGRect], nextValue: () -> [SpotlightTargetID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Identifies a spotlight target
enum SpotlightTargetID: Hashable {
    case tabBar
    case tab(MainTab)
    case quickLogBar
    case fab
    case statusCards
    case timeline
}

// MARK: - Spotlight Target Modifier

extension View {
    /// Marks this view as a spotlight target
    func spotlightTarget(_ id: SpotlightTargetID) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: SpotlightTargetPreferenceKey.self,
                    value: [id: geo.frame(in: .global)]
                )
            }
        )
    }
}

// MARK: - Spotlight Shape

/// Shape that creates a spotlight cutout effect
struct SpotlightCutoutShape: Shape {
    var targetRect: CGRect
    var cornerRadius: CGFloat
    var padding: CGFloat

    var animatableData: AnimatablePair<CGRect.AnimatableData, CGFloat> {
        get { AnimatablePair(targetRect.animatableData, cornerRadius) }
        set {
            targetRect.animatableData = newValue.first
            cornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Full screen rectangle
        path.addRect(rect)

        // Cutout rectangle (with padding and corner radius)
        let cutoutRect = targetRect.insetBy(dx: -padding, dy: -padding)
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
            .path(in: cutoutRect)

        path.addPath(roundedRect)

        return path
    }
}

// MARK: - Tooltip Position

enum TooltipPosition {
    case above
    case below
    case leading
    case trailing

    static func best(for targetRect: CGRect, in screenSize: CGSize) -> TooltipPosition {
        let spaceAbove = targetRect.minY
        let spaceBelow = screenSize.height - targetRect.maxY

        // Prefer below for tab bar items, above otherwise
        if spaceBelow > 200 {
            return .below
        } else if spaceAbove > 200 {
            return .above
        } else if spaceBelow >= spaceAbove {
            return .below
        } else {
            return .above
        }
    }
}

// MARK: - Tour Tooltip

struct SpotlightTooltip: View {
    let step: TourStep
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text(step.title)
                .font(.headline)
                .foregroundStyle(.primary)

            // Body
            Text(step.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Actions
            HStack(spacing: 12) {
                // Progress indicator
                Text(Strings.GuidedTour.stepProgress(current: step.rawValue + 1, total: TourStep.totalSteps))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                // Skip button
                if step != .done {
                    Button(Strings.Common.skip) {
                        onSkip()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // Next button
                Button {
                    onNext()
                } label: {
                    Text(step.buttonText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.otisAccent)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: 280)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
    }
}

// MARK: - Spotlight Tour Overlay

struct SpotlightTourOverlay: View {
    @Binding var selectedTab: MainTab
    @Binding var isActive: Bool
    var targetFrames: [SpotlightTargetID: CGRect]

    @AppStorage(UserPreferences.Key.guidedTourStep.rawValue) private var currentStepIndex = 0
    @AppStorage(UserPreferences.Key.hasCompletedGuidedTour.rawValue) private var hasCompletedTour = false

    @State private var hasAppeared = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentStep: TourStep {
        TourStep(rawValue: currentStepIndex) ?? .welcome
    }

    private var currentTargetID: SpotlightTargetID? {
        switch currentStep {
        case .welcome, .done:
            return nil
        case .today:
            return .tab(.today)
        case .train:
            return .tab(.train)
        case .explore:
            return .tab(.explore)
        case .schedule:
            return .tab(.schedule)
        case .health:
            return .tab(.health)
        }
    }

    private var currentTargetRect: CGRect? {
        guard let targetID = currentTargetID else { return nil }
        return targetFrames[targetID]
    }

    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size

            ZStack {
                // Spotlight overlay (dimmed background with cutout)
                spotlightBackground(screenSize: screenSize)

                // Tooltip positioned relative to target
                tooltipView(screenSize: screenSize)
            }
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .ignoresSafeArea()
        .onAppear {
            // Navigate to the tab for this step
            if let tab = currentStep.associatedTab {
                selectedTab = tab
            }

            // Animate in
            let animation: Animation? = reduceMotion ? nil : .easeOut(duration: 0.3)
            withAnimation(animation) {
                hasAppeared = true
            }
        }
        .onChange(of: currentStepIndex) { _, newIndex in
            // Navigate to the associated tab when step changes
            if let step = TourStep(rawValue: newIndex),
               let tab = step.associatedTab {
                let animation: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.25)
                withAnimation(animation) {
                    selectedTab = tab
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Guided tour")
    }

    // MARK: - Spotlight Background

    @ViewBuilder
    private func spotlightBackground(screenSize: CGSize) -> some View {
        if let targetRect = currentTargetRect {
            // Spotlight with cutout
            SpotlightCutoutShape(
                targetRect: targetRect,
                cornerRadius: 12,
                padding: 6
            )
            .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: targetRect)
        } else {
            // Welcome/Done: lighter overlay, no cutout
            Color.black.opacity(0.4)
        }
    }

    // MARK: - Tooltip View

    @ViewBuilder
    private func tooltipView(screenSize: CGSize) -> some View {
        let tooltip = SpotlightTooltip(
            step: currentStep,
            onNext: advanceToNextStep,
            onSkip: completeTour
        )

        if let targetRect = currentTargetRect {
            // Position relative to target
            let position = TooltipPosition.best(for: targetRect, in: screenSize)

            tooltip
                .position(tooltipPosition(for: targetRect, position: position, screenSize: screenSize))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else {
            // Center for welcome/done steps
            VStack {
                Spacer()
                tooltip
                    .padding(.horizontal, 24)
                Spacer()
                    .frame(height: screenSize.height * 0.3)
            }
        }
    }

    private func tooltipPosition(for targetRect: CGRect, position: TooltipPosition, screenSize: CGSize) -> CGPoint {
        let tooltipWidth: CGFloat = 280
        let tooltipHeight: CGFloat = 140
        let margin: CGFloat = 16

        var x = targetRect.midX
        var y: CGFloat

        switch position {
        case .above:
            y = targetRect.minY - tooltipHeight / 2 - margin
        case .below:
            y = targetRect.maxY + tooltipHeight / 2 + margin
        case .leading:
            x = targetRect.minX - tooltipWidth / 2 - margin
            y = targetRect.midY
        case .trailing:
            x = targetRect.maxX + tooltipWidth / 2 + margin
            y = targetRect.midY
        }

        // Keep tooltip within screen bounds
        x = max(tooltipWidth / 2 + margin, min(screenSize.width - tooltipWidth / 2 - margin, x))
        y = max(tooltipHeight / 2 + 60, min(screenSize.height - tooltipHeight / 2 - margin, y))

        return CGPoint(x: x, y: y)
    }

    // MARK: - Actions

    private func advanceToNextStep() {
        HapticFeedback.light()

        if let nextStep = currentStep.next {
            let animation: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.25)
            withAnimation(animation) {
                currentStepIndex = nextStep.rawValue
            }
        } else {
            completeTour()
        }
    }

    private func completeTour() {
        HapticFeedback.light()
        hasCompletedTour = true
        currentStepIndex = 0

        let animation: Animation? = reduceMotion ? nil : .easeOut(duration: 0.25)
        withAnimation(animation) {
            isActive = false
        }

        selectedTab = .today
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var selectedTab: MainTab = .today
        @State var isActive = true
        @State var targetFrames: [SpotlightTargetID: CGRect] = [:]

        var body: some View {
            ZStack {
                // Simulated tab view content
                VStack {
                    Spacer()
                    Text("Today Tab Content")
                    Spacer()

                    // Simulated tab bar
                    HStack {
                        ForEach([MainTab.today, .train, .explore, .schedule, .health], id: \.self) { tab in
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20))
                                Text(tab.title)
                                    .font(.caption2)
                            }
                            .foregroundStyle(tab == selectedTab ? Color.otisAccent : .secondary)
                            .frame(maxWidth: .infinity)
                            .spotlightTarget(.tab(tab))
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                }

                SpotlightTourOverlay(
                    selectedTab: $selectedTab,
                    isActive: $isActive,
                    targetFrames: targetFrames
                )
            }
            .onPreferenceChange(SpotlightTargetPreferenceKey.self) { frames in
                targetFrames = frames
            }
        }
    }

    return PreviewWrapper()
}
