//
//  CelebrationPreviewViews.swift
//  Ollie-app
//
//  Preview views for celebration settings
//  Extracted from CelebrationSettingsView.swift
//

import SwiftUI
import OllieShared

// MARK: - Tier 1 Preview Button

/// Tier 1 preview button with inline celebration
struct CelebrationTier1PreviewButton: View {
    @State private var celebrationTrigger = false

    var body: some View {
        Button {
            celebrationTrigger = true
            HapticFeedback.light()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tier 1: Subtle")
                        .font(.subheadline.weight(.medium))
                    Text("Inline shimmer effect")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.ollieAccent)
            }
            .padding()
            .background(Color.ollieAccent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .celebration(style: .quickLog, trigger: $celebrationTrigger)
    }
}

// MARK: - Tier 2 Preview Wrapper

/// Wrapper for Tier 2 preview that manages its own state
struct CelebrationTier2PreviewWrapper: View {
    @Binding var isPresented: Bool
    @State private var showContent = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(showContent ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Card content
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Badge
                    ZStack {
                        Circle()
                            .fill(Color.ollieSuccess.opacity(0.15))
                            .frame(width: 120, height: 120)

                        Circle()
                            .fill(Color.ollieSuccess.gradient)
                            .frame(width: 88, height: 88)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    // Text
                    VStack(spacing: 8) {
                        Text("First Vaccination")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Keep up the great work!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                dismiss()
                            } label: {
                                Label("Add Photo", systemImage: "camera.fill")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.glassPill(tint: .success))

                            Button {
                                dismiss()
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.glassSecondary)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.glassPrimary(tint: .accent))
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: Color.ollieSuccess.opacity(0.3), radius: 20, y: 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .offset(y: showContent ? 0 : 300)
                .opacity(showContent ? 1 : 0)

                Spacer(minLength: 0)
            }

            // Confetti
            CelebrationView(style: .milestone, isActive: $showConfetti)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
            HapticFeedback.success()
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Tier 3 Preview Wrapper

/// Wrapper for Tier 3 preview that manages its own state
struct CelebrationTier3PreviewWrapper: View {
    @Binding var isPresented: Bool
    @State private var phase = 0
    @State private var confettiBurst1 = false
    @State private var confettiBurst2 = false
    @State private var confettiBurst3 = false
    @State private var contentVisible = false
    @State private var buttonsVisible = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.ollieAccent.opacity(0.3),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Badge
                ZStack {
                    Circle()
                        .fill(Color.ollieAccent.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)

                    Circle()
                        .fill(Color.ollieAccent.gradient)
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.ollieAccent.opacity(0.5), radius: 20)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("14")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.3)))
                        .offset(x: 55, y: -55)
                }
                .scaleEffect(phase >= 1 ? 1 : 0.3)
                .opacity(phase >= 1 ? 1 : 0)

                // Text
                VStack(spacing: 12) {
                    Text("Potty Trained!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text("You did it!")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)

                Spacer()

                // Buttons
                if buttonsVisible {
                    VStack(spacing: 12) {
                        Text("Capture this moment")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Button {
                            isPresented = false
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.glassPrimary(tint: .accent))

                        Button {
                            isPresented = false
                        } label: {
                            Label("Add from Library", systemImage: "photo.on.rectangle")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.glassSecondary)

                        Button {
                            isPresented = false
                        } label: {
                            Text("Maybe Later")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
                    .frame(height: 60)
            }

            // Confetti bursts
            CelebrationView(style: .milestone, isActive: $confettiBurst1)
            CelebrationView(style: .streak, isActive: $confettiBurst2)
            CelebrationView(style: .milestone, isActive: $confettiBurst3)
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        if reduceMotion {
            phase = 2
            contentVisible = true
            buttonsVisible = true
            HapticFeedback.success()
            return
        }

        // Phase 1: Badge appears
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            phase = 1
        }
        confettiBurst1 = true
        HapticFeedback.success()

        // Phase 2: Second confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            confettiBurst2 = true
        }

        // Phase 3: Content appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                contentVisible = true
            }
        }

        // Phase 4: Third confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            confettiBurst3 = true
        }

        // Phase 5: Buttons appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                buttonsVisible = true
            }
        }
    }
}
