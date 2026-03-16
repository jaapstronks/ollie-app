//
//  VisitSummaryGenerator.swift
//  Ollie-app
//
//  Generates vet visit summaries in PDF and text formats.
//  Includes profile info, conditions, medications, and recent symptoms.
//

import SwiftUI
import UIKit
import OtisShared

/// Generates vet visit preparation summaries in multiple formats.
class VisitSummaryGenerator {

    // MARK: - Text Generation

    /// Generate a plain text summary for clipboard/sharing
    func generateText(
        for profile: PuppyProfile,
        conditions: [HealthCondition],
        medications: [Medication],
        recentSymptoms: [HealthSymptomLog],
        recentCheckIns: [HealthCheckIn],
        allergies: [Allergy],
        recentWeights: [WeightMeasurement]
    ) -> String {
        var lines: [String] = []

        // Header
        lines.append("═══════════════════════════════════════")
        lines.append(Strings.VetVisit.Summary.title)
        lines.append("═══════════════════════════════════════")
        lines.append("")

        // Profile Section
        lines.append(Strings.VetVisit.Summary.profileSection)
        lines.append("───────────────────────────────────────")
        lines.append("\(Strings.VetVisit.Summary.name): \(profile.name)")
        if let breed = profile.breed {
            lines.append("\(Strings.VetVisit.Summary.breed): \(breed)")
        }
        lines.append("\(Strings.VetVisit.Summary.age): \(formatAge(months: profile.ageInMonths))")
        lines.append("\(Strings.VetVisit.Summary.size): \(profile.sizeCategory.label)")
        lines.append("\(Strings.VetVisit.Summary.gender): \(profile.gender.label)")
        if let latestWeight = recentWeights.first {
            lines.append("\(Strings.VetVisit.Summary.weight): \(String(format: "%.1f", latestWeight.weightKg)) kg")
        }
        lines.append("")

        // Allergies Section (if any)
        if !allergies.isEmpty {
            lines.append(Strings.VetVisit.Summary.allergiesSection)
            lines.append("───────────────────────────────────────")
            for allergy in allergies {
                var allergyLine = "• \(allergy.allergen) (\(allergy.severity.label))"
                if let reaction = allergy.reaction, !reaction.isEmpty {
                    allergyLine += " - \(reaction)"
                }
                lines.append(allergyLine)
            }
            lines.append("")
        }

        // Conditions Section
        lines.append(Strings.VetVisit.Summary.conditionsSection)
        lines.append("───────────────────────────────────────")
        if conditions.isEmpty {
            lines.append(Strings.VetVisit.Summary.noConditions)
        } else {
            let activeConditions = conditions.filter { $0.status == .active || $0.status == .monitoring }
            for condition in activeConditions {
                var conditionLine = "• \(condition.displayName)"
                conditionLine += " [\(condition.severity.label), \(condition.status.label)]"
                if let diagnosed = formatDate(condition.diagnosedDate) {
                    conditionLine += "\n  \(Strings.VetVisit.Summary.diagnosed): \(diagnosed)"
                }
                if let notes = condition.vetRecommendations, !notes.isEmpty {
                    conditionLine += "\n  \(Strings.VetVisit.Summary.vetNotes): \(notes)"
                }
                lines.append(conditionLine)
            }
        }
        lines.append("")

        // Medications Section
        lines.append(Strings.VetVisit.Summary.medicationsSection)
        lines.append("───────────────────────────────────────")
        if medications.isEmpty {
            lines.append(Strings.VetVisit.Summary.noMedications)
        } else {
            let activeMeds = medications.filter { $0.isActive }
            for med in activeMeds {
                var medLine = "• \(med.name)"
                if let instructions = med.instructions, !instructions.isEmpty {
                    medLine += " - \(instructions)"
                }
                medLine += " (\(med.recurrence.label))"
                lines.append(medLine)
            }
        }
        lines.append("")

        // Recent Symptoms Section
        lines.append(Strings.VetVisit.Summary.recentSymptomsSection)
        lines.append("───────────────────────────────────────")
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recent = recentSymptoms.filter { $0.createdAt >= thirtyDaysAgo }
        if recent.isEmpty {
            lines.append(Strings.VetVisit.Summary.noRecentSymptoms)
        } else {
            // Group by symptom type
            let grouped = Dictionary(grouping: recent) { $0.symptomType.label }
            for (symptomName, occurrences) in grouped.sorted(by: { $0.value.count > $1.value.count }) {
                let count = occurrences.count
                let symptomLine = "• \(symptomName): \(count)x in last 30 days"
                lines.append(symptomLine)
            }
        }
        lines.append("")

        // Recent Health Assessments
        if !recentCheckIns.isEmpty {
            lines.append(Strings.VetVisit.Summary.assessmentsSection)
            lines.append("───────────────────────────────────────")
            // Group by category and show most recent score
            let grouped = Dictionary(grouping: recentCheckIns) { $0.category }
            for (category, checkIns) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                if let latest = checkIns.max(by: { $0.createdAt < $1.createdAt }) {
                    let scoreDesc = latest.scoreDescription
                    lines.append("• \(category.label): \(latest.score)/5 (\(scoreDesc))")
                }
            }
            lines.append("")
        }

