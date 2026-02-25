//
//  ContentView.swift
//  OllieWatch
//
//  Main app structure with TabView for navigation

import SwiftUI

struct ContentView: View {
    @StateObject private var dataProvider = WatchDataProvider.shared

    var body: some View {
        TabView {
            // Tab 1: Status (potty timer + streak)
            StatusView(dataProvider: dataProvider)
                .containerBackground(.black.gradient, for: .tabView)

            // Tab 2: Quick Log buttons
            QuickLogView(dataProvider: dataProvider)
                .containerBackground(.black.gradient, for: .tabView)
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            dataProvider.refresh()
        }
    }
}

#Preview {
    ContentView()
}
