//
//  ClosedDay.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 11/03/2026.
//

import Foundation
import SwiftData

@Model
final class ClosedDay {
    var id: UUID
    var date: Date
    var billableHours: Double
    var closedAt: Date

    init(date: Date, billableHours: Double) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.billableHours = billableHours
        self.closedAt = Date()
    }
}
