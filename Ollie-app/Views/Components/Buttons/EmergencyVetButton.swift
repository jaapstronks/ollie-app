//
//  EmergencyVetButton.swift
//  Ollie-app
//
//  Quick access button to call emergency vet
//

import SwiftUI
import OtisShared

/// Red capsule button for calling emergency vet
struct EmergencyVetButton: View {
    let contact: DogContact
    let onCall: (String) -> Void

    @State private var showConfirmation = false

    var body: some View {
        Button {
            showConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "cross.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(Strings.Contacts.emergencyVet)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red)
            .clipShape(Capsule())
            .shadow(color: .red.opacity(0.3), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            Strings.Contacts.emergencyVet,
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            if let phone = contact.phone, !phone.isEmpty {
                Button {
                    onCall(phone)
                } label: {
                    Label(Strings.Contacts.call + " " + contact.name, systemImage: "phone.fill")
                }
            }
            Button(Strings.Common.cancel, role: .cancel) {}
        } message: {
            Text(contact.name)
        }
    }
}

/// Floating emergency vet button that appears in corner
struct FloatingEmergencyVetButton: View {
    let contact: DogContact
    let onCall: (String) -> Void

    var body: some View {
        EmergencyVetButton(contact: contact, onCall: onCall)
            .padding()
    }
}

// MARK: - Preview

#Preview {
    let contact = DogContact(
        name: "24/7 Animal Emergency",
        contactType: .emergencyVet,
        phone: "555-9999"
    )

    return VStack(spacing: 20) {
        EmergencyVetButton(contact: contact) { phone in
            print("Calling: \(phone)")
        }

        FloatingEmergencyVetButton(contact: contact) { phone in
            print("Calling: \(phone)")
        }
    }
    .padding()
}
