//
//  FeatureTipCard.swift
//  Otis-app
//
//  Reusable card component for contextual feature discovery tips.
//  Shows friendly guidance when users first visit a view or when content is empty.
//

import SwiftUI
import OtisShared

/// A card that introduces a feature or provides guidance
/// Use this for first-time tips, empty states, or feature discovery
struct FeatureTipCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let actionLabel: String?
    let onAction: (() -> Void)?
    let onDismiss: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        iconColor: Color = .accentColor,
        title: String,
        message: String,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.onAction = onAction
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            // Text content
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Optional action button
            if let actionLabel = actionLabel, let onAction = onAction {
                Button {
                    onAction()
                } label: {
                    Text(actionLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(iconColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topTrailing) {
            // Dismiss button
            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .padding(8)
                .accessibilityLabel(Strings.Common.cancel)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var cardBackground: some ShapeStyle {
        AnyShapeStyle(Color(.secondarySystemBackground))
    }
}

// MARK: - Convenience Initializers

extension FeatureTipCard {
    /// Creates a tip card from a FeatureTip configuration
    init(tip: FeatureTip, onAction: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.init(
            icon: tip.icon,
            iconColor: tip.iconColor,
            title: tip.title,
            message: tip.message,
            actionLabel: tip.actionLabel,
            onAction: onAction,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Feature Tip Configuration

/// Configuration for a feature discovery tip
struct FeatureTip {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let actionLabel: String?

    init(
        icon: String,
        iconColor: Color = .accentColor,
        title: String,
        message: String,
        actionLabel: String? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
    }
}

// MARK: - Predefined Feature Tips

extension FeatureTip {
    // MARK: - Today View

    /// Tip shown on first visit to Today view
    static var todayIntro: FeatureTip {
        FeatureTip(
            icon: "sun.horizon.fill",
            iconColor: .orange,
            title: Strings.FeatureTips.todayTitle,
            message: Strings.FeatureTips.todayMessage
        )
    }

    // MARK: - Schedule Tab

    /// Tip for Development view in Schedule tab
    static var scheduleDevelopment: FeatureTip {
        FeatureTip(
            icon: "sparkles",
            iconColor: .purple,
            title: Strings.FeatureTips.developmentTitle,
            message: Strings.FeatureTips.developmentMessage
        )
    }

    /// Tip for Calendar view in Schedule tab
    static var scheduleCalendar: FeatureTip {
        FeatureTip(
            icon: "calendar",
            iconColor: .blue,
            title: Strings.FeatureTips.calendarTitle,
            message: Strings.FeatureTips.calendarMessage,
            actionLabel: Strings.FeatureTips.calendarAction
        )
    }

    /// Tip for Contacts view in Schedule tab
    static var scheduleContacts: FeatureTip {
        FeatureTip(
            icon: "person.2.fill",
            iconColor: .green,
            title: Strings.FeatureTips.contactsTitle,
            message: Strings.FeatureTips.contactsMessage,
            actionLabel: Strings.FeatureTips.contactsAction
        )
    }

    // MARK: - Train Tab

    /// Tip shown on first visit to Train tab
    static var trainIntro: FeatureTip {
        FeatureTip(
            icon: "graduationcap.fill",
            iconColor: .indigo,
            title: Strings.FeatureTips.trainTitle,
            message: Strings.FeatureTips.trainMessage
        )
    }

    /// Tip for Skills section in Train tab
    static var trainSkills: FeatureTip {
        FeatureTip(
            icon: "star.fill",
            iconColor: .yellow,
            title: Strings.FeatureTips.skillsTitle,
            message: Strings.FeatureTips.skillsMessage
        )
    }

    /// Tip for Socialization section in Train tab
    static var trainSocialization: FeatureTip {
        FeatureTip(
            icon: "figure.2.and.child.holdinghands",
            iconColor: .pink,
            title: Strings.FeatureTips.socializationTitle,
            message: Strings.FeatureTips.socializationMessage
        )
    }

    // MARK: - Places Tab

    /// Tip for Places/Explore tab
    static var placesIntro: FeatureTip {
        FeatureTip(
            icon: "map.fill",
            iconColor: .teal,
            title: Strings.FeatureTips.placesTitle,
            message: Strings.FeatureTips.placesMessage
        )
    }

    // MARK: - Health Tab

    /// Tip for Health tab
    static var healthIntro: FeatureTip {
        FeatureTip(
            icon: "heart.text.square.fill",
            iconColor: .red,
            title: Strings.FeatureTips.healthTitle,
            message: Strings.FeatureTips.healthMessage
        )
    }

    // MARK: - Appointments

    /// Tip for Appointments view
    static var appointmentsIntro: FeatureTip {
        FeatureTip(
            icon: "calendar.badge.clock",
            iconColor: .blue,
            title: Strings.FeatureTips.appointmentsTitle,
            message: Strings.FeatureTips.appointmentsMessage,
            actionLabel: Strings.FeatureTips.appointmentsAction
        )
    }

    // MARK: - Documents

    /// Tip for Documents view
    static var documentsIntro: FeatureTip {
        FeatureTip(
            icon: "doc.text.fill",
            iconColor: .orange,
            title: Strings.FeatureTips.documentsTitle,
            message: Strings.FeatureTips.documentsMessage,
            actionLabel: Strings.FeatureTips.documentsAction
        )
    }

    // MARK: - Spots

    /// Tip for spot detail view
    static var spotDetail: FeatureTip {
        FeatureTip(
            icon: "mappin.and.ellipse",
            iconColor: .teal,
            title: Strings.FeatureTips.spotDetailTitle,
            message: Strings.FeatureTips.spotDetailMessage
        )
    }

    // MARK: - Training Skills

    /// Tip for training skills view
    static var trainingSkillsIntro: FeatureTip {
        FeatureTip(
            icon: "list.bullet.clipboard.fill",
            iconColor: .indigo,
            title: Strings.FeatureTips.trainingSkillsTitle,
            message: Strings.FeatureTips.trainingSkillsMessage
        )
    }

    // MARK: - Moments Gallery

    /// Tip for moments gallery when populated
    static var momentsGallery: FeatureTip {
        FeatureTip(
            icon: "photo.on.rectangle.angled",
            iconColor: .pink,
            title: Strings.FeatureTips.momentsGalleryTitle,
            message: Strings.FeatureTips.momentsGalleryMessage
        )
    }

    // MARK: - Weight Tracking

    /// Tip for weight chart/growth tracking
    static var weightTracking: FeatureTip {
        FeatureTip(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: .green,
            title: Strings.FeatureTips.weightTrackingTitle,
            message: Strings.FeatureTips.weightTrackingMessage
        )
    }
}

// MARK: - View Modifier for First-Visit Tips

/// Tracks whether a tip has been seen and shows it conditionally
struct FirstVisitTipModifier: ViewModifier {
    let tip: FeatureTip
    let storageKey: String
    let onAction: (() -> Void)?

    @AppStorage private var hasSeenTip: Bool

    init(tip: FeatureTip, storageKey: String, onAction: (() -> Void)? = nil) {
        self.tip = tip
        self.storageKey = storageKey
        self.onAction = onAction
        self._hasSeenTip = AppStorage(wrappedValue: false, storageKey)
    }

    func body(content: Content) -> some View {
        if hasSeenTip {
            content
        } else {
            VStack(spacing: 16) {
                FeatureTipCard(
                    tip: tip,
                    onAction: onAction,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            hasSeenTip = true
                        }
                    }
                )

                content
            }
        }
    }
}

extension View {
    /// Shows a first-visit tip card above the content
    /// - Parameters:
    ///   - tip: The tip configuration to display
    ///   - storageKey: Unique key for persisting whether tip was seen
    ///   - onAction: Optional action when the tip's button is tapped
    func firstVisitTip(
        _ tip: FeatureTip,
        storageKey: String,
        onAction: (() -> Void)? = nil
    ) -> some View {
        modifier(FirstVisitTipModifier(tip: tip, storageKey: storageKey, onAction: onAction))
    }
}

// MARK: - Previews

#Preview("Feature Tip Card") {
    ScrollView {
        VStack(spacing: 16) {
            FeatureTipCard(tip: .todayIntro) {
                print("Dismissed")
            }

            FeatureTipCard(tip: .scheduleCalendar, onAction: {
                print("Action tapped")
            }) {
                print("Dismissed")
            }

            FeatureTipCard(tip: .scheduleContacts, onAction: {
                print("Add contact")
            }) {
                print("Dismissed")
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("All Tips") {
    ScrollView {
        VStack(spacing: 16) {
            FeatureTipCard(tip: .todayIntro, onDismiss: {})
            FeatureTipCard(tip: .scheduleDevelopment, onDismiss: {})
            FeatureTipCard(tip: .scheduleCalendar, onAction: {}, onDismiss: {})
            FeatureTipCard(tip: .scheduleContacts, onAction: {}, onDismiss: {})
            FeatureTipCard(tip: .trainSkills, onDismiss: {})
            FeatureTipCard(tip: .trainSocialization, onDismiss: {})
            FeatureTipCard(tip: .placesIntro, onDismiss: {})
            FeatureTipCard(tip: .healthIntro, onDismiss: {})
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
