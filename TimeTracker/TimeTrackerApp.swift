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
        WindowGroup("NMIC Time Tracker", id: "main") {
            ContentView(timerManager: timerManager)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 650, height: 450)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(String(localized: "Ny opgave")) {
                    NotificationCenter.default.post(name: .addNewTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandMenu(String(localized: "Opgaver")) {
                Button(String(localized: "Gå til i dag")) {
                    NotificationCenter.default.post(name: .goToToday, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Divider()

                Button(String(localized: "Vis faktisk tid")) {
                    NotificationCenter.default.post(name: .showActualTime, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button(String(localized: "Vis fakturerbar tid")) {
                    NotificationCenter.default.post(name: .showBillableTime, object: nil)
                }
                .keyboardShortcut("2", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }

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
