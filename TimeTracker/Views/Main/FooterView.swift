//
//  FooterView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI

struct FooterView: View {
    var tasks: [Task]
    var showBillableTime: Bool
    var onAddTask: () -> Void

    private var hasRunningTask: Bool {
        tasks.contains(where: { $0.isRunning })
    }

    var body: some View {
        HStack {
            // Add task button
            Button(action: onAddTask) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text(String(localized: "Ny opgave"))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color("BrandAccent"))
            }
            .buttonStyle(.plain)

            Spacer()

            // Total time — live updates only when a task is running
            if hasRunningTask {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    totalTimeDisplay
                }
            } else {
                totalTimeDisplay
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var totalTimeDisplay: some View {
        HStack(spacing: 16) {
            Text(String(localized: "I alt:"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text(totalFormattedTime)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)

            Text(String(format: "%.2f t", totalDecimalHours))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("BrandAccent"))
        }
    }

    private var totalDecimalHours: Double {
        if showBillableTime {
            return tasks.reduce(0) { $0 + $1.roundedDecimalHours }
        } else {
            return tasks.reduce(0) { $0 + $1.decimalHours }
        }
    }

    private var totalFormattedTime: String {
        let totalSeconds = tasks.reduce(0) { $0 + $1.currentTotalSeconds }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
