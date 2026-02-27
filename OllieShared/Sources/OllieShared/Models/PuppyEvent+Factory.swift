//
//  PuppyEvent+Factory.swift
//  OllieShared
//
//  Factory methods for creating PuppyEvent instances
//  Extracted from PuppyEvent.swift for better organization
//

import Foundation

// MARK: - Factory Methods

extension PuppyEvent {

    public static func potty(
        type: EventType,
        time: Date = Date(),
        location: EventLocation,
        note: String? = nil,
        photo: String? = nil,
        thumbnailPath: String? = nil,
        parentWalkId: UUID? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> PuppyEvent {
        precondition(type.isPottyEvent, "potty() factory only accepts plassen or poepen")

        return PuppyEvent(
            time: time,
            type: type,
            location: location,
            note: note,
            photo: photo,
            latitude: latitude,
            longitude: longitude,
            thumbnailPath: thumbnailPath,
            parentWalkId: parentWalkId
        )
    }

    public static func walk(
        time: Date = Date(),
        durationMin: Int? = nil,
        note: String? = nil,
        spot: WalkSpot? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        photo: String? = nil,
        thumbnailPath: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .uitlaten,
            note: note,
            durationMin: durationMin,
            photo: photo,
            latitude: latitude ?? spot?.latitude,
            longitude: longitude ?? spot?.longitude,
            thumbnailPath: thumbnailPath,
            spotId: spot?.id,
            spotName: spot?.name
        )
    }

    public static func training(
        time: Date = Date(),
        exercise: String,
        result: String? = nil,
        durationMin: Int? = nil,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .training,
            note: note,
            exercise: exercise,
            result: result,
            durationMin: durationMin
        )
    }

    public static func social(
        time: Date = Date(),
        who: String,
        note: String? = nil,
        durationMin: Int? = nil,
        photo: String? = nil,
        thumbnailPath: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .sociaal,
            note: note,
            who: who,
            durationMin: durationMin,
            photo: photo,
            thumbnailPath: thumbnailPath
        )
    }

    public static func sleep(
        time: Date = Date(),
        note: String? = nil,
        sleepSessionId: UUID? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .slapen,
            note: note,
            sleepSessionId: sleepSessionId
        )
    }

    public static func wake(
        time: Date = Date(),
        sleepSessionId: UUID?,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .ontwaken,
            note: note,
            sleepSessionId: sleepSessionId
        )
    }

    public static func weight(
        time: Date = Date(),
        weightKg: Double,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .gewicht,
            note: note,
            weightKg: weightKg
        )
    }

    public static func meal(
        time: Date = Date(),
        note: String? = nil,
        durationMin: Int? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .eten,
            note: note,
            durationMin: durationMin
        )
    }

    public static func drink(
        time: Date = Date(),
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .drinken,
            note: note
        )
    }

    public static func medication(
        time: Date = Date(),
        medicationName: String
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .medicatie,
            note: medicationName
        )
    }

    public static func moment(
        time: Date = Date(),
        photo: String,
        thumbnailPath: String? = nil,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .moment,
            note: note,
            photo: photo,
            thumbnailPath: thumbnailPath
        )
    }

    public static func milestone(
        time: Date = Date(),
        note: String
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: .milestone,
            note: note
        )
    }

    public static func simple(
        type: EventType,
        time: Date = Date(),
        note: String? = nil,
        durationMin: Int? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: time,
            type: type,
            note: note,
            durationMin: durationMin
        )
    }

    public static func coverageGap(
        startTime: Date = Date(),
        endTime: Date? = nil,
        gapType: CoverageGapType,
        location: String? = nil,
        note: String? = nil
    ) -> PuppyEvent {
        return PuppyEvent(
            time: startTime,
            type: .coverageGap,
            note: note,
            gapType: gapType,
            endTime: endTime,
            gapLocation: location
        )
    }
}
