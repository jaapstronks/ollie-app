//
//  SheetContent+Detents.swift
//  Otis-app
//
//  Presentation detent configurations for each sheet type
//

import SwiftUI
import OtisShared

extension SheetCoordinator.ActiveSheet {

    // MARK: - Presentation Detents

    /// Compact size class detents for this sheet type
    var compactDetents: Set<PresentationDetent> {
        switch self {
        // Small sheets (single action or picker)
        case .locationPicker, .momentSourcePicker:
            return [.height(200)]

        // Medium-small sheets
        case .quickLog(let type, _):
            if type == .uitlaten {
                return [.height(550)]
            } else if type.requiresLocation {
                return [.height(480)]
            } else {
                return [.height(380)]
            }

        case .endSleep:
            return [.height(420)]

        case .endCoverageGap:
            return [.height(450)]

        case .endActivity:
            return [.height(480)]

        // Medium sheets
        case .subscriptionSuccess, .gapDetection:
            return [.medium]

        case .potty:
            return [.height(580)]

        case .walkLog, .napLog:
            return [.height(520), .large]

        // Large sheets (with optional medium)
        case .allEvents:
            return [.fraction(0.75), .large]

        case .editEvent:
            return [.medium, .large]

        // Full large sheets
        case .otisPlus, .startActivity, .startCoverageGap, .catchUp,
             .developmentJourney, .socializationWindow, .medicalCare,
             .fullTimeline, .walkScheduleEditor, .crateTrainingGuide,
             .pottyTrainingGuide, .addAppointmentWithPrefill:
            return [.large]

        // Default for unspecified sheets
        default:
            return [.medium, .large]
        }
    }

    /// Regular size class detents for this sheet type
    var regularDetents: Set<PresentationDetent> {
        switch self {
        case .locationPicker, .momentSourcePicker, .endSleep, .endCoverageGap, .endActivity:
            return [.medium]

        case .subscriptionSuccess, .gapDetection:
            return [.medium]

        default:
            return [.medium, .large]
        }
    }
}
