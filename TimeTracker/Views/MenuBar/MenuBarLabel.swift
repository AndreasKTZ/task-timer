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
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text(task.formattedTime)
                        .font(.system(.body, design: .monospaced))
                }
            }
        } else {
            Image(systemName: "timer")
        }
    }
}
