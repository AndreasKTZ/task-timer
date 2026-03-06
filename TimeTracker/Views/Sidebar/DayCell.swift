//
//  DayCell.swift
//  TimeTracker
//
//  Extracted from CalendarView.swift
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundStyle(foregroundColor)
                .frame(width: 22, height: 22)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dag \(calendar.component(.day, from: date))\(isToday ? ", i dag" : "")\(isSelected ? ", valgt" : "")")
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color("BrandAccent")
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color("BrandAccent")
        } else {
            return .clear
        }
    }
}
