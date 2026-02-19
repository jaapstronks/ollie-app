//
//  AllEventsSheet.swift
//  Ollie-app
//
//  V2: Grid showing all event types for logging

import SwiftUI

/// Sheet showing all event types in a grid layout
struct AllEventsSheet: View {
    let onSelect: (EventType) -> Void
    let onCancel: () -> Void

    // Event types not in quick log bar
    private var additionalEventTypes: [EventType] {
        EventType.allCases.filter { !Constants.quickLogTypes.contains($0) }
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Additional event types section
                    Text("Meer events")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(additionalEventTypes) { type in
                            EventTypeButton(type: type) {
                                onSelect(type)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 8)

                    // Quick log types also available here
                    Text("Snelle events")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Constants.quickLogTypes) { type in
                            EventTypeButton(type: type) {
                                onSelect(type)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Log event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        onCancel()
                    }
                }
            }
        }
    }
}

/// Single event type button in the grid
struct EventTypeButton: View {
    let type: EventType
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.medium()
            action()
        } label: {
            VStack(spacing: 6) {
                EventIcon(type: type, size: 28)

                Text(type.label)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AllEventsSheet(
        onSelect: { type in
            print("Selected: \(type)")
        },
        onCancel: {}
    )
}
