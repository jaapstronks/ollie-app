//
//  ToastManager.swift
//  Otis-app
//
//  Observable manager for toast notifications with queue support.

import SwiftUI
import UIKit

@MainActor
@Observable
final class ToastManager {
    private(set) var currentToast: Toast?
    private var queue: [Toast] = []
    private var dismissTask: Task<Void, Never>?

    func show(_ toast: Toast) {
        queue.append(toast)
        showNextIfNeeded()
    }

    func show(_ message: String, type: ToastType = .info) {
        show(Toast(type: type, message: message))
    }

    /// Convenience: show success toast for event logging
    func showLogged() {
        show(Strings.Toast.logged, type: .success)
    }

    /// Convenience: show success toast for saving
    func showSaved() {
        show(Strings.Toast.saved, type: .success)
    }

    /// Convenience: show error toast
    func showError(_ message: String? = nil) {
        show(message ?? Strings.Toast.couldNotSave, type: .error)
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            currentToast = nil
        }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            showNextIfNeeded()
        }
    }

    private func showNextIfNeeded() {
        guard currentToast == nil, !queue.isEmpty else { return }

        let toast = queue.removeFirst()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentToast = toast
        }

        // Announce to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: toast.message)

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(toast.duration))
            if !Task.isCancelled {
                dismiss()
            }
        }
    }
}
