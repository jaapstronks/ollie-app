//
//  MilestoneCategory+Color.swift
//  Ollie-app
//
//  Adds SwiftUI Color support to MilestoneCategory

import SwiftUI
import OllieShared

extension MilestoneCategory {
    /// The color associated with this milestone category
    var color: Color {
        switch self {
        case .health:
            return .red
        case .developmental:
            return .purple
        case .administrative:
            return .blue
        case .custom:
            return .orange
        }
    }

    /// A lighter tint version of the category color for backgrounds
    var tintColor: Color {
        color.opacity(0.15)
    }
}

extension MilestoneStatus {
    /// The color associated with this milestone status
    var color: Color {
        switch self {
        case .upcoming:
            return .secondary
        case .nextUp:
            return .ollieAccent
        case .overdue:
            return .ollieWarning
        case .completed:
            return .ollieSuccess
        }
    }
}
