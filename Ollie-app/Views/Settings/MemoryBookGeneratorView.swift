//
//  MemoryBookGeneratorView.swift
//  Ollie-app
//
//  View for generating and sharing the memory book PDF
//

import SwiftUI
import OllieShared

/// View that generates a memory book PDF and allows sharing
struct MemoryBookGeneratorView: View {
    let profile: PuppyProfile
    @Binding var isPresented: Bool

    @StateObject private var service = MemoryBookService()
    @State private var showingShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if service.isGenerating {
                    generatingContent
                } else if let pdfURL = service.generatedPDFURL {
                    completedContent(pdfURL: pdfURL)
                } else if let error = errorMessage {
                    errorContent(error: error)
                } else {
                    // Initial state - start generating
                    Color.clear.onAppear {
                        startGenerating()
                    }
                }
            }
            .padding()
            .navigationTitle(Strings.Memorial.memoryBookTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) {
                        service.cleanupGeneratedPDF()
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = service.generatedPDFURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Generating State

    private var generatingContent: some View {
        VStack(spacing: 20) {
            Spacer()

            // Animated heart
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(.pink)
                .symbolEffect(.pulse, options: .repeating)

            Text(service.currentStep)
                .font(.headline)
                .foregroundStyle(.secondary)

            ProgressView(value: service.progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 200)

            Spacer()
        }
    }

    // MARK: - Completed State

    private func completedContent(pdfURL: URL) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Success icon
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundStyle(.pink)

            Text(Strings.Memorial.memoryBookReady)
                .font(.title2)
                .fontWeight(.semibold)

            Text(Strings.Memorial.saveOrShare)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Share button
            Button {
                showingShareSheet = true
            } label: {
                Label(Strings.Memorial.shareMemoryBook, systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Preview button
            Button {
                previewPDF(at: pdfURL)
            } label: {
                Text("Preview")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Error State

    private func errorContent(error: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                errorMessage = nil
                startGenerating()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    // MARK: - Actions

    private func startGenerating() {
        Task {
            do {
                _ = try await service.generateMemoryBook(for: profile)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func previewPDF(at url: URL) {
        // Open in system PDF viewer
        UIApplication.shared.open(url)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    var profile = PuppyProfile.defaultProfile(
        name: "Luna",
        birthDate: Date().addingTimeInterval(-86400 * 365),
        homeDate: Date().addingTimeInterval(-86400 * 300),
        size: .medium
    )
    profile.passedDate = Date().addingTimeInterval(-86400 * 7)

    return MemoryBookGeneratorView(
        profile: profile,
        isPresented: .constant(true)
    )
}
