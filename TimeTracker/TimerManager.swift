//
//  TimerManager.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@Observable
final class TimerManager {
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var activeTaskID: UUID?
    private var timer: Timer?
    var tick: Int = 0  // Publicly observable to trigger UI updates
    var showBillableTime: Bool = true  // Toggle between actual and billable (rounded) hours
    var isEditing: Bool = false  // True when user is editing a task name or time

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

        // Start the timer for UI updates
        startTimer()

        try? modelContext.save()
    }

    func stopTask(_ task: Task, modelContext: ModelContext) {
        task.stop()
        if activeTaskID == task.id {
            activeTaskID = nil
            stopTimer()
        }
        try? modelContext.save()
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
        stopTimer()
        try? modelContext.save()
    }

    func syncActiveTask(with tasks: [Task]) {
        // Find if there's a running task and sync state
        if let runningTask = tasks.first(where: { $0.isRunning }) {
            activeTaskID = runningTask.id
            startTimer()
        } else {
            activeTaskID = nil
            stopTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
