//
//  RoutineStore.swift
//  Otis-app
//
//  Manages daily routines, weight goals, body condition scores, grooming activities,
//  and enrichment activities for adult dogs with Core Data and CKSyncEngine-based CloudKit sync.
//

import Foundation
import CoreData
import OtisShared
import Combine
import os

/// Manages routine and wellness features for adult dogs
@MainActor
final class RoutineStore: BaseStore, ProfileAccessible {

    // MARK: - State

    private(set) var routineItems: [RoutineItem] = []
    private(set) var weightGoal: WeightGoal?
    private(set) var weightGoalHistory: [WeightGoal] = []
    private(set) var bodyConditionScores: [BodyConditionScore] = []
    private(set) var groomingActivities: [GroomingActivity] = []
    private(set) var enrichmentActivities: [EnrichmentActivity] = []

    /// Whether initial data is still loading
    private(set) var isLoading: Bool = true

    // MARK: - ProfileAccessible

    weak var profileStore: ProfileStore?

    // MARK: - Event Store Reference (for timeline events)

    /// Reference to EventStore for creating timeline events when grooming is logged
    weak var eventStoreRef: EventStore?

    // MARK: - Computed Properties

    /// Latest body condition score
    var latestBodyConditionScore: BodyConditionScore? {
        bodyConditionScores.first
    }

    /// Grooming activities that are due or overdue
    var dueGroomingActivities: [GroomingActivity] {
        groomingActivities.filter { $0.isEnabled && $0.isDue }.sortedByUrgency()
    }

    /// Grooming activities that are overdue
    var overdueGroomingActivities: [GroomingActivity] {
        groomingActivities.filter { $0.isEnabled && $0.isOverdue }
    }

    /// Enrichment activities from today
    var todayEnrichmentActivities: [EnrichmentActivity] {
        enrichmentActivities.completedToday
    }

    /// Enrichment activities from this week
    var weeklyEnrichmentActivities: [EnrichmentActivity] {
        enrichmentActivities.thisWeek
    }

    /// Routine items grouped by category
    var routineItemsByCategory: [RoutineCategory: [RoutineItem]] {
        Dictionary(grouping: routineItems.filter(\.isEnabled)) { $0.category }
    }

    /// Next scheduled routine item
    var nextRoutineItem: RoutineItem? {
        routineItems.enabled.nextItem()
    }

    // MARK: - Init

    init(
        persistenceController: PersistenceController = .shared,
        profileStore: ProfileStore? = nil
    ) {
        self.profileStore = profileStore
        super.init(persistenceController: persistenceController, logCategory: "RoutineStore")
    }

    /// Set the profile store (for when it's not available at init time)
    func setProfileStore(_ profileStore: ProfileStore) {
        configureProfileStore(profileStore)
    }

    /// Set the event store reference for creating timeline events
    func setEventStore(_ eventStore: EventStore) {
        self.eventStoreRef = eventStore
    }

    // MARK: - Data Loading

    override func performInitialLoad() {
        // Defer heavy loading to background to avoid blocking app startup
        // This method is called from BaseStore.init(), so we fire-and-forget async
        Task {
            await loadDataAsync()
        }
    }

    /// Load all routine data asynchronously on background context
    private func loadDataAsync() async {
        guard let profile = getCurrentProfile() else {
            routineItems = []
            weightGoal = nil
            weightGoalHistory = []
            bodyConditionScores = []
            groomingActivities = []
            enrichmentActivities = []
            isLoading = false
            return
        }

        // Use main context but defer to next run loop to avoid blocking
        // This keeps the data loading non-blocking while maintaining thread safety
        let context = viewContext

        // Load all data (still on main actor, but deferred from init)
        let cdRoutineItems = CDRoutineItem.fetchItems(for: profile, in: context)
        let cdWeightGoals = CDWeightGoal.fetchGoals(for: profile, in: context)
        let cdBCSScores = CDBodyConditionScore.fetchScores(for: profile, in: context)
        let cdGroomingActivities = CDGroomingActivity.fetchActivities(for: profile, in: context)
        let cdEnrichmentActivities = CDEnrichmentActivity.fetchActivities(for: profile, in: context)

        // Transform to model objects
        routineItems = cdRoutineItems.compactMap { $0.toRoutineItem() }
        weightGoalHistory = cdWeightGoals.compactMap { $0.toWeightGoal() }
        weightGoal = weightGoalHistory.first { $0.isActive }
        bodyConditionScores = cdBCSScores.compactMap { $0.toBodyConditionScore() }
        groomingActivities = cdGroomingActivities.compactMap { $0.toGroomingActivity() }
        enrichmentActivities = cdEnrichmentActivities.compactMap { $0.toEnrichmentActivity() }

        isLoading = false
        logger.info("Loaded routine data: \(self.routineItems.count) items, \(self.groomingActivities.count) grooming, \(self.enrichmentActivities.count) enrichment")
    }

