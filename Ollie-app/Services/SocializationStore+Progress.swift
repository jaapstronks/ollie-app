//
//  SocializationStore+Progress.swift
//  Otis-app
//
//  Progress calculations and item lookups for SocializationStore
//

import Foundation
import OtisShared

extension SocializationStore {

    // MARK: - Progress Calculations

    /// Progress fraction for an item (0.0 to 1.0)
    func progressFraction(for itemId: String) -> Double {
        // If explicitly marked comfortable, return 1.0
        if isExplicitlyComfortable(itemId: itemId) {
            return 1.0
        }

        guard let item = item(withId: itemId) else { return 0 }
        let positiveCount = getExposures(for: itemId).filter { $0.reaction.isPositive }.count
        return min(1.0, Double(positiveCount) / Double(item.targetExposures))
    }

    /// Whether the puppy is comfortable with this item (explicitly marked OR enough positive exposures)
    func isComfortable(itemId: String) -> Bool {
        // Check explicit marking first
        if isExplicitlyComfortable(itemId: itemId) {
            return true
        }

        // Fall back to exposure-based check
        guard let item = item(withId: itemId) else { return false }
        let positiveCount = getExposures(for: itemId).filter { $0.reaction.isPositive }.count
        return positiveCount >= item.targetExposures
    }

    /// Progress for a category
    func categoryProgress(for categoryId: String) -> (completed: Int, total: Int) {
        guard let category = categories.first(where: { $0.id == categoryId }) else {
            return (0, 0)
        }
        let completed = category.items.filter { isComfortable(itemId: $0.id) }.count
        return (completed, category.items.count)
    }

    /// Most recent exposure for an item
    func lastExposure(for itemId: String) -> Exposure? {
        // PERF: Use max(by:) O(n) instead of sorted().first O(n log n)
        getExposures(for: itemId).max(by: { $0.date < $1.date })
    }

    // MARK: - Item Lookup

    /// Find an item by ID
    func item(withId id: String) -> SocializationItem? {
        for category in categories {
            if let item = category.items.first(where: { $0.id == id }) {
                return item
            }
        }
        return nil
    }

    /// Find category for an item
    func category(forItemId itemId: String) -> SocializationCategory? {
        categories.first { category in
            category.items.contains { $0.id == itemId }
        }
    }

    // MARK: - Walk Suggestions

    /// Get suggested items to watch for during walks
    func suggestedWalkItems(limit: Int = 3) -> [SocializationItem] {
        // Only suggest items from current phase or earlier
        let availableItems = itemsUpToPhase(currentPhase).filter { $0.isWalkable && !isComfortable(itemId: $0.id) }

        let scoredItems = availableItems.map { item -> (SocializationItem, Int) in
            let exposures = getExposures(for: item.id)
            let positiveCount = exposures.filter { $0.reaction.isPositive }.count
            // PERF: Use max(by:) O(n) instead of sorted().first O(n log n)
            let lastExposure = exposures.max(by: { $0.date < $1.date })

            var score = item.priority * 20 // Priority is key

            // Boost items with recent negative reactions
            if let last = lastExposure, !last.reaction.isPositive {
                let daysSince = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
                if daysSince < 7 {
                    score += 100
                }
            }

            // Boost items close to completion
            let remaining = item.targetExposures - positiveCount
            if remaining > 0 && remaining <= 2 {
                score += 50
            }

            // Boost items not yet started
            if exposures.isEmpty {
                score += 30
            }

            return (item, score)
        }

        return scoredItems
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    /// Get suggested focus categories (categories with least progress)
    func suggestedFocusCategories(limit: Int = 2) -> [SocializationCategory] {
        let sortedCategories = categories.sorted { cat1, cat2 in
            let (completed1, total1) = categoryProgress(for: cat1.id)
            let (completed2, total2) = categoryProgress(for: cat2.id)

            let progress1 = total1 > 0 ? Double(completed1) / Double(total1) : 0
            let progress2 = total2 > 0 ? Double(completed2) / Double(total2) : 0

            return progress1 < progress2
        }

        return Array(sortedCategories.prefix(limit))
    }
}
