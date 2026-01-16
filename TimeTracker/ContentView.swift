//
//  ContentView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [Task]
    @State private var timerManager = TimerManager()
    @State private var showDeleteConfirmation = false
    @State private var taskToDelete: Task?
    @State private var selectedTaskIndex: Int? = nil

    private var tasksForSelectedDate: [Task] {
        allTasks.filter { task in
            Calendar.current.isDate(task.date, inSameDayAs: timerManager.selectedDate)
        }
    }

    private var sortedTasks: [Task] {
        tasksForSelectedDate.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main content area
            VStack(spacing: 0) {
                // Header with date and global controls
                HeaderView(
                    timerManager: timerManager,
                    tasks: tasksForSelectedDate,
                    onStopAll: {
                        timerManager.stopAllTasks(allTasks, modelContext: modelContext)
                    },
                    onStartFirst: {
                        if let firstTask = tasksForSelectedDate.sorted(by: { $0.sortOrder < $1.sortOrder }).first {
                            timerManager.startTask(firstTask, allTasks: allTasks, modelContext: modelContext)
                        }
                    }
                )

                Divider()

                // Task list
                if tasksForSelectedDate.isEmpty {
                    emptyStateView
                } else {
                    TaskListView(
                        tasks: tasksForSelectedDate,
                        timerManager: timerManager,
                        modelContext: modelContext,
                        selectedTaskIndex: selectedTaskIndex,
                        onDelete: { task in
                            confirmDelete(task)
                        },
                        onSelectTask: { index in
                            selectedTaskIndex = index
                        }
                    )
                }

                Divider()

                // Footer with add button and total
                FooterView(
                    tasks: tasksForSelectedDate,
                    tick: timerManager.tick,
                    showBillableTime: timerManager.showBillableTime,
                    onAddTask: addTask
                )
            }

            // Calendar sidebar
            VStack(spacing: 0) {
                CalendarView(
                    selectedDate: $timerManager.selectedDate,
                    onDateSelected: { date in
                        timerManager.navigateToDate(date)
                    }
                )

                Divider()
                    .opacity(0.5)

                TemplateListView(onAddTask: { templateName in
                    addTaskFromTemplate(templateName)
                })
            }
            .frame(width: 180)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 550, minHeight: 350)
        .overlay(alignment: .top) {
            Color("BrandAccent").frame(height: 2)
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.space) {
            guard !timerManager.isEditing else { return .ignored }
            handleSpaceKey()
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard !timerManager.isEditing else { return .ignored }
            selectPreviousTask()
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard !timerManager.isEditing else { return .ignored }
            selectNextTask()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            guard !timerManager.isEditing else { return .ignored }
            timerManager.goToPreviousDay()
            selectedTaskIndex = nil
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard !timerManager.isEditing else { return .ignored }
            timerManager.goToNextDay()
            selectedTaskIndex = nil
            return .handled
        }
        .onKeyPress(.return, phases: .down, action: { press in
            guard !timerManager.isEditing else { return .ignored }
            guard press.modifiers.contains(.command) else { return .ignored }
            addTask()
            return .handled
        })
        .onKeyPress(characters: .init(charactersIn: "t"), phases: .down, action: { press in
            guard !timerManager.isEditing else { return .ignored }
            guard press.modifiers.contains(.command) else { return .ignored }
            timerManager.goToToday()
            selectedTaskIndex = nil
            return .handled
        })
        .onAppear {
            timerManager.syncActiveTask(with: tasksForSelectedDate)
        }
        .onChange(of: timerManager.selectedDate) { _, _ in
            selectedTaskIndex = nil
        }
        .alert("Slet opgave", isPresented: $showDeleteConfirmation) {
            Button("Annuller", role: .cancel) {
                taskToDelete = nil
            }
            Button("Slet", role: .destructive) {
                if let task = taskToDelete {
                    deleteTask(task)
                }
                taskToDelete = nil
            }
        } message: {
            if let task = taskToDelete {
                if task.accumulatedSeconds > 0 || task.isRunning {
                    Text("Denne opgave har registreret tid. Er du sikker på, at du vil slette \"\(task.name.isEmpty ? "Unavngivet opgave" : task.name)\"?")
                } else {
                    Text("Slet \"\(task.name.isEmpty ? "Unavngivet opgave" : task.name)\"?")
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Ingen opgaver for denne dag")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text("Klik på \"Ny opgave\" for at tilføje en")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func addTask() {
        withAnimation {
            let newTask = Task(
                name: "",
                date: timerManager.selectedDate,
                sortOrder: tasksForSelectedDate.count
            )
            modelContext.insert(newTask)
        }
    }

    private func addTaskFromTemplate(_ name: String) {
        withAnimation {
            let newTask = Task(
                name: name,
                date: timerManager.selectedDate,
                sortOrder: tasksForSelectedDate.count
            )
            modelContext.insert(newTask)
        }
    }

    private func confirmDelete(_ task: Task) {
        taskToDelete = task
        showDeleteConfirmation = true
    }

    private func deleteTask(_ task: Task) {
        withAnimation {
            if task.isRunning {
                timerManager.stopTask(task, modelContext: modelContext)
            }
            modelContext.delete(task)
        }
    }

    private func handleSpaceKey() {
        let tasks = sortedTasks
        guard !tasks.isEmpty else { return }

        if let index = selectedTaskIndex, index < tasks.count {
            timerManager.toggleTask(tasks[index], allTasks: allTasks, modelContext: modelContext)
        } else if timerManager.isAnyTaskRunning {
            timerManager.stopAllTasks(allTasks, modelContext: modelContext)
        } else if let firstTask = tasks.first {
            selectedTaskIndex = 0
            timerManager.startTask(firstTask, allTasks: allTasks, modelContext: modelContext)
        }
    }

    private func selectPreviousTask() {
        let tasks = sortedTasks
        guard !tasks.isEmpty else { return }

        if let current = selectedTaskIndex {
            selectedTaskIndex = max(0, current - 1)
        } else {
            selectedTaskIndex = tasks.count - 1
        }
    }

    private func selectNextTask() {
        let tasks = sortedTasks
        guard !tasks.isEmpty else { return }

        if let current = selectedTaskIndex {
            selectedTaskIndex = min(tasks.count - 1, current + 1)
        } else {
            selectedTaskIndex = 0
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}
