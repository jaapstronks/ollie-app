//
//  ShareCardView.swift
//  Ollie-app
//
//  Share card template for achievements
//  Generates visually appealing images for sharing

import SwiftUI
import OllieShared

/// A shareable card view for achievements
struct ShareCardView: View {
    let achievement: Achievement
    let puppyName: String
    let puppyPhoto: UIImage?
    let achievementDate: Date
    let aspectRatio: ShareCardAspectRatio

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Content
            VStack(spacing: 16) {
                Spacer()

                // Puppy photo (if available)
                if let photo = puppyPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: photoSize, height: photoSize)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(color: categoryColor.opacity(0.3), radius: 10)
                }

                // Achievement badge
                achievementBadge

                // Achievement text
                VStack(spacing: 8) {
                    Text(achievement.localizedLabel)
                        .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    if achievement.value != nil {
                        Text(achievement.celebrationMessage)
                            .font(.system(size: subtitleFontSize))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Puppy name
                HStack(spacing: 4) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: nameFontSize - 2))
                    Text(puppyName)
                        .font(.system(size: nameFontSize, weight: .semibold))
                }
                .foregroundStyle(categoryColor)
                .padding(.top, 8)

                // Date
                Text(formattedDate)
                    .font(.system(size: dateFontSize))
                    .foregroundStyle(.secondary)

                Spacer()

                // Branding
                branding
            }
            .padding(cardPadding)
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }

    // MARK: - Components

    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                categoryColor.opacity(0.15),
                Color(UIColor.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            // Subtle pattern
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    @ViewBuilder
    private var achievementBadge: some View {
        ZStack {
            Circle()
                .fill(categoryColor.gradient)
                .frame(width: badgeSize, height: badgeSize)
                .shadow(color: categoryColor.opacity(0.4), radius: 10)

            Image(systemName: achievement.category.icon)
                .font(.system(size: badgeIconSize, weight: .semibold))
                .foregroundStyle(.white)

            // Value overlay
            if let value = achievement.value {
                Text("\(value)")
                    .font(.system(size: valueSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                    .offset(x: badgeSize * 0.35, y: -badgeSize * 0.35)
            }
        }
    }

    @ViewBuilder
    private var branding: some View {
        HStack {
            Spacer()
            Text("ollie.app")
                .font(.system(size: brandingFontSize, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Styling

    private var categoryColor: Color {
        switch achievement.category {
        case .pottyStreak: return .ollieAccent
        case .training: return .olliePurple
        case .socialization: return .ollieAccent
        case .health: return .ollieSuccess
        case .lifestyle: return .olliePurple
        case .timeBased: return .ollieRose
        }
    }

    private var formattedDate: String {
        achievementDate.formatted(.dateTime.month(.wide).day().year())
    }

    // MARK: - Sizing

    private var cardSize: CGSize {
        aspectRatio.size
    }

    private var cardPadding: CGFloat {
        switch aspectRatio {
        case .square: return 24
        case .story: return 32
        case .horizontal: return 20
        }
    }

    private var photoSize: CGFloat {
        switch aspectRatio {
        case .square: return 100
        case .story: return 120
        case .horizontal: return 80
        }
    }

    private var badgeSize: CGFloat {
        switch aspectRatio {
        case .square: return 80
        case .story: return 100
        case .horizontal: return 60
        }
    }

    private var badgeIconSize: CGFloat {
        switch aspectRatio {
        case .square: return 36
        case .story: return 44
        case .horizontal: return 28
        }
    }

    private var valueSize: CGFloat {
        switch aspectRatio {
        case .square: return 14
        case .story: return 16
        case .horizontal: return 12
        }
    }

    private var titleFontSize: CGFloat {
        switch aspectRatio {
        case .square: return 24
        case .story: return 28
        case .horizontal: return 20
        }
    }

    private var subtitleFontSize: CGFloat {
        switch aspectRatio {
        case .square: return 16
        case .story: return 18
        case .horizontal: return 14
        }
    }

    private var nameFontSize: CGFloat {
        switch aspectRatio {
        case .square: return 18
        case .story: return 20
        case .horizontal: return 16
        }
    }

    private var dateFontSize: CGFloat {
        switch aspectRatio {
        case .square: return 14
        case .story: return 16
        case .horizontal: return 12
        }
    }

    private var brandingFontSize: CGFloat {
        switch aspectRatio {
        case .square: return 12
        case .story: return 14
        case .horizontal: return 10
        }
    }
}

// MARK: - Aspect Ratios

enum ShareCardAspectRatio: String, CaseIterable {
    case square
    case story
    case horizontal

    var size: CGSize {
        switch self {
        case .square: return CGSize(width: 1080, height: 1080)
        case .story: return CGSize(width: 1080, height: 1920)
        case .horizontal: return CGSize(width: 1200, height: 630)
        }
    }

    var displayName: String {
        switch self {
        case .square: return String(localized: "Square (1:1)")
        case .story: return String(localized: "Story (9:16)")
        case .horizontal: return String(localized: "Horizontal (16:9)")
        }
    }
}

// MARK: - Preview

#Preview("Square") {
    ShareCardView(
        achievement: Achievement.pottyStreak(days: 7, isRecord: true),
        puppyName: "Ollie",
        puppyPhoto: nil,
        achievementDate: Date(),
        aspectRatio: .square
    )
    .scaleEffect(0.3)
}

#Preview("Story") {
    ShareCardView(
        achievement: Achievement.monthlyBirthday(months: 6),
        puppyName: "Ollie",
        puppyPhoto: nil,
        achievementDate: Date(),
        aspectRatio: .story
    )
    .scaleEffect(0.2)
}
