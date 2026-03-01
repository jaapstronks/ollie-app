//
//  DiaryCardView.swift
//  Otis-app
//
//  Large photo card for diary view mode with date and caption

import SwiftUI
import OtisShared

/// A large photo card showing one photo per day with date and caption
struct DiaryCardView: View {
    let event: PuppyEvent
    @State private var image: UIImage?

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Formatted date string (e.g., "February 15, 2026")
    private var formattedDate: String {
        event.time.formatted(date: .long, time: .omitted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo - full width, 4:3 aspect ratio
            GeometryReader { geometry in
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.width * 0.75)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(.tertiarySystemBackground))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                            }
                    }
                }
            }
            .aspectRatio(4/3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Date and caption
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 4)
        }
        .task {
            loadImage()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(formattedDate)\(event.note.map { ", \($0)" } ?? "")")
        .accessibilityHint("Double-tap to view full photo")
    }

    private func loadImage() {
        // Load full photo for diary view (not thumbnail)
        guard let path = event.photo else { return }

        let url = documentsURL.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url),
              let loaded = UIImage(data: data) else { return }
        image = loaded
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            DiaryCardView(event: PuppyEvent(
                time: Date(),
                type: .milestone,
                note: "First time at the dog park! He was so excited to meet other puppies."
            ))

            DiaryCardView(event: PuppyEvent(
                time: Date().addingTimeInterval(-86400),
                type: .sociaal,
                note: nil
            ))
        }
        .padding()
    }
}
