//
//  ErrorHandling.swift
//  Ollie-app
//

import SwiftUI
import OllieShared
import Combine

/// App error types with user-friendly messages
enum AppError: LocalizedError {
    case networkError(underlying: Error)
    case fileError(underlying: Error)
    case dataCorrupted
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Netwerkfout"
        case .fileError:
            return "Bestandsfout"
        case .dataCorrupted:
            return "Data beschadigd"
        case .unknown:
            return "Onbekende fout"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Controleer je internetverbinding en probeer het opnieuw."
        case .fileError:
            return "Er is iets misgegaan bij het opslaan. Probeer het opnieuw."
        case .dataCorrupted:
            return "De data kon niet worden gelezen. Probeer de app opnieuw te starten."
        case .unknown:
            return "Probeer het later opnieuw."
        }
    }
}

/// View modifier for showing error alerts
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .alert("Fout", isPresented: $isPresented) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let appError = error as? AppError {
                    Text("\(appError.localizedDescription)\n\n\(appError.recoverySuggestion ?? "")")
                } else if let localizedError = error as? LocalizedError {
                    Text(localizedError.localizedDescription)
                } else if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    /// Show an error alert when error is non-nil
    func errorAlert(error: Binding<Error?>, isPresented: Binding<Bool>) -> some View {
        modifier(ErrorAlert(error: error, isPresented: isPresented))
    }
}

/// Observable error state for view models
@MainActor
class ErrorState: ObservableObject {
    @Published var currentError: Error?
    @Published var showError: Bool = false

    func handle(_ error: Error) {
        currentError = error
        showError = true
        HapticFeedback.error()
    }

    func clear() {
        currentError = nil
        showError = false
    }
}
