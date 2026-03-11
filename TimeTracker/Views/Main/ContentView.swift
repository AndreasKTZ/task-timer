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
    @Environment(\.colorScheme) private var colorScheme
    @Query private var allTasks: [Task]
    @Query(sort: \ProjectCode.sortOrder) private var projectCodes: [ProjectCode]
    @Bindable var timerManager: TimerManager
    @State private var taskToDelete: Task?
    @State private var selectedTaskID: UUID?
    @State private var showAddBanner = false
    @State private var newTaskName = ""
    @FocusState private var isAddFieldFocused: Bool
    @State private var codeEditTask: Task?
    @State private var editedCode = ""
    @FocusState private var isCodeFieldFocused: Bool
    @State private var showSettings = false

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
        Group {
            if showSettings {
                InlineSettingsView(onBack: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSettings = false
                    }
                })
            } else {
                mainContent
            }
        }
        .frame(width: 420, height: 600)
        .background(Theme.panelBackground(colorScheme))
        .onTapGesture {
            // Resign first responder to dismiss any active text field
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .onAppear {
            timerManager.syncActiveTask(with: allTasks)
        }
    }

    private var mainContent: some View {
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
                onAddEmpty: {
                    showAddTaskBanner()
                },
                onAddFromTemplate: { template in
                    addTaskFromTemplate(template)
                },
                onShowSettings: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showSettings = true
                    }
                }
            )
        }
        // Inline delete confirmation overlay (system alerts close the menu bar panel)
        .overlay(alignment: .bottom) {
            if let task = taskToDelete {
                deleteConfirmationBanner(for: task)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Inline add-task banner (green themed)
        .overlay(alignment: .bottom) {
            if showAddBanner {
                addTaskBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Inline project code banner (blue themed)
        .overlay(alignment: .bottom) {
            if codeEditTask != nil {
                projectCodeBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        let isRunning = activeTask != nil

        return ZStack {
            // Gradient background — red/pink when active, grey when idle
            LinearGradient(
                colors: isRunning
                    ? Theme.heroActiveGradient(colorScheme)
                    : Theme.heroIdleGradient(colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Left: Play/Pause button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        if let task = activeTask {
                            timerManager.stopTask(task, modelContext: modelContext)
                        } else if let task = selectedTask ?? tasksForSelectedDate.first {
                            timerManager.startTask(task, allTasks: allTasks, modelContext: modelContext)
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRunning
                                  ? Color(red: 0.90, green: 0.25, blue: 0.35)
                                  : Theme.heroButtonIdle(colorScheme))
                            .frame(width: 64, height: 64)
                            .shadow(color: isRunning ? Color(red: 0.90, green: 0.25, blue: 0.35).opacity(0.5) : .clear, radius: 12)

                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.heroText(colorScheme, isRunning: isRunning))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 24)

                // Right: Timer + task info
                VStack(alignment: .leading, spacing: 4) {
                    // Selected/active task timer
                    Text(heroFormattedTime)
                        .font(.system(size: 42, weight: .thin))
                        .foregroundStyle(Theme.heroText(colorScheme, isRunning: isRunning))
                        .contentTransition(.numericText())

                    // Active task info
                    if let task = heroDisplayTask {
                        HStack(spacing: 6) {
                            if let code = task.projectCode {
                                Text(code.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.heroMutedText(colorScheme, isRunning: isRunning))
                                    .tracking(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.heroButtonIdle(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            Text(task.name.isEmpty ? String(localized: "Unavngivet opgave") : task.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.heroSubtext(colorScheme, isRunning: isRunning))
                                .lineLimit(1)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    } else {
                        Text(String(localized: "Ingen aktiv session"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.heroMutedText(colorScheme, isRunning: isRunning))
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                }

                Spacer()
            }
        }
        .frame(height: 110)
        .clipped()
        .animation(.easeInOut(duration: 0.35), value: isRunning)
        .animation(.easeInOut(duration: 0.35), value: heroDisplayTask?.id)
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
        .foregroundStyle(Theme.textTertiary(colorScheme))
        .textCase(.uppercase)
        .tracking(0.5)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.surfaceTint(colorScheme))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.separator(colorScheme))
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
                        },
                        onEditCode: {
                            showCodeBanner(for: task)
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
                .foregroundStyle(Theme.textTertiary(colorScheme))
                .textCase(.uppercase)
                .padding(.leading, 16)

            Spacer()

            Text(timeStr)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.textSecondary(colorScheme))
                .frame(width: 68, alignment: .trailing)

            Text(String(format: "%.2f", totalDecimalHours))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surfaceTint(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.separator(colorScheme))
                .frame(height: 1)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.emptyStateCircle(colorScheme))
                    .frame(width: 64, height: 64)

                Image(systemName: "clock")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Theme.emptyStateIcon(colorScheme))
            }

            VStack(spacing: 5) {
                Text(String(localized: "Ingen opgaver"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                Text(String(localized: "Tilf\u{00f8}j en opgave for at komme i gang"))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary(colorScheme))
            }

            Button(action: showAddTaskBanner) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text(String(localized: "Ny opgave"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Theme.accentButton)
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

    private func addTaskFromTemplate(_ template: TaskTemplate) {
        withAnimation(.easeInOut(duration: 0.2)) {
            let newTask = Task(
                name: template.name,
                date: timerManager.selectedDate,
                sortOrder: tasksForSelectedDate.count
            )
            newTask.projectCode = template.projectCode
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

    // MARK: - Add Task Banner

    private var addTaskBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.green)

            TextField(String(localized: "Opgavenavn"), text: $newTaskName)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary(colorScheme))
                .focused($isAddFieldFocused)
                .onSubmit { commitAddTask() }
                .onChange(of: isAddFieldFocused) { _, focused in
                    if !focused { commitAddTask() }
                }

            Spacer()

            Button(action: { cancelAdd() }) {
                Text(String(localized: "Annuller"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.bannerSecondaryText(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.bannerSecondaryButton(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Button(action: { commitAddTask() }) {
                Text(String(localized: "Tilf\u{00f8}j"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.green)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.addBannerBackground(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.green.opacity(0.5))
                .frame(height: 1)
        }
    }

    private func showAddTaskBanner() {
        newTaskName = ""
        withAnimation(.easeInOut(duration: 0.15)) {
            showAddBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAddFieldFocused = true
        }
    }

    private func commitAddTask() {
        guard showAddBanner else { return }
        let trimmed = newTaskName.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.easeInOut(duration: 0.2)) {
            let newTask = Task(
                name: String(trimmed.prefix(200)),
                date: timerManager.selectedDate,
                sortOrder: tasksForSelectedDate.count
            )
            modelContext.insert(newTask)
            showAddBanner = false
            newTaskName = ""
        }
    }

    private func cancelAdd() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showAddBanner = false
            newTaskName = ""
        }
    }

    // MARK: - Project Code Banner

    private var projectCodeBanner: some View {
        let taskName = codeEditTask.map { $0.name.isEmpty ? String(localized: "Unavngivet opgave") : $0.name } ?? ""

        return VStack(spacing: 8) {
            // Project code quick-pick
            if !projectCodes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(projectCodes) { code in
                            Button(action: {
                                editedCode = editedCode == code.code ? "" : code.code
                            }) {
                                Text(code.displayName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(editedCode == code.code ? .white : Theme.blue)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(editedCode == code.code ? Theme.blue : Theme.blue.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(taskName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                        .lineLimit(1)

                    TextField(String(localized: "Projektkode"), text: $editedCode)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary(colorScheme))
                        .focused($isCodeFieldFocused)
                        .onSubmit { commitCodeEdit() }
                        .onChange(of: isCodeFieldFocused) { _, focused in
                            if !focused { commitCodeEdit() }
                        }
                }

                Spacer()

                if codeEditTask?.projectCode != nil {
                    Button(action: { clearCode() }) {
                        Text(String(localized: "Fjern"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.bannerSecondaryText(colorScheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.bannerSecondaryButton(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { cancelCodeEdit() }) {
                    Text(String(localized: "Annuller"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.bannerSecondaryText(colorScheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.bannerSecondaryButton(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button(action: { commitCodeEdit() }) {
                    Text(String(localized: "Gem"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.codeBannerBackground(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.blue.opacity(0.5))
                .frame(height: 1)
        }
    }

    private func showCodeBanner(for task: Task) {
        editedCode = task.projectCode ?? ""
        withAnimation(.easeInOut(duration: 0.15)) {
            codeEditTask = task
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isCodeFieldFocused = true
        }
    }

    private func commitCodeEdit() {
        guard let task = codeEditTask else { return }
        let trimmed = editedCode.trimmingCharacters(in: .whitespacesAndNewlines)
        task.projectCode = trimmed.isEmpty ? nil : String(trimmed.prefix(20))
        withAnimation(.easeInOut(duration: 0.15)) {
            codeEditTask = nil
            editedCode = ""
        }
    }

    private func clearCode() {
        guard let task = codeEditTask else { return }
        task.projectCode = nil
        withAnimation(.easeInOut(duration: 0.15)) {
            codeEditTask = nil
            editedCode = ""
        }
    }

    private func cancelCodeEdit() {
        withAnimation(.easeInOut(duration: 0.15)) {
            codeEditTask = nil
            editedCode = ""
        }
    }

    private func deleteConfirmationBanner(for task: Task) -> some View {
        let name = task.name.isEmpty ? String(localized: "Unavngivet opgave") : task.name

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Slet \"\(name)\"?"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                    .lineLimit(1)

                Text(String(localized: "Denne opgave har registreret tid."))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary(colorScheme))
            }

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    taskToDelete = nil
                }
            }) {
                Text(String(localized: "Annuller"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.bannerSecondaryText(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.bannerSecondaryButton(colorScheme))
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
                    .background(Theme.destructive)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.deleteBannerBackground(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.destructive.opacity(0.5))
                .frame(height: 1)
        }
    }
}

// MARK: - Day Strip (replaces WeekStripView usage)

private struct DayStripView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var timerManager: TimerManager

    private let calendar = Calendar.current
    private let dayLabels = ["Ma", "Ti", "On", "To", "Fr", "L\u{00f8}", "S\u{00f8}"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Previous week
                Button(action: { timerManager.goToPreviousWeek() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
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

                // Next week
                Button(action: { timerManager.goToNextWeek() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary(colorScheme))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Theme.surfaceTint(colorScheme))

            // "Go to today" banner
            if !timerManager.isToday {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accent)

                    Text(String(localized: "Du kigger p\u{00e5} en anden dag"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary(colorScheme))

                    Spacer()

                    Button(action: { timerManager.goToToday() }) {
                        Text(String(localized: "G\u{00e5} til i dag"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Theme.todayBannerBackground(colorScheme))
            }

            Rectangle()
                .fill(Theme.separator(colorScheme))
                .frame(height: 1)
        }
    }
}

private struct DayCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let number: Int
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary(colorScheme))

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
        if isToday { return Theme.accent }
        return Theme.textSecondary(colorScheme)
    }

    private var backgroundColor: Color {
        if isSelected { return Theme.accent }
        return .clear
    }
}

// MARK: - Bottom Bar

private struct BottomBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \TaskTemplate.sortOrder) private var templates: [TaskTemplate]
    @Bindable var timerManager: TimerManager
    var onAddEmpty: () -> Void
    var onAddFromTemplate: (TaskTemplate) -> Void
    var onShowSettings: () -> Void

    @State private var showTemplates = false

    var body: some View {
        HStack(spacing: 0) {
            // + button — single click adds a new task
            Button(action: onAddEmpty) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            // Quick-add from template
            if !templates.isEmpty {
                Button(action: { showTemplates.toggle() }) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showTemplates, arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Hurtig tilf\u{00f8}j"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                            .padding(.horizontal, 8)
                            .padding(.top, 4)

                        ForEach(templates) { template in
                            Button(action: {
                                onAddFromTemplate(template)
                                showTemplates = false
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.accent.opacity(0.7))

                                    Text(template.name)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Spacer()

                                    if let code = template.projectCode {
                                        Text(code)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(Theme.accent)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Theme.accent.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .frame(width: 220)
                }
            }

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
                .foregroundStyle(timerManager.showBillableTime ? Theme.accent : Theme.textSecondary(colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(timerManager.showBillableTime ? Theme.accent.opacity(0.12) : Theme.surfaceTint(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Spacer()

            // Settings button
            Button(action: onShowSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Theme.barBackground(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.separator(colorScheme))
                .frame(height: 1)
        }
    }
}
