//
//  SoundFeedback.swift
//  Ollie-app
//
//  Subtle audio feedback for key interactions.
//  Sounds confirm actions and reduce "did it work?" anxiety.
//

import AVFoundation
import SwiftUI

/// Audio feedback utilities for UI interactions
enum SoundFeedback {

    // MARK: - Sound Types

    /// Available system sounds for feedback
    enum Sound {
        /// Soft pop - for successful quick logs
        case logSuccess
        /// Cheerful tone - for streak milestones
        case milestone
        /// Gentle confirmation - for saves and completions
        case confirm
        /// Light tick - for selections and toggles
        case tick
        /// Subtle swoosh - for deletions
        case delete
        /// Soft alert - for warnings
        case alert

        /// System sound ID (using iOS system sounds for reliability)
        var soundID: SystemSoundID {
            switch self {
            case .logSuccess:
                return 1004  // Soft pop (Tock)
            case .milestone:
                return 1025  // Celebratory (New Mail)
            case .confirm:
                return 1001  // Light confirmation (Mail Sent)
            case .tick:
                return 1104  // Light tick
            case .delete:
                return 1155  // Swoosh
            case .alert:
                return 1007  // Soft alert
            }
        }
    }

    // MARK: - Settings

    /// UserDefaults key for sound enabled preference
    private static let soundsEnabledKey = "soundFeedbackEnabled"

    /// Whether sound feedback is enabled
    static var isEnabled: Bool {
        get {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: soundsEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: soundsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: soundsEnabledKey)
        }
    }

    // MARK: - Playback

    /// Play a sound if sound feedback is enabled
    static func play(_ sound: Sound) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(sound.soundID)
    }

    // MARK: - Convenience Methods

    /// Play sound for successful event logging
    static func logSuccess() {
        play(.logSuccess)
    }

    /// Play sound for milestone achievement
    static func milestone() {
        play(.milestone)
    }

    /// Play sound for save/confirm actions
    static func confirm() {
        play(.confirm)
    }

    /// Play sound for selections
    static func tick() {
        play(.tick)
    }

    /// Play sound for deletions
    static func delete() {
        play(.delete)
    }

    /// Play alert sound
    static func alert() {
        play(.alert)
    }
}

// MARK: - Combined Feedback

/// Combines haptic and sound feedback for richer interactions
enum FeedbackManager {

    /// Success feedback - haptic + optional sound
    static func success(withSound: Bool = true) {
        HapticFeedback.success()
        if withSound {
            SoundFeedback.confirm()
        }
    }

    /// Log success feedback - medium haptic + pop sound
    static func logEvent() {
        HapticFeedback.medium()
        SoundFeedback.logSuccess()
    }

    /// Milestone celebration - strong haptic + milestone sound
    static func milestone() {
        HapticFeedback.success()
        SoundFeedback.milestone()
    }

    /// Selection feedback - light haptic + tick sound
    static func selection(withSound: Bool = false) {
        HapticFeedback.selection()
        if withSound {
            SoundFeedback.tick()
        }
    }

    /// Warning feedback - warning haptic + alert sound
    static func warning(withSound: Bool = false) {
        HapticFeedback.warning()
        if withSound {
            SoundFeedback.alert()
        }
    }

    /// Delete feedback - warning haptic + swoosh sound
    static func delete(withSound: Bool = true) {
        HapticFeedback.warning()
        if withSound {
            SoundFeedback.delete()
        }
    }

    /// Error feedback - error haptic, no sound (sounds on errors can be annoying)
    static func error() {
        HapticFeedback.error()
    }
}

// MARK: - SwiftUI Preference

/// Environment key for sound feedback preference
private struct SoundFeedbackEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var soundFeedbackEnabled: Bool {
        get { self[SoundFeedbackEnabledKey.self] }
        set { self[SoundFeedbackEnabledKey.self] = newValue }
    }
}

// MARK: - Preview Helper

#if DEBUG
struct SoundFeedbackPreview: View {
    var body: some View {
        List {
            Section("Sound Feedback") {
                Button("Log Success") {
                    SoundFeedback.logSuccess()
                }

                Button("Milestone") {
                    SoundFeedback.milestone()
                }

                Button("Confirm") {
                    SoundFeedback.confirm()
                }

                Button("Tick") {
                    SoundFeedback.tick()
                }

                Button("Delete") {
                    SoundFeedback.delete()
                }

                Button("Alert") {
                    SoundFeedback.alert()
                }
            }

            Section("Combined Feedback") {
                Button("Success") {
                    FeedbackManager.success()
                }

                Button("Log Event") {
                    FeedbackManager.logEvent()
                }

                Button("Milestone") {
                    FeedbackManager.milestone()
                }

                Button("Delete") {
                    FeedbackManager.delete()
                }
            }

            Section("Settings") {
                Toggle("Sound Enabled", isOn: Binding(
                    get: { SoundFeedback.isEnabled },
                    set: { SoundFeedback.isEnabled = $0 }
                ))
            }
        }
        .navigationTitle("Sound Feedback")
    }
}

#Preview("Sound Feedback") {
    NavigationStack {
        SoundFeedbackPreview()
    }
}
#endif
