//
//  HeaderView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI

struct HeaderView: View {
    @Bindable var timerManager: TimerManager
    var tasks: [Task]
    var onStopAll: () -> Void
    var onStartFirst: () -> Void

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "da_DK")
        formatter.dateFormat = "EEEE d. MMMM yyyy"
        return formatter
    }

    var body: some View {
        HStack(spacing: 16) {
            // Global play/pause button
            Button(action: {
                if timerManager.isAnyTaskRunning {
                    onStopAll()
                } else {
                    onStartFirst()
                }
            }) {
                Image(systemName: timerManager.isAnyTaskRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(timerManager.isAnyTaskRunning ? Color.orange : Color.green)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!timerManager.isAnyTaskRunning && tasks.isEmpty)
            .opacity(!timerManager.isAnyTaskRunning && tasks.isEmpty ? 0.5 : 1)
            .help(timerManager.isAnyTaskRunning ? "Sæt aktiv opgave på pause" : (tasks.isEmpty ? "Ingen opgaver" : "Start første opgave"))

            Spacer()

            // Date navigation
            HStack(spacing: 8) {
                Button(action: timerManager.goToPreviousDay) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(dateFormatter.string(from: timerManager.selectedDate))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)

                Button(action: timerManager.goToNextDay) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Toggle between actual and billable time
            Picker("", selection: $timerManager.showBillableTime) {
                Text("Faktisk").tag(false)
                Text("Fakturerbar").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
