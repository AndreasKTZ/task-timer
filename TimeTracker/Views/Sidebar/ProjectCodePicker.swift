//
//  ProjectCodePicker.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import SwiftUI
import SwiftData

struct ProjectCodePicker: View {
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
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color("BrandAccent"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color("BrandAccent").opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "tag")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