    // MARK: - Routine Items CRUD

    /// Add a new routine item
    @discardableResult
    func addRoutineItem(_ item: RoutineItem) -> Bool {
        guard let profile = getCurrentProfile() else {
            logger.error("Cannot add routine item: no profile")
            return false
        }

        _ = CDRoutineItem.create(from: item, profile: profile, in: viewContext)

        let result = performSave(operation: "Added routine item: \(item.label)") {
            routineItems.append(item)
            routineItems.sort { $0.sortOrder < $1.sortOrder }
        }

        if result {
            let recordID = SyncCoordinator.shared.recordID(for: "CDRoutineItem", id: item.id)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)
        }

        return result
    }

    /// Update an existing routine item
    @discardableResult
    func updateRoutineItem(_ item: RoutineItem) -> Bool {
        guard let cdItem = CDRoutineItem.fetchItem(byId: item.id, in: viewContext) else {
            logger.warning("Routine item not found for update: \(item.id)")
            return false
        }

        cdItem.update(from: item)

        let result = performSave(operation: "Updated routine item: \(item.label)") {
            if let index = routineItems.firstIndex(where: { $0.id == item.id }) {
                routineItems[index] = item
            }
            routineItems.sort { $0.sortOrder < $1.sortOrder }
        }

        if result {
            let recordID = SyncCoordinator.shared.recordID(for: "CDRoutineItem", id: item.id)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)
        }

        return result
    }

    /// Delete a routine item
    @discardableResult
    func deleteRoutineItem(_ item: RoutineItem) -> Bool {
        guard let cdItem = CDRoutineItem.fetchItem(byId: item.id, in: viewContext) else {
            logger.warning("Routine item not found for deletion: \(item.id)")
            return false
        }

        // Queue for CloudKit deletion BEFORE local delete
        let recordID = SyncCoordinator.shared.recordID(for: "CDRoutineItem", id: item.id)
        SyncCoordinator.shared.markPendingDelete(recordID: recordID)

        viewContext.delete(cdItem)

        return performDelete(operation: "Deleted routine item: \(item.label)") {
            routineItems.removeAll { $0.id == item.id }
        }
    }

    /// Seed default routine items if none exist
    func seedDefaultRoutineItemsIfNeeded() {
        guard routineItems.isEmpty else { return }
        guard let profile = getCurrentProfile() else { return }

        let defaultRoutine = DailyRoutine.adultDogDefault()

        for item in defaultRoutine.items {
            _ = CDRoutineItem.create(from: item, profile: profile, in: viewContext)
        }

        performSave(operation: "Seeded default routine items") {
            performInitialLoad()
        }
    }

    // MARK: - Weight Goals CRUD

    /// Add a new weight goal (deactivates any existing active goal)
    @discardableResult
    func addWeightGoal(_ goal: WeightGoal) -> Bool {
        guard let profile = getCurrentProfile() else {
            logger.error("Cannot add weight goal: no profile")
            return false
        }

        // Deactivate any existing active goals
        if let existingActive = CDWeightGoal.fetchActiveGoal(for: profile, in: viewContext) {
            existingActive.isActive = false
        }

        _ = CDWeightGoal.create(from: goal, profile: profile, in: viewContext)

        let result = performSave(operation: "Added weight goal: \(String(format: "%.1f", goal.targetWeightKg)) kg") {
            performInitialLoad()
        }

        if result {
            let recordID = SyncCoordinator.shared.recordID(for: "CDWeightGoal", id: goal.id)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)
        }

        return result
    }

    /// Update an existing weight goal
    @discardableResult
    func updateWeightGoal(_ goal: WeightGoal) -> Bool {
        guard let cdGoal = CDWeightGoal.fetchGoal(byId: goal.id, in: viewContext) else {
            logger.warning("Weight goal not found for update: \(goal.id)")
            return false
        }

        cdGoal.update(from: goal)

        let result = performSave(operation: "Updated weight goal") {
            performInitialLoad()
        }

        if result {
            let recordID = SyncCoordinator.shared.recordID(for: "CDWeightGoal", id: goal.id)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)
        }

        return result
    }

    /// Delete a weight goal
    @discardableResult
    func deleteWeightGoal(_ goal: WeightGoal) -> Bool {
        guard let cdGoal = CDWeightGoal.fetchGoal(byId: goal.id, in: viewContext) else {
            logger.warning("Weight goal not found for deletion: \(goal.id)")
            return false
        }

        // Queue for CloudKit deletion BEFORE local delete
        let recordID = SyncCoordinator.shared.recordID(for: "CDWeightGoal", id: goal.id)
        SyncCoordinator.shared.markPendingDelete(recordID: recordID)

        viewContext.delete(cdGoal)

        return performDelete(operation: "Deleted weight goal") {
            performInitialLoad()
        }
    }

    // MARK: - Body Condition Score CRUD

    /// Add a new body condition score
    @discardableResult
    func addBodyConditionScore(_ score: BodyConditionScore) -> Bool {
        guard let profile = getCurrentProfile() else {
            logger.error("Cannot add BCS: no profile")
            return false
        }

        _ = CDBodyConditionScore.create(from: score, profile: profile, in: viewContext)

        let result = performSave(operation: "Added BCS: \(score.score)/9") {
            bodyConditionScores.insert(score, at: 0)
        }

        if result {
            let recordID = SyncCoordinator.shared.recordID(for: "CDBodyConditionScore", id: score.id)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)
        }

        return result
    }

    /// Add a body condition score with just the value
    @discardableResult
    func addBodyConditionScore(_ score: Int, note: String? = nil) -> Bool {
        let bcs = BodyConditionScore(score: score, note: note)
        return addBodyConditionScore(bcs)
    }

    /// Delete a body condition score
    @discardableResult
    func deleteBodyConditionScore(_ score: BodyConditionScore) -> Bool {
        guard let cdScore = CDBodyConditionScore.fetchScore(byId: score.id, in: viewContext) else {
            logger.warning("BCS not found for deletion: \(score.id)")
            return false
        }

        // Queue for CloudKit deletion BEFORE local delete
        let recordID = SyncCoordinator.shared.recordID(for: "CDBodyConditionScore", id: score.id)
        SyncCoordinator.shared.markPendingDelete(recordID: recordID)

        viewContext.delete(cdScore)

        return performDelete(operation: "Deleted BCS") {
            bodyConditionScores.removeAll { $0.id == score.id }
        }
    }

    // MARK: - Grooming Activities CRUD

    /// Add a new grooming activity
    @discardableResult
    func addGroomingActivity(_ activity: GroomingActivity) -> Bool {
        guard let profile = getCurrentProfile() else {
            logger.error("Cannot add grooming activity: no profile")
            return false
        }

        _ = CDGroomingActivity.create(from: activity, profile: profile, in: viewContext)

        let result = performSave(operation: "Added grooming: \(activity.type.label)") {
            groomingActivities.append(activity)
        }

        if result {
            let recordID = SyncCoordinator.shared.recordID(for: "CDGroomingActivity", id: activity.id)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)
        }

        return result
    }

    /// Update an existing grooming activity
    @discardableResult
    func updateGroomingActivity(_ activity: GroomingActivity) -> Bool {
        guard let cdActivity = CDGroomingActivity.fetchActivity(byId: activity.id, in: viewContext) else {
            logger.warning("Grooming activity not found for update: \(activity.id)")
            return false
        }

        cdActivity.update(from: activity)

        let result = performSave(operation: "Updated grooming: \(activity.type.label)") {
            if let index = groomingActivities.firstIndex(where: { $0.id == activity.id }) {
                groomingActivities[index] = activity
            }
        }

        if result {
            let recordID = SyncCoordinator.shared.recordID(for: "CDGroomingActivity", id: activity.id)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)
        }

        return result
    }

    /// Mark a grooming activity as completed
    @discardableResult
    func markGroomingCompleted(_ activity: GroomingActivity, at date: Date = Date()) -> Bool {
        var updatedActivity = activity
        updatedActivity.markCompleted(at: date)
        let result = updateGroomingActivity(updatedActivity)

        // Also create a PuppyEvent so it appears on the timeline
        if result {
            createGroomingTimelineEvent(type: activity.type, date: date)
        }

        return result
    }

    /// Mark a grooming type as completed (creates if doesn't exist)
    @discardableResult
    func markGroomingCompleted(type: GroomingType, at date: Date = Date(), note: String? = nil) -> Bool {
        let result: Bool
        if var existing = groomingActivities.first(where: { $0.type == type }) {
            existing.markCompleted(at: date)
            if let note = note {
                existing.note = note
            }
            result = updateGroomingActivity(existing)
        } else {
            let activity = GroomingActivity.justCompleted(type: type, note: note)
            result = addGroomingActivity(activity)
        }

        // Also create a PuppyEvent so it appears on the timeline
        if result {
            createGroomingTimelineEvent(type: type, date: date)
        }

        return result
    }

    /// Create a timeline event for a grooming activity
    private func createGroomingTimelineEvent(type: GroomingType, date: Date) {
        guard let eventStore = eventStoreRef else {
            logger.warning("EventStore not set - grooming won't appear on timeline")
            return
        }

        let groomingEvent = PuppyEvent(
            time: date,
            type: .verzorging,
            note: type.label  // Store the grooming type label for display
        )
        eventStore.addEvent(groomingEvent)
    }

    /// Delete a grooming activity
    @discardableResult
    func deleteGroomingActivity(_ activity: GroomingActivity) -> Bool {
        guard let cdActivity = CDGroomingActivity.fetchActivity(byId: activity.id, in: viewContext) else {
            logger.warning("Grooming activity not found for deletion: \(activity.id)")
            return false
        }

        // Queue for CloudKit deletion BEFORE local delete
        let recordID = SyncCoordinator.shared.recordID(for: "CDGroomingActivity", id: activity.id)
        SyncCoordinator.shared.markPendingDelete(recordID: recordID)

        viewContext.delete(cdActivity)

        return performDelete(operation: "Deleted grooming: \(activity.type.label)") {
            groomingActivities.removeAll { $0.id == activity.id }
        }
    }

    /// Seed default grooming activities if none exist
    func seedDefaultGroomingActivitiesIfNeeded() {
        guard groomingActivities.isEmpty else { return }
        guard let cdProfile = getCurrentProfile() else { return }

        // Get coat type from profile (effectiveCoatType is on PuppyProfile, not CDPuppyProfile)
        // First try explicit coatType, then breed-based suggestion
        let coatType: CoatType?
        if let coatTypeString = cdProfile.coatType {
            coatType = CoatType(rawValue: coatTypeString)
        } else {
            coatType = CoatType.suggested(for: cdProfile.breed)
        }

        // Use coat-type-specific defaults if available
        let defaults: [GroomingActivity]
        if let coatType = coatType {
            defaults = GroomingActivity.defaultActivities(for: coatType)
        } else {
            defaults = GroomingActivity.defaultActivities()
        }

        for activity in defaults {
            _ = CDGroomingActivity.create(from: activity, profile: cdProfile, in: viewContext)
        }

        performSave(operation: "Seeded default grooming activities") {
            performInitialLoad()
        }
    }

    /// Reset grooming activities to coat-type defaults
    /// Useful when user changes coat type
    func resetGroomingActivitiesToDefaults(for coatType: CoatType) {
        guard let profile = getCurrentProfile() else { return }

        // Delete all existing grooming activities
        for cdActivity in CDGroomingActivity.fetchActivities(for: profile, in: viewContext) {
            viewContext.delete(cdActivity)
        }

        // Create new defaults for the coat type
        let defaults = GroomingActivity.defaultActivities(for: coatType)
        for activity in defaults {
            _ = CDGroomingActivity.create(from: activity, profile: profile, in: viewContext)
        }

        performSave(operation: "Reset grooming to \(coatType.label) defaults") {
            performInitialLoad()
        }
    }

    // MARK: - Enrichment Activities CRUD

    /// Add a new enrichment activity
    @discardableResult
    func addEnrichmentActivity(_ activity: EnrichmentActivity) -> Bool {
        guard let profile = getCurrentProfile() else {
            logger.error("Cannot add enrichment activity: no profile")
            return false
        }

        _ = CDEnrichmentActivity.create(from: activity, profile: profile, in: viewContext)

        let result = performSave(operation: "Added enrichment: \(activity.type.label)") {
            enrichmentActivities.insert(activity, at: 0)
        }

        if result {
            let recordID = SyncCoordinator.shared.recordID(for: "CDEnrichmentActivity", id: activity.id)
            SyncCoordinator.shared.markPendingSave(recordID: recordID)
        }

        return result
    }

    /// Add an enrichment activity with type and optional duration
    @discardableResult
    func addEnrichment(type: EnrichmentType, durationMinutes: Int? = nil, note: String? = nil) -> Bool {
        let activity = EnrichmentActivity.now(type: type, durationMinutes: durationMinutes, note: note)
        return addEnrichmentActivity(activity)
    }

    /// Delete an enrichment activity
    @discardableResult
    func deleteEnrichmentActivity(_ activity: EnrichmentActivity) -> Bool {
        guard let cdActivity = CDEnrichmentActivity.fetchActivity(byId: activity.id, in: viewContext) else {
            logger.warning("Enrichment activity not found for deletion: \(activity.id)")
            return false
        }

        // Queue for CloudKit deletion BEFORE local delete
        let recordID = SyncCoordinator.shared.recordID(for: "CDEnrichmentActivity", id: activity.id)
        SyncCoordinator.shared.markPendingDelete(recordID: recordID)

        viewContext.delete(cdActivity)

        return performDelete(operation: "Deleted enrichment: \(activity.type.label)") {
            enrichmentActivities.removeAll { $0.id == activity.id }
        }
    }

    // MARK: - Enrichment Suggestions

    /// Get an enrichment suggestion, excluding recently done activities
    func enrichmentSuggestion(excludingDays: Int = 3) -> EnrichmentType? {
        enrichmentActivities.randomSuggestion(excludingDays: excludingDays)
    }

    /// Get enrichment suggestions by category
    func enrichmentSuggestions(for category: EnrichmentCategory, limit: Int = 3) -> [EnrichmentType] {
        let recentTypes = Set(enrichmentActivities.withinDays(7).map(\.type))
        return EnrichmentType.allCases
            .filter { $0.category == category && !recentTypes.contains($0) }
            .shuffled()
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Migration Support

    /// Migrate orphaned items to the current profile
    func migrateOrphanedItems() {
        guard let profile = getCurrentProfile() else { return }

        var migrated = 0

        // Migrate routine items
        for cdItem in CDRoutineItem.fetchOrphanedItems(in: viewContext) {
            cdItem.profile = profile
            migrated += 1
        }

        // Migrate weight goals
        for cdGoal in CDWeightGoal.fetchOrphanedGoals(in: viewContext) {
            cdGoal.profile = profile
            migrated += 1
        }

        // Migrate BCS scores
        for cdScore in CDBodyConditionScore.fetchOrphanedScores(in: viewContext) {
            cdScore.profile = profile
            migrated += 1
        }

        // Migrate grooming activities
        for cdActivity in CDGroomingActivity.fetchOrphanedActivities(in: viewContext) {
            cdActivity.profile = profile
            migrated += 1
        }

        // Migrate enrichment activities
        for cdActivity in CDEnrichmentActivity.fetchOrphanedActivities(in: viewContext) {
            cdActivity.profile = profile
            migrated += 1
        }

        if migrated > 0 {
            performSave(operation: "Migrated \(migrated) orphaned routine items") {
                performInitialLoad()
            }
        }
    }
}
