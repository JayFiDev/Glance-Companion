//
//  CalendarManager.swift
//  Glance Companion
//
//  Manages calendar and reminder access via EventKit.
//  Provides data models and JSON encoding for BLE transfer.
//

import Foundation
import EventKit

// MARK: - Calendar Info Model

struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let color: CGColor
    let source: String
    
    init(from calendar: EKCalendar) {
        self.id = calendar.calendarIdentifier
        self.title = calendar.title
        self.color = calendar.cgColor
        self.source = calendar.source.title
    }
}

// MARK: - Reminder List Info Model

struct ReminderListInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let color: CGColor
    let source: String
    
    init(from calendar: EKCalendar) {
        self.id = calendar.calendarIdentifier
        self.title = calendar.title
        self.color = calendar.cgColor
        self.source = calendar.source.title
    }
}

@Observable
final class CalendarManager {
    // MARK: - State

    var calendarAuthorized = false
    var remindersAuthorized = false
    
    // MARK: - Available Sources
    
    var availableCalendars: [CalendarInfo] = []
    var availableReminderLists: [ReminderListInfo] = []
    
    // MARK: - Selected Sources
    
    var selectedCalendarIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "selectedCalendarIDs") ?? []) {
        didSet {
            UserDefaults.standard.set(Array(selectedCalendarIDs), forKey: "selectedCalendarIDs")
        }
    }
    
    var selectedReminderListIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "selectedReminderListIDs") ?? []) {
        didSet {
            UserDefaults.standard.set(Array(selectedReminderListIDs), forKey: "selectedReminderListIDs")
        }
    }

    // MARK: - Private

    private let eventStore = EKEventStore()
    
    // MARK: - Init
    
    init() {
        checkExistingAuthorization()
    }
    
    /// Check current authorization status without prompting
    private func checkExistingAuthorization() {
        let calendarStatus = EKEventStore.authorizationStatus(for: .event)
        calendarAuthorized = (calendarStatus == .fullAccess)
        
        let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
        remindersAuthorized = (reminderStatus == .fullAccess)
        
        // Load data asynchronously if already authorized
        if calendarAuthorized || remindersAuthorized {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                
                let calendars = self.calendarAuthorized ? self.eventStore.calendars(for: .event).map { CalendarInfo(from: $0) } : []
                let reminderLists = self.remindersAuthorized ? self.eventStore.calendars(for: .reminder).map { ReminderListInfo(from: $0) } : []
                
                DispatchQueue.main.async {
                    self.availableCalendars = calendars
                    self.availableReminderLists = reminderLists
                    
                    // Select all by default if none selected
                    if self.selectedCalendarIDs.isEmpty && !calendars.isEmpty {
                        self.selectedCalendarIDs = Set(calendars.map { $0.id })
                    }
                    if self.selectedReminderListIDs.isEmpty && !reminderLists.isEmpty {
                        self.selectedReminderListIDs = Set(reminderLists.map { $0.id })
                    }
                }
            }
        }
    }
    private let daysToFetch = 7
    private let maxEvents = 20
    private let maxReminders = 60

    // MARK: - Permissions

    func requestPermissions() {
        requestCalendarPermission()
        requestRemindersPermission()
    }
    
    func requestCalendarPermission() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.calendarAuthorized = granted
                if granted {
                    self?.loadAvailableCalendars()
                }
                if let error { print("Calendar permission error: \(error)") }
            }
        }
    }
    
    func requestRemindersPermission() {
        eventStore.requestFullAccessToReminders { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.remindersAuthorized = granted
                if granted {
                    self?.loadAvailableReminderLists()
                }
                if let error { print("Reminder permission error: \(error)") }
            }
        }
    }
    
    // MARK: - Load Available Sources
    
    func loadAvailableCalendars() {
        let calendars = eventStore.calendars(for: .event)
        availableCalendars = calendars.map { CalendarInfo(from: $0) }
        
        // If no calendars selected yet, select all by default
        if selectedCalendarIDs.isEmpty {
            selectedCalendarIDs = Set(availableCalendars.map { $0.id })
        }
    }
    
    func loadAvailableReminderLists() {
        let lists = eventStore.calendars(for: .reminder)
        availableReminderLists = lists.map { ReminderListInfo(from: $0) }
        
        // If no lists selected yet, select all by default
        if selectedReminderListIDs.isEmpty {
            selectedReminderListIDs = Set(availableReminderLists.map { $0.id })
        }
    }
    
    // MARK: - Selection Management
    
    func toggleCalendarSelection(_ calendarID: String) {
        if selectedCalendarIDs.contains(calendarID) {
            selectedCalendarIDs.remove(calendarID)
        } else {
            selectedCalendarIDs.insert(calendarID)
        }
    }
    
    func toggleReminderListSelection(_ listID: String) {
        if selectedReminderListIDs.contains(listID) {
            selectedReminderListIDs.remove(listID)
        } else {
            selectedReminderListIDs.insert(listID)
        }
    }
    
    func selectAllCalendars() {
        selectedCalendarIDs = Set(availableCalendars.map { $0.id })
    }
    
    func deselectAllCalendars() {
        selectedCalendarIDs = []
    }
    
    func selectAllReminderLists() {
        selectedReminderListIDs = Set(availableReminderLists.map { $0.id })
    }
    
    func deselectAllReminderLists() {
        selectedReminderListIDs = []
    }

    // MARK: - Fetch Data

    func fetchCalendarData() async -> CalendarData {
        var fetchedEvents: [CalendarEvent] = []
        var fetchedReminders: [ReminderItem] = []

        if calendarAuthorized {
            fetchedEvents = fetchEvents()
        }
        if remindersAuthorized {
            fetchedReminders = await fetchReminders()
        }

        return CalendarData(events: fetchedEvents, reminders: fetchedReminders)
    }

    // MARK: - Private Fetch

    private func fetchEvents() -> [CalendarEvent] {
        let now = Date()
        guard let end = Calendar.current.date(byAdding: .day, value: daysToFetch, to: now) else {
            return []
        }

        // Get selected calendars
        let selectedCalendars = eventStore.calendars(for: .event).filter { calendar in
            selectedCalendarIDs.contains(calendar.calendarIdentifier)
        }
        
        // If no calendars selected, return empty
        guard !selectedCalendars.isEmpty else { return [] }

        let predicate = eventStore.predicateForEvents(withStart: now, end: end, calendars: selectedCalendars)
        let ekEvents = eventStore.events(matching: predicate)

        return Array(ekEvents.prefix(maxEvents).map { event in
            CalendarEvent(
                title: event.title ?? "Untitled",
                start: event.startDate,
                end: event.endDate,
                allDay: event.isAllDay,
                location: event.location
            )
        })
    }

    // MARK: - Complete Reminders (Two-Way Sync)

    func completeReminders(ids: [String]) {
        guard remindersAuthorized, !ids.isEmpty else { return }

        for id in ids {
            if let item = eventStore.calendarItem(withIdentifier: id) as? EKReminder {
                item.isCompleted = true
                item.completionDate = Date()
                do {
                    try eventStore.save(item, commit: false)
                    print("[CalendarManager] Marked reminder completed: \(item.title ?? id)")
                } catch {
                    print("[CalendarManager] Error completing reminder \(id): \(error)")
                }
            } else {
                print("[CalendarManager] Reminder not found: \(id)")
            }
        }

        do {
            try eventStore.commit()
            print("[CalendarManager] Committed \(ids.count) completion(s)")
        } catch {
            print("[CalendarManager] Commit error: \(error)")
        }
    }

    private func fetchReminders() async -> [ReminderItem] {
        await withCheckedContinuation { continuation in
            // Get selected reminder lists
            let selectedLists = eventStore.calendars(for: .reminder).filter { calendar in
                selectedReminderListIDs.contains(calendar.calendarIdentifier)
            }
            
            guard !selectedLists.isEmpty else {
                continuation.resume(returning: [])
                return
            }
            
            let predicate = eventStore.predicateForReminders(in: selectedLists)
            eventStore.fetchReminders(matching: predicate) { [maxReminders] ekReminders in
                guard let ekReminders else {
                    continuation.resume(returning: [])
                    return
                }

                let items = Array(
                    ekReminders
                        .filter { !$0.isCompleted }
                        .sorted { ($0.calendar?.title ?? "") < ($1.calendar?.title ?? "") }
                        .prefix(maxReminders)
                        .map { reminder in
                            ReminderItem(
                                title: reminder.title ?? "Untitled",
                                dueDate: reminder.dueDateComponents?.date,
                                priority: reminder.priority,
                                completed: reminder.isCompleted,
                                calendarItemIdentifier: reminder.calendarItemIdentifier,
                                list: reminder.calendar?.title ?? ""
                            )
                        }
                )
                continuation.resume(returning: items)
            }
        }
    }
}

