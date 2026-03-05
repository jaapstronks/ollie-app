//
//  iPadLayoutHelpers.swift
//  Otis-app
//
//  Utilities for adaptive iPad layouts
//

import SwiftUI

// MARK: - Layout Constants

/// Constants for iPad-optimized layouts
enum iPadLayout {
    /// Maximum width for content on iPad (keeps cards readable)
    static let maxContentWidth: CGFloat = 700

    /// Maximum width for wide content like galleries
    static let maxWideContentWidth: CGFloat = 900

    /// Minimum width for adaptive grid items
    static let adaptiveGridMinWidth: CGFloat = 120

    /// Minimum width for larger adaptive grid items (e.g., diary cards)
    static let adaptiveGridLargeMinWidth: CGFloat = 300
}

// MARK: - Adaptive Container Modifier

/// View modifier that constrains content width on iPad while keeping it full-width on iPhone
struct AdaptiveContainerModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let maxWidth: CGFloat
    let alignment: Alignment

    init(maxWidth: CGFloat = iPadLayout.maxContentWidth, alignment: Alignment = .center) {
        self.maxWidth = maxWidth
        self.alignment = alignment
    }

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: horizontalSizeClass == .regular ? maxWidth : .infinity)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

// MARK: - Adaptive Grid Columns

/// Returns appropriate grid columns based on size class
/// - Parameters:
///   - minWidth: Minimum width for each grid item
///   - spacing: Spacing between items
/// - Returns: Array of GridItem for use with LazyVGrid
func adaptiveGridColumns(minWidth: CGFloat = iPadLayout.adaptiveGridMinWidth, spacing: CGFloat = 2) -> [GridItem] {
    [GridItem(.adaptive(minimum: minWidth), spacing: spacing)]
}

/// Returns fixed grid columns for compact layouts (iPhone)
/// - Parameters:
///   - count: Number of columns
///   - spacing: Spacing between items
/// - Returns: Array of GridItem for use with LazyVGrid
func fixedGridColumns(count: Int = 3, spacing: CGFloat = 2) -> [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
}

// MARK: - Adaptive Grid View

/// Grid that adapts column count based on size class
struct AdaptivePhotoGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let spacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat = 2, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content()
        }
    }

    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            // iPad: adaptive columns
            return adaptiveGridColumns(spacing: spacing)
        } else {
            // iPhone: fixed 3 columns
            return fixedGridColumns(count: 3, spacing: spacing)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Constrains content width on iPad while keeping full width on iPhone
    /// - Parameters:
    ///   - maxWidth: Maximum width on iPad (default: 700)
    ///   - alignment: Alignment within the container (default: center)
    func adaptiveContainer(maxWidth: CGFloat = iPadLayout.maxContentWidth, alignment: Alignment = .center) -> some View {
        modifier(AdaptiveContainerModifier(maxWidth: maxWidth, alignment: alignment))
    }

    /// Applies different presentation detents based on size class
    /// - Parameters:
    ///   - compactDetents: Detents to use on iPhone (compact)
    ///   - regularDetents: Detents to use on iPad (regular)
    func adaptivePresentationDetents(
        compact compactDetents: Set<PresentationDetent>,
        regular regularDetents: Set<PresentationDetent>
    ) -> some View {
        modifier(AdaptivePresentationDetentsModifier(
            compactDetents: compactDetents,
            regularDetents: regularDetents
        ))
    }
}

// MARK: - Adaptive Presentation Detents

/// View modifier that applies different presentation detents based on size class
struct AdaptivePresentationDetentsModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let compactDetents: Set<PresentationDetent>
    let regularDetents: Set<PresentationDetent>

    func body(content: Content) -> some View {
        content
            .presentationDetents(horizontalSizeClass == .regular ? regularDetents : compactDetents)
    }
}

// MARK: - Size Class Environment Helper

/// Environment key for checking if current device is iPad in regular width
struct IsRegularWidthKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isRegularWidth: Bool {
        get { self[IsRegularWidthKey.self] }
        set { self[IsRegularWidthKey.self] = newValue }
    }
}

// MARK: - Popover/Sheet Adaptive Modifier

/// Modifier that shows popover on iPad and sheet on iPhone
struct AdaptivePopoverModifier<PopoverContent: View>: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var isPresented: Bool
    let popoverContent: () -> PopoverContent
    let sheetDetents: Set<PresentationDetent>

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .popover(isPresented: $isPresented) {
                    popoverContent()
                }
        } else {
            content
                .sheet(isPresented: $isPresented) {
                    popoverContent()
                        .presentationDetents(sheetDetents)
                }
        }
    }
}

extension View {
    /// Shows a popover on iPad and a sheet on iPhone
    /// - Parameters:
    ///   - isPresented: Binding to control presentation
    ///   - sheetDetents: Detents to use for sheet on iPhone
    ///   - content: Content to present
    func adaptivePopover<Content: View>(
        isPresented: Binding<Bool>,
        sheetDetents: Set<PresentationDetent> = [.medium],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(AdaptivePopoverModifier(
            isPresented: isPresented,
            popoverContent: content,
            sheetDetents: sheetDetents
        ))
    }
}
