//
//  OnboardingSizeStep.swift
//  Ollie-app
//
//  Size category selection step for onboarding
//

import SwiftUI
import OllieShared

/// Size category selection step (shown only for custom breeds)
struct OnboardingSizeStep: View {
    let puppyName: String
    @Binding var sizeCategory: PuppyProfile.SizeCategory
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 24)

            // Header
            VStack(spacing: 12) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.ollieAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.sizeQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.bottom, 24)

            // Size options
            VStack(spacing: 10) {
                ForEach(Array(PuppyProfile.SizeCategory.allCases.enumerated()), id: \.element) { index, size in
                    SizeCategoryButton(
                        size: size,
                        isSelected: sizeCategory == size,
                        onSelect: {
                            HapticFeedback.light()
                            sizeCategory = size
                        }
                    )
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 15)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: hasAppeared)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                OnboardingBackButton(action: onBack)
                OnboardingNextButton(enabled: true, action: onNext)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(hasAppeared ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Size Category Button

private struct SizeCategoryButton: View {
    let size: PuppyProfile.SizeCategory
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(size.label)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(size.examples)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.ollieAccent : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.ollieAccent.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.ollieAccent.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