// MARK: - Data Models

struct CalendarData: Codable, Sendable {
    let events: [CalendarEvent]
    let reminders: [ReminderItem]
    let syncDate: String
    let version: Int

    init(events: [CalendarEvent], reminders: [ReminderItem]) {
        self.events = events
        self.reminders = reminders
        self.syncDate = ISO8601DateFormatter().string(from: Date())
        self.version = 1
    }
}

struct CalendarEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let start: Date
    let end: Date
    let allDay: Bool
    let location: String?

    enum CodingKeys: String, CodingKey {
        case title, start, end, allDay, location
    }

    init(title: String, start: Date, end: Date, allDay: Bool, location: String?) {
        self.id = UUID()
        self.title = title
        self.start = start
        self.end = end
        self.allDay = allDay
        self.location = location
    }

    init(from decoder: Decoder) throws {
        id = UUID()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decode(String.self, forKey: .title)
        allDay = try c.decode(Bool.self, forKey: .allDay)
        location = try c.decodeIfPresent(String.self, forKey: .location)

        let fmt = ISO8601DateFormatter()
        let startStr = try c.decode(String.self, forKey: .start)
        let endStr = try c.decode(String.self, forKey: .end)
        guard let s = fmt.date(from: startStr), let e = fmt.date(from: endStr) else {
            throw DecodingError.dataCorruptedError(forKey: .start, in: c,
                                                    debugDescription: "Invalid date")
        }
        start = s
        end = e
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let fmt = ISO8601DateFormatter()
        try c.encode(title, forKey: .title)
        try c.encode(fmt.string(from: start), forKey: .start)
        try c.encode(fmt.string(from: end), forKey: .end)
        try c.encode(allDay, forKey: .allDay)
        try c.encodeIfPresent(location, forKey: .location)
    }
}

