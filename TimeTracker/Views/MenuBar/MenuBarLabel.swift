//
//  MenuBarLabel.swift
//  TimeTracker
//
//  Extracted from TimeTrackerApp.swift
//

import SwiftUI
import SwiftData

struct MenuBarLabel: View {
    @Query private var allTasks: [Task]
    @Bindable var timerManager: TimerManager
    @AppStorage("defaultShowBillableTime") private var defaultShowBillableTime = true

    private var runningTask: Task? {
        allTasks.first(where: { $0.isRunning })
    }

    private var todayTasks: [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        return allTasks.filter { $0.date == today }
    }

    var body: some View {
        let _ = timerManager.tick

        if let task = runningTask {
            let s = task.currentTotalSeconds
            let h = s / 3600
            let m = (s % 3600) / 60
            let sec = s % 60
            let name = task.name.isEmpty ? "·" : task.name

            let timeStr = String(format: "%02d:%02d:%02d", h, m, sec)

            HStack(spacing: 4) {
                Image(systemName: "hourglass")
                    .font(.system(size: 16))
                Text("\(timeStr) · \(name)")
                    .font(.system(.body, design: .monospaced))
            }
        } else {
            let totalHours = defaultShowBillableTime
                ? todayTasks.reduce(0.0) { $0 + $1.roundedDecimalHours }
                : todayTasks.reduce(0.0) { $0 + $1.decimalHours }

            HStack(spacing: 4) {
                Image(systemName: "hourglass.bottomhalf.filled")
                    .font(.system(size: 16))
                if totalHours > 0 {
                    Text(String(format: "%.2ft", totalHours))
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }
}
