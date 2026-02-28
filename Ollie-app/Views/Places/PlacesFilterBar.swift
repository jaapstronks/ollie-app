//
//  PlacesFilterBar.swift
//  Ollie-app
//
//  Horizontal scrollable filter chips for the expanded places map
//

import SwiftUI
import OllieShared

/// Filter categories for the places map
enum PlacesFilterCategory: String, CaseIterable, Identifiable {
    case spots
    case discovered
    case contacts
    case photos
    case favorites

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spots: return Strings.Places.filterSpots
        case .discovered: return Strings.Places.filterDogParks
        case .contacts: return Strings.Places.filterContacts
        case .photos: return Strings.Places.filterPhotos
        case .favorites: return Strings.Places.filterFavorites
        }
    }

    var icon: String {
        switch self {
        case .spots: return "mappin.circle.fill"
        case .discovered: return "dog.fill"
        case .contacts: return "person.fill"
        case .photos: return "camera.fill"
        case .favorites: return "star.fill"
        }
    }

    /// Category-specific color for filter chips
    var categoryColor: Color {
        switch self {
        case .spots: return .ollieSuccess     // Green - places/outdoor
        case .discovered: return .ollieInfo   // Blue - discovery
        case .contacts: return .olliePurple   // Purple - social/training
        case .photos: return .ollieAccent     // Gold - moments
        case .favorites: return .ollieRose    // Rose - special
        }
    }
}

/// Horizontal scrollable filter bar for places map
struct PlacesFilterBar: View {
    @Binding var activeFilters: Set<PlacesFilterCategory>
    @Binding var selectedContactTypes: Set<ContactType>
    @Binding var selectedSpotCategories: Set<SpotCategory>

    @State private var showingContactTypeSheet = false
    @State private var showingSpotCategorySheet = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Main filter chips
                ForEach(PlacesFilterCategory.allCases) { category in
                    FilterChip(
                        label: category.label,
                        icon: category.icon,
                        isSelected: activeFilters.contains(category),
                        selectedColor: category.categoryColor,
                        hasSubfilter: category == .contacts || category == .spots,
                        subfilterCount: subfilterCount(for: category)
                    ) {
                        toggleFilter(category)
                    } onLongPress: {
                        handleLongPress(category)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showingContactTypeSheet) {
            ContactTypeFilterSheet(selectedTypes: $selectedContactTypes)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingSpotCategorySheet) {
            SpotCategoryFilterSheet(selectedCategories: $selectedSpotCategories)
                .presentationDetents([.medium])
        }
    }

    private func toggleFilter(_ category: PlacesFilterCategory) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if activeFilters.contains(category) {
                activeFilters.remove(category)
            } else {
                activeFilters.insert(category)
            }
        }
    }

    private func handleLongPress(_ category: PlacesFilterCategory) {
        switch category {
        case .contacts:
            showingContactTypeSheet = true
        case .spots:
            showingSpotCategorySheet = true
        default:
            break
        }
    }

    private func subfilterCount(for category: PlacesFilterCategory) -> Int? {
        switch category {
        case .contacts:
            let allCount = ContactType.allCases.count
            return selectedContactTypes.count < allCount ? selectedContactTypes.count : nil
        case .spots:
            let allCount = SpotCategory.allCases.count
            return selectedSpotCategories.count < allCount ? selectedSpotCategories.count : nil
        default:
            return nil
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    var selectedColor: Color = .ollieAccent
    var hasSubfilter: Bool = false
    var subfilterCount: Int? = nil
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let count = subfilterCount {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if hasSubfilter {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? selectedColor : Color(.tertiarySystemBackground))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress?()
                }
        )
    }
}

// MARK: - Contact Type Filter Sheet

struct ContactTypeFilterSheet: View {
    @Binding var selectedTypes: Set<ContactType>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if selectedTypes.count == ContactType.allCases.count {
                            selectedTypes.removeAll()
                        } else {
                            selectedTypes = Set(ContactType.allCases)
                        }
                    } label: {
                        HStack {
                            Text(Strings.Places.selectAll)
                            Spacer()
                            if selectedTypes.count == ContactType.allCases.count {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.ollieAccent)
                            }
                        }
                    }
                }

                Section {
                    ForEach(ContactType.allCases, id: \.self) { type in
                        Button {
                            if selectedTypes.contains(type) {
                                selectedTypes.remove(type)
                            } else {
                                selectedTypes.insert(type)
                            }
                        } label: {
                            HStack {
                                Label(type.displayName, systemImage: type.icon)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedTypes.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.ollieAccent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.Places.filterContactTypes)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Spot Category Filter Sheet

struct SpotCategoryFilterSheet: View {
    @Binding var selectedCategories: Set<SpotCategory>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if selectedCategories.count == SpotCategory.allCases.count {
                            selectedCategories.removeAll()
                        } else {
                            selectedCategories = Set(SpotCategory.allCases)
                        }
                    } label: {
                        HStack {
                            Text(Strings.Places.selectAll)
                            Spacer()
                            if selectedCategories.count == SpotCategory.allCases.count {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.ollieAccent)
                            }
                        }
                    }
                }

                Section {
                    ForEach(SpotCategory.allCases, id: \.self) { category in
                        Button {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        } label: {
                            HStack {
                                Label(category.label, systemImage: category.icon)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedCategories.contains(category) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.ollieAccent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.Places.filterSpotCategories)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PlacesFilterBar(
            activeFilters: .constant([.spots, .contacts]),
            selectedContactTypes: .constant(Set(ContactType.allCases)),
            selectedSpotCategories: .constant(Set(SpotCategory.allCases))
        )
        Spacer()
    }
}
