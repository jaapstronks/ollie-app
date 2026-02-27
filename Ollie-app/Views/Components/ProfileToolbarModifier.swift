//
//  ProfileToolbarModifier.swift
//  Ollie-app
//
//  Reusable modifier to add profile/settings button to navigation toolbar
//

import SwiftUI
import OllieShared

/// View modifier that adds a ProfilePhotoButton to the navigation toolbar
struct ProfileToolbarModifier: ViewModifier {
    let profile: PuppyProfile?
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfilePhotoButton(profile: profile, action: action)
                }
            }
    }
}

extension View {
    /// Adds a profile photo button to the navigation toolbar (top trailing position)
    /// - Parameters:
    ///   - profile: The puppy profile (for showing profile photo)
    ///   - action: Action to perform when tapped (typically opens settings)
    func profileToolbar(profile: PuppyProfile?, action: @escaping () -> Void) -> some View {
        modifier(ProfileToolbarModifier(profile: profile, action: action))
    }
}
