//
//  TaskListView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    var tasks: [Task]
    @Bindable var timerManager: TimerManager
    var modelContext: ModelContext
    var selectedTaskIndex: Int?
    var onDelete: (Task) -> Void
    var onSelectTask: (Int) -> Void

    private var sortedTasks: [Task] {
        tasks.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(sortedTasks.enumerated()), id: \.element.id) { index, task in
                    TaskRowView(
                        task: task,
                        timerManager: timerManager,
                        isActive: task.isRunning,
                        isSelected: selectedTaskIndex == index,
                        onToggle: {
                            timerManager.toggleTask(task, allTasks: tasks, modelContext: modelContext)
                        },
                        onDelete: {
                            onDelete(task)
                        },
                        onSelect: {
                            onSelectTask(index)
                        }
                    )
                }
            }
        }
    }
}
