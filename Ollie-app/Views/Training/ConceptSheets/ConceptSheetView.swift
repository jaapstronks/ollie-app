//
//  ConceptSheetView.swift
//  Otis-app
//
//  Shared base view for rich concept explanation sheets
//

import SwiftUI

/// Reusable concept sheet view with rich educational content
struct ConceptSheetView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let explanation: String
    let keyPoints: [String]
    let exampleTitle: String
    let exampleText: String
    let onAcknowledge: () -> Void
    let onDismiss: () -> Void

    @State private var isAcknowledged = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    // Main explanation
                    explanationSection

                    // Key points
                    keyPointsSection

                    // Example
                    exampleSection

                    // Acknowledge checkbox
                    acknowledgeSection
                }
                .padding()
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.close) {
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(iconColor)
                .frame(maxWidth: .infinity)

            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // Subtitle
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        Text(explanation)
            .font(.body)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Key Points Section

    private var keyPointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "pin.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                Text(Strings.Training.Concepts.keyPoints)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(keyPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.otisAccent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(point)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    // MARK: - Example Section

    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                Text(Strings.Training.Concepts.example)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(exampleTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(exampleText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.yellow.opacity(0.1) : Color.yellow.opacity(0.15))
        )
    }

    // MARK: - Acknowledge Section

    private var acknowledgeSection: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isAcknowledged.toggle()
            }
            if isAcknowledged {
                HapticFeedback.success()
                onAcknowledge()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isAcknowledged ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(isAcknowledged ? Color.otisSuccess : .secondary)

                Text(Strings.Training.Concepts.iUnderstand)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isAcknowledged ? Color.otisSuccess : .primary)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isAcknowledged ? Color.otisSuccess : Color.secondary.opacity(0.3), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isAcknowledged ? Color.otisSuccess.opacity(0.1) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ConceptSheetView(
        icon: "brain.head.profile",
        iconColor: .purple,
        title: "Operant Conditioning",
        subtitle: "Learning through self-discovery",
        explanation: "In operant conditioning, you stay passive while your puppy self-discovers the desired behavior.",
        keyPoints: [
            "You stay quiet and still",
            "Wait for the behavior",
            "Click at the exact moment"
        ],
        exampleTitle: "Teaching Watch Me",
        exampleText: "Sit quietly with your hands behind your back.",
        onAcknowledge: {},
        onDismiss: {}
    )
}
