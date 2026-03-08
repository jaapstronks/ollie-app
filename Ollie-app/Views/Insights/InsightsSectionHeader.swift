//
//  InsightsSectionHeader.swift
//  Otis-app
//
//  Section header for Insights sections
//  NOTE: This is a convenience wrapper around SectionHeader for backward compatibility.
//  New code should use SectionHeader directly.
//

import SwiftUI

/// Section header used across Insights sections
/// @available(*, deprecated, message: "Use SectionHeader instead")
struct InsightsSectionHeader: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        SectionHeader(title: title, icon: icon, tint: tint)
    }
}
