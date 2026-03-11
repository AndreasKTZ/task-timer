//
//  SettingsView.swift
//  TimeTracker
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultShowBillableTime") private var defaultShowBillableTime = true
    @AppStorage("workbookAPIKey") private var workbookAPIKey = ""

    var body: some View {
        Form {
            Section(String(localized: "Generelt")) {
                Toggle(String(localized: "Vis fakturerbar tid som standard"), isOn: $defaultShowBillableTime)
            }

            Section(String(localized: "Workbook")) {
                SecureField(String(localized: "API-n\u{00f8}gle"), text: $workbookAPIKey)
                    .textFieldStyle(.roundedBorder)

                Text(String(localized: "Indtast din personlige API-n\u{00f8}gle fra Workbook for at synkronisere tidsregistreringer."))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 200)
    }
}
