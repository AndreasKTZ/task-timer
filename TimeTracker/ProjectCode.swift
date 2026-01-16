//
//  ProjectCode.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import Foundation
import SwiftData

@Model
final class ProjectCode {
    var id: UUID
    var code: String
    var name: String
    var sortOrder: Int
    var createdAt: Date

    init(code: String, name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.code = code
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var displayName: String {
        if name.isEmpty {
            return code
        }
        return "\(code) – \(name)"
    }
}
