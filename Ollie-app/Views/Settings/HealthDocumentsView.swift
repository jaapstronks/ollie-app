//
//  HealthDocumentsView.swift
//  Otis-app
//
//  Health and documents settings: medications and documents

import SwiftUI
import OtisShared

/// Settings screen for health documents: medications, documents, and food alerts
struct HealthDocumentsView: View {
    @ObservedObject var profileStore: ProfileStore
    @ObservedObject var documentStore: DocumentStore
    @ObservedObject var foodRecallService: FoodRecallService

    var body: some View {
        List {
            if profileStore.profile != nil {
                // Medications
                NavigationLink {
                    MedicationSettingsView(profileStore: profileStore)
                } label: {
                    SettingsItemRow(
                        icon: "pills.fill",
                        iconColor: .purple,
                        title: Strings.Medications.title,
                        count: profileStore.profile?.medicationSchedule.medications.count ?? 0
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
            documentStore: DocumentStore(),
            foodRecallService: FoodRecallService()
        )
    }
}
