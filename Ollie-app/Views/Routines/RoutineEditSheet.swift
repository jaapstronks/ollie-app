//
//  RoutineEditSheet.swift
//  Otis-app
//
//  Sheet for editing routine items
//

import SwiftUI
import OtisShared

/// Sheet for editing the daily routine
struct RoutineEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RoutineStore.self) private var routineStore

    @State private var editingItem: RoutineItem?
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(RoutineCategory.allCases, id: \.self) { category in
                    let categoryItems = routineStore.routineItems.filter { $0.category == category }
                    if !categoryItems.isEmpty {
                        Section(category.label) {
                            ForEach(categoryItems) { item in
                                RoutineItemRow(item: item, onTap: {
                                    editingItem = item
                                })
                            }
                            .onDelete { indexSet in
                                deleteItems(categoryItems, at: indexSet)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.Routine.editRoutine)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingItem) { item in
                RoutineItemEditSheet(item: item)
            }
            .sheet(isPresented: $showAddSheet) {
                RoutineItemEditSheet(item: nil)
            }
        }
    }

    private func deleteItems(_ items: [RoutineItem], at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            routineStore.deleteRoutineItem(item)
        }
    }
}

// MARK: - Routine Item Row

private struct RoutineItemRow: View {
    let item: RoutineItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Enable/disable indicator
                Circle()
                    .fill(item.isEnabled ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(.body)
                        .foregroundStyle(item.isEnabled ? .primary : .secondary)

                    if let time = item.formattedTime {
                        Text(time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let linkedType = item.linkedEventType {
                    Text(linkedType)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Routine Item Edit Sheet

private struct RoutineItemEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RoutineStore.self) private var routineStore

    let item: RoutineItem?

    @State private var label: String = ""
    @State private var time: Date = Date()
    @State private var hasTime: Bool = true
    @State private var category: RoutineCategory = .morning
    @State private var isEnabled: Bool = true
    @State private var linkedEventType: String = ""

    private var isEditing: Bool { item != nil }

    private let eventTypes = ["eten", "drinken", "uitlaten", "slapen", "training"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(Strings.Routine.itemLabel, text: $label)

                    Picker(Strings.Routine.itemCategory, selection: $category) {
                        ForEach(RoutineCategory.allCases, id: \.self) { cat in
                            Label(cat.label, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section {
                    Toggle(Strings.Routine.itemTime, isOn: $hasTime)

                    if hasTime {
                        DatePicker(
                            Strings.Routine.itemTime,
                            selection: $time,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }

                Section {
                    Toggle(Strings.Routine.enabled, isOn: $isEnabled)
                }

                Section(header: Text(Strings.Routine.linkedEvent)) {
                    Picker(Strings.Routine.linkedEvent, selection: $linkedEventType) {
                        Text("None").tag("")
                        ForEach(eventTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(Strings.Routine.linkedEventDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isEditing ? item!.label : Strings.Routine.addItem)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        save()
                        dismiss()
                    }
                    .disabled(label.isEmpty)
                }
            }
            .onAppear {
                if let item = item {
                    label = item.label
                    time = item.time ?? Date()
                    hasTime = item.time != nil
                    category = item.category
                    isEnabled = item.isEnabled
                    linkedEventType = item.linkedEventType ?? ""
                }
            }
        }
    }

    private func save() {
        let newItem = RoutineItem(
            id: item?.id ?? UUID(),
            label: label,
            time: hasTime ? time : nil,
            category: category,
            isEnabled: isEnabled,
            linkedEventType: linkedEventType.isEmpty ? nil : linkedEventType,
            sortOrder: item?.sortOrder ?? routineStore.routineItems.count
        )

        if isEditing {
            routineStore.updateRoutineItem(newItem)
        } else {
            routineStore.addRoutineItem(newItem)
        }
    }
}

// MARK: - Preview

#Preview {
    RoutineEditSheet()
        .environment(RoutineStore())
}
