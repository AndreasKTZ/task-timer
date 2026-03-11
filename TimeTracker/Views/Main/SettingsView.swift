//
//  SettingsView.swift
//  TimeTracker
//

import SwiftUI
import SwiftData

enum SettingsTab: String, CaseIterable {
    case settings, templates, projectCodes

    var label: String {
        switch self {
        case .settings: String(localized: "Indstillinger")
        case .templates: String(localized: "Skabeloner")
        case .projectCodes: String(localized: "Projektkoder")
        }
    }

    var icon: String {
        switch self {
        case .settings: "gearshape"
        case .templates: "doc.text"
        case .projectCodes: "tag"
        }
    }
}

struct InlineSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    var onBack: () -> Void
    @State private var selectedTab: SettingsTab = .settings

    var body: some View {
        VStack(spacing: 0) {
            // Header: back button + tab bar
            HStack(spacing: 8) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack(spacing: 2) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            HStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 10))
                                Text(tab.label)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(selectedTab == tab ? Theme.accent : Theme.textSecondary(colorScheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(selectedTab == tab ? Theme.accent.opacity(0.12) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.surfaceTint(colorScheme))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.separator(colorScheme))
                    .frame(height: 1)
            }

            // Tab content
            switch selectedTab {
            case .settings:
                GeneralSettingsTab()
            case .templates:
                TemplateListView(onAddTask: { _ in })
            case .projectCodes:
                ProjectCodeListView()
            }
        }
    }
}

// MARK: - General Settings Tab

private struct GeneralSettingsTab: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("defaultShowBillableTime") private var defaultShowBillableTime = true
    @AppStorage("workbookAPIKey") private var workbookAPIKey = ""
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                settingsSection(title: String(localized: "Generelt")) {
                    HStack {
                        Text(String(localized: "Vis fakturerbar tid som standard"))
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textPrimary(colorScheme))
                        Spacer()
                        Toggle("", isOn: $defaultShowBillableTime)
                            .toggleStyle(.switch)
                            .tint(Theme.accent)
                            .labelsHidden()
                    }
                }

                settingsSection(title: String(localized: "Udseende")) {
                    HStack(spacing: 2) {
                        ForEach(["system", "light", "dark"], id: \.self) { mode in
                            Button(action: { appearanceMode = mode }) {
                                Text(appearanceModeLabel(mode))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(appearanceMode == mode ? .white : Theme.textPrimary(colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(appearanceMode == mode ? Theme.accent : Theme.surfaceTint(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                settingsSection(title: String(localized: "Workbook")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "API-n\u{00f8}gle"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary(colorScheme))

                        SecureField(String(localized: "Indtast API-n\u{00f8}gle"), text: $workbookAPIKey)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textPrimary(colorScheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.surfaceTint(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.separator(colorScheme), lineWidth: 1)
                            )

                        Text(String(localized: "Indtast din personlige API-n\u{00f8}gle fra Workbook for at synkronisere tidsregistreringer."))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary(colorScheme))
                    }
                }
            }
            .padding(20)
        }
    }

    private func appearanceModeLabel(_ mode: String) -> String {
        switch mode {
        case "light": String(localized: "Lys")
        case "dark": String(localized: "Mørk")
        default: String(localized: "System")
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textTertiary(colorScheme))
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceTint(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.separator(colorScheme), lineWidth: 1)
            )
        }
    }
}
