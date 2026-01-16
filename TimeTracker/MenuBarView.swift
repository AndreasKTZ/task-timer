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

    private var runningTask: Task? {
        allTasks.first(where: { $0.isRunning })
    }

    private var totalTodayHours: Double {
        let _ = timerManager.tick
        return todaysTasks.reduce(0) { $0 + $1.decimalHours }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with total
            HStack {
                Text("I dag")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2f t", totalTodayHours))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Task list
            if todaysTasks.isEmpty {
                Text("Ingen opgaver i dag")
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
                                tick: timerManager.tick,
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
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text("Åbn Time Tracker")
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
                    Text("Afslut")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 240)
    }

    private func toggleTask(_ task: Task) {
        if task.isRunning {
            timerManager.stopTask(task, modelContext: modelContext)
        } else {
            timerManager.startTask(task, allTasks: allTasks, modelContext: modelContext)
        }
    }
}

struct MenuBarTaskRow: View {
    let task: Task
    let isActive: Bool
    let tick: Int
    let onToggle: () -> Void

    private var displayedTime: String {
        let _ = tick
        return task.formattedTime
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                // Play/Pause indicator
                Image(systemName: isActive ? "pause.circle.fill" : "play.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isActive ? Color("BrandAccent") : .secondary)

                // Task name with optional project code
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        if let code = task.projectCode {
                            Text(code)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color("BrandAccent"))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color("BrandAccent").opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                        Text(task.name.isEmpty ? "Unavngivet" : task.name)
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Time
                Text(displayedTime)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color("BrandAccent").opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
