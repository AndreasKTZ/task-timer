//
//  TaskTemplate.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import Foundation
import SwiftData

@Model
final class TaskTemplate {
    var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date

    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
