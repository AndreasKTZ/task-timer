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
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            // Main clickable area for adding task
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 10))
                        .foregroundStyle(Color("BrandAccent"))

                    Text(template.name)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Always visible delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? Color("BrandAccent").opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
