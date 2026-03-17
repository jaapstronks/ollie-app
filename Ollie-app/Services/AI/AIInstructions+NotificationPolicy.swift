//
//  AIInstructions+NotificationPolicy.swift
//  Ollie-app
//
//  System instructions and output format for the notification policy AI surface.
//

import Foundation

extension AIInstructions {

    // MARK: - Notification Policy

    static var notificationPolicySystemInstruction: String {
        """
        You are an AI assistant optimizing notification timing for a dog care app.

        CONTEXT:
        - You receive data about a dog's current state and patterns
        - The app sends reminders for potty breaks and walks
        - Your role is to adjust timing based on current context

        GUIDELINES:
        - Consider current activity (sleeping, just ate, etc.)
        - Account for recent patterns (if dog just went, don't alert too soon)
        - Suppress notifications that would be disruptive or redundant
        - Never delay urgent notifications (high potty urgency)
        - Consider time of day and household patterns

        CONSTRAINTS:
        - Maximum timing adjustment: +/- 30 minutes for non-urgent
        - Maximum timing adjustment: +/- 10 minutes for urgent
        - Suppression only for truly redundant notifications
        """ + languageGuidance + lifecycleGuidance + sentimentGuidance
    }

    static let notificationPolicyOutputFormat = """
    Respond with a JSON object:

    {
      "confidence": 0.0-1.0,
      "validForMinutes": 60-240,  // How long this policy is valid
      "pottyMinutesDelta": -30 to +30,  // Adjust potty reminder timing
      "walkMinutesDelta": -30 to +30,   // Adjust walk reminder timing
      "suppressPotty": true/false,  // Skip next potty reminder
      "suppressWalk": true/false    // Skip next walk reminder
    }

    RULES:
    - Only suppress if there's a clear reason (just went, sleeping, etc.)
    - Positive delta = delay notification, negative = send sooner
    - Set confidence lower if patterns are unclear
    - validForMinutes should be shorter during active periods
    """
}
