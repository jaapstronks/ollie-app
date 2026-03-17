//
//  ContributionPeriodPicker.swift
//  Otis-app
//
//  Segmented picker for contribution time periods
//

import SwiftUI
import OtisShared

/// Segmented picker for selecting contribution time period
struct ContributionPeriodPicker: View {
    @Binding var selectedPeriod: ContributionPeriod

    var body: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(ContributionPeriod.allCases, id: \.self) { period in
                Text(period.label)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var period: ContributionPeriod = .thisWeek

        var body: some View {
            ContributionPeriodPicker(selectedPeriod: $period)
                .padding()
        }
    }

    return PreviewWrapper()
}
