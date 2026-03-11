//
//  ProjectCodeListView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct ProjectCodeListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \ProjectCode.sortOrder) private var projectCodes: [ProjectCode]
    @Environment(\.modelContext) private var modelContext

    @State private var showBanner = false
    @State private var editingCode: ProjectCode?
    @State private var bannerCode = ""
    @State private var bannerName = ""
    @FocusState private var isCodeFocused: Bool
    @FocusState private var isNameFocused: Bool

    private var isEditing: Bool { editingCode != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(String(localized: "Projektkoder"))
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

            // Project code list
            if projectCodes.isEmpty && !showBanner {
                Text(String(localized: "Ingen projektkoder"))
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(projectCodes) { code in
                            ProjectCodeRow(
                                projectCode: code,
                                onEdit: { showEdit(code) },
                                onDelete: {
                                    modelContext.delete(code)
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
        HStack(spacing: 8) {
            Image(systemName: "tag.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.blue)

            TextField(String(localized: "Kode"), text: $bannerCode)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary(colorScheme))
                .focused($isCodeFocused)
                .onSubmit { isNameFocused = true }
                .frame(width: 60)

            TextField(String(localized: "Navn (valgfrit)"), text: $bannerName)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
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
                    .background(Theme.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
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
        editingCode = nil
        bannerCode = ""
        bannerName = ""
        withAnimation(.easeInOut(duration: 0.15)) {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isCodeFocused = true
        }
    }

    private func showEdit(_ code: ProjectCode) {
        editingCode = code
        bannerCode = code.code
        bannerName = code.name
        withAnimation(.easeInOut(duration: 0.15)) {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isCodeFocused = true
        }
    }

    private func commitBanner() {
        let code = bannerCode.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else {
            cancelBanner()
            return
        }

        let name = bannerName.trimmingCharacters(in: .whitespaces)

        if let existing = editingCode {
            existing.code = code
            existing.name = name
        } else {
            let projectCode = ProjectCode(code: code, name: name, sortOrder: projectCodes.count)
            modelContext.insert(projectCode)
        }

        withAnimation(.easeInOut(duration: 0.15)) {
            showBanner = false
            editingCode = nil
            bannerCode = ""
            bannerName = ""
        }
    }

    private func cancelBanner() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showBanner = false
            editingCode = nil
            bannerCode = ""
            bannerName = ""
        }
    }
}
