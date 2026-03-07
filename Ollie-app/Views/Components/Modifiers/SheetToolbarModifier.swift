//
//  SheetToolbarModifier.swift
//  Otis-app
//
//  Reusable toolbar modifier for sheet navigation bars with cancel/save actions

import SwiftUI

/// Configuration for sheet toolbar buttons
struct SheetToolbarConfig {
    var cancelLabel: String = Strings.Common.cancel
    var saveLabel: String = Strings.Common.save
    var canSave: Bool = true
    var showCancel: Bool = true
    var showSave: Bool = true
}

/// ViewModifier that adds standard cancel/save toolbar to sheets
struct SheetToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let config: SheetToolbarConfig
    let onCancel: (() -> Void)?
    let onSave: () -> Void

    init(
        config: SheetToolbarConfig = SheetToolbarConfig(),
        onCancel: (() -> Void)? = nil,
        onSave: @escaping () -> Void
    ) {
        self.config = config
        self.onCancel = onCancel
        self.onSave = onSave
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                if config.showCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(config.cancelLabel) {
                            if let onCancel = onCancel {
                                onCancel()
                            } else {
                                dismiss()
                            }
                        }
                    }
                }

                if config.showSave {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(config.saveLabel) {
                            onSave()
                        }
                        .disabled(!config.canSave)
                    }
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds standard cancel/save toolbar to a sheet
    /// - Parameters:
    ///   - canSave: Whether the save button should be enabled
    ///   - saveLabel: Label for the save button (default: "Save")
    ///   - onCancel: Optional custom cancel action (defaults to dismiss)
    ///   - onSave: Action to perform when save is tapped
    func sheetToolbar(
        canSave: Bool = true,
        saveLabel: String = Strings.Common.save,
        onCancel: (() -> Void)? = nil,
        onSave: @escaping () -> Void
    ) -> some View {
        modifier(SheetToolbarModifier(
            config: SheetToolbarConfig(
                saveLabel: saveLabel,
                canSave: canSave
            ),
            onCancel: onCancel,
            onSave: onSave
        ))
    }

    /// Adds cancel-only toolbar to a sheet (for informational sheets)
    /// - Parameters:
    ///   - cancelLabel: Label for the cancel button (default: "Cancel")
    ///   - onCancel: Optional custom cancel action (defaults to dismiss)
    func sheetCancelToolbar(
        cancelLabel: String = Strings.Common.cancel,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(SheetToolbarModifier(
            config: SheetToolbarConfig(
                cancelLabel: cancelLabel,
                showSave: false
            ),
            onCancel: onCancel,
            onSave: {}
        ))
    }

    /// Adds close-only toolbar to a sheet
    /// - Parameter onClose: Optional custom close action (defaults to dismiss)
    func sheetCloseToolbar(onClose: (() -> Void)? = nil) -> some View {
        sheetCancelToolbar(cancelLabel: Strings.Common.close, onCancel: onClose)
    }
}
