//
//  MenuBarView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Query private var allTasks: [Task]
    @Environment(\.modelContext) private var modelContext
    @Bindable var timerManager: TimerManager
    @Environment(\.openWindow) private var openWindow

    private var todaysTasks: [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        return allTasks
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    private var hasRunningTask: Bool {
        todaysTasks.contains(where: { $0.isRunning })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with total — live update when task is running
            if hasRunningTask {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    headerRow
                }
            } else {
                headerRow
            }

            Divider()

            // Task list
            if todaysTasks.isEmpty {
                Text(String(localized: "Ingen opgaver i dag"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(todaysTasks) { task in
                            MenuBarTaskRow(
                                task: task,
                                isActive: task.isRunning,
                                onToggle: {
                                    toggleTask(task)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 200)
            }

            Divider()

            // Actions
            Button(action: {
                // Focus existing window or open new one
                if let window = NSApplication.shared.windows.first(where: { $0.title == "NMIC Time Tracker" }) {
                    window.makeKeyAndOrderFront(nil)
                } else {
                    openWindow(id: "main")
                }
                NSApplication.shared.activate(ignoringOtherApps: true)
            }) {
                HStack {
                    Image(systemName: "timer")
                    Text(String(localized: "Åbn Time Tracker"))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text(String(localized: "Afslut"))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 240)
    }

    private var headerRow: some View {
        HStack {
            Text(String(localized: "I dag"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.2f t", todaysTasks.reduce(0) { $0 + $1.decimalHours }))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func toggleTask(_ task: Task) {
        if task.isRunning {
            timerManager.stopTask(task, modelContext: modelContext)
        } else {
            timerManager.startTask(task, allTasks: allTasks, modelContext: modelContext)
        }
    }
}