struct ReminderItem: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let dueDate: Date?
    let priority: Int
    let completed: Bool
    let calendarItemIdentifier: String
    let list: String

    enum CodingKeys: String, CodingKey {
        case title, dueDate, priority, completed, calendarItemIdentifier, list
    }

    init(title: String, dueDate: Date?, priority: Int, completed: Bool, calendarItemIdentifier: String = "", list: String = "") {
        self.id = UUID()
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.completed = completed
        self.calendarItemIdentifier = calendarItemIdentifier
        self.list = list
    }

    init(from decoder: Decoder) throws {
        id = UUID()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decode(String.self, forKey: .title)
        priority = try c.decode(Int.self, forKey: .priority)
        completed = try c.decode(Bool.self, forKey: .completed)
        calendarItemIdentifier = try c.decodeIfPresent(String.self, forKey: .calendarItemIdentifier) ?? ""
        list = try c.decodeIfPresent(String.self, forKey: .list) ?? ""

        if let dateStr = try c.decodeIfPresent(String.self, forKey: .dueDate) {
            dueDate = ISO8601DateFormatter().date(from: dateStr)
        } else {
            dueDate = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        if let dueDate {
            try c.encode(ISO8601DateFormatter().string(from: dueDate), forKey: .dueDate)
        } else {
            try c.encodeNil(forKey: .dueDate)
        }
        try c.encode(priority, forKey: .priority)
        try c.encode(completed, forKey: .completed)
        try c.encode(calendarItemIdentifier, forKey: .calendarItemIdentifier)
        try c.encode(list, forKey: .list)
    }
}

// MARK: - Display Configuration

struct DisplayConfig: Codable, Sendable {
    var autoSleepMinutes: Int = 5
    var useDithering: Bool = true
    var use24HourTime: Bool = true
    var utcOffsetSeconds: Int = TimeZone.current.secondsFromGMT()
}

// MARK: - Sync Package (sent to X4)

struct SyncPackage: Codable, Sendable {
    let calendarData: CalendarData
    let displayConfig: DisplayConfig
    let syncDate: String
    let version: Int

    init(calendarData: CalendarData, displayConfig: DisplayConfig) {
        self.calendarData = calendarData
        self.displayConfig = displayConfig
        self.syncDate = ISO8601DateFormatter().string(from: Date())
        self.version = 2  // Version 2 includes display config
    }

    func toJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try? encoder.encode(self)
    }
}
