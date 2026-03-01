//
//  Strings+Places.swift
//  Otis-app
//
//  Explore tab strings (spots and photo moments on map)

import Foundation

private let table = "Places"

extension Strings {

    // MARK: - Explore Tab
    enum Places {
        static let title = String(localized: "Explore", table: table)

        // View modes
        static let mapMode = String(localized: "Map", table: table)

        // Sections
        static let savedPlaces = String(localized: "Saved places", table: table)
        static let allSpots = String(localized: "All spots", table: table)

        // Empty states
        static let noSpotsYet = String(localized: "No spots saved yet", table: table)
        static let noSpotsHint = String(localized: "Save your favorite walk locations to see them here", table: table)
        static let noMomentsYet = String(localized: "No moments yet", table: table)
        static let noMomentsHint = String(localized: "Take photos of your adventures to see them here", table: table)
        static let noLocationData = String(localized: "No location", table: table)

        // Timeline
        static let momentsAndWalks = String(localized: "Moments & Walks", table: table)

        // Actions
        static let addSpot = String(localized: "Add spot", table: table)
        static let addContact = String(localized: "Add contact", table: table)
        static let addMoment = String(localized: "Add moment", table: table)
        static let expandMap = String(localized: "Expand map", table: table)

        // Expanded map
        static let expandedMap = String(localized: "Map", table: table, comment: "Navigation title for expanded map view")

        // Filter chips
        static let filterSpots = String(localized: "Spots", table: table, comment: "Filter chip for walk spots")
        static let filterDogParks = String(localized: "Discover", table: table, comment: "Filter chip for discovered places (vets, pet stores, dog parks, etc.)")
        static let filterContacts = String(localized: "Contacts", table: table, comment: "Filter chip for contacts")
        static let filterPhotos = String(localized: "Photos", table: table, comment: "Filter chip for photos")
        static let filterContactTypes = String(localized: "Contact types", table: table, comment: "Title for contact type filter sheet")
        static let filterSpotCategories = String(localized: "Spot categories", table: table, comment: "Title for spot category filter sheet")
        static let filterDiscoveryTypes = String(localized: "Place types", table: table, comment: "Title for discovery type filter sheet")
        static let selectAll = String(localized: "Select all", table: table, comment: "Button to select all filter options")

        // Location picker
        static let selectLocation = String(localized: "Select location", table: table, comment: "Navigation title for location picker")
        static let selectedLocation = String(localized: "Selected location", table: table, comment: "Label for selected coordinates")
        static let tapToSelectLocation = String(localized: "Tap on the map to place a pin", table: table, comment: "Hint for location picker")
        static let useAddress = String(localized: "Use address", table: table, comment: "Button to geocode from address")
        static let confirmLocation = String(localized: "Confirm location", table: table, comment: "Button to confirm selected location")

        // Stats
        static func photoCount(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 photo", table: table)
            } else {
                return String(localized: "\(count) photos", table: table)
            }
        }

        // Summary card
        static func placesDiscovered(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 place discovered", table: table)
            } else {
                return String(localized: "\(count) places discovered", table: table)
            }
        }

        static func puppysWorld(name: String) -> String {
            String(localized: "\(name)'s World", table: table, comment: "Title for summary card showing exploration stats, uses puppy name")
        }

        static let placesLabel = String(localized: "Places", table: table, comment: "Label for places count in summary card")
        static let momentsLabel = String(localized: "Moments", table: table, comment: "Label for photos/moments count in summary card")
        static let contactsLabel = String(localized: "Contacts", table: table, comment: "Label for contacts count in summary card")

        // Discovered spot categories
        static let categoryDogPark = String(localized: "Dog park", table: table, comment: "Category for fenced dog parks")
        static let categoryOffLeash = String(localized: "Off-leash area", table: table, comment: "Category for off-leash dog areas")
        static let categoryDogBeach = String(localized: "Dog beach", table: table, comment: "Category for dog-friendly beaches")
        static let categoryDogForest = String(localized: "Dog forest", table: table, comment: "Category for dog-friendly forests")
        static let categoryDogFriendly = String(localized: "Dog-friendly park", table: table, comment: "Category for general dog-friendly parks")

        // Discovery
        static let discoveredNearby = String(localized: "Nearby dog parks", table: table, comment: "Section header for discovered dog parks")
        static let dataAttribution = String(localized: "Data from %@", table: table, comment: "Attribution text, %@ is source name")
        static let saveToFavorites = String(localized: "Save to favorites", table: table, comment: "Button to save discovered spot to user's collection")
        static let discovering = String(localized: "Finding dog parks...", table: table, comment: "Loading state for discovery")
        static let noParksNearby = String(localized: "No dog parks found nearby", table: table, comment: "Empty state for discovery")
        static let spotSaved = String(localized: "Spot saved!", table: table, comment: "Confirmation when spot is saved")
        static let fenced = String(localized: "Fenced", table: table, comment: "Indicates dog park is fenced")
        static let amenities = String(localized: "Amenities", table: table, comment: "Section header for amenities list")

        // Surface types
        static let surfaceGrass = String(localized: "Grass", table: table, comment: "Grass surface type")
        static let surfaceSand = String(localized: "Sand", table: table, comment: "Sand surface type")
        static let surfaceGravel = String(localized: "Gravel", table: table, comment: "Gravel surface type")
        static let surfaceWoodChips = String(localized: "Wood chips", table: table, comment: "Wood chips surface type")
        static let surfaceAsphalt = String(localized: "Asphalt", table: table, comment: "Asphalt surface type")

        // Opening hours
        static let openingHours = String(localized: "Opening hours", table: table, comment: "Section header for opening hours")
        static let hoursClosed = String(localized: "Closed", table: table, comment: "Indicates the place is closed")
        static let hoursOpen24h = String(localized: "Open 24 hours", table: table, comment: "Indicates place is open 24/7")

        // Contact
        static let contact = String(localized: "Contact", table: table, comment: "Section header for contact info")

        // Facilities
        static let facilityWasteBin = String(localized: "Waste bin", table: table, comment: "Facility: waste disposal")
        static let facilityBench = String(localized: "Bench", table: table, comment: "Facility: seating bench")
        static let facilityWater = String(localized: "Water", table: table, comment: "Facility: drinking water")
        static let facilityLighting = String(localized: "Lighting", table: table, comment: "Facility: lights for evening use")
        static let facilityParking = String(localized: "Parking", table: table, comment: "Facility: parking available")
        static let facilityRestroom = String(localized: "Restroom", table: table, comment: "Facility: restroom/toilet")
        static let facilityAccessible = String(localized: "Accessible", table: table, comment: "Facility: wheelchair accessible")
        static let facilityShelter = String(localized: "Shelter", table: table, comment: "Facility: shade or rain shelter")
        static let facilityOutdoorSeating = String(localized: "Outdoor seating", table: table, comment: "Facility: outdoor seating area")
        static let facilityAgility = String(localized: "Agility", table: table, comment: "Facility: dog agility equipment")
    }

    // MARK: - Photo Pin Detail
    enum PhotoPin {
        static let moment = String(localized: "Moment", table: table, comment: "Navigation title for single photo detail")
        static let unknownLocation = String(localized: "Unknown location", table: table, comment: "When photo has no saved spot nearby")
        static let saveThisSpot = String(localized: "Save this spot", table: table, comment: "Button to save location as a new spot")
    }
}
