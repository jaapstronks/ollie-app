//
//  MiniQuizView.swift
//  Ollie-app
//
//  Interactive quiz component for training foundations.
//  Shows question, options, and reveals correct answer with explanation.
//

import SwiftUI

/// A single quiz question with options and explanation
struct MiniQuizQuestion: Identifiable, Equatable {
    let id: String
    let question: String
    let options: [QuizOption]
    let correctOptionId: String
    let explanation: String
    let explanationTitle: String  // e.g., "Here's why:" or "The truth:"

    struct QuizOption: Identifiable, Equatable {
        let id: String
        let text: String
    }
}

/// Interactive mini-quiz with reveal animation
struct MiniQuizView: View {
    let quiz: MiniQuizQuestion
    let onAnswered: (Bool) -> Void  // Called when user answers (correct/incorrect)

    @State private var selectedOptionId: String?
    @State private var hasRevealed = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCorrect: Bool {
        selectedOptionId == quiz.correctOptionId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    Text(Strings.Training.Foundations.quiz)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .textCase(.uppercase)
                }

                Text(quiz.question)
                    .font(.body)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Options
            VStack(spacing: 10) {
                ForEach(quiz.options) { option in
                    optionButton(for: option)
                }
            }

            // Reveal section
            if hasRevealed {
                revealSection
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.orange.opacity(0.08)
                    : Color.orange.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Option Button

    @ViewBuilder
    private func optionButton(for option: MiniQuizQuestion.QuizOption) -> some View {
        let isSelected = selectedOptionId == option.id
        let isThisCorrect = option.id == quiz.correctOptionId

        Button {
            guard !hasRevealed else { return }

            HapticFeedback.light()

            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                selectedOptionId = option.id
            }

            // Delay reveal slightly for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
                    hasRevealed = true
                }

                // Haptic feedback based on correctness
                if isThisCorrect {
                    HapticFeedback.success()
                } else {
                    HapticFeedback.warning()
                }

                onAnswered(option.id == quiz.correctOptionId)
            }
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(borderColor(for: option), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if hasRevealed && isThisCorrect {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.otisSuccess))
                    } else if hasRevealed && isSelected && !isThisCorrect {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.red))
                    } else if isSelected {
                        Circle()
                            .fill(Color.otisAccent)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(option.text)
                    .font(.subheadline)
                    .foregroundStyle(textColor(for: option))
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor(for: option))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor(for: option), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(hasRevealed)
    }

    // MARK: - Reveal Section

    @ViewBuilder
    private var revealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.vertical, 4)

            // Result badge
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(isCorrect ? Color.otisSuccess : .yellow)

                Text(isCorrect
                    ? Strings.Training.Foundations.quizCorrect
                    : Strings.Training.Foundations.quizSurprising)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isCorrect ? Color.otisSuccess : .yellow)
            }

            // Explanation
            VStack(alignment: .leading, spacing: 8) {
                Text(quiz.explanationTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(quiz.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(0.05)
                        : Color.black.opacity(0.03))
            )
        }
    }

    // MARK: - Styling Helpers

    private func backgroundColor(for option: MiniQuizQuestion.QuizOption) -> Color {
        let isSelected = selectedOptionId == option.id
        let isThisCorrect = option.id == quiz.correctOptionId

        if hasRevealed {
            if isThisCorrect {
                return Color.otisSuccess.opacity(0.1)
            } else if isSelected {
                return Color.red.opacity(0.1)
            }
        }

        if isSelected {
            return Color.otisAccent.opacity(0.1)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.white
    }

    private func borderColor(for option: MiniQuizQuestion.QuizOption) -> Color {
        let isSelected = selectedOptionId == option.id
        let isThisCorrect = option.id == quiz.correctOptionId

        if hasRevealed {
            if isThisCorrect {
                return Color.otisSuccess
            } else if isSelected {
                return Color.red
            }
        }

        if isSelected {
            return Color.otisAccent
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.15)
            : Color.black.opacity(0.1)
    }

    private func textColor(for option: MiniQuizQuestion.QuizOption) -> Color {
        let isSelected = selectedOptionId == option.id
        let isThisCorrect = option.id == quiz.correctOptionId

        if hasRevealed {
            if isThisCorrect {
                return Color.otisSuccess
            } else if isSelected {
                return .secondary
            }
        }

        return .primary
    }
}

// MARK: - True/False Quiz Convenience

extension MiniQuizView {
    /// Creates a True/False quiz
    static func trueFalse(
        id: String,
        question: String,
        correctAnswer: Bool,
        explanation: String,
        explanationTitle: String = Strings.Training.Foundations.heresWhy,
        onAnswered: @escaping (Bool) -> Void
    ) -> MiniQuizView {
        let quiz = MiniQuizQuestion(
            id: id,
            question: question,
            options: [
                .init(id: "true", text: Strings.Training.Foundations.quizTrue),
                .init(id: "false", text: Strings.Training.Foundations.quizFalse)
            ],
            correctOptionId: correctAnswer ? "true" : "false",
            explanation: explanation,
            explanationTitle: explanationTitle
        )
        return MiniQuizView(quiz: quiz, onAnswered: onAnswered)
    }
}

// MARK: - Preview

#Preview("True/False Quiz - Unanswered") {
    ScrollView {
        MiniQuizView.trueFalse(
            id: "lookAtMe",
            question: "To teach 'look at me', say the words repeatedly until your dog looks at you, then give a treat.",
            correctAnswer: false,
            explanation: "Your dog doesn't understand English. When you say 'look at me' while they're sniffing the floor, they associate those words with sniffing — not looking. The command becomes meaningless noise. Instead, wait silently until they happen to look at you, mark it, and treat. Add words only after the behavior is reliable.",
            onAnswered: { correct in
                print("Answered: \(correct ? "correctly" : "incorrectly")")
            }
        )
        .padding()
    }
}

#Preview("Multiple Choice Quiz") {
    ScrollView {
        MiniQuizView(
            quiz: MiniQuizQuestion(
                id: "sitLouder",
                question: "Your dog isn't sitting. You say \"sit\" louder: \"Sit. Sit. SIT!\" What is your dog learning?",
                options: [
                    .init(id: "a", text: "That they should sit faster"),
                    .init(id: "b", text: "That the command is \"sit-sit-SIT-with-anger\""),
                    .init(id: "c", text: "Nothing — they're ignoring you")
                ],
                correctOptionId: "b",
                explanation: "Your dog doesn't understand that you're repeating yourself. They think \"sit-sit-SIT\" is one long command. And they're learning that the cue involves you sounding increasingly upset. This is why we use hand signals first — they can't be \"shouted.\"",
                explanationTitle: "The truth:"
            ),
            onAnswered: { _ in }
        )
        .padding()
    }
}
