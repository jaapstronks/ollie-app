//
//  TabBarSpotlightTargets.swift
//  Ollie-app
//
//  Invisible overlay that provides spotlight targets for tab bar items

import SwiftUI

/// Invisible view that registers spotlight targets for each tab bar item
struct TabBarSpotlightTargets: View {
    private let tabs: [MainTab] = [.today, .train, .explore, .schedule, .health]
    private let tabBarHeight: CGFloat = 49

    var body: some View {
        GeometryReader { geo in
            let tabWidth = geo.size.width / CGFloat(tabs.count)
            let safeAreaBottom = geo.safeAreaInsets.bottom

            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Color.clear
                        .frame(width: tabWidth, height: tabBarHeight + safeAreaBottom)
                        .spotlightTarget(.tab(tab))
                }
            }
            .offset(y: tabBarHeight) // Push down into actual tab bar area
        }
        .frame(height: tabBarHeight)
        .allowsHitTesting(false)
    }
}
