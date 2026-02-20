//
//  ReminderListSelectionView.swift
//  Glance Companion
//
//  View for selecting which reminder lists to sync.
//

import SwiftUI

struct ReminderListSelectionView: View {
    let calendarManager: CalendarManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button("Select All") {
                            calendarManager.selectAllReminderLists()
                        }
                        Spacer()
                        Button("Deselect All") {
                            calendarManager.deselectAllReminderLists()
                        }
                    }
                    .buttonStyle(.borderless)
                }
                
                Section("Reminder Lists") {
                    if calendarManager.availableReminderLists.isEmpty {
                        Text("No reminder lists available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(calendarManager.availableReminderLists) { list in
                            ReminderListRow(
                                reminderList: list,
                                isSelected: calendarManager.selectedReminderListIDs.contains(list.id),
                                onToggle: {
                                    calendarManager.toggleReminderListSelection(list.id)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Select Reminder Lists")
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

// MARK: - Reminder List Row

struct ReminderListRow: View {
    let reminderList: ReminderListInfo
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(cgColor: reminderList.color))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminderList.title)
                        .foregroundStyle(.primary)
                    
                    Text(reminderList.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .orange : .secondary)
                    .font(.title3)
            }
        }
        .buttonStyle(.plain)
    }
}
