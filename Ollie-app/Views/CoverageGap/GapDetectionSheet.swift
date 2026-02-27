//
//  GapDetectionSheet.swift
//  Ollie-app
//
//  Sheet shown on app launch when a potential coverage gap is detected
//

import SwiftUI
import OllieShared

/// Sheet prompting user about a detected coverage gap
struct GapDetectionSheet: View {
    let hours: Int
    let puppyName: String
    let suggestedStartTime: Date
    let onLogCoverage: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "clock.badge.questionmark.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)
                    .padding(.top, 40)

                // Message
                VStack(spacing: 12) {
                    Text(Strings.CoverageGap.detectionPrompt(hours: hours, name: puppyName))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // Yes - log coverage gap
                    Button {
                        HapticFeedback.medium()
                        onLogCoverage()
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.clock.fill")
                            Text(Strings.CoverageGap.yesLogCoverage)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // No - just forgot to log
                    Button {
                        HapticFeedback.selection()
                        onDismiss()
                    } label: {
                        Text(Strings.CoverageGap.noIForgot)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GapDetectionSheet(
        hours: 18,
        puppyName: "Ollie",
        suggestedStartTime: Date().addingTimeInterval(-18 * 3600),
        onLogCoverage: {},
        onDismiss: {}
    )
}
