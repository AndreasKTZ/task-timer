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
        HStack(spacing: 8) {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                        .foregroundStyle(Color("BrandAccent").opacity(0.7))

                    Text(template.name)
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
