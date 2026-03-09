//
//  EditEventSheet.swift
//  Otis-app
//

import SwiftUI
import OtisShared

/// Sheet for editing an existing event
struct EditEventSheet: View {
    let event: PuppyEvent
    let onSave: (PuppyEvent) -> Void
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var time: Date
    @State private var location: EventLocation?
    @State private var napLocation: NapLocation?
    @State private var note: String
    @State private var who: String
    @State private var exercise: String
    @State private var result: String
    @State private var durationMin: String
    @State private var weightKg: String
    @State private var showingDeleteConfirmation = false
    @State private var showingLikersSheet = false
    @State private var showingPhotoViewer = false
    @State private var localEvent: PuppyEvent

    @EnvironmentObject private var eventStore: EventStore

    /// Get the CloudKit record ID of who logged this event
    private var loggedByRecordID: String? {
        event.loggedBy
    }

    /// Check if event was logged by someone else
    private var wasLoggedByOther: Bool {
        guard let recordID = loggedByRecordID else { return false }
        return !UserIdentityStore.shared.isCurrentUser(recordID)
    }

    init(event: PuppyEvent, onSave: @escaping (PuppyEvent) -> Void, onDelete: (() -> Void)? = nil) {
        self.event = event
        self.onSave = onSave
        self.onDelete = onDelete

        // Initialize state with existing values
        _time = State(initialValue: event.time)
        _location = State(initialValue: event.location)
        _napLocation = State(initialValue: event.napLocation)
        _note = State(initialValue: event.note ?? "")
        _who = State(initialValue: event.who ?? "")
        _exercise = State(initialValue: event.exercise ?? "")
        _result = State(initialValue: event.result ?? "")
        _durationMin = State(initialValue: event.durationMin.map { String($0) } ?? "")
        _weightKg = State(initialValue: event.weightKg.map { String($0) } ?? "")
        _localEvent = State(initialValue: event)
    }

    var body: some View {
        NavigationStack {
            List {
                // Event type header (not editable)
                Section {
                    HStack(spacing: 12) {
                        EventIconLarge(type: event.type, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.type.label)
                                .font(.title2)
                                .fontWeight(.semibold)

                            // Show attribution if logged by someone else
                            if wasLoggedByOther {
                                HStack(spacing: 4) {
                                    UserAvatarFromRecordID(cloudKitRecordID: loggedByRecordID, size: 14)
                                    Text(ParticipantResolver.shared.resolve(cloudKitRecordID: loggedByRecordID ?? "").displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Spacer()

                        // Like button
                        LikeButton(event: localEvent) {
                            toggleLike()
                        }
                    }
                }

                // Likes section (if any likes exist)
                if localEvent.hasLikes {
                    Section {
                        Button {
                            showingLikersSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                                Text(Strings.Likes.likedBy)
                                Spacer()
                                Text("\(localEvent.likeCount)")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Photo section (if event has a photo)
                if event.photo != nil {
                    Section {
                        Button {
                            showingPhotoViewer = true
                        } label: {
                            EventThumbnailView(event: event)
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }

                // Time picker
                Section(Strings.QuickLogSheet.time) {
                    DatePicker(
                        Strings.QuickLogSheet.time,
                        selection: $time,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .accessibilityIdentifier("EDIT_EVENT_TIME_PICKER")
                }

                // Location picker (for potty events)
                if event.type.requiresLocation {
                    Section(Strings.LocationPicker.title) {
                        Picker(Strings.LocationPicker.title, selection: $location) {
                            Text(Strings.EventLocation.outside).tag(EventLocation?.some(.buiten))
                            Text(Strings.EventLocation.inside).tag(EventLocation?.some(.binnen))
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Nap location picker (for sleep events)
                if event.type == .slapen {
                    Section(Strings.NapLocation.wherePrompt) {
                        Picker(Strings.NapLocation.wherePrompt, selection: $napLocation) {
                            Text(Strings.Common.notSet).tag(NapLocation?.none)
                            ForEach(NapLocation.allCases, id: \.self) { loc in
                                Label(loc.label, systemImage: loc.icon).tag(NapLocation?.some(loc))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Note
                Section(Strings.LogEvent.note) {
                    TextField(Strings.LogEvent.notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("EDIT_EVENT_NOTE_FIELD")
                }

                // Social event: who
                if event.type == .sociaal {
                    Section(Strings.LogEvent.who) {
                        TextField(Strings.LogEvent.whoPlaceholder, text: $who)
                    }
                }

                // Training event: exercise and result
                if event.type == .training {
                    Section(Strings.LogEvent.training) {
                        TextField(Strings.LogEvent.exercise, text: $exercise)
                        TextField(Strings.LogEvent.result, text: $result)
                    }
                }

                // Weight event
                if event.type == .gewicht {
                    Section(Strings.Health.weight) {
                        TextField(Strings.Health.weightPlaceholder, text: $weightKg)
                            .keyboardType(.decimalPad)
                    }
                }

                // Duration (optional for all events)
                Section(Strings.LogEvent.duration) {
                    TextField(Strings.Common.minutesFull, text: $durationMin)
                        .keyboardType(.numberPad)
                }

                // Delete button
                if onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text(Strings.Common.delete)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.Common.edit)
            .confirmationDialog(
                Strings.Timeline.deleteConfirmTitle,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Common.delete, role: .destructive) {
                    onDelete?()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                    .accessibilityIdentifier("EDIT_EVENT_CANCEL_BUTTON")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveEvent()
                    }
                    .accessibilityIdentifier("EDIT_EVENT_SAVE_BUTTON")
                }
            }
            .sheet(isPresented: $showingLikersSheet) {
                LikersSheet(event: localEvent)
            }
            .fullScreenCover(isPresented: $showingPhotoViewer) {
                MediaPreviewView(event: event) {
                    // Photo deleted - dismiss the edit sheet entirely
                    dismiss()
                }
            }
        }
    }

    private func toggleLike() {
        if let updated = eventStore.toggleLike(on: localEvent) {
            localEvent = updated
        }
    }

    private func saveEvent() {
        var updatedEvent = event
        updatedEvent.time = time
        updatedEvent.location = location
        updatedEvent.napLocation = napLocation
        updatedEvent.note = note.nilIfBlank
        updatedEvent.who = who.nilIfBlank
        updatedEvent.exercise = exercise.nilIfBlank
        updatedEvent.result = result.nilIfBlank
        updatedEvent.durationMin = Int(durationMin)
        updatedEvent.weightKg = Double(weightKg)

        HapticFeedback.success()
        onSave(updatedEvent)
    }
}

#Preview {
    EditEventSheet(
        event: PuppyEvent(
            time: Date(),
            type: .plassen,
            location: .buiten,
            note: "Good boy!"
        )
    ) { event in
        print("Saved: \(event)")
    }
    .environmentObject(EventStore())
}
