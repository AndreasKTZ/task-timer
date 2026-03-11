//
//  ProjectCodeRow.swift
//  TimeTracker
//
//  Extracted from ProjectCodeListView.swift
//

import SwiftUI

struct ProjectCodeRow: View {
    let projectCode: ProjectCode
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color("BrandAccent").opacity(0.7))

            VStack(alignment: .leading, spacing: 1) {
                Text(projectCode.code)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)

                if !projectCode.name.isEmpty {
                    Text(projectCode.name)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

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
