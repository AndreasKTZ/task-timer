//
//  WeekStripView.swift
//  TimeTracker
//
//  Compact horizontal week selector -- Mon-Sun strip.
//  Note: Currently unused in the main UI (DayStripView in ContentView is used instead).
//

import SwiftUI

struct WeekStripView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var timerManager: TimerManager

    private let calendar = Calendar.current
    private let dayLabels = ["Ma", "Ti", "On", "To", "Fr", "L\u{00f8}", "S\u{00f8}"]

    private var showTodayButton: Bool {
        !timerManager.isToday
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { timerManager.goToPreviousWeek() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary(colorScheme))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 2)

            HStack(spacing: 6) {
                ForEach(Array(timerManager.currentWeekDates.enumerated()), id: \.offset) { index, date in
                    WeekDayCell(
                        dayLabel: dayLabels[index],
                        dayNumber: calendar.component(.day, from: date),
                        isSelected: calendar.isDate(date, inSameDayAs: timerManager.selectedDate),
                        isToday: calendar.isDateInToday(date),
                        onTap: {
                            timerManager.navigateToDate(date)
                        }
                    )
                }
            }

            Spacer(minLength: 2)

            if showTodayButton {
                Button(action: { timerManager.goToToday() }) {
                    Text(String(localized: "I dag"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { timerManager.goToNextWeek() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.separator(colorScheme))
                .frame(height: 1)
        }
    }
}

private struct WeekDayCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let dayLabel: String
    let dayNumber: Int
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(dayLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textQuaternary(colorScheme))

                Text("\(dayNumber)")
                    .font(.system(size: 12, weight: isToday ? .bold : .medium))
                    .foregroundStyle(foregroundColor)
                    .frame(width: 28, height: 28)
                    .background(backgroundColor)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if isSelected { return .white }
        if isToday { return Theme.accent }
        return Theme.textSecondary(colorScheme)
    }

    private var backgroundColor: Color {
        if isSelected { return Theme.accent }
        return .clear
    }
}

#Preview {
    WeekStripView(timerManager: TimerManager())
        .frame(width: 420)
}
