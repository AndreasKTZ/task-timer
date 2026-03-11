//
//  TemplateButton.swift
//  TimeTracker
//
//  Extracted from TemplateListView.swift
//

import SwiftUI

struct TemplateButton: View {
    let template: TaskTemplate
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent.opacity(0.7))

                    Text(template.name)
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if let code = template.projectCode {
                        Text(code)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Theme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onTap) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.accent.opacity(0.6))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.04) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
