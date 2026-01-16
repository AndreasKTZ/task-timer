//
//  TimeTrackerApp.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

@main
struct TimeTrackerApp: App {
    @State private var timerManager = TimerManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
            TaskTemplate.self,
            ProjectCode.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup("NMIC Time Tracker", id: "main") {
            ContentView(timerManager: timerManager)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 650, height: 450)

        MenuBarExtra {
            MenuBarView(timerManager: timerManager)
                .modelContainer(sharedModelContainer)
        } label: {
            MenuBarLabel(timerManager: timerManager)
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @Query private var allTasks: [Task]
    @Bindable var timerManager: TimerManager

    private var runningTask: Task? {
        allTasks.first(where: { $0.isRunning })
    }

    private var displayText: String {
        let _ = timerManager.tick
        if let task = runningTask {
            return task.formattedTime
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: runningTask != nil ? "clock.fill" : "clock")
            if !displayText.isEmpty {
                Text(displayText)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
}
