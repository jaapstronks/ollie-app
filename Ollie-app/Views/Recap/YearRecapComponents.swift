//
//  YearRecapComponents.swift
//  Otis-app
//
//  Supporting components for YearRecapView
//

import SwiftUI
import OtisShared

// MARK: - Year Stat Box

struct YearStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mini Year Stat

struct MiniYearStat: View {
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Month Highlight Card

struct MonthHighlightCard: View {
    let highlight: MonthHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(highlight.shortMonthName)
                .font(.subheadline)
                .fontWeight(.semibold)

            if let caption = highlight.caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if highlight.walkCount > 0 {
                    StatPill(count: highlight.walkCount, icon: "figure.walk")
                }
                if highlight.trainingCount > 0 {
                    StatPill(count: highlight.trainingCount, icon: "graduationcap")
                }
                if highlight.socialCount > 0 {
                    StatPill(count: highlight.socialCount, icon: "dog")
                }
            }
        }
        .padding(12)
        .frame(width: 140)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let count: Int
    let icon: String

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(count)")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Top Moment Row

struct TopMomentRow: View {
    let moment: TopMoment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForCategory(moment.category))
                .font(.title3)
                .foregroundStyle(colorForCategory(moment.category))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(moment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let subtitle = moment.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func iconForCategory(_ category: TopMomentCategory) -> String {
        switch category {
        case .bestFriend: return "heart.fill"
        case .favoriteSpot: return "mappin.circle.fill"
        case .biggestMilestone: return "star.fill"
        case .mostActiveMonth: return "flame.fill"
        case .longestStreak: return "trophy.fill"
        }
    }

    private func colorForCategory(_ category: TopMomentCategory) -> Color {
        switch category {
        case .bestFriend: return .pink
        case .favoriteSpot: return .blue
        case .biggestMilestone: return .yellow
        case .mostActiveMonth: return .orange
        case .longestStreak: return .purple
        }
    }
}

// MARK: - Year Photo Grid Item

struct YearPhotoGridItem: View {
    let event: PuppyEvent

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .frame(height: 120)
        .cornerRadius(12)
        .clipped()
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let photoPath = event.photo else { return }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let imageURL = documentsURL?.appendingPathComponent(photoPath) else { return }

        if let data = try? Data(contentsOf: imageURL),
           let loadedImage = UIImage(data: data) {
            await MainActor.run {
                self.image = loadedImage
            }
        }
    }
}

// MARK: - Weight Progress Chart

struct WeightProgressChart: View {
    let weights: [MonthWeight]

    var body: some View {
        GeometryReader { geometry in
            let maxWeight = weights.map(\.weightKg).max() ?? 1
            let minWeight = weights.map(\.weightKg).min() ?? 0
            let range = max(maxWeight - minWeight, 1)

            ZStack(alignment: .topLeading) {
                // Grid lines
                VStack {
                    ForEach(0..<4) { _ in
                        Divider()
                        Spacer()
                    }
                    Divider()
                }

                // Weight line
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(max(weights.count - 1, 1))

                    for (index, weight) in weights.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = (weight.weightKg - minWeight) / range
                        let y = height - (CGFloat(normalized) * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.otisPurple, lineWidth: 2)

                // Weight points
                ForEach(Array(weights.enumerated()), id: \.element.id) { index, weight in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(max(weights.count - 1, 1))
                    let x = CGFloat(index) * stepX
                    let normalized = (weight.weightKg - minWeight) / range
                    let y = height - (CGFloat(normalized) * height)

                    Circle()
                        .fill(Color.otisPurple)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
