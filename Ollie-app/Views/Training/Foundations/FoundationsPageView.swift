//
//  FoundationsPageView.swift
//  Ollie-app
//
//  Individual page view for training foundations content.
//  Supports rich text, callouts, quizzes, and lists.
//

import SwiftUI

/// Content block types for foundations pages
enum FoundationsContentBlock: Identifiable, Equatable {
    case heading(String)
    case paragraph(String)
    case highlight(String)  // Emphasized text in a callout box
    case note(title: String, text: String)  // Info box with title
    case numberedList([String])
    case bulletList([String])
    case quiz(MiniQuizQuestion)
    case toolItem(icon: String, title: String, description: String)
    case spacer(height: CGFloat)

    var id: String {
        switch self {
        case .heading(let text): return "heading_\(text.prefix(20))"
        case .paragraph(let text): return "para_\(text.prefix(20))"
        case .highlight(let text): return "highlight_\(text.prefix(20))"
        case .note(let title, _): return "note_\(title)"
        case .numberedList(let items): return "numbered_\(items.first?.prefix(10) ?? "")"
        case .bulletList(let items): return "bullet_\(items.first?.prefix(10) ?? "")"
        case .quiz(let q): return "quiz_\(q.id)"
        case .toolItem(_, let title, _): return "tool_\(title)"
        case .spacer(let height): return "spacer_\(height)"
        }
    }
}

/// A single page in the foundations flow
struct FoundationsPage: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String?
    let content: [FoundationsContentBlock]

    static func == (lhs: FoundationsPage, rhs: FoundationsPage) -> Bool {
        lhs.id == rhs.id
    }
}

/// Renders a single foundations page with rich content
struct FoundationsPageView: View {
    let page: FoundationsPage
    let pageIndex: Int
    let totalPages: Int
    let onQuizAnswered: (String, Bool) -> Void  // quizId, wasCorrect

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Page header
                pageHeader

                // Content blocks
                ForEach(page.content) { block in
                    contentBlockView(for: block)
                }

                // Bottom spacing for safe area
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Page Header

    @ViewBuilder
    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Page number badge
            HStack(spacing: 8) {
                if let icon = page.icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.white)
                }
                Text(Strings.Training.Foundations.pageProgress(current: pageIndex + 1, total: totalPages))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.otisAccent)
            )

            // Page title
            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    // MARK: - Content Block Rendering

    @ViewBuilder
    private func contentBlockView(for block: FoundationsContentBlock) -> some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.top, 8)

        case .paragraph(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

        case .highlight(let text):
            highlightBox(text: text)

        case .note(let title, let text):
            noteBox(title: title, text: text)

        case .numberedList(let items):
            numberedListView(items: items)

        case .bulletList(let items):
            bulletListView(items: items)

        case .quiz(let question):
            MiniQuizView(quiz: question) { wasCorrect in
                onQuizAnswered(question.id, wasCorrect)
            }

        case .toolItem(let icon, let title, let description):
            toolItemView(icon: icon, title: title, description: description)

        case .spacer(let height):
            Spacer()
                .frame(height: height)
        }
    }

    // MARK: - Highlight Box

    @ViewBuilder
    private func highlightBox(text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.otisAccent)
                .frame(width: 4)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.trailing, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.otisAccent.opacity(0.08))
        )
    }

    // MARK: - Note Box

    @ViewBuilder
    private func noteBox(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Numbered List

    @ViewBuilder
    private func numberedListView(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.otisAccent))

                    Text(item)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02))
        )
    }

    // MARK: - Bullet List

    @ViewBuilder
    private func bulletListView(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.otisAccent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)

                    Text(item)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Tool Item

    @ViewBuilder
    private func toolItemView(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.otisAccent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02))
        )
    }
}

// MARK: - Preview

#Preview {
    FoundationsPageView(
        page: FoundationsPage(
            id: "welcome",
            title: "Welcome",
            icon: "sparkles",
            content: [
                .heading("Welcome to the most rewarding part of having a dog."),
                .paragraph("For thousands of years, humans and dogs have evolved together — a partnership unlike any other in the animal kingdom."),
                .highlight("Your dog already knows how to learn. They're ready. Willing. Eager."),
                .paragraph("What they're waiting for is you to learn how to teach them."),
                .note(title: "A note", text: "Nothing replaces in-person training with a professional. But most of the practice happens at home."),
                .numberedList([
                    "Capture first, cue later",
                    "Mark the moment",
                    "Reward immediately",
                    "Keep it short"
                ]),
                .quiz(MiniQuizQuestion(
                    id: "test",
                    question: "Is this a test question?",
                    options: [
                        .init(id: "yes", text: "Yes"),
                        .init(id: "no", text: "No")
                    ],
                    correctOptionId: "yes",
                    explanation: "This is indeed a test!",
                    explanationTitle: "Correct!"
                ))
            ]
        ),
        pageIndex: 0,
        totalPages: 6,
        onQuizAnswered: { _, _ in }
    )
}
