//
//  FoundationsSection.swift
//  Ollie-app
//
//  Section displaying training foundations modules in the training view.
//  Replaces the old PreparationSection checklist.
//

import SwiftUI

/// Section showing foundations modules that gate or enhance training
struct FoundationsSection: View {
    let foundationsStore: FoundationsProgressStore
    let masteredSkillCount: Int
    let hasReachedProofingPhase: Bool
    let onModuleTap: (FoundationsModule) -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Modules to display (required module + any suggested ones)
    private var visibleModules: [(module: FoundationsModule, isRequired: Bool, isSuggested: Bool)] {
        var result: [(FoundationsModule, Bool, Bool)] = []

        // Module 1: Getting Started (always visible, required until complete)
        let gettingStarted = FoundationsContentProvider.gettingStartedModule()
        let isModule1Complete = foundationsStore.isGettingStartedComplete
        result.append((gettingStarted, !isModule1Complete, false))

        // Module 2: How Dogs Learn (suggested after completing 2+ skills)
        if foundationsStore.shouldSuggestHowDogsLearn(masteredSkillCount: masteredSkillCount) {
            let howDogsLearn = FoundationsContentProvider.howDogsLearnModule()
            result.append((howDogsLearn, false, true))
        } else if foundationsStore.isHowDogsLearnComplete {
            // Show completed state if already done
            let howDogsLearn = FoundationsContentProvider.howDogsLearnModule()
            result.append((howDogsLearn, false, false))
        }

        // Module 3: Taking It Further (suggested when approaching proofing phases)
        if foundationsStore.shouldSuggestTakingFurther(hasReachedProofingPhase: hasReachedProofingPhase) {
            let takingFurther = FoundationsContentProvider.takingFurtherModule()
            result.append((takingFurther, false, true))
        } else if foundationsStore.isTakingFurtherComplete {
            // Show completed state if already done
            let takingFurther = FoundationsContentProvider.takingFurtherModule()
            result.append((takingFurther, false, false))
        }

        return result
    }

    /// Check if there are any active (non-completed) modules to show prominently
    private var hasActiveModules: Bool {
        visibleModules.contains { !($0.module.id == "gettingStarted" ?
            foundationsStore.isGettingStartedComplete :
            (foundationsStore.progress(for: $0.module.id).isComplete || foundationsStore.progress(for: $0.module.id).skipped)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "book.pages")
                    .font(.headline)
                    .foregroundStyle(Color.otisAccent)

                Text(Strings.Training.Foundations.sectionTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Progress badge
                let completed = [
                    foundationsStore.isGettingStartedComplete,
                    foundationsStore.isHowDogsLearnComplete,
                    foundationsStore.isTakingFurtherComplete
                ].filter { $0 }.count

                if completed > 0 {
                    Text("\(completed)/3")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                }
            }

            // Module cards
            ForEach(visibleModules, id: \.module.id) { item in
                FoundationsModuleCard(
                    module: item.module,
                    progress: foundationsStore.progress(for: item.module.id),
                    isRequired: item.isRequired,
                    isSuggested: item.isSuggested,
                    onTap: {
                        onModuleTap(item.module)
                    }
                )
            }
        }
    }
}

// MARK: - Strings Extension

private let foundationsTable = "Training"

extension Strings.Training.Foundations {
    static let sectionTitle = String(localized: "Training Theory", table: foundationsTable)
}

// MARK: - Preview

#Preview {
    ScrollView {
        FoundationsSection(
            foundationsStore: FoundationsProgressStore(),
            masteredSkillCount: 3,
            hasReachedProofingPhase: false,
            onModuleTap: { _ in }
        )
        .padding()
    }
}
