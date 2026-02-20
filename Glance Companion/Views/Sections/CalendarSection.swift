//
//  CalendarSection.swift
//  Glance Companion
//
//  Section for calendar and reminder list selection.
//

import SwiftUI

struct CalendarSection: View {
    let calendarManager: CalendarManager
    @State private var showingCalendarSelection = false
    @State private var showingReminderListSelection = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Data Sources", systemImage: "folder")
                    .font(.headline)
                Spacer()
            }
            
            // Calendar Selection
            sourceRow(
                title: "Calendars",
                icon: "calendar",
                iconColor: .blue,
                selectedCount: calendarManager.selectedCalendarIDs.count,
                totalCount: calendarManager.availableCalendars.count,
                isAuthorized: calendarManager.calendarAuthorized
            ) {
                if calendarManager.calendarAuthorized {
                    showingCalendarSelection = true
                } else {
                    calendarManager.requestCalendarPermission()
                }
            }
            
            Divider()
            
            // Reminder Selection
            sourceRow(
                title: "Reminders",
                icon: "checklist",
                iconColor: .orange,
                selectedCount: calendarManager.selectedReminderListIDs.count,
                totalCount: calendarManager.availableReminderLists.count,
                isAuthorized: calendarManager.remindersAuthorized
            ) {
                if calendarManager.remindersAuthorized {
                    showingReminderListSelection = true
                } else {
                    calendarManager.requestRemindersPermission()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
        )
        .glassEffect(in: .rect(cornerRadius: 30))
        .sheet(isPresented: $showingCalendarSelection) {
            CalendarSelectionView(calendarManager: calendarManager)
        }
        .sheet(isPresented: $showingReminderListSelection) {
            ReminderListSelectionView(calendarManager: calendarManager)
        }
    }
    
    private func sourceRow(
        title: String,
        icon: String,
        iconColor: Color,
        selectedCount: Int,
        totalCount: Int,
        isAuthorized: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                if isAuthorized {
                    Text("\(selectedCount) of \(totalCount) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Tap to grant access")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
            
            Image(systemName: isAuthorized ? "chevron.right" : "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundStyle(isAuthorized ? Color.secondary : Color.orange)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}
