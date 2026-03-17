//
//  FoundationsFlowSheet.swift
//  Ollie-app
//
//  Container for training foundations with horizontal swipe navigation.
//  Tracks page progress and quiz completion.
//

import SwiftUI

/// Flow sheet for training foundations modules
struct FoundationsFlowSheet: View {
    let module: FoundationsModule
    let foundationsStore: FoundationsProgressStore
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onDismiss: () -> Void

    @State private var currentPage: Int = 0
    @State private var answeredQuizzes: Set<String> = []
    @State private var pagesViewed: Set<Int> = [0]  // Start with first page viewed
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pages: [FoundationsPage] {
        module.pages
    }

    private var totalPages: Int {
        pages.count
    }

    /// Check if current page has required quizzes that need answering
    private var currentPageHasUnansweredQuiz: Bool {
        guard currentPage < pages.count else { return false }
        let page = pages[currentPage]

        for block in page.content {
            if case .quiz(let question) = block {
                if !answeredQuizzes.contains(question.id) {
                    return true
                }
            }
        }
        return false
    }

    /// Check if user can proceed to next page
    private var canProceed: Bool {
        !currentPageHasUnansweredQuiz
    }

    /// Is this the last page?
    private var isLastPage: Bool {
        currentPage == totalPages - 1
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    FoundationsPageView(
                        page: page,
                        pageIndex: index,
                        totalPages: totalPages,
                        onQuizAnswered: { quizId, _ in
                            answeredQuizzes.insert(quizId)
                            foundationsStore.markQuizAnswered(quizId, forModule: module.id)
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: currentPage)
            .navigationTitle(module.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    if totalPages > 1 {
                        ProgressDotsView(
                            currentPage: currentPage,
                            totalPages: totalPages,
                            pagesViewed: pagesViewed
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .onChange(of: currentPage) { _, newPage in
                pagesViewed.insert(newPage)
                foundationsStore.markPageViewed(newPage, forModule: module.id)
            }
            .onAppear {
                // Restore progress from store
                let progress = foundationsStore.progress(for: module.id)
                pagesViewed = progress.pagesViewed.union([0])
                answeredQuizzes = progress.quizzesAnswered

                // Resume from last viewed page if user is returning
                if !progress.pagesViewed.isEmpty {
                    currentPage = min(progress.pagesViewed.max() ?? 0, pages.count - 1)
                }
            }
        }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 12) {
            Divider()

            VStack(spacing: 8) {
                // Quiz hint if needed
                if currentPageHasUnansweredQuiz {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption)
                        Text(Strings.Training.Foundations.answerQuizToContinue)
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }

                HStack(spacing: 12) {
                    // Skip button (always available)
                    Button {
                        HapticFeedback.light()
                        onSkip()
                    } label: {
                        Text(Strings.Training.Foundations.skipFoundations)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            )
                    }

                    // Continue / Complete button
                    Button {
                        HapticFeedback.medium()
                        if isLastPage {
                            onComplete()
                        } else if canProceed {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isLastPage {
                                Image(systemName: "checkmark.circle.fill")
                                Text(Strings.Training.Foundations.letsBegin)
                            } else {
                                Text(Strings.Training.Foundations.continueReading)
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(canProceed ? Color.otisAccent : Color.gray)
                        )
                    }
                    .disabled(!canProceed)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Progress Dots

/// Visual progress indicator with viewed state
struct ProgressDotsView: View {
    let currentPage: Int
    let totalPages: Int
    let pagesViewed: Set<Int>

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: dotSize(for: index), height: dotSize(for: index))
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index == currentPage {
            return .otisAccent
        } else if pagesViewed.contains(index) {
            return .otisAccent.opacity(0.4)
        } else {
            return .gray.opacity(0.3)
        }
    }

    private func dotSize(for index: Int) -> CGFloat {
        index == currentPage ? 8 : 6
    }
}

// MARK: - Foundations Module Definition

/// A complete foundations module with metadata and pages
struct FoundationsModule: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let pages: [FoundationsPage]

    /// Is this the required first module?
    var isRequired: Bool {
        id == "gettingStarted"
    }
}

// MARK: - Preview

#Preview {
    FoundationsFlowSheet(
        module: FoundationsContentProvider.gettingStartedModule(),
        foundationsStore: FoundationsProgressStore(),
        onComplete: {},
        onSkip: {},
        onDismiss: {}
    )
}
