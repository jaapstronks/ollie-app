//
//  ToastView.swift
//  Otis-app
//
//  Toast notification UI component.

import SwiftUI

struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .foregroundStyle(toast.type.color)
                .font(.system(size: 18, weight: .semibold))

            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .onTapGesture(perform: onDismiss)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.height < -20 {
                        onDismiss()
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(toast.message)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityHint(Strings.Toast.dismissHint)
    }
}

// MARK: - Toast Container Modifier

struct ToastContainerModifier: ViewModifier {
    @Environment(ToastManager.self) private var toastManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast, onDismiss: toastManager.dismiss)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toastManager.currentToast?.id)
    }
}

extension View {
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}

// MARK: - Preview

#Preview("Success Toast") {
    VStack {
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.otisBackgroundLight)
    .overlay(alignment: .top) {
        ToastView(
            toast: Toast(type: .success, message: "Logged!"),
            onDismiss: {}
        )
        .padding(.top, 60)
    }
}

#Preview("Warning Toast") {
    VStack {
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.otisBackgroundLight)
    .overlay(alignment: .top) {
        ToastView(
            toast: Toast(type: .warning, message: "Go outside now!"),
            onDismiss: {}
        )
        .padding(.top, 60)
    }
}

#Preview("Error Toast") {
    VStack {
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.otisBackgroundLight)
    .overlay(alignment: .top) {
        ToastView(
            toast: Toast(type: .error, message: "Could not save. Try again."),
            onDismiss: {}
        )
        .padding(.top, 60)
    }
}
