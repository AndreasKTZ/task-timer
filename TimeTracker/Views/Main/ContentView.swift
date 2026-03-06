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
    @Bindable var timerManager: TimerManager
    @State private var showDeleteConfirmation = false
    @State private var taskToDelete: Task?
    @State private var selectedTaskIndex: Int? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var tasksForSelectedDate: [Task] {
        allTasks.filter { task in
            Calendar.current.isDate(task.date, inSameDayAs: timerManager.selectedDate)
        }
        .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
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

                Divider()
                    .opacity(0.5)

                ProjectCodeListView()
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            // Main content area
            VStack(spacing: 0) {
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

                FooterView(
                    tasks: tasksForSelectedDate,
                    showBillableTime: timerManager.showBillableTime,
                    onAddTask: addTask
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        if timerManager.isAnyTaskRunning {
                            timerManager.stopAllTasks(allTasks, modelContext: modelContext)
                        } else if let firstTask = tasksForSelectedDate.first {
                            timerManager.startTask(firstTask, allTasks: allTasks, modelContext: modelContext)
                        }
                    }) {
                        Image(systemName: timerManager.isAnyTaskRunning ? "pause.fill" : "play.fill")
                    }
                    .disabled(!timerManager.isAnyTaskRunning && tasksForSelectedDate.isEmpty)
                    .help(timerManager.isAnyTaskRunning ? String(localized: "Sæt aktiv opgave på pause") : (tasksForSelectedDate.isEmpty ? String(localized: "Ingen opgaver") : String(localized: "Start første opgave")))
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Button(action: timerManager.goToPreviousDay) {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.plain)

                        Text(Formatters.danishDayMonthYear.string(from: timerManager.selectedDate))
                            .font(.system(size: 14, weight: .medium))

                        Button(action: timerManager.goToNextDay) {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }
                }

                ToolbarItemGroup(placement: .secondaryAction) {
                    Picker(String(localized: "Tid"), selection: $timerManager.showBillableTime) {
                        Text(String(localized: "Faktisk")).tag(false)
                        Text(String(localized: "Fakturerbar")).tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("")
        }
        .frame(minWidth: 550, minHeight: 350)
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
        .onAppear {
            timerManager.syncActiveTask(with: allTasks, modelContext: modelContext)
        }
        .onChange(of: timerManager.selectedDate) { _, _ in
            selectedTaskIndex = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewTask)) { _ in
            addTask()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goToToday)) { _ in
            timerManager.goToToday()
            selectedTaskIndex = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .showActualTime)) { _ in
            timerManager.showBillableTime = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBillableTime)) { _ in
            timerManager.showBillableTime = true
        }
        .alert(String(localized: "Slet opgave"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "Annuller"), role: .cancel) {
                taskToDelete = nil
            }
            Button(String(localized: "Slet"), role: .destructive) {
                if let task = taskToDelete {
                    deleteTask(task)
                }
                taskToDelete = nil
            }
        } message: {
            if let task = taskToDelete {
                let name = task.name.isEmpty ? String(localized: "Unavngivet opgave") : task.name
                if task.accumulatedSeconds > 0 || task.isRunning {
                    Text("Denne opgave har registreret tid. Er du sikker på, at du vil slette \"\(name)\"?")
                } else {
                    Text("Slet \"\(name)\"?")
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
            Text(String(localized: "Ingen opgaver for denne dag"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text(String(localized: "Klik på \"Ny opgave\" for at tilføje en"))
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
        let tasks = tasksForSelectedDate
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
        let tasks = tasksForSelectedDate
        guard !tasks.isEmpty else { return }

        if let current = selectedTaskIndex {
            selectedTaskIndex = max(0, current - 1)
        } else {
            selectedTaskIndex = tasks.count - 1
        }
    }

    private func selectNextTask() {
        let tasks = tasksForSelectedDate
        guard !tasks.isEmpty else { return }

        if let current = selectedTaskIndex {
            selectedTaskIndex = min(tasks.count - 1, current + 1)
        } else {
            selectedTaskIndex = 0
        }
    }
}

#Preview {
    ContentView(timerManager: TimerManager())
        .modelContainer(for: Task.self, inMemory: true)
}
