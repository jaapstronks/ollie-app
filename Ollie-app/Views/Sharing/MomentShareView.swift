//
//  MomentShareView.swift
//  Otis-app
//
//  Shareable card view for individual photo moments
//  Creates a beautiful polaroid-style card for social sharing
//

import SwiftUI
import OtisShared

// MARK: - Moment Share Card

/// A shareable card wrapping a PuppyEvent with photo
struct MomentShareCard: ShareableCard {
    let event: PuppyEvent
    let profile: PuppyProfile
    let momentImage: UIImage

    var id: String { event.id.uuidString }
    var type: ShareableCardType { .moment }
    var generatedDate: Date { Date() }

    func cardView(for format: ShareFormat) -> some View {
        MomentShareView(
            event: event,
            profile: profile,
            image: momentImage,
            format: format
        )
    }

    func caption(for platform: SharePlatform) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        if let note = event.note, !note.isEmpty {
            return "\(profile.name): \"\(note)\" - \(dateFormatter.string(from: event.time))"
        } else {
            return Strings.Sharing.momentCaption(name: profile.name, date: dateFormatter.string(from: event.time))
        }
    }
}

// MARK: - Moment Share View

/// A beautiful polaroid-style shareable card for photo moments
struct MomentShareView: View {
    let event: PuppyEvent
    let profile: PuppyProfile
    let image: UIImage
    let format: ShareFormat

    // Sizing based on format
    private var cardSize: CGSize { format.size }

    // Layout proportions
    private var photoPadding: CGFloat {
        switch format {
        case .story: return 48
        case .squarePost: return 40
        case .portrait: return 44
        case .landscape: return 36
        }
    }

    private var bottomAreaHeight: CGFloat {
        switch format {
        case .story: return 320
        case .squarePost: return 200
        case .portrait: return 240
        case .landscape: return 160
        }
    }

