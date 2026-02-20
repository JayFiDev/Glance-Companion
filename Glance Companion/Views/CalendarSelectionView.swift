//
//  CalendarSelectionView.swift
//  Glance Companion
//
//  View for selecting which calendars to sync.
//

import SwiftUI

struct CalendarSelectionView: View {
    let calendarManager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button("Select All") {
                            calendarManager.selectAllCalendars()
                        }
                        Spacer()
                        Button("Deselect All") {
                            calendarManager.deselectAllCalendars()
                        }
                    }
                    .buttonStyle(.borderless)
                }
                
                Section("Calendars") {
                    if calendarManager.availableCalendars.isEmpty {
                        Text("No calendars available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(calendarManager.availableCalendars) { calendar in
                            CalendarRow(
                                calendar: calendar,
                                isSelected: calendarManager.selectedCalendarIDs.contains(calendar.id),
                                onToggle: {
                                    calendarManager.toggleCalendarSelection(calendar.id)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Select Calendars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Row

struct CalendarRow: View {
    let calendar: CalendarInfo
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(cgColor: calendar.color))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(calendar.title)
                        .foregroundStyle(.primary)
                    
                    Text(calendar.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.title3)
            }
        }
        .buttonStyle(.plain)
    }
}
