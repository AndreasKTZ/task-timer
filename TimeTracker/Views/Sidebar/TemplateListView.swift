//
//  TemplateListView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Query(sort: \TaskTemplate.sortOrder) private var templates: [TaskTemplate]
    @Environment(\.modelContext) private var modelContext
    var onAddTask: (String) -> Void

    @State private var isAddingTemplate = false
    @State private var newTemplateName = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(String(localized: "Skabeloner"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: {
                    isAddingTemplate = true
                    newTemplateName = ""
                    isTextFieldFocused = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color("BrandAccent"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)

            // New template input
            if isAddingTemplate {
                HStack(spacing: 4) {
                    TextField(String(localized: "Navn"), text: $newTemplateName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            addTemplate()
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Button(action: addTemplate) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(newTemplateName.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button(action: {
                        isAddingTemplate = false
                        newTemplateName = ""
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
            }

            // Template list
            if templates.isEmpty && !isAddingTemplate {
                Text(String(localized: "Ingen skabeloner"))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(templates) { template in
                            TemplateButton(
                                template: template,
                                onTap: {
                                    onAddTask(template.name)
                                },
                                onDelete: {
                                    deleteTemplate(template)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func addTemplate() {
        let name = newTemplateName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let template = TaskTemplate(name: name, sortOrder: templates.count)
        modelContext.insert(template)

        isAddingTemplate = false
        newTemplateName = ""
    }

    private func deleteTemplate(_ template: TaskTemplate) {
        modelContext.delete(template)
    }
}
