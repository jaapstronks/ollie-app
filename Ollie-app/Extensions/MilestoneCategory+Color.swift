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
            return .ollieHealthRed
        case .developmental:
            return .ollieDevelopmental
        case .administrative:
            return .ollieAdministrative
        case .custom:
            return .ollieCustomOrange
        }
    }

    /// A lighter tint version of the category color for backgrounds
    var tintColor: Color {
        switch self {
        case .health:
            return .ollieHealthRedTint
        case .developmental:
            return .ollieDevelopmentalTint
        case .administrative:
            return .ollieAdministrativeTint
        case .custom:
            return .ollieCustomOrangeTint
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
            return .ollieAccent
        case .overdue:
            return .ollieWarning
        case .completed:
            return .ollieSuccess
        }
    }
}
