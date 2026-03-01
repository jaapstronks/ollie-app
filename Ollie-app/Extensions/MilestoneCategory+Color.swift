//
//  MilestoneCategory+Color.swift
//  Otis-app
//
//  Adds SwiftUI Color support to MilestoneCategory

import SwiftUI
import OtisShared

extension MilestoneCategory {
    /// The color associated with this milestone category
    var color: Color {
        switch self {
        case .health:
            return .otisHealthRed
        case .developmental:
            return .otisDevelopmental
        case .administrative:
            return .otisAdministrative
        case .custom:
            return .otisCustomOrange
        }
    }

    /// A lighter tint version of the category color for backgrounds
    var tintColor: Color {
        switch self {
        case .health:
            return .otisHealthRedTint
        case .developmental:
            return .otisDevelopmentalTint
        case .administrative:
            return .otisAdministrativeTint
        case .custom:
            return .otisCustomOrangeTint
        }
    }
}

extension MilestoneStatus {
    /// The color associated with this milestone status
    var color: Color {
        switch self {
        case .upcoming:
            return .secondary
        case .nextUp:
            return .otisAccent
        case .overdue:
            return .otisWarning
        case .completed:
            return .otisSuccess
        }
    }
}
