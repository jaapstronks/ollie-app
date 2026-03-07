//
//  CDSkillProgress+Extensions.swift
//  Ollie-app
//
//  Extensions for converting between SkillProgress and CDSkillProgress
//

import CoreData
import OtisShared

extension CDSkillProgress {

    // MARK: - JSON Coders

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Convert from Swift Struct

    /// Update Core Data object from SkillProgress struct
    func update(from progress: SkillProgress) {
        self.id = progress.id
        self.skillId = progress.skillId
        self.phase = progress.phase.rawValue
        self.durationLevel = Int16(progress.proofingLevels.duration)
        self.distanceLevel = Int16(progress.proofingLevels.distance)
        self.distractionLevel = Int16(progress.proofingLevels.distraction)
        self.confidenceScore = progress.confidenceScore
        self.totalSuccessReps = Int32(progress.totalSuccessReps)
        self.totalFailedReps = Int32(progress.totalFailedReps)
        self.maintenanceTier = Int16(progress.maintenanceTier)
        self.nextReviewDate = progress.nextReviewDate
        self.lastPracticedAt = progress.lastPracticedAt
        self.createdAt = progress.createdAt
        self.modifiedAt = progress.modifiedAt

        // Encode complex types as JSON data
        self.recentSessionsData = try? Self.encoder.encode(progress.recentSessions)
        self.practicedContextsData = try? Self.encoder.encode(progress.practicedContexts)
    }

    /// Create a new CDSkillProgress from a SkillProgress struct
    static func create(from progress: SkillProgress, in context: NSManagedObjectContext) -> CDSkillProgress {
        let cdProgress = CDSkillProgress(context: context)
        cdProgress.update(from: progress)
        return cdProgress
    }

    // MARK: - Convert to Swift Struct

    /// Convert to SkillProgress struct
    func toSkillProgress() -> SkillProgress? {
        guard let id = self.id,
              let skillId = self.skillId,
              let phaseString = self.phase,
              let phase = SkillLearningPhase(rawValue: phaseString),
              let createdAt = self.createdAt,
              let modifiedAt = self.modifiedAt else {
            return nil
        }

        // Decode complex types
        var recentSessions: [SessionOutcome] = []
        if let data = self.recentSessionsData {
            recentSessions = (try? Self.decoder.decode([SessionOutcome].self, from: data)) ?? []
        }

        var practicedContexts: [TrainingContext] = []
        if let data = self.practicedContextsData {
            practicedContexts = (try? Self.decoder.decode([TrainingContext].self, from: data)) ?? []
        }

        return SkillProgress(
            id: id,
            skillId: skillId,
            phase: phase,
            proofingLevels: ProofingLevels(
                duration: Int(self.durationLevel),
                distance: Int(self.distanceLevel),
                distraction: Int(self.distractionLevel)
            ),
            confidenceScore: self.confidenceScore,
            totalSuccessReps: Int(self.totalSuccessReps),
            totalFailedReps: Int(self.totalFailedReps),
            recentSessions: recentSessions,
            maintenanceTier: Int(self.maintenanceTier),
            nextReviewDate: self.nextReviewDate,
            lastPracticedAt: self.lastPracticedAt,
            practicedContexts: practicedContexts,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

// MARK: - Fetch Request Helpers

extension CDSkillProgress {

    /// Fetch all skill progress records
    static func fetchAll(in context: NSManagedObjectContext) -> [CDSkillProgress] {
        let request = NSFetchRequest<CDSkillProgress>(entityName: "CDSkillProgress")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDSkillProgress.modifiedAt, ascending: false)
        ]
        var results: [CDSkillProgress] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch skill progress by ID
    static func fetch(byId id: UUID, in context: NSManagedObjectContext) -> CDSkillProgress? {
        let request = NSFetchRequest<CDSkillProgress>(entityName: "CDSkillProgress")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        var result: CDSkillProgress?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Fetch skill progress by skillId
    static func fetch(bySkillId skillId: String, in context: NSManagedObjectContext) -> CDSkillProgress? {
        let request = NSFetchRequest<CDSkillProgress>(entityName: "CDSkillProgress")
        request.predicate = NSPredicate(format: "skillId == %@", skillId)
        request.fetchLimit = 1
        var result: CDSkillProgress?
        context.performAndWait {
            result = try? context.fetch(request).first
        }
        return result
    }

    /// Fetch skills due for maintenance review
    static func fetchDueForReview(in context: NSManagedObjectContext) -> [CDSkillProgress] {
        let request = NSFetchRequest<CDSkillProgress>(entityName: "CDSkillProgress")
        request.predicate = NSPredicate(
            format: "phase == %@ AND nextReviewDate != nil AND nextReviewDate <= %@",
            SkillLearningPhase.maintaining.rawValue,
            Date() as CVarArg
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDSkillProgress.nextReviewDate, ascending: true)
        ]
        var results: [CDSkillProgress] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch skills in regression state (needs work)
    static func fetchNeedsWork(in context: NSManagedObjectContext) -> [CDSkillProgress] {
        let request = NSFetchRequest<CDSkillProgress>(entityName: "CDSkillProgress")
        request.predicate = NSPredicate(format: "phase == %@", SkillLearningPhase.needsWork.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDSkillProgress.modifiedAt, ascending: false)
        ]
        var results: [CDSkillProgress] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Fetch skills in active learning phases
    static func fetchActiveLearning(in context: NSManagedObjectContext) -> [CDSkillProgress] {
        let request = NSFetchRequest<CDSkillProgress>(entityName: "CDSkillProgress")
        let activePhases = [
            SkillLearningPhase.luring.rawValue,
            SkillLearningPhase.addingCue.rawValue,
            SkillLearningPhase.proofing.rawValue,
            SkillLearningPhase.generalizing.rawValue
        ]
        request.predicate = NSPredicate(format: "phase IN %@", activePhases)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDSkillProgress.modifiedAt, ascending: false)
        ]
        var results: [CDSkillProgress] = []
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    /// Check if progress exists for a skill
    static func exists(forSkillId skillId: String, in context: NSManagedObjectContext) -> Bool {
        let request = NSFetchRequest<CDSkillProgress>(entityName: "CDSkillProgress")
        request.predicate = NSPredicate(format: "skillId == %@", skillId)
        request.fetchLimit = 1
        var count = 0
        context.performAndWait {
            count = (try? context.count(for: request)) ?? 0
        }
        return count > 0
    }
}
