//
//  Formatters.swift
//  TimeTracker
//
//  Static DateFormatter instances to avoid recreation on every view body evaluation.
//

import Foundation

enum Formatters {
    static let danishDayMonthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "da_DK")
        f.dateFormat = "EEEE d. MMMM yyyy"
        return f
    }()

    static let danishMonthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "da_DK")
        f.dateFormat = "MMMM yyyy"
        return f
    }()
}
