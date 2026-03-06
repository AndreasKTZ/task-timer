//
//  CalendarView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    var onDateSelected: (Date) -> Void

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Ma", "Ti", "On", "To", "Fr", "Lø", "Sø"]


    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        // Get weekday of first day (1 = Sunday, 2 = Monday, ...)
        var firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Adjust for Monday start (Monday = 1, Sunday = 7)
        firstWeekday = firstWeekday == 1 ? 7 : firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    var body: some View {
        VStack(spacing: 8) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(Formatters.danishMonthYear.string(from: displayedMonth))
                    .font(.system(size: 12, weight: .semibold))

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            onTap: {
                                onDateSelected(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 22)
                    }
                }
            }
        }
        .padding(12)
        .onAppear {
            displayedMonth = selectedDate
        }
        .onChange(of: selectedDate) { _, newDate in
            // Only update displayed month if selected date is in a different month
            if !calendar.isDate(displayedMonth, equalTo: newDate, toGranularity: .month) {
                displayedMonth = newDate
            }
        }
    }

    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}
