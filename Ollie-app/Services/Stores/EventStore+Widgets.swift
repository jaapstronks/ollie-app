//
//  EventStore+Widgets.swift
//  Ollie-app
//
//  Widget data provider updates.
//

import Foundation
import OtisShared

extension EventStore {

    // MARK: - Widget Data

    func updateWidgetData(profile: PuppyProfile?) {
        let allRecentEvents = getEvents(from: Date.daysAgo(30), to: Date())

        WidgetDataProvider.shared.update(
            events: events,
            allEvents: allRecentEvents,
            profile: profile
        )
    }
}
