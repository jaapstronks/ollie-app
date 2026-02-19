//
//  LocationPickerSheet.swift
//  Ollie-app
//

import SwiftUI

struct LocationPickerSheet: View {
    let eventType: EventType
    let onSelect: (PottyLocation) -> Void
    let onCancel: () -> Void

    private var emoji: String {
        Constants.eventEmoji[eventType] ?? "📌"
    }

    private var label: String {
        Constants.eventLabels[eventType] ?? eventType.rawValue
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text(emoji)
                    .font(.largeTitle)
                Text(label)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 24)

            Text("Waar?")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Location buttons
            HStack(spacing: 16) {
                Button {
                    onSelect(.buiten)
                } label: {
                    VStack(spacing: 8) {
                        Text("🌳")
                            .font(.system(size: 48))
                        Text("Buiten")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Button {
                    onSelect(.binnen)
                } label: {
                    VStack(spacing: 8) {
                        Text("🏠")
                            .font(.system(size: 48))
                        Text("Binnen")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            Button("Annuleren", role: .cancel) {
                onCancel()
            }
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            LocationPickerSheet(
                eventType: .plassen,
                onSelect: { _ in },
                onCancel: { }
            )
        }
}
