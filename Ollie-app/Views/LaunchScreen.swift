//
//  LaunchScreen.swift
//  Ollie-app
//

import SwiftUI

/// Launch screen shown while app loads
struct LaunchScreen: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.76, blue: 0.4), Color(red: 1.0, green: 0.65, blue: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Paw icon
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("Ollie")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Puppy Dagboek")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
