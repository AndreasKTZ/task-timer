//
//  TimerManager.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class TimerManager {
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var activeTaskID: UUID?
    var showBillableTime: Bool = true
    var isEditing: Bool = false

    var isAnyTaskRunning: Bool {
        activeTaskID != nil
    }

    func startTask(_ task: Task, allTasks: [Task], modelContext: ModelContext) {
        // Stop any currently running task first
        if let currentActiveID = activeTaskID,
           let runningTask = allTasks.first(where: { $0.id == currentActiveID }) {
            runningTask.stop()
        }

        // Start the new task
        task.start()
        activeTaskID = task.id

        do {
            try modelContext.save()
        } catch {
            print("Failed to save after starting task: \(error.localizedDescription)")
        }
    }

    func stopTask(_ task: Task, modelContext: ModelContext) {
        task.stop()
        if activeTaskID == task.id {
            activeTaskID = nil
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save after stopping task: \(error.localizedDescription)")
        }
    }

    func toggleTask(_ task: Task, allTasks: [Task], modelContext: ModelContext) {
        if task.isRunning {
            stopTask(task, modelContext: modelContext)
        } else {
            startTask(task, allTasks: allTasks, modelContext: modelContext)
        }
    }

    func stopAllTasks(_ tasks: [Task], modelContext: ModelContext) {
        for task in tasks where task.isRunning {
            task.stop()
        }
        activeTaskID = nil
        do {
            try modelContext.save()
        } catch {
            print("Failed to save after stopping all tasks: \(error.localizedDescription)")
        }
    }

    /// Recovers from a previous session. Stops any orphaned running tasks
    /// (e.g. from a force-quit) so accumulated time is preserved and the
    /// UI doesn't get stuck in a TimelineView update loop.
    func syncActiveTask(with tasks: [Task], modelContext: ModelContext) {
        var didStop = false
        for task in tasks where task.isRunning {
            task.stop()
            didStop = true
        }
        activeTaskID = nil
        if didStop {
            do {
                try modelContext.save()
            } catch {
                print("Failed to save after recovering orphaned tasks: \(error.localizedDescription)")
            }
        }
    }

    func navigateToDate(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
    }

    func goToPreviousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }

    func goToNextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }

    func goToToday() {
        selectedDate = Calendar.current.startOfDay(for: Date())
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}
