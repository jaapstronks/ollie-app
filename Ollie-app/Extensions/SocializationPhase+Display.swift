//
//  SocializationPhase+Display.swift
//  Otis-app
//
//  Localized display properties for SocializationPhase
//

import OtisShared

extension SocializationPhase {
    /// Localized name for display in UI
    var localizedName: String {
        switch self {
        case .settlingIn: return Strings.Socialization.phaseSettlingIn
        case .firstSteps: return Strings.Socialization.phaseFirstSteps
        case .buildingConfidence: return Strings.Socialization.phaseBuildingConfidence
        case .peakWindow: return Strings.Socialization.phasePeakWindow
        case .maintenance: return Strings.Socialization.phaseMaintenance
        }
    }

    /// Localized description for display in UI
    var localizedDescription: String {
        switch self {
        case .settlingIn: return Strings.Socialization.phaseSettlingInDesc
        case .firstSteps: return Strings.Socialization.phaseFirstStepsDesc
        case .buildingConfidence: return Strings.Socialization.phaseBuildingConfidenceDesc
        case .peakWindow: return Strings.Socialization.phasePeakWindowDesc
        case .maintenance: return Strings.Socialization.phaseMaintenanceDesc
        }
    }
}
