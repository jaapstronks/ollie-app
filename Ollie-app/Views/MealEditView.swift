//
//  MealEditView.swift
//  Ollie-app
//

import SwiftUI

/// View for editing the meal schedule
struct MealEditView: View {
    @ObservedObject var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var mealsPerDay: Int
    @State private var portions: [MealSchedule.MealPortion]

    init(profileStore: ProfileStore) {
        self.profileStore = profileStore
        let schedule = profileStore.profile?.mealSchedule ?? MealSchedule.defaultSchedule(ageWeeks: 12, size: .medium)
        _mealsPerDay = State(initialValue: schedule.mealsPerDay)
        _portions = State(initialValue: schedule.portions)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(Strings.Meals.numberOfMeals) {
                    Picker(Strings.Meals.mealsPerDay, selection: $mealsPerDay) {
                        ForEach(2...4, id: \.self) { count in
                            Text(Strings.Meals.perDay(count)).tag(count)
                        }
                    }
                    .onChange(of: mealsPerDay) { _, newValue in
                        adjustPortions(to: newValue)
                    }
                }

                Section(Strings.Meals.mealsSection) {
                    ForEach($portions) { $portion in
                        MealPortionRow(portion: $portion)
                    }
                }
            }
            .navigationTitle(Strings.Meals.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        save()
                    }
                }
            }
        }
    }

    private func adjustPortions(to count: Int) {
        let defaultLabels = [Strings.Meals.breakfast, Strings.Meals.lunch, Strings.Meals.afternoon, Strings.Meals.dinner]
        let defaultTimes = ["07:00", "11:00", "15:00", "19:00"]

        if count > portions.count {
            // Add portions
            for i in portions.count..<count {
                let label = i < defaultLabels.count ? defaultLabels[i] : Strings.Meals.mealNumber(i + 1)
                let time = i < defaultTimes.count ? defaultTimes[i] : nil
                let amount = portions.first?.amount ?? "80g"
                portions.append(MealSchedule.MealPortion(label: label, amount: amount, targetTime: time))
            }
        } else if count < portions.count {
            // Remove portions from the end
            portions = Array(portions.prefix(count))
        }
    }

    private func save() {
        let schedule = MealSchedule(mealsPerDay: mealsPerDay, portions: portions)
        profileStore.updateMealSchedule(schedule)
        dismiss()
    }
}

/// Row for editing a single meal portion
struct MealPortionRow: View {
    @Binding var portion: MealSchedule.MealPortion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(Strings.Meals.name, text: $portion.label)
                .font(.headline)

            HStack {
                Text(Strings.Meals.amount)
                    .foregroundColor(.secondary)
                Spacer()
                TextField(Strings.Meals.amountExample, text: $portion.amount)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            HStack {
                Text(Strings.Meals.time)
                    .foregroundColor(.secondary)
                Spacer()
                DatePicker(
                    "",
                    selection: timeBinding,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }

    /// Binding that converts between String ("HH:mm") and Date
    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                if let timeString = portion.targetTime {
                    return dateFromTimeString(timeString) ?? defaultTime
                }
                return defaultTime
            },
            set: { newDate in
                portion.targetTime = timeStringFromDate(newDate)
            }
        )
    }

    private var defaultTime: Date {
        var components = DateComponents()
        components.hour = 12
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private func dateFromTimeString(_ timeString: String) -> Date? {
        guard let time = DateFormatters.timeOnly.date(from: timeString) else { return nil }

        // Combine with today's date
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components)
    }

    private func timeStringFromDate(_ date: Date) -> String {
        date.timeString
    }
}

#Preview {
    MealEditView(profileStore: ProfileStore())
}
