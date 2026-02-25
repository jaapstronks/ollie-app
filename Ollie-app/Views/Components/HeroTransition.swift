//
//  HeroTransition.swift
//  Ollie-app
//
//  Hero transition utilities for smooth view-to-view animations.
//  Creates visual continuity when navigating between related views.
//

import SwiftUI

// MARK: - Hero Transition Namespace

/// Shared namespace provider for hero transitions across the app
/// Use this when you need to share a namespace between parent and child views
@MainActor
final class HeroNamespace {
    let namespace: Namespace.ID

    init(namespace: Namespace.ID) {
        self.namespace = namespace
    }
}

// MARK: - Hero Source Modifier

/// Marks a view as the source of a hero transition
struct HeroSourceModifier: ViewModifier {
    let id: AnyHashable
    let namespace: Namespace.ID
    let isEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isEnabled && !reduceMotion {
            content
                .matchedGeometryEffect(id: id, in: namespace, isSource: true)
        } else {
            content
        }
    }
}

/// Marks a view as the destination of a hero transition
struct HeroDestinationModifier: ViewModifier {
    let id: AnyHashable
    let namespace: Namespace.ID
    let isEnabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isEnabled && !reduceMotion {
            content
                .matchedGeometryEffect(id: id, in: namespace, isSource: false)
        } else {
            content
        }
    }
}

extension View {
    /// Marks this view as the source of a hero transition
    func heroSource<ID: Hashable>(id: ID, in namespace: Namespace.ID, isEnabled: Bool = true) -> some View {
        modifier(HeroSourceModifier(id: AnyHashable(id), namespace: namespace, isEnabled: isEnabled))
    }

    /// Marks this view as the destination of a hero transition
    func heroDestination<ID: Hashable>(id: ID, in namespace: Namespace.ID, isEnabled: Bool = true) -> some View {
        modifier(HeroDestinationModifier(id: AnyHashable(id), namespace: namespace, isEnabled: isEnabled))
    }
}

// MARK: - Zoom Navigation Transition (iOS 18+)

/// View modifier that adds zoom navigation transition for iOS 18+
struct ZoomTransitionModifier: ViewModifier {
    let sourceID: AnyHashable
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), !reduceMotion {
            content
                .navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
    }
}

/// View modifier that marks a view as the source for zoom navigation
struct ZoomTransitionSourceModifier: ViewModifier {
    let id: AnyHashable
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), !reduceMotion {
            content
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

extension View {
    /// Adds a zoom navigation transition (iOS 18+)
    func zoomTransition<ID: Hashable>(sourceID: ID, in namespace: Namespace.ID) -> some View {
        modifier(ZoomTransitionModifier(sourceID: AnyHashable(sourceID), namespace: namespace))
    }

    /// Marks this view as the source for a zoom navigation transition (iOS 18+)
    func zoomTransitionSource<ID: Hashable>(id: ID, in namespace: Namespace.ID) -> some View {
        modifier(ZoomTransitionSourceModifier(id: AnyHashable(id), namespace: namespace))
    }
}

// MARK: - Sheet Hero Transition

/// Creates a smooth hero-like transition for sheet presentations
/// This simulates hero transitions for sheets where matchedGeometryEffect doesn't work
struct SheetHeroTransition<Content: View>: View {
    let isPresented: Bool
    let sourceFrame: CGRect
    @ViewBuilder let content: () -> Content

    @State private var animationProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            if isPresented {
                content()
                    .scaleEffect(reduceMotion ? 1 : currentScale)
                    .offset(reduceMotion ? .zero : currentOffset(in: geometry))
                    .opacity(animationProgress)
                    .onAppear {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            animationProgress = 1
                        }
                    }
            }
        }
    }

    private var currentScale: CGFloat {
        let minScale: CGFloat = 0.3
        return minScale + (1 - minScale) * animationProgress
    }

    private func currentOffset(in geometry: GeometryProxy) -> CGSize {
        let targetCenter = CGPoint(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2
        )
        let sourceCenter = CGPoint(
            x: sourceFrame.midX,
            y: sourceFrame.midY
        )

        return CGSize(
            width: (sourceCenter.x - targetCenter.x) * (1 - animationProgress),
            height: (sourceCenter.y - targetCenter.y) * (1 - animationProgress)
        )
    }
}

// MARK: - Animated Appear Modifier

/// Adds a subtle entrance animation to views
struct AnimatedAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 20)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.95)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay)) {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    /// Adds a subtle entrance animation when the view appears
    func animatedAppear(delay: Double = 0) -> some View {
        modifier(AnimatedAppearModifier(delay: delay))
    }
}

// MARK: - Staggered Animation Helper

/// Helper for creating staggered animations on a list of items
struct StaggeredAnimation {
    /// Calculate delay for an item at the given index
    static func delay(for index: Int, baseDelay: Double = 0.05, maxDelay: Double = 0.3) -> Double {
        min(Double(index) * baseDelay, maxDelay)
    }
}

// MARK: - Preview

#Preview("Hero Transitions") {
    struct HeroDemo: View {
        @Namespace private var namespace
        @State private var selectedItem: Int?

        var body: some View {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(0..<6, id: \.self) { index in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedItem = index
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.ollieAccent.opacity(0.3))
                                    .frame(height: 100)
                                    .overlay {
                                        Text("Item \(index)")
                                    }
                                    .heroSource(id: "item-\(index)", in: namespace)
                            }
                            .buttonStyle(.glassScale)
                            .animatedAppear(delay: StaggeredAnimation.delay(for: index))
                        }
                    }
                    .padding()
                }
                .navigationTitle("Hero Demo")
                .overlay {
                    if let selected = selectedItem {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedItem = nil
                                }
                            }

                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.ollieAccent)
                            .frame(width: 300, height: 400)
                            .overlay {
                                VStack {
                                    Text("Detail for Item \(selected)")
                                        .font(.title)
                                    Text("Tap outside to close")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .heroDestination(id: "item-\(selected)", in: namespace)
                    }
                }
            }
        }
    }

    return HeroDemo()
}

#Preview("Staggered Appear") {
    struct StaggeredDemo: View {
        var body: some View {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<10, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(Color.ollieAccent)
                                .frame(width: 40, height: 40)

                            VStack(alignment: .leading) {
                                Text("Item \(index)")
                                    .font(.headline)
                                Text("Description text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .animatedAppear(delay: StaggeredAnimation.delay(for: index))
                    }
                }
                .padding()
            }
        }
    }

    return StaggeredDemo()
}
