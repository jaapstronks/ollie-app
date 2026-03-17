//
//  Strings+Documents.swift
//  OtisShared
//
//  Document type strings for the document tracker.
//

import Foundation

extension Strings {
    // MARK: - Documents
    public enum Documents {
        public static var passport: String { String(localized: "Passport", bundle: Strings.bundle) }
        public static var chipRegistration: String { String(localized: "Chip Registration", bundle: Strings.bundle) }
        public static var insurance: String { String(localized: "Insurance", bundle: Strings.bundle) }
        public static var pedigree: String { String(localized: "Pedigree", bundle: Strings.bundle) }
        public static var vaccination: String { String(localized: "Vaccination Record", bundle: Strings.bundle) }
        public static var medicalRecord: String { String(localized: "Medical Record", bundle: Strings.bundle) }
        public static var registration: String { String(localized: "Registration", bundle: Strings.bundle) }
        public static var trainingCertificate: String { String(localized: "Training Certificate", bundle: Strings.bundle) }
        public static var other: String { String(localized: "Other", bundle: Strings.bundle) }
    }
}
