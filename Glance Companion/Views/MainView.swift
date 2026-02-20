//
//  MainView.swift
//  Glance Companion
//
//  Main UI for syncing calendar events and reminders to the Xteink X4.
//

import SwiftUI

struct MainView: View {
    let bleManager: BLEManager
    let calendarManager: CalendarManager
    @Binding var appState: AppState
    
    @State private var displayConfig = DisplayConfig()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection & Sync Section
                    ConnectionSection(
                        bleManager: bleManager,
                        useDemoData: appState.useDemoData,
                        syncAction: syncToX4
                    )
                    
                    // Calendar & Reminders Selection
                    CalendarSection(calendarManager: calendarManager)
                    
                    // Display Settings
                    SettingsSection(
                        config: $displayConfig,
                        useDemoData: $appState.useDemoData
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("Glance Companion")
        }
    }
    
    private func syncToX4() {
        Task {
            bleManager.addLog("Starting sync...")
            
            let data: CalendarData
            if appState.useDemoData {
                data = DemoData.demoCalendarData
                bleManager.addLog("Using demo data")
            } else {
                data = await calendarManager.fetchCalendarData()
            }
            
            bleManager.addLog("Found \(data.events.count) events, \(data.reminders.count) reminders")
            
            let package = SyncPackage(calendarData: data, displayConfig: displayConfig)
            guard let json = package.toJSON() else {
                bleManager.addLog("ERROR: JSON encoding failed")
                return
            }
            
            bleManager.addLog("JSON size: \(json.count) bytes")
            bleManager.sendData(json)
        }
    }
}
