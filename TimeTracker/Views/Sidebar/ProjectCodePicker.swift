//
//  ProjectCodePicker.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct ProjectCodePicker: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedCode: String?
    @Query(sort: \ProjectCode.sortOrder) private var projectCodes: [ProjectCode]

    var body: some View {
        Menu {
            Button(action: {
                selectedCode = nil
            }) {
                HStack {
                    Text(String(localized: "Ingen"))
                    if selectedCode == nil {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            if !projectCodes.isEmpty {
                Divider()

                ForEach(projectCodes) { code in
                    Button(action: {
                        selectedCode = code.code
                    }) {
                        HStack {
                            Text(code.displayName)
                            if selectedCode == code.code {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            if let code = selectedCode {
                Text(code)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Image(systemName: "tag")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textQuaternary(colorScheme))
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
