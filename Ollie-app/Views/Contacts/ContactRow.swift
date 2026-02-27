//
//  ContactRow.swift
//  Ollie-app
//
//  Row component for displaying a contact in a list

import SwiftUI
import OllieShared

/// Row view for displaying a contact in a list
struct ContactRow: View {
    let contact: DogContact

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: contact.contactType.icon)
                .font(.system(size: 20))
                .foregroundColor(.ollieAccent)
                .frame(width: 40, height: 40)
                .background(Color.ollieAccent.opacity(0.1))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(contact.name)
                    .font(.headline)
                    .lineLimit(1)

                // Type + phone preview
                HStack(spacing: 8) {
                    Text(contact.contactType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let phone = contact.phone, !phone.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ContactRow(contact: DogContact(
            name: "Dierenkliniek Utrecht",
            contactType: .vet,
            phone: "+31 30 123 4567"
        ))

        ContactRow(contact: DogContact(
            name: "Spoeddienst Dieren",
            contactType: .emergencyVet,
            phone: "+31 30 987 6543"
        ))

        ContactRow(contact: DogContact(
            name: "Marieke's Hondentrimmen",
            contactType: .groomer
        ))

        ContactRow(contact: DogContact(
            name: "Hondenoppas Jan",
            contactType: .sitter,
            phone: "+31 6 12345678"
        ))
    }
}
