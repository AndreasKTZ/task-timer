//
//  TaskRowView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI

struct TaskRowView: View {
    @Bindable var task: Task
    var isActive: Bool
    var isSelected: Bool
    var tick: Int  // Used to trigger time recalculation
    var showBillableTime: Bool
    var onToggle: () -> Void
    var onDelete: () -> Void
    var onSelect: () -> Void

    @State private var isEditing = false
    @State private var editedName: String = ""
    @FocusState private var isTextFieldFocused: Bool

    // Computed with tick dependency to force refresh
    private var displayedTime: String {
        let _ = tick
        return task.formattedTime
    }

    private var displayedHours: Double {
        let _ = tick
        return showBillableTime ? task.roundedDecimalHours : task.decimalHours
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
            if isEditing {
                TextField("Opgavenavn", text: $editedName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        commitEdit()
                    }
            } else {
                Text(task.name.isEmpty ? "Unavngivet opgave" : task.name)
                    .font(.system(size: 14))
                    .foregroundStyle(task.name.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        startEditing()
                    }
                    .onTapGesture(count: 1) {
                        onSelect()
                    }
            }

            Spacer()

            // Time display (HH:MM:SS)
            Text(displayedTime)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)

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
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(borderColor, lineWidth: 1.5)
                )
        )
    }

    private func startEditing() {
        editedName = task.name
        isEditing = true
        isTextFieldFocused = true
    }

    private func commitEdit() {
        task.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditing = false
    }
}
