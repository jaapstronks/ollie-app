//
//  MemoryBookService.swift
//  Ollie-app
//
//  Generates a memory book PDF for a dog who has passed
//

import CoreData
import Foundation
import OllieShared
import os
import PDFKit
import UIKit

/// Service for generating memory book PDFs
@MainActor
class MemoryBookService: ObservableObject {

    // MARK: - Published State

    @Published var isGenerating = false
    @Published var progress: Double = 0.0
    @Published var currentStep: String = ""
    @Published var generatedPDFURL: URL?

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private let logger = Logger.ollie(category: "MemoryBookService")
    private let fileManager = FileManager.default

    // MARK: - Constants

    private let pageWidth: CGFloat = 612  // US Letter width in points
    private let pageHeight: CGFloat = 792 // US Letter height in points
    private let margin: CGFloat = 50
    private let photoSize: CGFloat = 150

    // MARK: - Init

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    private var viewContext: NSManagedObjectContext {
        persistenceController.viewContext
    }

    // MARK: - Generate Memory Book

    /// Generate a memory book PDF for the given profile
    func generateMemoryBook(for profile: PuppyProfile) async throws -> URL {
        isGenerating = true
        progress = 0.0
        currentStep = Strings.Memorial.gatheringMemories
        generatedPDFURL = nil

        defer { isGenerating = false }

        // Gather all the data
        progress = 0.1
        let memoryData = await gatherMemoryData(for: profile)

        // Generate PDF
        progress = 0.3
        currentStep = Strings.Memorial.generating
        let pdfURL = try generatePDF(profile: profile, data: memoryData)

        progress = 1.0
        generatedPDFURL = pdfURL
        logger.info("Memory book generated at \(pdfURL.path)")

        return pdfURL
    }

    // MARK: - Data Gathering

    private func gatherMemoryData(for profile: PuppyProfile) async -> MemoryBookData {
        let endDate = profile.passedDate ?? Date()
        let startDate = profile.homeDate

        // Fetch all events
        let allEvents = await fetchAllEvents(from: startDate, to: endDate)

        // Categorize events
        let milestoneEvents = allEvents.filter { $0.type == .milestone }
        let walkEvents = allEvents.filter { $0.type == .uitlaten }
        let trainingEvents = allEvents.filter { $0.type == .training }
        let socialEvents = allEvents.filter { $0.type == .sociaal }
        let mealEvents = allEvents.filter { $0.type == .eten }
        let sleepEvents = allEvents.filter { $0.type == .slapen }
        let eventsWithPhotos = allEvents.filter { $0.photo != nil }

        // Extract unique places from walks
        let places = extractUniquePlaces(from: walkEvents)

        // Extract unique friends from social events
        let friends = extractUniqueFriends(from: socialEvents)

        // Extract training exercises
        let exercises = extractTrainingExercises(from: trainingEvents)

        // Calculate days together
        let daysTogether = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0

        return MemoryBookData(
            milestoneEvents: milestoneEvents,
            walkCount: walkEvents.count,
            mealCount: mealEvents.count,
            sleepCount: sleepEvents.count,
            places: places,
            friends: friends,
            exercises: exercises,
            eventsWithPhotos: eventsWithPhotos,
            daysTogether: daysTogether
        )
    }

    private func fetchAllEvents(from startDate: Date, to endDate: Date) async -> [PuppyEvent] {
        let cdEvents = CDPuppyEvent.fetchEvents(from: startDate, to: endDate, in: viewContext)
        return cdEvents.compactMap { $0.toPuppyEvent() }.sorted { $0.time < $1.time }
    }

    private func extractUniquePlaces(from walkEvents: [PuppyEvent]) -> [String] {
        var places = Set<String>()
        for event in walkEvents {
            if let spotName = event.spotName, !spotName.isEmpty {
                places.insert(spotName)
            } else if let note = event.note, !note.isEmpty {
                places.insert(note)
            }
        }
        return Array(places).sorted()
    }

    private func extractUniqueFriends(from socialEvents: [PuppyEvent]) -> [String] {
        var friends = Set<String>()
        for event in socialEvents {
            if let who = event.who, !who.isEmpty {
                friends.insert(who)
            }
        }
        return Array(friends).sorted()
    }

