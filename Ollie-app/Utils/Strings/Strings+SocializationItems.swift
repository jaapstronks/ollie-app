//
//  Strings+SocializationItems.swift
//  Ollie-app
//
//  Localized names for socialization checklist items
//

import Foundation
import OllieShared

private let table = "SocializationItems"

// MARK: - SocializationCategory Extension

extension SocializationCategory {

    /// Returns the localized name for this category
    var localizedDisplayName: String {
        switch id {
        case "mensen": return String(localized: "People", table: table)
        case "dieren": return String(localized: "Animals", table: table)
        case "voertuigen": return String(localized: "Vehicles", table: table)
        case "geluiden": return String(localized: "Sounds", table: table)
        case "omgevingen": return String(localized: "Environments", table: table)
        case "ondergronden": return String(localized: "Surfaces", table: table)
        case "handling": return String(localized: "Handling", table: table)
        case "objecten": return String(localized: "Objects", table: table)
        case "weer": return String(localized: "Weather", table: table)
        default: return name
        }
    }
}

// MARK: - SocializationItem Extension

extension SocializationItem {

    /// Returns the localized name for this item
    var localizedDisplayName: String {
        switch id {
        // People
        case "kind-0-5": return String(localized: "Toddler (0-5 years)", table: table)
        case "kind-6-12": return String(localized: "Child (6-12 years)", table: table)
        case "tiener": return String(localized: "Teenager", table: table)
        case "volwassene-man": return String(localized: "Adult man", table: table)
        case "volwassene-vrouw": return String(localized: "Adult woman", table: table)
        case "oudere": return String(localized: "Elderly person", table: table)
        case "baard": return String(localized: "Person with beard", table: table)
        case "hoed": return String(localized: "Person with hat", table: table)
        case "zonnebril": return String(localized: "Person with sunglasses", table: table)
        case "uniform": return String(localized: "Person in uniform", table: table)
        case "rolstoel": return String(localized: "Person in wheelchair", table: table)
        case "krukken": return String(localized: "Person with crutches/walker", table: table)
        case "paraplu": return String(localized: "Person with umbrella", table: table)
        case "rugzak": return String(localized: "Person with large backpack", table: table)
        case "rennend": return String(localized: "Running person", table: table)
        case "groep": return String(localized: "Group of people", table: table)

        // Animals
        case "hond-klein": return String(localized: "Small dog", table: table)
        case "hond-groot": return String(localized: "Large dog", table: table)
        case "puppy": return String(localized: "Other puppy", table: table)
        case "kat": return String(localized: "Cat", table: table)
        case "vogel": return String(localized: "Bird", table: table)
        case "eend-gans": return String(localized: "Duck/goose", table: table)
        case "paard": return String(localized: "Horse", table: table)
        case "koe-schaap": return String(localized: "Cow/sheep", table: table)

        // Vehicles
        case "auto": return String(localized: "Car", table: table)
        case "bus": return String(localized: "Bus", table: table)
        case "vrachtwagen": return String(localized: "Truck", table: table)
        case "motor": return String(localized: "Motorcycle", table: table)
        case "fiets": return String(localized: "Bicycle", table: table)
        case "scooter": return String(localized: "Scooter/moped", table: table)
        case "skateboard": return String(localized: "Skateboard/rollerblades", table: table)
        case "kinderwagen": return String(localized: "Stroller/pram", table: table)
        case "ambulance": return String(localized: "Emergency vehicle", table: table)
        case "tram-trein": return String(localized: "Tram/train", table: table)

        // Sounds
        case "stofzuiger": return String(localized: "Vacuum cleaner", table: table)
        case "fohn": return String(localized: "Hair dryer", table: table)
        case "wasmachine": return String(localized: "Washing machine", table: table)
        case "vaatwasser": return String(localized: "Dishwasher", table: table)
        case "deurbel": return String(localized: "Doorbell", table: table)
        case "telefoon": return String(localized: "Phone ringing", table: table)
        case "alarm": return String(localized: "Alarm/siren", table: table)
        case "bouw": return String(localized: "Construction noise", table: table)
        case "onweer": return String(localized: "Thunder", table: table)
        case "vuurwerk": return String(localized: "Fireworks", table: table)
        case "muziek": return String(localized: "Loud music", table: table)
        case "geschreeuw": return String(localized: "Shouting/cheering", table: table)
        case "kerkklok": return String(localized: "Church bells", table: table)
        case "huilende-baby": return String(localized: "Crying baby", table: table)

        // Environments
        case "drukke-straat": return String(localized: "Busy street", table: table)
        case "winkelstraat": return String(localized: "Shopping street", table: table)
        case "park": return String(localized: "Park", table: table)
        case "bos": return String(localized: "Forest", table: table)
        case "strand": return String(localized: "Beach", table: table)
        case "terras": return String(localized: "Outdoor cafe/terrace", table: table)
        case "station": return String(localized: "Train/bus station", table: table)
        case "parkeergarage": return String(localized: "Parking garage", table: table)
        case "lift": return String(localized: "Elevator", table: table)
        case "trap": return String(localized: "Stairs", table: table)
        case "speeltuin": return String(localized: "Playground", table: table)
        case "dierenwinkel": return String(localized: "Pet store", table: table)

        // Surfaces
        case "gras": return String(localized: "Grass", table: table)
        case "grind": return String(localized: "Gravel", table: table)
        case "zand": return String(localized: "Sand", table: table)
        case "tegels": return String(localized: "Tiles/pavement", table: table)
        case "hout": return String(localized: "Wood/decking", table: table)
        case "metaal": return String(localized: "Metal grating", table: table)
        case "water": return String(localized: "Shallow water", table: table)
        case "modder": return String(localized: "Mud", table: table)
        case "bladeren": return String(localized: "Leaves/mulch", table: table)
        case "sneeuw": return String(localized: "Snow", table: table)

        // Handling
        case "oren-aanraken": return String(localized: "Touching ears", table: table)
        case "poten-aanraken": return String(localized: "Touching paws", table: table)
        case "staart-aanraken": return String(localized: "Touching tail", table: table)
        case "bek-openen": return String(localized: "Opening mouth", table: table)
        case "nagels-knippen": return String(localized: "Nail trimming", table: table)
        case "borstelen": return String(localized: "Brushing", table: table)
        case "baden": return String(localized: "Bathing", table: table)
        case "afdrogen": return String(localized: "Towel drying", table: table)
        case "optillen": return String(localized: "Being picked up", table: table)
        case "vastpakken-halsband": return String(localized: "Collar grab", table: table)

        // Objects
        case "paraplu-open": return String(localized: "Opening umbrella", table: table)
        case "ballonnen": return String(localized: "Balloons", table: table)
        case "vuilniszak": return String(localized: "Garbage bags", table: table)
        case "kliko": return String(localized: "Trash bins/dumpsters", table: table)
        case "bezem": return String(localized: "Broom/mop", table: table)
        case "stoel-tafel": return String(localized: "Moving furniture", table: table)
        case "plastic-zak": return String(localized: "Plastic bags (sound)", table: table)
        case "vlaggend-object": return String(localized: "Flags/banners", table: table)
        case "spiegel": return String(localized: "Mirror", table: table)
        case "standbeeld": return String(localized: "Statues/mannequins", table: table)

        // Weather
        case "regen": return String(localized: "Rain", table: table)
        case "wind": return String(localized: "Strong wind", table: table)
        case "sneeuw-hagel": return String(localized: "Snow/hail", table: table)
        case "warmte": return String(localized: "Hot weather", table: table)
        case "kou": return String(localized: "Cold weather", table: table)
        case "donker": return String(localized: "Darkness/night walk", table: table)

        default: return name
        }
    }

    /// Returns the localized description for this item (optional tips)
    var localizedDescription: String? {
        switch id {
        case "uniform": return String(localized: "Police, delivery person, postal worker", table: table)
        case "ambulance": return String(localized: "Ambulance, fire truck, police car", table: table)
        case "vuurwerk": return String(localized: "Start with recordings at low volume", table: table)
        case "metaal": return String(localized: "Bridges, grates, manhole covers", table: table)
        case "nagels-knippen": return String(localized: "Start with just touching clippers", table: table)
        case "vastpakken-halsband": return String(localized: "Important for safety", table: table)
        default: return description
        }
    }
}
