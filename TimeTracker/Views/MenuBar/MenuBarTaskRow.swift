//
//  MenuBarTaskRow.swift
//  TimeTracker
//
//  Extracted from MenuBarView.swift
//

import SwiftUI

struct MenuBarTaskRow: View {
    let task: Task
    let isActive: Bool
    let onToggle: () -> Void

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
                        Text(task.name.isEmpty ? String(localized: "Unavngivet") : task.name)
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Time — live update only when running
                if isActive {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(task.formattedTime)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(task.formattedTime)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color("BrandAccent").opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