    var body: some View {
        ZStack {
            // Gradient background
            backgroundGradient

            VStack(spacing: 0) {
                // Main photo area
                photoSection
                    .padding(.horizontal, photoPadding)
                    .padding(.top, photoPadding)

                Spacer(minLength: 0)

                // Info section (polaroid-style bottom)
                infoSection

                Spacer(minLength: 0)

                // Branding footer
                brandingFooter
                    .padding(.horizontal, photoPadding)
                    .padding(.bottom, photoPadding * 0.6)
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundGradient: some View {
        // Warm, cozy gradient that complements photos
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.96, blue: 0.93), // Warm cream
                Color(red: 0.95, green: 0.92, blue: 0.88), // Soft beige
                Color(red: 0.92, green: 0.89, blue: 0.85)  // Light tan
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Subtle texture overlay
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: cardSize.width * 0.8
                    )
                )
                .offset(x: -cardSize.width * 0.3, y: -cardSize.height * 0.2)
        )
    }

    // MARK: - Photo Section

    @ViewBuilder
    private var photoSection: some View {
        let availableHeight = cardSize.height - bottomAreaHeight - photoPadding * 2
        let photoAreaWidth = cardSize.width - photoPadding * 2

        ZStack {
            // Photo container with shadow
            RoundedRectangle(cornerRadius: photoCornerRadius)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.08), radius: 40, x: 0, y: 20)

            // The photo itself
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: photoAreaWidth - photoInsetPadding * 2,
                       height: availableHeight - photoInsetPadding * 2)
                .clipShape(RoundedRectangle(cornerRadius: photoCornerRadius - 4))
                .clipped()
        }
        .frame(width: photoAreaWidth, height: availableHeight)
    }

    private var photoCornerRadius: CGFloat {
        switch format {
        case .story: return 24
        case .squarePost: return 16
        case .portrait: return 20
        case .landscape: return 12
        }
    }

    private var photoInsetPadding: CGFloat {
        switch format {
        case .story: return 16
        case .squarePost: return 12
        case .portrait: return 14
        case .landscape: return 10
        }
    }

    // MARK: - Info Section

    @ViewBuilder
    private var infoSection: some View {
        VStack(spacing: infoSpacing) {
            // Puppy name with paw and age
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: pawIconSize, weight: .semibold))
                    .foregroundStyle(Color.otisAccent)

                Text(profile.name)
                    .font(.system(size: nameFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.85))

                // Age badge
                if profile.ageInMonths > 0 {
                    Text(ageText)
                        .font(.system(size: ageFontSize, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.otisAccent.opacity(0.15))
                        )
                }
            }

            // Optional note/caption
            if let note = event.note, !note.isEmpty {
                Text("\"\(note)\"")
                    .font(.system(size: noteFontSize, weight: .medium, design: .serif))
                    .foregroundStyle(Color.primary.opacity(0.7))
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, photoPadding)
            }

            // Date
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: dateFontSize - 2))
                Text(formattedDate)
                    .font(.system(size: dateFontSize, weight: .medium))
            }
            .foregroundStyle(Color.secondary.opacity(0.8))
        }
        .padding(.vertical, 16)
    }

    private var infoSpacing: CGFloat {
        switch format {
        case .story: return 16
        case .squarePost: return 12
        case .portrait: return 14
        case .landscape: return 10
        }
    }

    private var pawIconSize: CGFloat {
        switch format {
        case .story: return 28
        case .squarePost: return 22
        case .portrait: return 24
        case .landscape: return 18
        }
    }

    private var nameFontSize: CGFloat {
        switch format {
        case .story: return 42
        case .squarePost: return 32
        case .portrait: return 36
        case .landscape: return 26
        }
    }

    private var ageFontSize: CGFloat {
        switch format {
        case .story: return 20
        case .squarePost: return 16
        case .portrait: return 18
        case .landscape: return 14
        }
    }

    private var noteFontSize: CGFloat {
        switch format {
        case .story: return 26
        case .squarePost: return 20
        case .portrait: return 22
        case .landscape: return 16
        }
    }

    private var dateFontSize: CGFloat {
        switch format {
        case .story: return 20
        case .squarePost: return 16
        case .portrait: return 18
        case .landscape: return 14
        }
    }

    private var ageText: String {
        let months = profile.ageInMonths
        if months < 12 {
            return Strings.Sharing.ageMonths(months)
        } else {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 {
                return Strings.Sharing.ageYears(years)
            } else {
                return Strings.Sharing.ageYearsMonths(years, remainingMonths)
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: event.time)
    }

    // MARK: - Branding Footer

    @ViewBuilder
    private var brandingFooter: some View {
        HStack {
            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: brandingFontSize, weight: .medium))
                    .foregroundStyle(Color.otisAccent.opacity(0.7))

                Text(Strings.Sharing.madeWithOllie)
                    .font(.system(size: brandingFontSize, weight: .medium))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
        }
    }

    private var brandingFontSize: CGFloat {
        switch format {
        case .story: return 18
        case .squarePost: return 14
        case .portrait: return 16
        case .landscape: return 12
        }
    }
}

// MARK: - Preview

#Preview("Story Format") {
    MomentShareView(
        event: PuppyEvent(
            time: Date(),
            type: .moment,
            note: "First snow day adventure!"
        ),
        profile: PuppyProfile.defaultProfile(
            name: "Luna",
            birthDate: Calendar.current.date(byAdding: .month, value: -8, to: Date())!,
            homeDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
            size: .medium
        ),
        image: UIImage(systemName: "photo.fill")!,
        format: .story
    )
    .scaleEffect(0.2)
}

#Preview("Square Format") {
    MomentShareView(
        event: PuppyEvent(
            time: Date(),
            type: .moment,
            note: nil
        ),
        profile: PuppyProfile.defaultProfile(
            name: "Max",
            birthDate: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
            homeDate: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
            size: .large
        ),
        image: UIImage(systemName: "photo.fill")!,
        format: .squarePost
    )
    .scaleEffect(0.35)
}
