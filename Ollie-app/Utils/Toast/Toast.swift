//
//  Toast.swift
//  Ollie-app
//
//  Lightweight toast notification model for fleeting feedback messages.

import SwiftUI

// MARK: - Toast Type

enum ToastType {
    case success
    case info
    case warning
    case error

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .ollieSuccess
        case .info: return .ollieInfo
        case .warning: return .ollieWarning
        case .error: return .ollieDanger
        }
    }

    var defaultDuration: TimeInterval {
        switch self {
        case .success: return 2.0
        case .info: return 3.0
        case .warning: return 4.0
        case .error: return 5.0
        }
    }
}

// MARK: - Toast Model

struct Toast: Identifiable, Equatable {
    let id: UUID
    let type: ToastType
    let message: String
    let duration: TimeInterval

    init(type: ToastType, message: String, duration: TimeInterval? = nil) {
        self.id = UUID()
        self.type = type
        self.message = message
        self.duration = duration ?? type.defaultDuration
    }
}
