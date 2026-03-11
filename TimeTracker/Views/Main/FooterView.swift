//
//  FooterView.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI

struct FooterView: View {
    var tasks: [Task]
    var showBillableTime: Bool
    var tick: Int

    private var totalDecimalHours: Double {
        let _ = tick
        if showBillableTime {
            return tasks.reduce(0) { $0 + $1.roundedDecimalHours }
        } else {
            return tasks.reduce(0) { $0 + $1.decimalHours }
        }
    }

    private var totalFormattedTime: String {
        let _ = tick
        let totalSeconds = tasks.reduce(0) { $0 + $1.currentTotalSeconds }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(String(localized: "I alt"))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()

            Text(totalFormattedTime)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)

            Text(String(format: "%.2f t", totalDecimalHours))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color("BrandAccent"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.02))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)
        }
    }
}
