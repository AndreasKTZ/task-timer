//
//  SettingsView.swift
//  TimeTracker
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultShowBillableTime") private var defaultShowBillableTime = true

    var body: some View {
        Form {
            Toggle(String(localized: "Vis fakturerbar tid som standard"), isOn: $defaultShowBillableTime)
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 100)
    }
}
