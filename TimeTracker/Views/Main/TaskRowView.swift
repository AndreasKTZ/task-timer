//
//  TaskRowView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI

struct TaskRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var task: Task
    @Bindable var timerManager: TimerManager
    var isActive: Bool
    var isSelected: Bool
    var isDayClosed: Bool = false
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onSelect: () -> Void
    var onEditCode: () -> Void

    @State private var isEditingName = false
    @State private var editedName: String = ""
    @State private var isEditingTime = false
    @State private var editedTime: String = ""
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isTimeFieldFocused: Bool
    @State private var isHovered = false

    private var displayedTime: String {
        let _ = timerManager.tick
        return task.formattedTime
    }

    private var displayedHours: Double {
        let _ = timerManager.tick
        return timerManager.showBillableTime ? task.roundedDecimalHours : task.decimalHours
    }

    var body: some View {
        HStack(spacing: 0) {
            // Play/pause button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isDayClosed ? Theme.textQuaternary(colorScheme) : (isActive ? Theme.accent : Theme.accent.opacity(0.15)))
                        .frame(width: 30, height: 30)

                    Image(systemName: isDayClosed ? "lock.fill" : (isActive ? "pause.fill" : "play.fill"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isDayClosed ? Theme.textTertiary(colorScheme) : (isActive ? .white : Theme.accent))
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(.plain)
            .disabled(isDayClosed)
            .padding(.trailing, 8)

            // Task name
            if isEditingName {
                TextField(String(localized: "Opgavenavn"), text: $editedName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                    .focused($isNameFieldFocused)
                    .onSubmit { commitNameEdit() }
                    .onChange(of: isNameFieldFocused) { _, focused in
                        if !focused { commitNameEdit() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(task.name.isEmpty ? String(localized: "Unavngivet opgave") : task.name)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(task.name.isEmpty ? Theme.textQuaternary(colorScheme) : Theme.textPrimary(colorScheme))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect()
                        if !isDayClosed { startNameEditing() }
                    }
            }

            // Project code — tap to edit via banner
            Button(action: { if !isDayClosed { onEditCode() } }) {
                if let code = task.projectCode {
                    Text(code)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    Image(systemName: "tag")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textQuaternary(colorScheme))
                }
            }
            .buttonStyle(.plain)
            .frame(width: 64)

            // Time (HH:MM:SS)
            if isEditingTime {
                TextField("00:00:00", text: $editedTime)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                    .multilineTextAlignment(.trailing)
                    .focused($isTimeFieldFocused)
                    .frame(width: 68, alignment: .trailing)
                    .onSubmit { commitTimeEdit() }
                    .onChange(of: isTimeFieldFocused) { _, focused in
                        if !focused { commitTimeEdit() }
                    }
            } else {
                Text(displayedTime)
                    .font(.system(size: 12, weight: isActive ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(isActive ? Theme.textPrimary(colorScheme) : Theme.textSecondary(colorScheme))
                    .frame(width: 68, alignment: .trailing)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isDayClosed { startTimeEditing() }
                    }
            }

            // Decimal hours
            Text(String(format: "%.2f", displayedHours))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.textTertiary(colorScheme))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(rowBackground)
        .opacity(isDayClosed ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.separator(colorScheme).opacity(0.6))
                .frame(height: 1)
                .padding(.leading, 50)
        }
        .contextMenu {
            if !isDayClosed {
                Button(isActive ? String(localized: "Stop") : String(localized: "Start")) {
                    onToggle()
                }

                Divider()

                Button(String(localized: "Rediger navn")) {
                    startNameEditing()
                }

                Button(String(localized: "Rediger projektkode")) {
                    onEditCode()
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
    }

    private var rowBackground: Color {
        if isActive {
            return Theme.accent.opacity(0.08)
        } else if isHovered {
            return Theme.hoverBackground(colorScheme)
        }
        return .clear
    }

    // MARK: - Editing

    private func startNameEditing() {
        editedName = task.name
        isEditingName = true
        isNameFieldFocused = true
        timerManager.isEditing = true
    }

    private func commitNameEdit() {
        guard isEditingName else { return }
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        task.name = String(trimmed.prefix(200))
        isEditingName = false
        timerManager.isEditing = false
    }

    private func startTimeEditing() {
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
        guard isEditingTime else { return }
        let trimmed = editedTime.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            isEditingTime = false
            timerManager.isEditing = false
            return
        }

        let parts = trimmed.split(separator: ":").compactMap { Int($0) }
        var totalSeconds: Int?

        switch parts.count {
        case 3:
            guard parts[1] >= 0, parts[1] < 60, parts[2] >= 0, parts[2] < 60, parts[0] >= 0 else { return }
            totalSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2]
        case 2:
            guard parts[1] >= 0, parts[1] < 60, parts[0] >= 0 else { return }
            totalSeconds = parts[0] * 3600 + parts[1] * 60
        case 1:
            guard parts[0] >= 0 else { return }
            totalSeconds = parts[0] * 60
        default:
            return
        }

        if let seconds = totalSeconds {
            task.accumulatedSeconds = seconds
        }

        isEditingTime = false
        timerManager.isEditing = false
    }
}
