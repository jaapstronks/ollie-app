//
//  MemorialSection.swift
//  Otis-app
//
//  A gentle section for remembering a dog who has passed
//

import SwiftUI
import OtisShared

/// Section in dog profile for memorial features
struct MemorialSection: View {
    let profile: PuppyProfile
    var profileStore: ProfileStore
    var profileId: UUID? = nil

    @State private var showingConfirmation = false
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var showingMemoryBookSheet = false
    @State private var isGeneratingMemoryBook = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        Section {
            if let passedDate = profile.passedDate {
                // Dog has passed - show memorial options
                passedStateContent(passedDate: passedDate)
            } else {
                // Dog is still with us - show subtle discovery text
                aliveStateContent
            }
        } header: {
            if profile.passedDate != nil {
                Label(Strings.Memorial.remembered, systemImage: "heart.fill")
                    .foregroundStyle(.secondary)
            }
        } footer: {
            if profile.passedDate == nil {
                Text(Strings.Memorial.memoryBookDescription)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .confirmationDialog(
            Strings.Memorial.confirmTitle,
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button(Strings.Memorial.idLikeThat) {
                selectedDate = Date()
                showingDatePicker = true
            }
            Button(Strings.Memorial.notYet, role: .cancel) { }
        } message: {
            Text(Strings.Memorial.confirmMessage(name: profile.name))
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showingMemoryBookSheet) {
            MemoryBookGeneratorView(
                profile: profile,
                isPresented: $showingMemoryBookSheet
            )
        }
    }

    // MARK: - Alive State (subtle discovery)

    private var aliveStateContent: some View {
        Button {
            showingConfirmation = true
        } label: {
            HStack {
                Text(Strings.Memorial.markAsPassed)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Passed State (memorial options)

    @ViewBuilder
    private func passedStateContent(passedDate: Date) -> some View {
        // Show passed date
        HStack {
            Label(Strings.Memorial.passedDateLabel, systemImage: "heart")
                .foregroundStyle(.secondary)
            Spacer()
            Text(dateFormatter.string(from: passedDate))
                .foregroundStyle(.secondary)
        }

        // Create/view memory book button
        Button {
            showingMemoryBookSheet = true
        } label: {
            Label(Strings.Memorial.createMemoryBook, systemImage: "book.closed.fill")
        }

        // Undo option (discrete)
        Button(role: .destructive) {
            profileStore.updatePassedDate(nil, for: profileId)
        } label: {
            Text(Strings.Memorial.undoPassedStatus)
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(Strings.Memorial.whenDidPass)
                    .font(.headline)
                    .padding(.top)

                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: profile.birthDate...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(profile.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        showingDatePicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Memorial.continue_) {
                        profileStore.updatePassedDate(selectedDate, for: profileId)
                        showingDatePicker = false
                        // Show memory book generator after a brief moment
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.5))
                            showingMemoryBookSheet = true
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Alive") {
    Form {
        MemorialSection(
            profile: PuppyProfile.defaultProfile(
                name: "Luna",
                birthDate: Date().addingTimeInterval(-86400 * 365),
                homeDate: Date().addingTimeInterval(-86400 * 300),
                size: .medium
            ),
            profileStore: ProfileStore()
        )
    }
}

#Preview("Passed") {
    var profile = PuppyProfile.defaultProfile(
        name: "Max",
        birthDate: Date().addingTimeInterval(-86400 * 365 * 5),
        homeDate: Date().addingTimeInterval(-86400 * 365 * 5 + 86400 * 60),
        size: .large
    )
    profile.passedDate = Date().addingTimeInterval(-86400 * 30)

    return Form {
        MemorialSection(
            profile: profile,
            profileStore: ProfileStore()
        )
    }
}
