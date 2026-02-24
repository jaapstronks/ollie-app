//
//  SiriSection.swift
//  Ollie-app
//
//  Siri & Shortcuts help section for SettingsView

import SwiftUI

/// Siri & Shortcuts help section explaining voice commands
struct SiriSection: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            // Explanation
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(Strings.Siri.helpTitle)
                        .font(.subheadline.weight(.medium))
                } icon: {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(Color.ollieAccent)
                }

                Text(Strings.Siri.helpDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            // Example commands
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Siri.exampleCommands)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                ForEach(examplePhrases, id: \.self) { phrase in
                    HStack(spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(phrase)
                            .font(.callout)
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)

            // Open Shortcuts app button
            Button {
                if let url = URL(string: "shortcuts://") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Strings.Siri.openShortcuts)
                            Text(Strings.Siri.openShortcutsDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(Color.ollieAccent)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        } header: {
            Text(Strings.Siri.sectionTitle)
        } footer: {
            Text(Strings.Siri.helpFooter)
        }
    }

    private var examplePhrases: [String] {
        [
            Strings.Siri.examplePeedOutside,
            Strings.Siri.exampleSleeping,
            Strings.Siri.exampleStatus
        ]
    }
}

#Preview {
    Form {
        SiriSection()
    }
}
