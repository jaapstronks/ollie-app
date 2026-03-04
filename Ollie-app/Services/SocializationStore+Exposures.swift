//
//  SocializationStore+Exposures.swift
//  Otis-app
//
//  Exposure and comfortable item management for SocializationStore
//

import Foundation
import CoreData
import OtisShared
import os

extension SocializationStore {

    // MARK: - Exposure CRUD

    /// Add a new exposure for an item
    @discardableResult
    func addExposure(
        itemId: String,
        distance: ExposureDistance,
        reaction: SocializationReaction,
        note: String? = nil
    ) -> Exposure {
        let exposure = Exposure(
            itemId: itemId,
            date: Date(),
            distance: distance,
            reaction: reaction,
            note: note
        )

        _ = CDExposure.create(from: exposure, in: viewContext)

        performSave(operation: "Added exposure for item: \(itemId)") {
            var exposures = exposuresByItem[itemId] ?? []
            exposures.append(exposure)
            exposuresByItem[itemId] = exposures
        }

        // Check if this makes the item comfortable and update explicit tracking
        checkAndUpdateComfortStatus(itemId: itemId)

        return exposure
    }

    /// Get all exposures for an item
    func getExposures(for itemId: String) -> [Exposure] {
        exposuresByItem[itemId] ?? []
    }

    /// Delete an exposure
    func deleteExposure(_ exposure: Exposure) {
        guard let cdExposure = CDExposure.fetch(byId: exposure.id, in: viewContext) else {
            logger.warning("Exposure not found for deletion: \(exposure.id)")
            return
        }

        viewContext.delete(cdExposure)

        performDelete(operation: "Deleted exposure: \(exposure.id)") {
            exposuresByItem[exposure.itemId]?.removeAll { $0.id == exposure.id }
        }
    }

    // MARK: - Comfortable Item CRUD

    /// Mark an item as comfortable (quick check or via logging)
    func markComfortable(_ itemId: String, method: ComfortableItem.ComfortMethod = .quickCheck) {
        // Check if already marked
        if comfortableItems.contains(where: { $0.itemId == itemId }) {
            return
        }

        let item = ComfortableItem(itemId: itemId, method: method)
        _ = CDComfortableItem.create(from: item, in: viewContext)

        performSave(operation: "Marked comfortable: \(itemId)") {
            comfortableItems.append(item)
        }
    }

    /// Unmark an item as comfortable
    func unmarkComfortable(_ itemId: String) {
        CDComfortableItem.delete(byItemId: itemId, in: viewContext)

        performSave(operation: "Unmarked comfortable: \(itemId)") {
            comfortableItems.removeAll { $0.itemId == itemId }
        }
    }

    /// Toggle comfortable status
    func toggleComfortable(_ itemId: String) {
        if isExplicitlyComfortable(itemId: itemId) {
            unmarkComfortable(itemId)
        } else {
            markComfortable(itemId)
        }
    }

    /// Check if item is explicitly marked comfortable (via CDComfortableItem)
    func isExplicitlyComfortable(itemId: String) -> Bool {
        comfortableItems.contains { $0.itemId == itemId }
    }

    /// Update comfort status after logging exposures
    internal func checkAndUpdateComfortStatus(itemId: String) {
        // If already explicitly marked, skip
        if isExplicitlyComfortable(itemId: itemId) { return }

        // Check if now comfortable via exposures
        guard let item = item(withId: itemId) else { return }
        let positiveCount = getExposures(for: itemId).filter { $0.reaction.isPositive }.count

        if positiveCount >= item.targetExposures {
            markComfortable(itemId, method: .logged)
        }
    }

    // MARK: - Early Milestone CRUD

    /// Mark an early milestone as achieved
    func markMilestoneAchieved(_ milestoneId: String) {
        // Check if already achieved
        if earlyMilestones.contains(where: { $0.milestoneId == milestoneId }) {
            return
        }

        let record = EarlyMilestoneRecord(milestoneId: milestoneId)
        _ = CDEarlyMilestone.create(from: record, in: viewContext)

        performSave(operation: "Marked milestone achieved: \(milestoneId)") {
            earlyMilestones.append(record)
        }
    }

    /// Unmark an early milestone
    func unmarkMilestone(_ milestoneId: String) {
        CDEarlyMilestone.delete(byMilestoneId: milestoneId, in: viewContext)

        performSave(operation: "Unmarked milestone: \(milestoneId)") {
            earlyMilestones.removeAll { $0.milestoneId == milestoneId }
        }
    }

    /// Toggle milestone achieved status
    func toggleMilestone(_ milestoneId: String) {
        if isMilestoneAchieved(milestoneId) {
            unmarkMilestone(milestoneId)
        } else {
            markMilestoneAchieved(milestoneId)
        }
    }

    /// Check if a milestone is achieved
    func isMilestoneAchieved(_ milestoneId: String) -> Bool {
        earlyMilestones.contains { $0.milestoneId == milestoneId }
    }

    /// Get early milestone definition by ID
    func milestoneDefinition(for id: String) -> EarlyMilestoneDefinition? {
        milestoneDefinitions.first { $0.id == id }
    }
}
