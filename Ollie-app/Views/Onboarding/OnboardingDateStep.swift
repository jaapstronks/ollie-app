//
//  OnboardingDateStep.swift
//  Otis-app
//
//  Birth date and home date steps for onboarding
//

import SwiftUI
import OtisShared

/// Birth date selection step
struct OnboardingBirthStep: View {
    let puppyName: String
    @Binding var birthDate: Date
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.otisAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(Strings.Onboarding.birthDateQuestion(name: puppyName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Date picker
            DatePicker(
                Strings.Onboarding.birthDate,
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(Color.otisAccent)
            .padding(.horizontal, 8)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .accessibilityLabel(Strings.Onboarding.birthDateAccessibility(name: puppyName))

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

/// Home date selection step
struct OnboardingHomeStep: View {
    let puppyName: String
    @Binding var homeDate: Date
    let minDate: Date  // birthDate
    let isExpecting: Bool  // true = dog hasn't arrived yet, false = already home
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var hasAppeared = false

    /// Date range depends on whether dog is expected (future allowed) or already home (past only)
    private var dateRange: ClosedRange<Date> {
        if isExpecting {
            // Expecting: from birth date to 1 year in the future
            let maxDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            return minDate...maxDate
        } else {
            // Already home: from birth date to today
            return minDate...Date()
        }
    }

    /// Question text based on status
    private var questionText: String {
        if isExpecting {
            return Strings.Onboarding.homeDateQuestionFuture(name: puppyName)
        } else {
            return Strings.Onboarding.homeDateQuestionPast(name: puppyName)
        }
    }

    /// Accessibility label based on status
    private var accessibilityLabel: String {
        if isExpecting {
            return Strings.Onboarding.homeDateAccessibilityFuture(name: puppyName)
        } else {
            return Strings.Onboarding.homeDateAccessibilityPast(name: puppyName)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: isExpecting ? "calendar.badge.clock" : "house.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.otisAccent)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)

                Text(questionText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Date picker
            DatePicker(
                Strings.Onboarding.homeDate,
                selection: $homeDate,
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(Color.otisAccent)
            .padding(.horizontal, 8)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .accessibilityLabel(accessibilityLabel)

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
