//
//  Notifications.swift
//  TimeTracker
//
//  Notification names for menu bar command communication.
//

import Foundation

extension Notification.Name {
    static let addNewTask = Notification.Name("addNewTask")
    static let goToToday = Notification.Name("goToToday")
    static let showActualTime = Notification.Name("showActualTime")
    static let showBillableTime = Notification.Name("showBillableTime")
}