    private func extractTrainingExercises(from trainingEvents: [PuppyEvent]) -> [(exercise: String, count: Int)] {
        var exerciseCounts: [String: Int] = [:]
        for event in trainingEvents {
            if let exercise = event.exercise, !exercise.isEmpty {
                exerciseCounts[exercise, default: 0] += 1
            }
        }
        return exerciseCounts.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }
    }

    // MARK: - PDF Generation

    private func generatePDF(profile: PuppyProfile, data: MemoryBookData) throws -> URL {
        let pdfMetaData = [
            kCGPDFContextCreator: "Ollie - Puppy Logbook",
            kCGPDFContextAuthor: "Ollie App",
            kCGPDFContextTitle: "In Loving Memory of \(profile.name)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none

        let pdfData = renderer.pdfData { context in
            // Cover page
            drawCoverPage(context: context, profile: profile, dateFormatter: dateFormatter)
            progress = 0.4

            // The Beginning
            drawBeginningPage(context: context, profile: profile, dateFormatter: dateFormatter, data: data)
            progress = 0.5

            // Milestones (if any)
            if !data.milestoneEvents.isEmpty {
                drawMilestonesPage(context: context, profile: profile, milestones: data.milestoneEvents, dateFormatter: dateFormatter)
            }
            progress = 0.6

            // Adventures / Places
            if !data.places.isEmpty {
                drawAdventuresPage(context: context, profile: profile, places: data.places)
            }
            progress = 0.7

            // Learning & Growing
            if !data.exercises.isEmpty {
                drawTrainingPage(context: context, profile: profile, exercises: data.exercises)
            }
            progress = 0.75

            // Friends
            if !data.friends.isEmpty {
                drawFriendsPage(context: context, profile: profile, friends: data.friends)
            }
            progress = 0.8

            // By the Numbers
            drawNumbersPage(context: context, profile: profile, data: data)
            progress = 0.85

            // Photo gallery pages
            if !data.eventsWithPhotos.isEmpty {
                drawPhotoPages(context: context, profile: profile, events: data.eventsWithPhotos, dateFormatter: dateFormatter)
            }
            progress = 0.95

            // Final message page
            drawFinalPage(context: context, profile: profile)
        }

        // Save to temp directory
        let fileName = "MemoryBook_\(profile.name.replacingOccurrences(of: " ", with: "_"))_\(UUID().uuidString.prefix(8)).pdf"
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
        try pdfData.write(to: tempURL)

        return tempURL
    }

    // MARK: - Page Drawing

    private func drawCoverPage(context: UIGraphicsPDFRendererContext, profile: PuppyProfile, dateFormatter: DateFormatter) {
        context.beginPage()

        let contentRect = CGRect(x: margin, y: margin, width: pageWidth - margin * 2, height: pageHeight - margin * 2)

        // Profile photo (if exists)
        var yOffset: CGFloat = contentRect.minY + 100

        if let photoFilename = profile.profilePhotoFilename,
           let image = ProfilePhotoStore.shared.load(filename: photoFilename) {
            let photoRect = CGRect(
                x: (pageWidth - 200) / 2,
                y: yOffset,
                width: 200,
                height: 200
            )
            // Draw circular photo
            let path = UIBezierPath(ovalIn: photoRect)
            context.cgContext.saveGState()
            path.addClip()
            image.draw(in: photoRect)
            context.cgContext.restoreGState()
            yOffset += 230
        }

        // "In Loving Memory"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .light),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let titleText = Strings.Memorial.coverTitle
        let titleSize = titleText.size(withAttributes: titleAttributes)
        titleText.draw(
            at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: yOffset),
            withAttributes: titleAttributes
        )
        yOffset += 40

        // Dog's name
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let nameSize = profile.name.size(withAttributes: nameAttributes)
        profile.name.draw(
            at: CGPoint(x: (pageWidth - nameSize.width) / 2, y: yOffset),
            withAttributes: nameAttributes
        )
        yOffset += 70

        // Dates
        let birthDateStr = dateFormatter.string(from: profile.birthDate)
        let passedDateStr = profile.passedDate.map { dateFormatter.string(from: $0) } ?? ""

        let dateText = "\(birthDateStr) — \(passedDateStr)"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let dateSize = dateText.size(withAttributes: dateAttributes)
        dateText.draw(
            at: CGPoint(x: (pageWidth - dateSize.width) / 2, y: yOffset),
            withAttributes: dateAttributes
        )
    }

    private func drawBeginningPage(context: UIGraphicsPDFRendererContext, profile: PuppyProfile, dateFormatter: DateFormatter, data: MemoryBookData) {
        context.beginPage()

        var yOffset: CGFloat = margin + 50

        // Title
        drawSectionTitle(Strings.Memorial.theBeginning, at: &yOffset)
        yOffset += 30

        // "On [date], [name] came home."
        let homeDateStr = dateFormatter.string(from: profile.homeDate)
        let cameHomeText = Strings.Memorial.cameHome(name: profile.name, date: homeDateStr)
        drawBodyText(cameHomeText, at: &yOffset)
        yOffset += 20

        // Age when arrived
        let weeksOld = Calendar.current.dateComponents([.weekOfYear], from: profile.birthDate, to: profile.homeDate).weekOfYear ?? 0
        let weeksText = Strings.Memorial.weeksOldWhenArrived(weeks: weeksOld)
        drawBodyText(weeksText, at: &yOffset, color: .secondaryLabel)
    }

    private func drawMilestonesPage(context: UIGraphicsPDFRendererContext, profile: PuppyProfile, milestones: [PuppyEvent], dateFormatter: DateFormatter) {
        context.beginPage()

        var yOffset: CGFloat = margin + 50

        drawSectionTitle(Strings.Memorial.milestones, at: &yOffset)
        yOffset += 30

        for milestone in milestones.prefix(15) {
            let dateStr = dateFormatter.string(from: milestone.time)
            let note = milestone.note ?? "Milestone"

            drawBodyText("• \(dateStr): \(note)", at: &yOffset)
            yOffset += 10

            if yOffset > pageHeight - margin - 50 {
                break
            }
        }
    }

    private func drawAdventuresPage(context: UIGraphicsPDFRendererContext, profile: PuppyProfile, places: [String]) {
        context.beginPage()

        var yOffset: CGFloat = margin + 50

        drawSectionTitle(Strings.Memorial.adventures, at: &yOffset)
        yOffset += 20

        let exploredText = Strings.Memorial.exploredPlaces(count: places.count)
        drawBodyText(exploredText, at: &yOffset, color: .secondaryLabel)
        yOffset += 30

        for place in places.prefix(20) {
            drawBodyText("• \(place)", at: &yOffset)
            yOffset += 10

            if yOffset > pageHeight - margin - 50 {
                break
            }
        }
    }

    private func drawTrainingPage(context: UIGraphicsPDFRendererContext, profile: PuppyProfile, exercises: [(exercise: String, count: Int)]) {
        context.beginPage()

        var yOffset: CGFloat = margin + 50

        drawSectionTitle(Strings.Memorial.learningAndGrowing, at: &yOffset)
        yOffset += 30

        for (exercise, count) in exercises.prefix(15) {
            let text = Strings.Memorial.practicedExercise(name: profile.name, exercise: exercise, count: count)
            drawBodyText(text, at: &yOffset)
            yOffset += 10

            if yOffset > pageHeight - margin - 50 {
                break
            }
        }
    }

    private func drawFriendsPage(context: UIGraphicsPDFRendererContext, profile: PuppyProfile, friends: [String]) {
        context.beginPage()

        var yOffset: CGFloat = margin + 50

        drawSectionTitle(Strings.Memorial.friends, at: &yOffset)
        yOffset += 20

        let friendsText = Strings.Memorial.madeFriends(count: friends.count)
        drawBodyText(friendsText, at: &yOffset, color: .secondaryLabel)
        yOffset += 30

        for friend in friends.prefix(20) {
            drawBodyText("• \(friend)", at: &yOffset)
            yOffset += 10

            if yOffset > pageHeight - margin - 50 {
                break
            }
        }
    }

    private func drawNumbersPage(context: UIGraphicsPDFRendererContext, profile: PuppyProfile, data: MemoryBookData) {
        context.beginPage()

        var yOffset: CGFloat = margin + 50

        drawSectionTitle(Strings.Memorial.theNumbers, at: &yOffset)
        yOffset += 40

        let stats = [
            Strings.Memorial.daysTogether(count: data.daysTogether),
            Strings.Memorial.walksShared(count: data.walkCount),
            Strings.Memorial.mealsTogether(count: data.mealCount),
            Strings.Memorial.napsObserved(count: data.sleepCount)
        ]

        for stat in stats {
            drawBodyText(stat, at: &yOffset, fontSize: 20)
            yOffset += 30
        }
    }

    private func drawPhotoPages(context: UIGraphicsPDFRendererContext, profile: PuppyProfile, events: [PuppyEvent], dateFormatter: DateFormatter) {
        let photosPerPage = 4
        let chunks = stride(from: 0, to: events.count, by: photosPerPage).map {
            Array(events[$0..<min($0 + photosPerPage, events.count)])
        }

        for (pageIndex, chunk) in chunks.prefix(5).enumerated() { // Max 5 pages of photos
            context.beginPage()

            var yOffset: CGFloat = margin + 20

            if pageIndex == 0 {
                drawSectionTitle(Strings.Memorial.moments, at: &yOffset)
                yOffset += 30
            }

            let photoWidth = (pageWidth - margin * 2 - 20) / 2
            let photoHeight: CGFloat = 180

            for (index, event) in chunk.enumerated() {
                let row = index / 2
                let col = index % 2

                let x = margin + CGFloat(col) * (photoWidth + 20)
                let y = yOffset + CGFloat(row) * (photoHeight + 40)

                if let photoPath = event.photo,
                   let image = loadEventPhoto(relativePath: photoPath) {
                    let photoRect = CGRect(x: x, y: y, width: photoWidth, height: photoHeight)

                    // Draw photo
                    let aspectRatio = image.size.width / image.size.height
                    var drawRect: CGRect
                    if aspectRatio > photoWidth / photoHeight {
                        // Image is wider
                        let height = photoWidth / aspectRatio
                        drawRect = CGRect(x: x, y: y + (photoHeight - height) / 2, width: photoWidth, height: height)
                    } else {
                        // Image is taller
                        let width = photoHeight * aspectRatio
                        drawRect = CGRect(x: x + (photoWidth - width) / 2, y: y, width: width, height: photoHeight)
                    }
                    image.draw(in: drawRect)

                    // Date caption
                    let dateStr = dateFormatter.string(from: event.time)
                    let captionAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                    dateStr.draw(at: CGPoint(x: x, y: y + photoHeight + 5), withAttributes: captionAttributes)
                }
            }
        }
    }

    private func drawFinalPage(context: UIGraphicsPDFRendererContext, profile: PuppyProfile) {
        context.beginPage()

        let contentRect = CGRect(x: margin + 30, y: margin, width: pageWidth - margin * 2 - 60, height: pageHeight - margin * 2)
        var yOffset: CGFloat = contentRect.minY + 150

        // Final message
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 8

        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]

        let message = Strings.Memorial.finalMessage
        let messageRect = CGRect(x: contentRect.minX, y: yOffset, width: contentRect.width, height: 300)
        message.draw(in: messageRect, withAttributes: messageAttributes)

        // Heart at bottom
        let heartAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40),
            .foregroundColor: UIColor.systemPink
        ]
        let heart = "♥"
        let heartSize = heart.size(withAttributes: heartAttributes)
        heart.draw(
            at: CGPoint(x: (pageWidth - heartSize.width) / 2, y: pageHeight - margin - 100),
            withAttributes: heartAttributes
        )
    }

    // MARK: - Drawing Helpers

    private func drawSectionTitle(_ title: String, at yOffset: inout CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: attributes)
        yOffset += 40
    }

    private func drawBodyText(_ text: String, at yOffset: inout CGFloat, fontSize: CGFloat = 14, color: UIColor = .label) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = CGRect(x: margin, y: yOffset, width: pageWidth - margin * 2, height: 100)
        let boundingRect = text.boundingRect(with: textRect.size, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
        text.draw(in: textRect, withAttributes: attributes)
        yOffset += boundingRect.height
    }

    private func loadEventPhoto(relativePath: String) -> UIImage? {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photoURL = documentsURL.appendingPathComponent(relativePath)

        guard fileManager.fileExists(atPath: photoURL.path),
              let image = UIImage(contentsOfFile: photoURL.path) else {
            return nil
        }

        return image
    }

    // MARK: - Cleanup

    func cleanupGeneratedPDF() {
        if let url = generatedPDFURL {
            try? fileManager.removeItem(at: url)
            generatedPDFURL = nil
        }
    }
}

// MARK: - Memory Book Data

private struct MemoryBookData {
    let milestoneEvents: [PuppyEvent]
    let walkCount: Int
    let mealCount: Int
    let sleepCount: Int
    let places: [String]
    let friends: [String]
    let exercises: [(exercise: String, count: Int)]
    let eventsWithPhotos: [PuppyEvent]
    let daysTogether: Int
}
