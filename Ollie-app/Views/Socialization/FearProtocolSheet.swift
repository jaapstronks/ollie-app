//
//  FearProtocolSheet.swift
//  Ollie-app
//
//  Tips sheet shown when puppy has a fearful reaction

import SwiftUI
import OllieShared

/// Sheet showing tips for handling fearful reactions
struct FearProtocolSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Tips
                    tipsSection

                    // Dismiss button
                    Button {
                        dismiss()
                    } label: {
                        Text(Strings.Socialization.understood)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ollieAccent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle(Strings.Socialization.fearProtocolTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Warning icon
            ZStack {
                Circle()
                    .fill(Color.ollieWarning.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.ollieWarning)
            }

            Text("It's okay — this is a learning opportunity!")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Fearful reactions are normal, especially for new experiences. Here's how to help your puppy feel more confident.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Tips Section

    @ViewBuilder
    private var tipsSection: some View {
        VStack(spacing: 16) {
            tipRow(
                icon: "arrow.left.arrow.right",
                title: Strings.Socialization.fearProtocolTip1,
                description: "Create more space between your puppy and the stimulus"
            )

            tipRow(
                icon: "gift.fill",
                title: Strings.Socialization.fearProtocolTip2,
                description: "Look at scary thing → get treat → look away. Repeat."
            )

            tipRow(
                icon: "clock.fill",
                title: Strings.Socialization.fearProtocolTip3,
                description: "Better to do 2 good minutes than 10 stressful ones"
            )

            tipRow(
                icon: "hand.thumbsup.fill",
                title: Strings.Socialization.fearProtocolTip4,
                description: "Always try to end the session when puppy is calm"
            )

            tipRow(
                icon: "person.fill.questionmark",
                title: Strings.Socialization.fearProtocolTip5,
                description: "A certified trainer can help with persistent fears"
            )
        }
    }

    @ViewBuilder
    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.ollieAccent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.08))
        )
    }
}

// MARK: - Preview

#Preview {
    FearProtocolSheet()
}
