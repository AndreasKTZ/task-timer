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

    private var runningTask: Task? {
        allTasks.first(where: { $0.isRunning })
    }

    var body: some View {
        if let task = runningTask {
            let _ = timerManager.tick
            let total = task.currentTotalSeconds
            let h = total / 3600
            let m = (total % 3600) / 60
            let s = total % 60

            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(String(format: "%02d:%02d:%02d", h, m, s))
                    .font(.system(.body, design: .monospaced))
            }
        } else {
            Image(systemName: "timer")
        }
    }
}
