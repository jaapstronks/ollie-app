//
//  HealthDocumentsView.swift
//  Otis-app
//
//  Health and documents settings: medications and documents

import SwiftUI
import OtisShared

/// Settings screen for health documents: medications, documents, and food alerts
struct HealthDocumentsView: View {
    var profileStore: ProfileStore
    var medicationStore: MedicationStore
    var documentStore: DocumentStore
    var foodRecallService: FoodRecallService
    let profileId: UUID

    /// The profile being edited (looked up by ID)
    private var targetProfile: PuppyProfile? {
        profileStore.profile(for: profileId)
    }

    var body: some View {
        List {
            if let profile = targetProfile {
                // Medications
                NavigationLink {
                    MedicationSettingsView(
                        profileStore: profileStore,
                        medicationStore: medicationStore,
                        profileId: profileId
                    )
                } label: {
                    SettingsItemRow(
                        icon: "pills.fill",
                        iconColor: .purple,
                        title: Strings.Medications.title,
                        count: profile.medicationSchedule.medications.count
                    )
                }

                // Documents
                NavigationLink {
                    DocumentsView(documentStore: documentStore)
                } label: {
                    SettingsItemRow(
                        icon: "doc.text.fill",
                        iconColor: .blue,
                        title: Strings.Documents.title,
                        count: documentStore.documentCount
                    )
                }

                // Food Recall Alerts
                NavigationLink {
                    FoodRecallSettingsView(foodRecallService: foodRecallService)
                } label: {
                    SettingsItemRow(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: Strings.FoodRecall.title,
                        count: foodRecallService.unacknowledgedRecalls.count
                    )
                }
            }
        }
        .navigationTitle(Strings.Settings.healthDocuments)
    }
}

/// Reusable row for settings items with icon and optional count badge
private struct SettingsItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var count: Int = 0

    var body: some View {
        HStack {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HealthDocumentsView(
            profileStore: ProfileStore(),
            medicationStore: MedicationStore(),
            documentStore: DocumentStore(),
            foodRecallService: FoodRecallService(),
            profileId: UUID()
        )
    }
}
