//
//  TemplateListView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \TaskTemplate.sortOrder) private var templates: [TaskTemplate]
    @Query(sort: \ProjectCode.sortOrder) private var projectCodes: [ProjectCode]
    @Environment(\.modelContext) private var modelContext
    var onAddTask: (String) -> Void

    @State private var showBanner = false
    @State private var editingTemplate: TaskTemplate?
    @State private var bannerName = ""
    @State private var selectedCode: String?
    @FocusState private var isNameFocused: Bool

    private var isEditing: Bool { editingTemplate != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(String(localized: "Skabeloner"))
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button(action: showAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 20, height: 20)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Template list
            if templates.isEmpty && !showBanner {
                Text(String(localized: "Ingen skabeloner"))
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(templates) { template in
                            TemplateButton(
                                template: template,
                                onTap: {
                                    onAddTask(template.name)
                                },
                                onEdit: { showEdit(template) },
                                onDelete: {
                                    modelContext.delete(template)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }

            // Add/Edit banner at bottom
            if showBanner {
                banner
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var banner: some View {
        VStack(spacing: 8) {
            // Project code quick-pick
            if !projectCodes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(projectCodes) { code in
                            Button(action: {
                                selectedCode = selectedCode == code.code ? nil : code.code
                            }) {
                                Text(code.displayName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(selectedCode == code.code ? .white : Theme.accent)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(selectedCode == code.code ? Theme.accent : Theme.accent.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent)

                TextField(String(localized: "Skabelonnavn"), text: $bannerName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                    .focused($isNameFocused)
                    .onSubmit { commitBanner() }

                Spacer()

                Button(action: cancelBanner) {
                    Text(String(localized: "Annuller"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.bannerSecondaryText(colorScheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.bannerSecondaryButton(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Button(action: commitBanner) {
                    Text(String(localized: isEditing ? "Gem" : "Tilf\u{00f8}j"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surfaceTint(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.separator(colorScheme))
                .frame(height: 1)
        }
    }

    private func showAdd() {
        editingTemplate = nil
        bannerName = ""
        selectedCode = nil
        withAnimation(.easeInOut(duration: 0.15)) {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNameFocused = true
        }
    }

    private func showEdit(_ template: TaskTemplate) {
        editingTemplate = template
        bannerName = template.name
        selectedCode = template.projectCode
        withAnimation(.easeInOut(duration: 0.15)) {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNameFocused = true
        }
    }

    private func commitBanner() {
        let name = bannerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            cancelBanner()
            return
        }

        if let existing = editingTemplate {
            existing.name = name
            existing.projectCode = selectedCode
        } else {
            let template = TaskTemplate(
                name: name,
                projectCode: selectedCode,
                sortOrder: templates.count
            )
            modelContext.insert(template)
        }

        withAnimation(.easeInOut(duration: 0.15)) {
            showBanner = false
            editingTemplate = nil
            bannerName = ""
            selectedCode = nil
        }
    }

    private func cancelBanner() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showBanner = false
            editingTemplate = nil
            bannerName = ""
            selectedCode = nil
        }
    }
}
