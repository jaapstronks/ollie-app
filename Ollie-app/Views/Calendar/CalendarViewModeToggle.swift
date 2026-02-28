//
//  CalendarViewModeToggle.swift
//  Ollie-app
//
//  Segmented control for switching between Development and Calendar view modes

import SwiftUI

/// View mode for the Schedule tab (formerly Calendar tab)
enum CalendarViewMode: String, CaseIterable, RawRepresentable {
    case development  // List-based view focused on milestones
    case calendar     // Traditional month grid view
    case contacts     // Contacts list view

    /// Localized label for the view mode
    var label: String {
        switch self {
        case .development:
            return Strings.Calendar.developmentMode
        case .calendar:
            return Strings.Calendar.calendarMode
        case .contacts:
            return Strings.Contacts.title
        }
    }

    /// SF Symbol icon for the view mode
    var icon: String {
        switch self {
        case .development:
            return "chart.bar.fill"
        case .calendar:
            return "calendar"
        case .contacts:
            return "person.crop.circle.fill"
        }
    }
}

/// Sub-mode for the calendar view (week vs month)
enum CalendarGridMode: String, CaseIterable {
    case week   // Week view showing 7 days
    case month  // Month grid view

    var label: String {
        switch self {
        case .week:
            return Strings.Calendar.weekMode
        case .month:
            return Strings.Calendar.monthMode
        }
    }

    var icon: String {
        switch self {
        case .week:
            return "calendar.day.timeline.left"
        case .month:
            return "calendar"
        }
    }
}

/// Segmented control for switching between view modes
struct CalendarViewModeToggle: View {
    @Binding var mode: CalendarViewMode

    var body: some View {
        Picker(selection: $mode) {
            ForEach(CalendarViewMode.allCases, id: \.self) { viewMode in
                Label(viewMode.label, systemImage: viewMode.icon)
                    .tag(viewMode)
            }
        } label: {
            Text("View Mode")
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Calendar view mode")
    }
}

#Preview {
    @Previewable @State var mode: CalendarViewMode = .development

    VStack(spacing: 20) {
        CalendarViewModeToggle(mode: $mode)
            .padding(.horizontal)

        Text("Selected: \(mode.label)")
            .foregroundStyle(.secondary)
    }
}
