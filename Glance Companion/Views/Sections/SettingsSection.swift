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

    private var wakeTime: Binding<Date> {
        Binding(
            get: {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = config.wakeScheduleHour
                components.minute = config.wakeScheduleMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                config.wakeScheduleHour = components.hour ?? 7
                config.wakeScheduleMinute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Settings", systemImage: "gearshape")
                    .font(.headline)
                Spacer()
            }

            // MARK: Auto Sleep

            Toggle(isOn: $config.autoSleepEnabled) {
                Label("Auto Sleep", systemImage: "moon.fill")
                    .font(.subheadline)
            }

            if config.autoSleepEnabled {
                HStack {
                    Text("After")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Stepper("\(config.autoSleepMinutes) min", value: $config.autoSleepMinutes, in: 1...60)
                        .fixedSize()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()

            // MARK: Daily BLE Wake Schedule

            Toggle(isOn: $config.wakeScheduleEnabled) {
                Label("Daily BLE Wake", systemImage: "alarm")
                    .font(.subheadline)
            }

            if config.wakeScheduleEnabled {
                HStack {
                    Text("Wake at")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: wakeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                Text("Device wakes from sleep and opens Bluetooth for 10 minutes at this time every day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // MARK: Sleep Screen

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Sleep Screen", systemImage: "display")
                        .font(.subheadline)
                    Spacer()
                    Picker("Sleep Screen", selection: $config.sleepScreen) {
                        ForEach(SleepScreenMode.allCases, id: \.self) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Divider()

            // MARK: Time Format

            Toggle(isOn: $config.use24HourTime) {
                Label("24-Hour Time", systemImage: "clock")
                    .font(.subheadline)
            }

            Divider()

            // MARK: Demo Data

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
        .animation(.easeInOut(duration: 0.2), value: config.autoSleepEnabled)
        .animation(.easeInOut(duration: 0.2), value: config.wakeScheduleEnabled)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
        )
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}
