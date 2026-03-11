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

    /// Incremented every second while a task is running.
    /// Views read this to force a 1-second UI refresh without
    /// using TimelineView (which conflicts with SwiftData @Query).
    var tick: Int = 0
    private var timer: Timer?

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
        startTimer()

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
            stopTimer()
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
        stopTimer()
        do {
            try modelContext.save()
        } catch {
            print("Failed to save after stopping all tasks: \(error.localizedDescription)")
        }
    }

    /// Recovers from a previous session. If a task was left running
    /// (e.g. from a force-quit), resume tracking it.
    func syncActiveTask(with tasks: [Task]) {
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

    // MARK: - Week Navigation

    /// Returns the 7 dates (Mon–Sun) for the week containing `selectedDate`.
    var currentWeekDates: [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: selectedDate)
        // Convert to Monday=0 ... Sunday=6
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: cal.startOfDay(for: selectedDate)) else {
            return []
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    func goToPreviousWeek() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -7, to: selectedDate) {
            selectedDate = newDate
        }
    }

    func goToNextWeek() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 7, to: selectedDate) {
            selectedDate = newDate
        }
    }
}
