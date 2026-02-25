//
//  AddMilestoneSheet.swift
//  Ollie-app
//
//  Sheet for creating custom milestones (Ollie+ feature)

import SwiftUI
import OllieShared

/// Sheet for adding a custom milestone
struct AddMilestoneSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (Milestone) -> Void

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var profileStore: ProfileStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: MilestoneCategory = .custom
    @State private var notes: String = ""
    @State private var enableReminder: Bool = true
    @State private var reminderDays: Int = 3
    @State private var addToCalendar: Bool = false
    @State private var showCalendarError: Bool = false
    @State private var calendarErrorMessage: String = ""

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title section
                Section {
                    TextField(Strings.Health.customMilestoneTitle, text: $title)
                        .textContentType(.none)
                } header: {
                    Text(Strings.Health.customMilestoneTitle)
                }

                // Date section
                Section {
                    DatePicker(
                        Strings.Health.customMilestoneDate,
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                } header: {
                    Text(Strings.Health.customMilestoneDate)
                }

                // Category section
                Section {
                    Picker(Strings.Health.customMilestoneCategory, selection: $selectedCategory) {
                        ForEach(MilestoneCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(Strings.Health.customMilestoneCategory)
                }

                // Notes section
                Section {
                    TextField(Strings.Health.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(Strings.Health.addNotes)
                } footer: {
                    Text(Strings.Health.optionalNotes)
                }

                // Reminder section
                Section {
                    Toggle(Strings.Health.customMilestoneReminder, isOn: $enableReminder)

                    if enableReminder {
                        Stepper(value: $reminderDays, in: 1...30) {
                            HStack {
                                Text("\(reminderDays)")
                                    .fontWeight(.semibold)
                                Text(Strings.Health.customMilestoneReminderDays)
                            }
                        }
                    }
                } header: {
                    Text(Strings.Health.customMilestoneReminder)
                }

                // Calendar integration (Premium)
                if subscriptionManager.hasAccess(to: .calendarIntegration) {
                    Section {
                        Toggle(Strings.Health.addToCalendar, isOn: $addToCalendar)
                    } header: {
                        Text(Strings.Health.addToCalendar)
                    } footer: {
                        Text(Strings.Health.calendarHelpText)
                    }
                }
            }
            .navigationTitle(Strings.Health.addMilestone)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        createMilestone()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .alert(Strings.Common.calendarSyncFailed, isPresented: $showCalendarError) {
            Button(Strings.Common.ok) { }
        } message: {
            Text(calendarErrorMessage)
        }
    }

    // MARK: - Actions

    private func createMilestone() {
        let milestone = Milestone(
            category: selectedCategory,
            labelKey: title.trimmingCharacters(in: .whitespaces),
            detailKey: notes.isEmpty ? nil : notes,
            fixedDate: selectedDate,
            reminderDaysBefore: enableReminder ? reminderDays : 0,
            icon: selectedCategory.icon,
            isActionable: true,
            isUserDismissable: true,
            sortOrder: 999,  // Custom milestones at the end
            isCustom: true
        )

        // Track custom milestone creation
        Analytics.track(.customMilestoneCreated, properties: [
            "category": selectedCategory.rawValue,
            "has_notes": !notes.isEmpty,
            "has_reminder": enableReminder,
            "add_to_calendar": addToCalendar
        ])

        HapticFeedback.success()
        onAdd(milestone)

        // Handle calendar integration
        if addToCalendar, let profile = profileStore.profile {
            Task {
                do {
                    let hasAccess = try await CalendarService.shared.requestAccess()
                    if hasAccess {
                        _ = try await CalendarService.shared.addMilestone(milestone, profile: profile)
                        // Calendar sync succeeded, dismiss the sheet
                        await MainActor.run {
                            isPresented = false
                        }
                    } else {
                        // Access denied - show error but milestone is still created
                        await MainActor.run {
                            calendarErrorMessage = Strings.Common.calendarAccessDenied
                            showCalendarError = true
                        }
                    }
                } catch {
                    // Calendar sync failed - show error but milestone is still created
                    await MainActor.run {
                        calendarErrorMessage = error.localizedDescription
                        showCalendarError = true
                    }
                }
            }
        } else {
            // No calendar integration requested, dismiss immediately
            isPresented = false
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isPresented = true

    return AddMilestoneSheet(isPresented: $isPresented) { milestone in
        print("Added milestone: \(milestone.localizedLabel)")
    }
    .environmentObject(SubscriptionManager.shared)
    .environmentObject(ProfileStore())
}
