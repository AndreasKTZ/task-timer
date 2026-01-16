//
//  Task.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var name: String
    var date: Date
    var accumulatedSeconds: Int
    var lastStartTime: Date?
    var sortOrder: Int
    var createdAt: Date

    init(name: String, date: Date, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.date = Calendar.current.startOfDay(for: date)
        self.accumulatedSeconds = 0
        self.lastStartTime = nil
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var isRunning: Bool {
        lastStartTime != nil
    }

    var currentTotalSeconds: Int {
        guard let startTime = lastStartTime else {
            return accumulatedSeconds
        }
        let additionalSeconds = Int(Date().timeIntervalSince(startTime))
        return accumulatedSeconds + additionalSeconds
    }

    var formattedTime: String {
        let total = currentTotalSeconds
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var decimalHours: Double {
        Double(currentTotalSeconds) / 3600.0
    }

    var roundedDecimalHours: Double {
        let totalMinutes = Double(currentTotalSeconds) / 60.0
        guard totalMinutes > 0 else { return 0 }

        // Round to nearest 15 min, but only round UP if >5 min into next block
        let remainder = totalMinutes.truncatingRemainder(dividingBy: 15.0)

        if remainder > 5 {
            return ceil(totalMinutes / 15.0) * 0.25
        } else {
            return floor(totalMinutes / 15.0) * 0.25
        }
    }

    func start() {
        guard lastStartTime == nil else { return }
        lastStartTime = Date()
    }

    func stop() {
        guard let startTime = lastStartTime else { return }
        let additionalSeconds = Int(Date().timeIntervalSince(startTime))
        accumulatedSeconds += additionalSeconds
        lastStartTime = nil
    }
}
