//
//  SettingsView.swift
//  TimeTracker
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum SettingsTab: String, CaseIterable {
    case settings, templates, projectCodes, export, stats

    var label: String {
        switch self {
        case .settings: String(localized: "Indstillinger")
        case .templates: String(localized: "Skabeloner")
        case .projectCodes: String(localized: "Projektkoder")
        case .export: String(localized: "Eksport")
        case .stats: String(localized: "Statistik")
        }
    }

    var icon: String {
        switch self {
        case .settings: "gearshape"
        case .templates: "doc.text"
        case .projectCodes: "tag"
        case .export: "square.and.arrow.up"
        case .stats: "chart.bar"
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
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(selectedTab == tab ? Theme.accent : Theme.textSecondary(colorScheme))
                                .frame(width: 36, height: 28)
                                .contentShape(Rectangle())
                                .background(selectedTab == tab ? Theme.accent.opacity(0.12) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                        .help(tab.label)
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
            case .export:
                ExportSettingsTab()
            case .stats:
                StatsTab()
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
                        Text(String(localized: "Vis fakturerbar tid i menulinjen"))
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
                        Text(String(localized: "API-nøgle"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textTertiary(colorScheme))

                        SecureField(String(localized: "Indtast API-nøgle"), text: $workbookAPIKey)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textTertiary(colorScheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.surfaceTint(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.separator(colorScheme), lineWidth: 1)
                            )
                            .disabled(true)

                        Text(String(localized: "Workbook-integration er endnu ikke tilgængelig."))
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
        SettingsSection(title: title, colorScheme: colorScheme, content: content)
    }
}

// MARK: - Shared Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let colorScheme: ColorScheme
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textTertiary(colorScheme))
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(alignment: .leading, spacing: 12) {
                content
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

// MARK: - Export Settings Tab

private struct ExportSettingsTab: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [Task]
    @State private var exportRange: ExportRange = .thisWeek
    @State private var exportFormat: ExportFormat = .csv
    @State private var showExportSuccess = false

    enum ExportRange: String, CaseIterable {
        case today, thisWeek, thisMonth, all

        var label: String {
            switch self {
            case .today: String(localized: "I dag")
            case .thisWeek: String(localized: "Uge")
            case .thisMonth: String(localized: "Måned")
            case .all: String(localized: "Alt")
            }
        }
    }

    enum ExportFormat: String, CaseIterable {
        case csv, json

        var label: String {
            switch self {
            case .csv: "CSV"
            case .json: "JSON"
            }
        }
    }

    private var filteredTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        switch exportRange {
        case .today:
            return allTasks.filter { calendar.isDateInToday($0.date) }
        case .thisWeek:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
            return allTasks.filter { $0.date >= weekStart }
        case .thisMonth:
            guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return [] }
            return allTasks.filter { $0.date >= monthStart }
        case .all:
            return allTasks
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsSection(title: String(localized: "Periode"), colorScheme: colorScheme) {
                    HStack(spacing: 2) {
                        ForEach(ExportRange.allCases, id: \.self) { range in
                            Button(action: { exportRange = range }) {
                                Text(range.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(exportRange == range ? .white : Theme.textPrimary(colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(exportRange == range ? Theme.accent : Theme.surfaceTint(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SettingsSection(title: String(localized: "Format"), colorScheme: colorScheme) {
                    HStack(spacing: 2) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(action: { exportFormat = format }) {
                                Text(format.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(exportFormat == format ? .white : Theme.textPrimary(colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(exportFormat == format ? Theme.accent : Theme.surfaceTint(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SettingsSection(title: String(localized: "Oversigt"), colorScheme: colorScheme) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "Opgaver"))
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textPrimary(colorScheme))
                            Spacer()
                            Text("\(filteredTasks.count)")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.textSecondary(colorScheme))
                        }

                        let totalHours = filteredTasks.reduce(0.0) { $0 + $1.decimalHours }
                        HStack {
                            Text(String(localized: "Timer i alt"))
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textPrimary(colorScheme))
                            Spacer()
                            Text(String(format: "%.2f", totalHours))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.textSecondary(colorScheme))
                        }

                        let billableHours = filteredTasks.reduce(0.0) { $0 + $1.roundedDecimalHours }
                        HStack {
                            Text(String(localized: "Fakturerbare timer"))
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textPrimary(colorScheme))
                            Spacer()
                            Text(String(format: "%.2f", billableHours))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.textSecondary(colorScheme))
                        }
                    }
                }

                Button(action: exportData) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                        Text(String(localized: "Eksportér"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(filteredTasks.isEmpty ? Theme.textTertiary(colorScheme) : Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(filteredTasks.isEmpty)

                if showExportSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.green)
                        Text(String(localized: "Eksport gemt"))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary(colorScheme))
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(20)
        }
    }

    private func exportData() {
        let tasks = filteredTasks.sorted(by: { $0.date < $1.date })
        guard !tasks.isEmpty else { return }

        let content: String
        let fileExtension: String

        switch exportFormat {
        case .csv:
            fileExtension = "csv"
            let sep = ";"
            var lines = ["Dato\(sep)Opgave\(sep)Projektkode\(sep)Sekunder\(sep)Timer\(sep)Fakturerbare timer"]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            for task in tasks {
                let date = dateFormatter.string(from: task.date)
                let name = csvEscape(task.name)
                let code = csvEscape(task.projectCode ?? "")
                let hours = String(format: "%.2f", task.decimalHours).replacingOccurrences(of: ".", with: ",")
                let billable = String(format: "%.2f", task.roundedDecimalHours).replacingOccurrences(of: ".", with: ",")
                lines.append("\(date)\(sep)\(name)\(sep)\(code)\(sep)\(task.accumulatedSeconds)\(sep)\(hours)\(sep)\(billable)")
            }
            // UTF-8 BOM for Excel compatibility
            content = "\u{FEFF}" + lines.joined(separator: "\n")

        case .json:
            fileExtension = "json"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let items: [[String: Any]] = tasks.map { task in
                [
                    "date": dateFormatter.string(from: task.date),
                    "name": task.name,
                    "projectCode": task.projectCode ?? "",
                    "seconds": task.accumulatedSeconds,
                    "hours": round(task.decimalHours * 100) / 100,
                    "billableHours": round(task.roundedDecimalHours * 100) / 100
                ]
            }
            if let data = try? JSONSerialization.data(withJSONObject: items, options: [.prettyPrinted, .sortedKeys]),
               let jsonString = String(data: data, encoding: .utf8) {
                content = jsonString
            } else {
                content = "[]"
            }
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = fileExtension == "csv"
            ? [.commaSeparatedText]
            : [.json]
        panel.nameFieldStringValue = "timetracker-export.\(fileExtension)"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
            withAnimation { showExportSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showExportSuccess = false }
            }
        }
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(";") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}

// MARK: - Stats Tab

private struct StatsTab: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query private var allTasks: [Task]
    @Query private var closedDays: [ClosedDay]
    @State private var statsPeriod: StatsPeriod = .thisWeek

    enum StatsPeriod: String, CaseIterable {
        case thisWeek, thisMonth, allTime

        var label: String {
            switch self {
            case .thisWeek: String(localized: "Uge")
            case .thisMonth: String(localized: "Måned")
            case .allTime: String(localized: "Alt")
            }
        }
    }

    private var filteredTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        switch statsPeriod {
        case .thisWeek:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
            return allTasks.filter { $0.date >= weekStart }
        case .thisMonth:
            guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return [] }
            return allTasks.filter { $0.date >= monthStart }
        case .allTime:
            return allTasks
        }
    }

    private var totalSeconds: Int {
        filteredTasks.reduce(0) { $0 + $1.accumulatedSeconds }
    }

    private var totalBillable: Double {
        filteredTasks.reduce(0.0) { $0 + $1.roundedDecimalHours }
    }

    private var uniqueDays: Int {
        Set(filteredTasks.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    private var avgHoursPerDay: Double {
        guard uniqueDays > 0 else { return 0 }
        return Double(totalSeconds) / 3600.0 / Double(uniqueDays)
    }

    /// Tasks grouped by project code, sorted by total hours descending
    private var projectBreakdown: [(code: String, hours: Double, billable: Double, count: Int)] {
        var grouped: [String: (hours: Double, billable: Double, count: Int)] = [:]
        for task in filteredTasks {
            let code = task.projectCode ?? String(localized: "Ingen kode")
            let existing = grouped[code, default: (0, 0, 0)]
            grouped[code] = (existing.hours + task.decimalHours, existing.billable + task.roundedDecimalHours, existing.count + 1)
        }
        return grouped.map { (code: $0.key, hours: $0.value.hours, billable: $0.value.billable, count: $0.value.count) }
            .sorted { $0.hours > $1.hours }
    }

    /// Daily hours for bar chart
    private var dailyHours: [(date: Date, hours: Double)] {
        var grouped: [Date: Double] = [:]
        for task in filteredTasks {
            let day = Calendar.current.startOfDay(for: task.date)
            grouped[day, default: 0] += task.decimalHours
        }
        return grouped.map { (date: $0.key, hours: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period selector
                SettingsSection(title: String(localized: "Periode"), colorScheme: colorScheme) {
                    HStack(spacing: 2) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Button(action: { statsPeriod = period }) {
                                Text(period.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(statsPeriod == period ? .white : Theme.textPrimary(colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(statsPeriod == period ? Theme.accent : Theme.surfaceTint(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Summary cards
                SettingsSection(title: String(localized: "Overblik"), colorScheme: colorScheme) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(label: String(localized: "Total tid"), value: formatSeconds(totalSeconds))
                        statCard(label: String(localized: "Fakturerbart"), value: String(format: "%.1f t", totalBillable))
                        statCard(label: String(localized: "Arbejdsdage"), value: "\(uniqueDays)")
                        statCard(label: String(localized: "Gns./dag"), value: String(format: "%.1f t", avgHoursPerDay))
                    }
                }

                // Daily bar chart
                if !dailyHours.isEmpty {
                    SettingsSection(title: String(localized: "Timer pr. dag"), colorScheme: colorScheme) {
                        dailyBarChart
                    }
                }

                // Project breakdown
                if !projectBreakdown.isEmpty {
                    SettingsSection(title: String(localized: "Pr. projektkode"), colorScheme: colorScheme) {
                        VStack(spacing: 0) {
                            ForEach(Array(projectBreakdown.enumerated()), id: \.offset) { index, item in
                                if index > 0 {
                                    Rectangle()
                                        .fill(Theme.separator(colorScheme))
                                        .frame(height: 1)
                                        .padding(.vertical, 6)
                                }

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.code)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Theme.textPrimary(colorScheme))
                                        Text(String(localized: "\(item.count) opgaver"))
                                            .font(.system(size: 10))
                                            .foregroundStyle(Theme.textTertiary(colorScheme))
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(String(format: "%.1f t", item.hours))
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .foregroundStyle(Theme.textPrimary(colorScheme))
                                        Text(String(format: "%.1f t fakt.", item.billable))
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(Theme.textTertiary(colorScheme))
                                    }
                                }

                                // Proportion bar
                                let maxHours = projectBreakdown.first?.hours ?? 1
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.accent.opacity(0.3))
                                        .frame(width: geo.size.width * CGFloat(item.hours / maxHours), height: 4)
                                }
                                .frame(height: 4)
                                .padding(.top, 4)
                            }
                        }
                    }
                }

                // Closed days count
                let closedCount = closedDays.count
                if closedCount > 0 {
                    SettingsSection(title: String(localized: "Afsluttede dage"), colorScheme: colorScheme) {
                        HStack {
                            Text(String(localized: "Dage afsluttet"))
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textPrimary(colorScheme))
                            Spacer()
                            Text("\(closedCount)")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Theme.textSecondary(colorScheme))
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.accent)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.textTertiary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.panelBackground(colorScheme).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var dailyBarChart: some View {
        let maxHours = dailyHours.map(\.hours).max() ?? 1
        let dayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "E"
            f.locale = Locale(identifier: "da_DK")
            return f
        }()
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "d/M"
            return f
        }()

        return VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(dailyHours.enumerated()), id: \.offset) { _, entry in
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", entry.hours))
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Theme.textTertiary(colorScheme))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.accent.opacity(0.7))
                            .frame(height: max(4, CGFloat(entry.hours / maxHours) * 80))

                        VStack(spacing: 0) {
                            Text(dayFormatter.string(from: entry.date))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Theme.textSecondary(colorScheme))
                            Text(dateFormatter.string(from: entry.date))
                                .font(.system(size: 8))
                                .foregroundStyle(Theme.textTertiary(colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }
}
