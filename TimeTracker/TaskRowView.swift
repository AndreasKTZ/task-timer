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

    // Computed with tick dependency to force refresh
    private var displayedTime: String {
        let _ = timerManager.tick
        return task.formattedTime
    }

    private var displayedHours: Double {
        let _ = timerManager.tick
        return timerManager.showBillableTime ? task.roundedDecimalHours : task.decimalHours
    }

    private var backgroundColor: Color {
        if isActive {
            return Color.green.opacity(0.1)
        } else if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        isSelected ? Color.blue.opacity(0.5) : Color.clear
    }

    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: onToggle) {
                Image(systemName: isActive ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isActive ? .orange : .green)
                    .frame(width: 28, height: 28)
                    .background(isActive ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Task name
            if isEditingName {
                TextField("Opgavenavn", text: $editedName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        commitNameEdit()
                    }
            } else {
                HStack(spacing: 6) {
                    Text(task.name.isEmpty ? "Unavngivet opgave" : task.name)
                        .font(.system(size: 14))
                        .foregroundStyle(task.name.isEmpty ? .secondary : .primary)

                    // Edit button (visible on hover)
                    Button(action: startNameEditing) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered ? 1 : 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
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
                Text(displayedTime)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startTimeEditing()
                    }
                    .help("Klik for at redigere tid")
            }

            // Decimal hours
            Text(String(format: "%.2f", displayedHours))
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .opacity(isActive ? 0.5 : 1)
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
    }

    private func startNameEditing() {
        editedName = task.name
        isEditingName = true
        isNameFieldFocused = true
        timerManager.isEditing = true
    }

    private func commitNameEdit() {
        task.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditingName = false
        timerManager.isEditing = false
    }

    private func startTimeEditing() {
        // Stop the task if running before editing
        if task.isRunning {
            task.stop()
        }
        editedTime = task.formattedTime
        isEditingTime = true
        isTimeFieldFocused = true
        timerManager.isEditing = true
    }

    private func commitTimeEdit() {
        // Parse HH:MM:SS or HH:MM or just minutes
        let trimmed = editedTime.trimmingCharacters(in: .whitespaces)
        var totalSeconds = 0

        let parts = trimmed.split(separator: ":").compactMap { Int($0) }

        if parts.count == 3 {
            // HH:MM:SS
            totalSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2]
        } else if parts.count == 2 {
            // HH:MM (assume hours:minutes)
            totalSeconds = parts[0] * 3600 + parts[1] * 60
        } else if parts.count == 1 {
            // Just a number - treat as minutes
            totalSeconds = parts[0] * 60
        }

        if totalSeconds >= 0 {
            task.accumulatedSeconds = totalSeconds
        }

        isEditingTime = false
        timerManager.isEditing = false
    }
}
