//
//  SettingsSection.swift
//  Glance Companion
//
//  Section for display and sync settings.
//

import SwiftUI

struct SettingsSection: View {
    @Binding var config: DisplayConfig
    @Binding var useDemoData: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Settings", systemImage: "gearshape")
                    .font(.headline)
                Spacer()
            }
            
            // Auto Sleep
            HStack {
                Label("Auto Sleep", systemImage: "moon.fill")
                    .font(.subheadline)
                
                Spacer()
                
                Stepper("\(config.autoSleepMinutes) min", value: $config.autoSleepMinutes, in: 1...60)
                    .fixedSize()
            }
            
            Divider()
            
            // Time Format
            Toggle(isOn: $config.use24HourTime) {
                Label("24-Hour Time", systemImage: "clock")
                    .font(.subheadline)
            }
            
            Divider()
            
            // Demo Data Toggle
            Toggle(isOn: $useDemoData) {
                Label("Use Demo Data", systemImage: "sparkles")
                    .font(.subheadline)
            }
            .tint(.purple)
            
            if useDemoData {
                Text("Sync will send sample data instead of your calendars and reminders")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
        )
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}
