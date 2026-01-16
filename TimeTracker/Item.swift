//
//  Item.swift
//  TimeTracker
//
//  Created by Andreas Katzmann on 16/01/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
