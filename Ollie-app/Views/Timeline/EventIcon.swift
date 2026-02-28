//
//  EventIcon.swift
//  Ollie-app
//
//  Reusable icon component for event types

import SwiftUI
import OllieShared

/// Displays an SF Symbol icon for an event type with appropriate color
struct EventIcon: View {
    let type: EventType
    var location: EventLocation?
    var size: CGFloat = 24

    var body: some View {
        Image(systemName: type.iconName)
            .font(.system(size: size * 0.85, weight: .medium))
            .foregroundStyle(iconColor)
            .frame(width: size, height: size)
    }

    private var iconColor: Color {
        // Potty events: color based on location
        if type.requiresLocation {
            guard let loc = location else { return .ollieMuted }
            return loc == .buiten ? .ollieSuccess : .ollieDanger
        }
        return type.iconColor
    }
}

/// Large icon variant for sheets and modals
struct EventIconLarge: View {
    let type: EventType
    var location: EventLocation?
    var size: CGFloat = 48

    var body: some View {
        EventIcon(type: type, location: location, size: size)
    }
}

/// Location icon for binnen/buiten picker
struct LocationIcon: View {
    let location: EventLocation
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: location.iconName)
            .font(.system(size: size * 0.85, weight: .medium))
            .foregroundStyle(location.iconColor)
            .frame(width: size, height: size)
    }
}

// MARK: - EventType Icon Extensions

extension EventType {
    /// SF Symbol name for this event type
    var iconName: String {
        switch self {
        case .plassen: return "drop.fill"
        case .poepen: return "circle.inset.filled"
        case .eten: return "fork.knife"
        case .drinken: return "cup.and.saucer.fill"
        case .slapen: return "moon.fill"
        case .ontwaken: return "sun.max.fill"
        case .uitlaten: return "figure.walk"
        case .tuin: return "leaf.fill"
        case .training: return "scope"
        case .bench: return "house.fill"
        case .sociaal: return "pawprint.fill"
        case .milestone: return "star.fill"
        case .gedrag: return "bolt.fill"
        case .gewicht: return "scalemass.fill"
        case .moment: return "camera.fill"
        case .medicatie: return "pills.fill"
        case .coverageGap: return "person.badge.clock.fill"
        }
    }

    /// Default icon color (when location doesn't apply)
    /// Colors match the Ollie semantic color system:
    /// - Green: positive, outdoor, social
    /// - Gold: food, attention
    /// - Blue: rest, sleep, crate
    /// - Purple: training, learning
    /// - Rose: milestones, celebrations
    /// - Teal: data, measurements
    var iconColor: Color {
        switch self {
        case .plassen, .poepen:
            return .ollieMuted // Overridden by location
        case .eten:
            return .ollieAccent // Warm gold - nourishment
        case .drinken:
            return .ollieInfo // Teal - bodily/data
        case .slapen:
            return .ollieSleep // Blue - rest
        case .ontwaken:
            return .ollieAccent // Warm gold - energy
        case .uitlaten:
            return .ollieSuccess // Green - outdoor activity
        case .tuin:
            return .ollieSuccess // Green - outdoor activity
        case .training:
            return .olliePurple // Purple - learning/mental
        case .bench:
            return .ollieSleep // Blue - rest (matches sleep)
        case .sociaal:
            return .ollieSuccess // Green - positive interaction
        case .milestone:
            return .ollieRose // Rose - celebration
        case .gedrag:
            return .ollieMuted // Gray - neutral observation
        case .gewicht:
            return .ollieHealth // Coral - health/medical
        case .moment:
            return .ollieAccent // Gold - brand accent for photos
        case .medicatie:
            return .ollieHealth // Coral - health/medical
        case .coverageGap:
            return .ollieWarning // Coverage gap status
        }
    }
}

// MARK: - EventLocation Icon Extensions

extension EventLocation {
    /// SF Symbol name for this location
    var iconName: String {
        switch self {
        case .buiten: return "tree.fill"
        case .binnen: return "house.fill"
        }
    }

    /// Icon color for this location
    var iconColor: Color {
        switch self {
        case .buiten: return .ollieSuccess
        case .binnen: return .ollieDanger
        }
    }
}

// MARK: - Previews

#Preview("Event Icons") {
    VStack(spacing: 16) {
        Text("Event Types").font(.headline)

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
            ForEach(EventType.allCases) { type in
                VStack(spacing: 4) {
                    EventIcon(type: type, size: 28)
                    Text(type.label)
                        .font(.caption2)
                }
            }
        }

        Divider()

        Text("Potty with Location").font(.headline)

        HStack(spacing: 24) {
            VStack {
                EventIcon(type: .plassen, location: .buiten, size: 32)
                Text("Buiten").font(.caption)
            }
            VStack {
                EventIcon(type: .plassen, location: .binnen, size: 32)
                Text("Binnen").font(.caption)
            }
            VStack {
                EventIcon(type: .poepen, location: .buiten, size: 32)
                Text("Buiten").font(.caption)
            }
            VStack {
                EventIcon(type: .poepen, location: .binnen, size: 32)
                Text("Binnen").font(.caption)
            }
        }

        Divider()

        Text("Location Icons").font(.headline)

        HStack(spacing: 24) {
            VStack {
                LocationIcon(location: .buiten, size: 40)
                Text("Buiten").font(.caption)
            }
            VStack {
                LocationIcon(location: .binnen, size: 40)
                Text("Binnen").font(.caption)
            }
        }
    }
    .padding()
}

#Preview("Large Icons") {
    HStack(spacing: 20) {
        EventIconLarge(type: .eten)
        EventIconLarge(type: .slapen)
        EventIconLarge(type: .plassen, location: .buiten)
        EventIconLarge(type: .poepen, location: .binnen)
    }
    .padding()
}
