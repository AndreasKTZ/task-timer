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

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [self] _ in
            MainActor.assumeIsolated {
                let context = sharedModelContainer.mainContext
                let descriptor = FetchDescriptor<Task>()
                if let tasks = try? context.fetch(descriptor) {
                    timerManager.stopAllTasks(tasks, modelContext: context)
                }
            }
        }
    }

    var body: some Scene {
        Settings {
            SettingsView()
        }

        MenuBarExtra {
            MenuBarContentView(timerManager: timerManager)
                .modelContainer(sharedModelContainer)
        } label: {
            MenuBarLabel(timerManager: timerManager)
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}
