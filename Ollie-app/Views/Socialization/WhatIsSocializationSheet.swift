//
//  WhatIsSocializationSheet.swift
//  Otis-app
//
//  Educational sheet explaining what socialization is

import SwiftUI

/// Sheet explaining what socialization actually means
struct WhatIsSocializationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero section
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.otisAccent)

                        Text(Strings.Socialization.infoTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)

                    // Goal section
                    infoSection(
                        icon: "target",
                        title: Strings.Socialization.infoGoalTitle,
                        body: Strings.Socialization.infoGoalBody,
                        color: .otisAccent
                    )

                    // Positive section
                    infoSection(
                        icon: "checkmark.circle",
                        title: Strings.Socialization.infoPositiveTitle,
                        body: Strings.Socialization.infoPositiveBody,
                        color: .otisSuccess
                    )

                    // Trap section
                    infoSection(
                        icon: "exclamationmark.triangle",
                        title: Strings.Socialization.infoTrapTitle,
                        body: Strings.Socialization.infoTrapBody,
                        color: .otisWarning
                    )

                    // Distance section
                    infoSection(
                        icon: "ruler",
                        title: Strings.Socialization.infoDistanceTitle,
                        body: Strings.Socialization.infoDistanceBody,
                        color: .otisInfo
                    )

                    // Practice section
                    infoSection(
                        icon: "list.bullet.clipboard",
                        title: Strings.Socialization.infoPracticeTitle,
                        body: Strings.Socialization.infoPracticeBody,
                        color: .otisPurple
                    )

                    // Summary
                    Text(Strings.Socialization.infoSummary)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.otisAccent)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.otisAccent.opacity(colorScheme == .dark ? 0.15 : 0.08))
                        )
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private func infoSection(icon: String, title: String, body: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    WhatIsSocializationSheet()
}
