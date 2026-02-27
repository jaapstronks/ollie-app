//
//  StartCoverageGapSheet.swift
//  Ollie-app
//
//  Sheet for starting a coverage gap when puppy is cared for by someone else
//

import SwiftUI
import OllieShared

/// Sheet for starting a coverage gap
struct StartCoverageGapSheet: View {
    let onSave: (CoverageGapType, Date, String?, String?) -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedType: CoverageGapType?
    @State private var startTime = Date()
    @State private var location = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon and title
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.clock.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)

                        Text(Strings.CoverageGap.startTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Gap type selection
                    VStack(alignment: .leading, spacing: 12) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(CoverageGapType.allCases, id: \.self) { type in
                                GapTypeButton(
                                    type: type,
                                    isSelected: selectedType == type,
                                    onSelect: {
                                        selectedType = type
                                        HapticFeedback.selection()
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Start time picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.CoverageGap.startTime)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        DatePicker(
                            "",
                            selection: $startTime,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.horizontal)
                    }

                    // Optional location
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(Strings.CoverageGap.locationPlaceholder, text: $location)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }

                    // Optional note
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(Strings.CoverageGap.notePlaceholder, text: $note)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }

                    // Start button
                    Button {
                        guard let type = selectedType else { return }
                        HapticFeedback.medium()
                        onSave(
                            type,
                            startTime,
                            location.isEmpty ? nil : location,
                            note.isEmpty ? nil : note
                        )
                    } label: {
                        Text(Strings.CoverageGap.startButton)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedType != nil ? Color.orange : Color.gray.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(selectedType == nil)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                }
            }
            .navigationTitle(Strings.CoverageGap.eventLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        onCancel()
                    }
                }
            }
        }
    }
}

/// Button for selecting a gap type
private struct GapTypeButton: View {
    let type: CoverageGapType
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(type.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.orange : GlassButtonHelpers.glassColor(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.orange : Color.primary.opacity(0.1),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Strings.CoverageGap.gapTypeAccessibility(type.label))
    }
}

#Preview {
    StartCoverageGapSheet(
        onSave: { type, time, location, note in
            print("Start gap: \(type), \(time), \(location ?? ""), \(note ?? "")")
        },
        onCancel: { print("Cancel") }
    )
}
