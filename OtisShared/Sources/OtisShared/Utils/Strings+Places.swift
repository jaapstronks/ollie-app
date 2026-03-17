//
//  Strings+Places.swift
//  OtisShared
//
//  Places discovery strings for finding dog-friendly locations.
//

import Foundation

extension Strings {
    // MARK: - Places Discovery
    public enum PlacesDiscovery {
        // Categories
        public static var categoryDogPark: String { String(localized: "Dog park", bundle: Strings.bundle) }
        public static var categoryOffLeash: String { String(localized: "Off-leash area", bundle: Strings.bundle) }
        public static var categoryDogBeach: String { String(localized: "Dog beach", bundle: Strings.bundle) }
        public static var categoryDogForest: String { String(localized: "Dog forest", bundle: Strings.bundle) }
        public static var categoryDogFriendly: String { String(localized: "Dog-friendly park", bundle: Strings.bundle) }
        public static var categoryVetClinic: String { String(localized: "Vet clinic", bundle: Strings.bundle) }
        public static var categoryPetStore: String { String(localized: "Pet store", bundle: Strings.bundle) }
        public static var categoryDogFriendlyCafe: String { String(localized: "Dog-friendly café", bundle: Strings.bundle) }

        // Filter groups
        public static var filterDogAreas: String { String(localized: "Dog Areas", bundle: Strings.bundle) }
        public static var filterVets: String { String(localized: "Vets", bundle: Strings.bundle) }
        public static var filterPetStores: String { String(localized: "Pet Stores", bundle: Strings.bundle) }
        public static var filterDogFriendly: String { String(localized: "Dog-Friendly", bundle: Strings.bundle) }
    }
}