        // Weight Trend (if multiple measurements)
        if recentWeights.count >= 2 {
            lines.append(Strings.VetVisit.Summary.weightTrendSection)
            lines.append("───────────────────────────────────────")
            for weight in recentWeights.prefix(5) {
                if let dateStr = formatDate(weight.date) {
                    lines.append("• \(dateStr): \(String(format: "%.1f", weight.weightKg)) kg")
                }
            }
            lines.append("")
        }

        // Footer
        lines.append("═══════════════════════════════════════")
        lines.append(Strings.VetVisit.Summary.generatedBy)
        if let dateStr = formatDate(Date()) {
            lines.append(dateStr)
        }
        lines.append("═══════════════════════════════════════")

        return lines.joined(separator: "\n")
    }

    // MARK: - PDF Generation

    /// Generate a PDF summary for sharing/printing
    @MainActor
    func generatePDF(
        for profile: PuppyProfile,
        conditions: [HealthCondition],
        medications: [Medication],
        recentSymptoms: [HealthSymptomLog],
        recentCheckIns: [HealthCheckIn],
        allergies: [Allergy],
        recentWeights: [WeightMeasurement]
    ) -> Data {
        // Create the SwiftUI view for the summary
        let summaryView = VisitSummaryPDFView(
            profile: profile,
            conditions: conditions,
            medications: medications,
            recentSymptoms: recentSymptoms,
            recentCheckIns: recentCheckIns,
            allergies: allergies,
            recentWeights: recentWeights
        )

        // Render to image using ImageRenderer
        let renderer = ImageRenderer(content: summaryView)
        renderer.scale = 2.0  // Higher resolution for printing

        // Configure for PDF output
        let pageSize = CGSize(width: 612, height: 792)  // US Letter size in points

        var pdfData = Data()

        renderer.render { size, context in
            // Calculate how many pages we need
            let contentHeight = size.height
            let pageHeight = pageSize.height - 72  // 36pt margins top and bottom
            let pageCount = Int(ceil(contentHeight / pageHeight))

            var box = CGRect(origin: .zero, size: pageSize)

            guard let consumer = CGDataConsumer(data: pdfData as! CFMutableData),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
                return
            }

            for pageIndex in 0..<max(1, pageCount) {
                pdfContext.beginPage(mediaBox: &box)

                // Translate for margins
                pdfContext.translateBy(x: 36, y: pageSize.height - 36)

                // Offset for current page
                let yOffset = CGFloat(pageIndex) * pageHeight
                pdfContext.translateBy(x: 0, y: yOffset)

                // Scale to fit width
                let scale = (pageSize.width - 72) / size.width
                pdfContext.scaleBy(x: scale, y: -scale)

                // Draw the content
                context(pdfContext)

                pdfContext.endPage()
            }

            pdfContext.closePDF()
        }

        // Fallback: if ImageRenderer didn't work, use UIGraphicsPDFRenderer
        if pdfData.isEmpty {
            pdfData = generatePDFUsingUIKit(
                for: profile,
                conditions: conditions,
                medications: medications,
                recentSymptoms: recentSymptoms,
                allergies: allergies,
                recentWeights: recentWeights
            )
        }

        return pdfData
    }

    // MARK: - UIKit PDF Fallback

    private func generatePDFUsingUIKit(
        for profile: PuppyProfile,
        conditions: [HealthCondition],
        medications: [Medication],
        recentSymptoms: [HealthSymptomLog],
        allergies: [Allergy],
        recentWeights: [WeightMeasurement]
    ) -> Data {
        let pageSize = CGSize(width: 612, height: 792)
        let margin: CGFloat = 36
        let contentWidth = pageSize.width - (margin * 2)

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(profile.name) - \(Strings.VetVisit.Summary.title)",
            kCGPDFContextCreator as String: "Ollie App"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = margin

            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.label
            ]
            let title = "\(profile.name) - \(Strings.VetVisit.Summary.title)"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Date
            let dateFont = UIFont.systemFont(ofSize: 12)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            let dateStr = formatDate(Date()) ?? ""
            dateStr.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttributes)
            yPosition += 30

            // Divider
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)

            // Profile Info
            let sectionFont = UIFont.boldSystemFont(ofSize: 16)
            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: sectionFont,
                .foregroundColor: UIColor.label
            ]
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.label
            ]

            Strings.VetVisit.Summary.profileSection.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25

            let profileInfo = [
                "\(Strings.VetVisit.Summary.breed): \(profile.breed ?? "Unknown")",
                "\(Strings.VetVisit.Summary.age): \(formatAge(months: profile.ageInMonths))",
                "\(Strings.VetVisit.Summary.size): \(profile.sizeCategory.label)",
                "\(Strings.VetVisit.Summary.gender): \(profile.gender.label)"
            ]
            for info in profileInfo {
                info.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 18
            }
            yPosition += 15

            // Allergies (if critical)
            let criticalAllergies = allergies.filter { $0.severity == .severe || $0.severity == .lifeThreatening }
            if !criticalAllergies.isEmpty {
                yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)

                let warningAttributes: [NSAttributedString.Key: Any] = [
                    .font: sectionFont,
                    .foregroundColor: UIColor.systemRed
                ]
                Strings.VetVisit.Summary.allergiesSection.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: warningAttributes)
                yPosition += 25

                for allergy in criticalAllergies {
                    let allergyText = "• \(allergy.allergen) (\(allergy.severity.label))"
                    allergyText.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
                yPosition += 15
            }

            // Conditions
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)
            Strings.VetVisit.Summary.conditionsSection.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25

            let activeConditions = conditions.filter { $0.status == .active || $0.status == .monitoring }
            if activeConditions.isEmpty {
                Strings.VetVisit.Summary.noConditions.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 18
            } else {
                for condition in activeConditions {
                    let conditionText = "• \(condition.displayName) (\(condition.severity.label))"
                    conditionText.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
            }
            yPosition += 15

            // Medications
            yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)
            Strings.VetVisit.Summary.medicationsSection.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 25

            let activeMeds = medications.filter { $0.isActive }
            if activeMeds.isEmpty {
                Strings.VetVisit.Summary.noMedications.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 18
            } else {
                for med in activeMeds {
                    var medText = "• \(med.name)"
                    if let instructions = med.instructions, !instructions.isEmpty {
                        medText += " - \(instructions)"
                    }
                    medText += " (\(med.recurrence.label))"
                    medText.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
            }
            yPosition += 15

            // Recent Symptoms
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recent = recentSymptoms.filter { $0.createdAt >= thirtyDaysAgo }

            if !recent.isEmpty {
                yPosition = drawDivider(at: yPosition, margin: margin, width: contentWidth, in: context)
                Strings.VetVisit.Summary.recentSymptomsSection.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25

                let grouped = Dictionary(grouping: recent) { $0.symptomType.label }
                for (symptomName, occurrences) in grouped.sorted(by: { $0.value.count > $1.value.count }).prefix(10) {
                    let symptomText = "• \(symptomName): \(occurrences.count)x in last 30 days"
                    symptomText.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
            }

            // Footer
            let footerFont = UIFont.systemFont(ofSize: 10)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.tertiaryLabel
            ]
            let footer = Strings.VetVisit.Summary.generatedBy
            footer.draw(at: CGPoint(x: margin, y: pageSize.height - margin - 20), withAttributes: footerAttributes)
        }

        return data
    }

    private func drawDivider(
        at yPosition: CGFloat,
        margin: CGFloat,
        width: CGFloat,
        in context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: margin, y: yPosition))
        context.cgContext.addLine(to: CGPoint(x: margin + width, y: yPosition))
        context.cgContext.strokePath()
        return yPosition + 15
    }

    // MARK: - Helpers

    private func formatAge(months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12

        if years > 0 && remainingMonths > 0 {
            return "\(years) year\(years == 1 ? "" : "s"), \(remainingMonths) month\(remainingMonths == 1 ? "" : "s")"
        } else if years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else {
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }

    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - PDF SwiftUI View

/// SwiftUI view for PDF rendering
private struct VisitSummaryPDFView: View {
    let profile: PuppyProfile
    let conditions: [HealthCondition]
    let medications: [Medication]
    let recentSymptoms: [HealthSymptomLog]
    let recentCheckIns: [HealthCheckIn]
    let allergies: [Allergy]
    let recentWeights: [WeightMeasurement]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("\(profile.name) - \(Strings.VetVisit.Summary.title)")
                    .font(.title)
                    .fontWeight(.bold)

                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Profile
            sectionHeader(Strings.VetVisit.Summary.profileSection)
            VStack(alignment: .leading, spacing: 4) {
                if let breed = profile.breed {
                    Text("\(Strings.VetVisit.Summary.breed): \(breed)")
                }
                Text("\(Strings.VetVisit.Summary.age): \(formatAge(months: profile.ageInMonths))")
                Text("\(Strings.VetVisit.Summary.size): \(profile.sizeCategory.label)")
                if let weight = recentWeights.first {
                    Text("\(Strings.VetVisit.Summary.weight): \(String(format: "%.1f", weight.weightKg)) kg")
                }
            }
            .font(.body)

            // Allergies
            if !allergies.isEmpty {
                Divider()
                sectionHeader(Strings.VetVisit.Summary.allergiesSection)
                ForEach(allergies, id: \.id) { allergy in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("\(allergy.allergen) - \(allergy.severity.label)")
                    }
                    .font(.body)
                }
            }

            // Conditions
            Divider()
            sectionHeader(Strings.VetVisit.Summary.conditionsSection)
            let activeConditions = conditions.filter { $0.status == .active || $0.status == .monitoring }
            if activeConditions.isEmpty {
                Text(Strings.VetVisit.Summary.noConditions)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeConditions, id: \.id) { condition in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("• \(condition.displayName)")
                            .fontWeight(.medium)
                        Text("\(condition.severity.label) - \(condition.status.label)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Medications
            Divider()
            sectionHeader(Strings.VetVisit.Summary.medicationsSection)
            let activeMeds = medications.filter { $0.isActive }
            if activeMeds.isEmpty {
                Text(Strings.VetVisit.Summary.noMedications)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeMeds, id: \.id) { med in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("• \(med.name)")
                            .fontWeight(.medium)
                        if let instructions = med.instructions, !instructions.isEmpty {
                            Text("\(instructions) - \(med.recurrence.label)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(med.recurrence.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Recent Symptoms
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recent = recentSymptoms.filter { $0.createdAt >= thirtyDaysAgo }
            if !recent.isEmpty {
                Divider()
                sectionHeader(Strings.VetVisit.Summary.recentSymptomsSection)
                let grouped = Dictionary(grouping: recent) { $0.symptomType.label }
                ForEach(grouped.keys.sorted(), id: \.self) { symptomName in
                    if let occurrences = grouped[symptomName] {
                        Text("• \(symptomName): \(occurrences.count)x")
                    }
                }
            }

            Spacer()

            // Footer
            Text(Strings.VetVisit.Summary.generatedBy)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(width: 540)  // Approximate content width for letter size
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func formatAge(months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12

        if years > 0 && remainingMonths > 0 {
            return "\(years) year\(years == 1 ? "" : "s"), \(remainingMonths) month\(remainingMonths == 1 ? "" : "s")"
        } else if years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else {
            return "\(months) month\(months == 1 ? "" : "s")"
        }
    }
}
