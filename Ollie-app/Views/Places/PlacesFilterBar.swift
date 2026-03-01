//
//  PlacesFilterBar.swift
//  Otis-app
//
//  Horizontal scrollable filter chips for the expanded places map
//

import SwiftUI
import OtisShared

/// Filter categories for the places map
enum PlacesFilterCategory: String, CaseIterable, Identifiable {
    case spots
    case discovered
    case contacts
    case photos

    var id: String { rawValue }

    var label: String {
        switch self {
        case .spots: return Strings.Places.filterSpots
        case .discovered: return Strings.Places.filterDogParks
        case .contacts: return Strings.Places.filterContacts
        case .photos: return Strings.Places.filterPhotos
        }
    }

    var icon: String {
        switch self {
        case .spots: return "mappin.circle.fill"
        case .discovered: return "dog.fill"
        case .contacts: return "person.fill"
        case .photos: return "camera.fill"
        }
    }

    /// Category-specific color for filter chips
    var categoryColor: Color {
        switch self {
        case .spots: return .otisSuccess     // Green - places/outdoor
        case .discovered: return .otisInfo   // Blue - discovery
        case .contacts: return .otisPurple   // Purple - social/training
        case .photos: return .otisAccent     // Gold - moments
        }
    }
}

/// Horizontal scrollable filter bar for places map
struct PlacesFilterBar: View {
    @Binding var activeFilters: Set<PlacesFilterCategory>
    @Binding var selectedContactTypes: Set<ContactType>
    @Binding var selectedSpotCategories: Set<SpotCategory>
    @Binding var selectedDiscoveryTypes: Set<DiscoverablePlaceType>

    @State private var showingContactTypeSheet = false
    @State private var showingSpotCategorySheet = false
    @State private var showingDiscoveryTypeSheet = false

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
                        hasSubfilter: category == .contacts || category == .spots || category == .discovered,
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
        .sheet(isPresented: $showingDiscoveryTypeSheet) {
            DiscoveryTypeFilterSheet(selectedTypes: $selectedDiscoveryTypes)
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
        case .discovered:
            showingDiscoveryTypeSheet = true
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
        case .discovered:
            let allCount = DiscoverablePlaceType.allCases.count
            return selectedDiscoveryTypes.count < allCount ? selectedDiscoveryTypes.count : nil
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
    var selectedColor: Color = .otisAccent
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
                                    .foregroundStyle(Color.otisAccent)
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
                                        .foregroundStyle(Color.otisAccent)
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
                                    .foregroundStyle(Color.otisAccent)
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
                                        .foregroundStyle(Color.otisAccent)
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

// MARK: - Discovery Type Filter Sheet

struct DiscoveryTypeFilterSheet: View {
    @Binding var selectedTypes: Set<DiscoverablePlaceType>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if selectedTypes.count == DiscoverablePlaceType.allCases.count {
                            selectedTypes.removeAll()
                        } else {
                            selectedTypes = Set(DiscoverablePlaceType.allCases)
                        }
                    } label: {
                        HStack {
                            Text(Strings.Places.selectAll)
                            Spacer()
                            if selectedTypes.count == DiscoverablePlaceType.allCases.count {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.otisAccent)
                            }
                        }
                    }
                }

                Section {
                    ForEach(DiscoverablePlaceType.allCases, id: \.self) { type in
                        Button {
                            if selectedTypes.contains(type) {
                                selectedTypes.remove(type)
                            } else {
                                selectedTypes.insert(type)
                            }
                        } label: {
                            HStack {
                                Label(type.label, systemImage: iconForPlaceType(type))
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedTypes.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.otisAccent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.Places.filterDiscoveryTypes)
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

    private func iconForPlaceType(_ type: DiscoverablePlaceType) -> String {
        switch type {
        case .dogParks: return "dog.fill"
        case .vetClinics: return "stethoscope"
        case .petStores: return "bag.fill"
        case .dogFriendlyPlaces: return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PlacesFilterBar(
            activeFilters: .constant([.spots, .contacts]),
            selectedContactTypes: .constant(Set(ContactType.allCases)),
            selectedSpotCategories: .constant(Set(SpotCategory.allCases)),
            selectedDiscoveryTypes: .constant(Set(DiscoverablePlaceType.allCases))
        )
        Spacer()
    }
}
