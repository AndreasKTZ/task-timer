//
//  ContentView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct MenuBarContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [Task]
    @Query(sort: \ProjectCode.sortOrder) private var projectCodes: [ProjectCode]
    @Bindable var timerManager: TimerManager
    @State private var taskToDelete: Task?
    @State private var selectedTaskID: UUID?

    private var tasksForSelectedDate: [Task] {
        allTasks.filter { task in
            Calendar.current.isDate(task.date, inSameDayAs: timerManager.selectedDate)
        }
        .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    private var activeTask: Task? {
        allTasks.first(where: { $0.isRunning })
    }

    private var selectedTask: Task? {
        guard let id = selectedTaskID else { return activeTask }
        return tasksForSelectedDate.first(where: { $0.id == id })
    }

    private var heroDisplayTask: Task? {
        // Show active task in hero if running, otherwise show selected
        activeTask ?? selectedTask
    }

    private var heroFormattedTime: String {
        let _ = timerManager.tick
        if let task = heroDisplayTask {
            let total = task.currentTotalSeconds
            let h = total / 3600
            let m = (total % 3600) / 60
            let s = total % 60
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return "00:00:00"
    }

    private var totalDecimalHours: Double {
        let _ = timerManager.tick
        if timerManager.showBillableTime {
            return tasksForSelectedDate.reduce(0) { $0 + $1.roundedDecimalHours }
        } else {
            return tasksForSelectedDate.reduce(0) { $0 + $1.decimalHours }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hero header with play/pause, timer, task info
            heroHeader

            // Day navigation strip
            DayStripView(timerManager: timerManager)

            // Task list or empty state — fills remaining vertical space
            if tasksForSelectedDate.isEmpty {
                Spacer()
                emptyStateView
                Spacer()
            } else {
                columnHeaders
                    .fixedSize(horizontal: false, vertical: true)

                taskList

                totalsFooter
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Bottom toolbar
            BottomBar(
                timerManager: timerManager,
                onAddTask: { name in
                    addTaskFromTemplate(name)
                },
                onAddEmpty: {
                    addTask()
                }
            )
        }
        .frame(width: 420, height: 600)
        .background(Color(red: 0.11, green: 0.12, blue: 0.14))
        .onTapGesture {
            // Resign first responder to dismiss any active text field
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .onAppear {
            timerManager.syncActiveTask(with: allTasks)
        }
        // Inline delete confirmation overlay (system alerts close the menu bar panel)
        .overlay(alignment: .bottom) {
            if let task = taskToDelete {
                deleteConfirmationBanner(for: task)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        let isRunning = activeTask != nil

        return ZStack {
            // Red/pink gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.75, green: 0.18, blue: 0.28).opacity(0.5),
                    Color(red: 0.45, green: 0.10, blue: 0.18).opacity(0.7),
                    Color(red: 0.20, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Left: Play/Pause button
                Button(action: {
                    if let task = activeTask {
                        timerManager.stopTask(task, modelContext: modelContext)
                    } else if let task = selectedTask ?? tasksForSelectedDate.first {
                        timerManager.startTask(task, allTasks: allTasks, modelContext: modelContext)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRunning
                                  ? Color(red: 0.90, green: 0.25, blue: 0.35)
                                  : Color.white.opacity(0.12))
                            .frame(width: 64, height: 64)
                            .shadow(color: isRunning ? Color(red: 0.90, green: 0.25, blue: 0.35).opacity(0.5) : .clear, radius: 12)

                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 24)

                // Right: Timer + task info
                VStack(alignment: .leading, spacing: 4) {
                    // Selected/active task timer
                    Text(heroFormattedTime)
                        .font(.system(size: 42, weight: .thin))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    // Active task info
                    if let task = heroDisplayTask {
                        HStack(spacing: 6) {
                            if let code = task.projectCode {
                                Text(code.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .tracking(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            Text(task.name.isEmpty ? String(localized: "Unavngivet opgave") : task.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    } else {
                        Text(String(localized: "Ingen aktiv session"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                Spacer()
            }
        }
        .frame(height: 110)
        .clipped()
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text(String(localized: "Opgave"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 50)

            Text(String(localized: "Kode"))
                .frame(width: 64, alignment: .center)

            Text(String(localized: "Tid"))
                .frame(width: 68, alignment: .trailing)

            Text(timerManager.showBillableTime ? String(localized: "Fakt.") : String(localized: "Dec."))
                .frame(width: 44, alignment: .trailing)
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white.opacity(0.3))
        .textCase(.uppercase)
        .tracking(0.5)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(tasksForSelectedDate) { task in
                    TaskRowView(
                        task: task,
                        timerManager: timerManager,
                        isActive: task.isRunning,
                        isSelected: selectedTaskID == task.id,
                        onToggle: {
                            timerManager.toggleTask(task, allTasks: allTasks, modelContext: modelContext)
                        },
                        onDelete: {
                            confirmDelete(task)
                        },
                        onSelect: {
                            selectedTaskID = task.id
                        }
                    )
                }
            }
        }
    }

    // MARK: - Totals Footer

    private var totalsFooter: some View {
        let _ = timerManager.tick
        let totalSeconds = tasksForSelectedDate.reduce(0) { $0 + $1.currentTotalSeconds }
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        let timeStr = String(format: "%02d:%02d:%02d", h, m, s)

        return HStack(spacing: 0) {
            Text(String(localized: "I alt"))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
                .padding(.leading, 16)

            Spacer()

            Text(timeStr)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 68, alignment: .trailing)

            Text(String(format: "%.2f", totalDecimalHours))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.90, green: 0.35, blue: 0.45))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.02))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 64, height: 64)

                Image(systemName: "clock")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
            }

            VStack(spacing: 5) {
                Text(String(localized: "Ingen opgaver"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Text(String(localized: "Tilf\u{00f8}j en opgave for at komme i gang"))
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Button(action: addTask) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text(String(localized: "Ny opgave"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Color(red: 0.85, green: 0.25, blue: 0.35))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(height: 200)
    }

    // MARK: - Actions

    private func addTask() {
        withAnimation(.easeInOut(duration: 0.2)) {
            let newTask = Task(
                name: "",
                date: timerManager.selectedDate,
                sortOrder: tasksForSelectedDate.count
            )
            modelContext.insert(newTask)
        }
    }

    private func addTaskFromTemplate(_ name: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            let newTask = Task(
                name: name,
                date: timerManager.selectedDate,
                sortOrder: tasksForSelectedDate.count
            )
            modelContext.insert(newTask)
        }
    }

    private func confirmDelete(_ task: Task) {
        // No time logged and not running — delete instantly
        if task.accumulatedSeconds == 0 && !task.isRunning {
            deleteTask(task)
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                taskToDelete = task
            }
        }
    }

    private func deleteTask(_ task: Task) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if task.isRunning {
                timerManager.stopTask(task, modelContext: modelContext)
            }
            if selectedTaskID == task.id {
                selectedTaskID = nil
            }
            modelContext.delete(task)
            taskToDelete = nil
        }
    }

    private func deleteConfirmationBanner(for task: Task) -> some View {
        let name = task.name.isEmpty ? String(localized: "Unavngivet opgave") : task.name

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Slet \"\(name)\"?"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(String(localized: "Denne opgave har registreret tid."))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    taskToDelete = nil
                }
            }) {
                Text(String(localized: "Annuller"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Button(action: {
                deleteTask(task)
            }) {
                Text(String(localized: "Slet"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.85, green: 0.20, blue: 0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.18, green: 0.14, blue: 0.15))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.85, green: 0.20, blue: 0.25).opacity(0.5))
                .frame(height: 1)
        }
    }
}

// MARK: - Day Strip (replaces WeekStripView usage)

private struct DayStripView: View {
    @Bindable var timerManager: TimerManager

    private let calendar = Calendar.current
    private let dayLabels = ["Ma", "Ti", "On", "To", "Fr", "L\u{00f8}", "S\u{00f8}"]
    private let accentColor = Color(red: 0.90, green: 0.35, blue: 0.45)

    var body: some View {
        HStack(spacing: 0) {
            // Previous week — always visible
            Button(action: { timerManager.goToPreviousWeek() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            // Day cells — equal width distribution
            HStack(spacing: 0) {
                ForEach(Array(timerManager.currentWeekDates.enumerated()), id: \.offset) { index, date in
                    DayCell(
                        label: dayLabels[index],
                        number: calendar.component(.day, from: date),
                        isSelected: calendar.isDate(date, inSameDayAs: timerManager.selectedDate),
                        isToday: calendar.isDateInToday(date),
                        onTap: { timerManager.navigateToDate(date) }
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            // Next week — always visible
            Button(action: { timerManager.goToNextWeek() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
        // "I dag" button overlaid when not on today
        .overlay(alignment: .bottomTrailing) {
            if !timerManager.isToday {
                Button(action: { timerManager.goToToday() }) {
                    Text(String(localized: "I dag"))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 40)
                .padding(.bottom, 2)
            }
        }
    }
}

private struct DayCell: View {
    let label: String
    let number: Int
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private let accentColor = Color(red: 0.90, green: 0.35, blue: 0.45)

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? accentColor : .white.opacity(0.3))

                Text("\(number)")
                    .font(.system(size: 11, weight: isToday ? .bold : .medium))
                    .foregroundStyle(foregroundColor)
                    .frame(width: 26, height: 26)
                    .background(backgroundColor)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if isSelected { return .white }
        if isToday { return accentColor }
        return .white.opacity(0.6)
    }

    private var backgroundColor: Color {
        if isSelected { return accentColor }
        return .clear
    }
}

// MARK: - Bottom Bar

private struct BottomBar: View {
    @Bindable var timerManager: TimerManager
    var onAddTask: (String) -> Void
    var onAddEmpty: () -> Void

    @State private var showTemplates = false
    @State private var showProjectCodes = false

    private let accentColor = Color(red: 0.90, green: 0.35, blue: 0.45)

    var body: some View {
        HStack(spacing: 0) {
            // + button — single click adds a new task
            Button(action: onAddEmpty) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()

            // Billable/Actual toggle
            Button(action: {
                timerManager.showBillableTime.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: timerManager.showBillableTime ? "clock.badge.checkmark" : "clock")
                        .font(.system(size: 10))
                    Text(timerManager.showBillableTime ? String(localized: "Fakturerbar") : String(localized: "Faktisk"))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(timerManager.showBillableTime ? accentColor : .white.opacity(0.45))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(timerManager.showBillableTime ? accentColor.opacity(0.12) : Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Spacer()

            // Settings gear
            Menu {
                Button(action: { showTemplates = true }) {
                    Label(String(localized: "Skabeloner"), systemImage: "doc.text")
                }

                Button(action: { showProjectCodes = true }) {
                    Label(String(localized: "Projektkoder"), systemImage: "tag")
                }

                Divider()

                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Label(String(localized: "Indstillinger"), systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color(red: 0.09, green: 0.10, blue: 0.12))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
        }
        .popover(isPresented: $showTemplates, arrowEdge: .top) {
            TemplateListView(onAddTask: { name in
                onAddTask(name)
                showTemplates = false
            })
            .frame(width: 240, height: 300)
        }
        .popover(isPresented: $showProjectCodes, arrowEdge: .top) {
            ProjectCodeListView()
                .frame(width: 260, height: 300)
        }
    }
}
