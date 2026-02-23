//
//  LaunchScreen.swift
//  Ollie-app
//

import SwiftUI
import OllieShared

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

            VStack(spacing: 16) {
                Spacer()

                // Paw icon
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text(Strings.App.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                // Tagline at bottom
                Text(Strings.App.tagline)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
