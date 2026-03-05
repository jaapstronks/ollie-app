//
//  DevelopmentStage+Display.swift
//  Otis-app
//
//  UI extension for DevelopmentStage - adds localized labels and colors
//

import SwiftUI
import OtisShared

extension DevelopmentStage {

    /// Localized title for this stage
    var title: String {
        switch self {
        case .neonatal: return Strings.Development.stageNeonatal
        case .transitional: return Strings.Development.stageTransitional
        case .socialization: return Strings.Development.stageSocialization
        case .juvenile: return Strings.Development.stageJuvenile
        case .adolescent: return Strings.Development.stageAdolescent
        case .adult: return Strings.Development.stageAdult
        }
    }

    /// Localized age range description
    var ageRange: String {
        switch self {
        case .neonatal: return Strings.Development.stageNeonatalDesc
        case .transitional: return Strings.Development.stageTransitionalDesc
        case .socialization: return Strings.Development.stageSocializationDesc
        case .juvenile: return Strings.Development.stageJuvenileDesc
        case .adolescent: return Strings.Development.stageAdolescentDesc
        case .adult: return Strings.Development.stageAdultDesc
        }
    }

    /// Theme color for this stage
    var color: Color {
        switch self {
        case .neonatal: return .otisSleep
        case .transitional: return .otisInfo
        case .socialization: return .otisAccent
        case .juvenile: return .otisSuccess
        case .adolescent: return .otisWarning
        case .adult: return .secondary
        }
    }
}
