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
        HStack(spacing: 6) {
            Image(systemName: "tag.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color("BrandAccent"))

            VStack(alignment: .leading, spacing: 1) {
                Text(projectCode.code)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)

                if !projectCode.name.isEmpty {
                    Text(projectCode.name)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

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
