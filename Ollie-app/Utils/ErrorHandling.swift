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
            return Strings.Errors.networkError
        case .fileError:
            return Strings.Errors.fileError
        case .dataCorrupted:
            return Strings.Errors.dataCorrupted
        case .unknown:
            return Strings.Errors.unknownError
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return Strings.Errors.networkRecovery
        case .fileError:
            return Strings.Errors.fileRecovery
        case .dataCorrupted:
            return Strings.Errors.dataRecovery
        case .unknown:
            return Strings.Errors.unknownRecovery
        }
    }
}

/// View modifier for showing error alerts
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .alert(Strings.Errors.title, isPresented: $isPresented) {
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
