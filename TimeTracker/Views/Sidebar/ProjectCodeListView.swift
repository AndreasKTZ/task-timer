//
//  ProjectCodeListView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct ProjectCodeListView: View {
    @Query(sort: \ProjectCode.sortOrder) private var projectCodes: [ProjectCode]
    @Environment(\.modelContext) private var modelContext

    @State private var isAddingCode = false
    @State private var newCode = ""
    @State private var newName = ""
    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(String(localized: "Projektkoder"))
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button(action: {
                    isAddingCode = true
                    newCode = ""
                    newName = ""
                    isCodeFieldFocused = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 20, height: 20)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)

            // New code input
            if isAddingCode {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        TextField(String(localized: "Kode"), text: $newCode)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .focused($isCodeFieldFocused)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .frame(width: 60)

                        TextField(String(localized: "Navn (valgfrit)"), text: $newName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .onSubmit {
                                addProjectCode()
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    HStack {
                        Spacer()

                        Button(action: addProjectCode) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        .disabled(newCode.trimmingCharacters(in: .whitespaces).isEmpty)

                        Button(action: {
                            isAddingCode = false
                            newCode = ""
                            newName = ""
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
            }

            // Project code list
            if projectCodes.isEmpty && !isAddingCode {
                Text(String(localized: "Ingen projektkoder"))
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(projectCodes) { code in
                            ProjectCodeRow(
                                projectCode: code,
                                onDelete: {
                                    deleteProjectCode(code)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func addProjectCode() {
        let code = newCode.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return }

        let name = newName.trimmingCharacters(in: .whitespaces)
        let projectCode = ProjectCode(code: code, name: name, sortOrder: projectCodes.count)
        modelContext.insert(projectCode)

        isAddingCode = false
        newCode = ""
        newName = ""
    }

    private func deleteProjectCode(_ code: ProjectCode) {
        modelContext.delete(code)
    }
}
