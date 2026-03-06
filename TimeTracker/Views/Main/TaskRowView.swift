//
//  TaskRowView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI

struct TaskRowView: View {
    @Bindable var task: Task
    @Bindable var timerManager: TimerManager
    var isActive: Bool
    var isSelected: Bool
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onSelect: () -> Void

    @State private var isEditingName = false
    @State private var editedName: String = ""
    @State private var isEditingTime = false
    @State private var editedTime: String = ""
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isTimeFieldFocused: Bool
    @State private var isHovered = false


    private var backgroundColor: Color {
        if isActive {
            return Color("BrandAccent").opacity(0.1)
        } else if isSelected {
            return Color("BrandAccent").opacity(0.06)
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        isSelected ? Color("BrandAccent").opacity(0.5) : Color.clear
    }

    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: onToggle) {
                Image(systemName: isActive ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isActive ? Color("BrandBackground") : Color("BrandAccent"))
                    .frame(width: 28, height: 28)
                    .background(isActive ? Color("BrandBackground").opacity(0.15) : Color("BrandAccent").opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isActive ? String(localized: "Stop opgave") : String(localized: "Start opgave"))
            .accessibilityHint(task.name.isEmpty ? String(localized: "Unavngivet opgave") : task.name)

            // Project code picker
            ProjectCodePicker(selectedCode: $task.projectCode)

            // Task name
            if isEditingName {
                HStack(spacing: 4) {
                    TextField(String(localized: "Opgavenavn"), text: $editedName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .focused($isNameFieldFocused)
                        .onSubmit {
                            commitNameEdit()
                        }

                    Button(action: commitNameEdit) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)

                    Button(action: cancelNameEdit) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text(task.name.isEmpty ? String(localized: "Unavngivet opgave") : task.name)
                    .font(.system(size: 14))
                    .foregroundStyle(task.name.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startNameEditing()
                    }
            }

            Spacer()

            // Time display (HH:MM:SS) - clickable to edit
            if isEditingTime {
                TextField("00:00:00", text: $editedTime)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .monospaced))
                    .multilineTextAlignment(.trailing)
                    .focused($isTimeFieldFocused)
                    .frame(width: 70)
                    .onSubmit {
                        commitTimeEdit()
                    }
            } else {
                LiveTimeText(task: task, isActive: isActive)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startTimeEditing()
                    }
                    .help(String(localized: "Klik for at redigere tid"))
            }

            // Decimal hours
            LiveDecimalHours(task: task, isActive: isActive, showBillable: timerManager.showBillableTime)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .opacity(isActive ? 0.5 : 1)
            .accessibilityLabel(String(localized: "Slet opgave"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onHover { hovering in
            isHovered = hovering
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(borderColor, lineWidth: 1.5)
                )
        )
        .contextMenu {
            Button(isActive ? String(localized: "Stop") : String(localized: "Start")) {
                onToggle()
            }

            Divider()

            Button(String(localized: "Rediger navn")) {
                startNameEditing()
            }

            Button(String(localized: "Rediger tid")) {
                startTimeEditing()
            }

            Divider()

            Button(String(localized: "Slet"), role: .destructive) {
                onDelete()
            }
        }
    }

    private func startNameEditing() {
        editedName = task.name
        isEditingName = true
        isNameFieldFocused = true
        timerManager.isEditing = true
    }

    private func commitNameEdit() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        task.name = String(trimmed.prefix(200))
        isEditingName = false
        timerManager.isEditing = false
    }

    private func cancelNameEdit() {
        isEditingName = false
        timerManager.isEditing = false
    }

    private func startTimeEditing() {
        // Stop the task if running before editing (also clear TimerManager state)
        if task.isRunning {
            task.stop()
            if timerManager.activeTaskID == task.id {
                timerManager.activeTaskID = nil
            }
        }
        editedTime = task.formattedTime
        isEditingTime = true
        isTimeFieldFocused = true
        timerManager.isEditing = true
    }

    private func commitTimeEdit() {
        let trimmed = editedTime.trimmingCharacters(in: .whitespaces)

        // Empty input cancels edit
        guard !trimmed.isEmpty else {
            isEditingTime = false
            timerManager.isEditing = false
            return
        }

        let parts = trimmed.split(separator: ":").compactMap { Int($0) }
        var totalSeconds: Int?

        switch parts.count {
        case 3:
            // HH:MM:SS — validate minutes and seconds are 0-59
            guard parts[1] >= 0, parts[1] < 60, parts[2] >= 0, parts[2] < 60, parts[0] >= 0 else { return }
            totalSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2]
        case 2:
            // HH:MM — validate minutes are 0-59
            guard parts[1] >= 0, parts[1] < 60, parts[0] >= 0 else { return }
            totalSeconds = parts[0] * 3600 + parts[1] * 60
        case 1:
            // Just a number — treat as minutes
            guard parts[0] >= 0 else { return }
            totalSeconds = parts[0] * 60
        default:
            return // Invalid format, stay in edit mode
        }

        if let seconds = totalSeconds {
            task.accumulatedSeconds = seconds
        }

        isEditingTime = false
        timerManager.isEditing = false
    }
}

// MARK: - Live Time Display Helpers

/// Displays formatted time (HH:MM:SS) with live updates only when the task is running.
private struct LiveTimeText: View {
    let task: Task
    let isActive: Bool

    var body: some View {
        if isActive {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                timeText
            }
        } else {
            timeText
        }
    }

    private var timeText: some View {
        Text(task.formattedTime)
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 70, alignment: .trailing)
    }
}

/// Displays decimal hours with live updates only when the task is running.
private struct LiveDecimalHours: View {
    let task: Task
    let isActive: Bool
    let showBillable: Bool

    var body: some View {
        if isActive {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                hoursText
            }
        } else {
            hoursText
        }
    }

    private var hoursText: some View {
        Text(String(format: "%.2f", showBillable ? task.roundedDecimalHours : task.decimalHours))
            .font(.system(size: 14, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 50, alignment: .trailing)
    }
}
