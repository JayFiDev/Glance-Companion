//
//  DemoData.swift
//  Glance Companion
//
//  Provides generic demo data for screenshots without leaking personal information.
//

import Foundation

enum DemoData {
    // MARK: - Demo Events
    
    static var demoEvents: [CalendarEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            CalendarEvent(
                title: "Team Standup",
                start: calendar.date(byAdding: .hour, value: 1, to: now) ?? now,
                end: calendar.date(byAdding: .hour, value: 2, to: now) ?? now,
                allDay: false,
                location: "Conference Room A"
            ),
            CalendarEvent(
                title: "Project Review",
                start: calendar.date(byAdding: .hour, value: 3, to: now) ?? now,
                end: calendar.date(byAdding: .hour, value: 4, to: now) ?? now,
                allDay: false,
                location: "Virtual Meeting"
            ),
            CalendarEvent(
                title: "Lunch Break",
                start: calendar.date(byAdding: .hour, value: 5, to: now) ?? now,
                end: calendar.date(byAdding: .hour, value: 6, to: now) ?? now,
                allDay: false,
                location: nil
            ),
            CalendarEvent(
                title: "Client Presentation",
                start: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                end: calendar.date(byAdding: .hour, value: 26, to: now) ?? now,
                allDay: false,
                location: "Main Office"
            ),
            CalendarEvent(
                title: "Team Building Event",
                start: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                end: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                allDay: true,
                location: "City Park"
            ),
            CalendarEvent(
                title: "Sprint Planning",
                start: calendar.date(byAdding: .day, value: 3, to: now) ?? now,
                end: calendar.date(byAdding: .hour, value: 74, to: now) ?? now,
                allDay: false,
                location: "Conference Room B"
            )
        ]
    }
    
    // MARK: - Demo Reminders
    
    static var demoReminders: [ReminderItem] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            // Errands
            ReminderItem(
                title: "Schedule dentist appointment",
                dueDate: nil,
                priority: 9,
                completed: false,
                calendarItemIdentifier: "demo-reminder-3",
                list: "Errands"
            ),
            ReminderItem(
                title: "Call insurance company",
                dueDate: calendar.date(byAdding: .day, value: 3, to: now),
                priority: 1,
                completed: false,
                calendarItemIdentifier: "demo-reminder-5",
                list: "Errands"
            ),
            ReminderItem(
                title: "Renew gym membership",
                dueDate: calendar.date(byAdding: .day, value: 7, to: now),
                priority: 9,
                completed: false,
                calendarItemIdentifier: "demo-reminder-6",
                list: "Errands"
            ),
            // Shopping
            ReminderItem(
                title: "Buy groceries",
                dueDate: calendar.date(byAdding: .day, value: 2, to: now),
                priority: 5,
                completed: false,
                calendarItemIdentifier: "demo-reminder-4",
                list: "Shopping"
            ),
            // Work
            ReminderItem(
                title: "Review pull requests",
                dueDate: now,
                priority: 1,
                completed: false,
                calendarItemIdentifier: "demo-reminder-1",
                list: "Work"
            ),
            ReminderItem(
                title: "Update documentation",
                dueDate: calendar.date(byAdding: .day, value: 1, to: now),
                priority: 5,
                completed: false,
                calendarItemIdentifier: "demo-reminder-2",
                list: "Work"
            )
        ]
    }
    
    // MARK: - Demo Calendar Data
    
    static var demoCalendarData: CalendarData {
        CalendarData(events: demoEvents, reminders: demoReminders)
    }
    
    // MARK: - Demo Sync Package
    
    static func demoSyncPackage(with config: DisplayConfig) -> SyncPackage {
        SyncPackage(calendarData: demoCalendarData, displayConfig: config)
    }
}
