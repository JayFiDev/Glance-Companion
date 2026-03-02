//
//  SyncIntent.swift
//  Glance Companion
//
//  Apple Shortcuts AppIntent — syncs calendar & reminders to the Glance X4.
//  Add "Sync to Glance X4" to any Shortcut or automation in the Shortcuts app.
//

import AppIntents

struct SyncGlanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync to Glance X4"
    static var description = IntentDescription(
        "Syncs your calendar events and reminders to the Glance X4 e-ink display.",
        categoryName: "Glance"
    )
    static var openAppWhenRun: Bool = true

    @Dependency var bleManager: BLEManager
    @Dependency var calendarManager: CalendarManager
    @Dependency var appState: AppState

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let data: CalendarData
        if appState.useDemoData {
            data = DemoData.demoCalendarData
        } else {
            data = await calendarManager.fetchCalendarData()
        }

        let package = SyncPackage(calendarData: data, displayConfig: appState.displayConfig)
        guard let json = package.toJSON() else {
            throw SyncIntentError.encodingFailed
        }

        bleManager.addLog("[Shortcut] Sync triggered — \(data.events.count) events, \(data.reminders.count) reminders")
        try await bleManager.connectAndSend(json)

        return .result(
            dialog: "Synced \(data.events.count) event(s) and \(data.reminders.count) reminder(s) to Glance."
        )
    }
}

enum SyncIntentError: Error, LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode sync data."
        }
    }
}
