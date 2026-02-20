//
//  OnboardingView.swift
//  ReminderSync
//
//  Onboarding flow for permission setup.
//

import SwiftUI

struct OnboardingView: View {
    let calendarManager: CalendarManager
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Welcome
            OnboardingPage(
                icon: "calendar.badge.clock",
                iconColor: .blue,
                title: "Welcome to Glance Companion",
                subtitle: "Sync your calendars and reminders to your Xteink X4 e-ink display.",
                buttonTitle: "Get Started",
                buttonAction: { withAnimation { currentPage = 1 } }
            )
            .tag(0)
            
            // Calendar Permission
            OnboardingPage(
                icon: calendarManager.calendarAuthorized ? "checkmark.circle.fill" : "calendar",
                iconColor: calendarManager.calendarAuthorized ? .green : .blue,
                title: "Calendar Access",
                subtitle: "Allow access to your calendars so we can display your upcoming events on the X4.",
                buttonTitle: calendarManager.calendarAuthorized ? "Continue" : "Allow Calendar Access",
                buttonAction: {
                    if calendarManager.calendarAuthorized {
                        withAnimation { currentPage = 2 }
                    } else {
                        calendarManager.requestCalendarPermission()
                    }
                },
                secondaryButtonTitle: calendarManager.calendarAuthorized ? nil : "Skip for Now",
                secondaryButtonAction: { withAnimation { currentPage = 2 } }
            )
            .tag(1)
            
            // Reminders Permission
            OnboardingPage(
                icon: calendarManager.remindersAuthorized ? "checkmark.circle.fill" : "checklist",
                iconColor: calendarManager.remindersAuthorized ? .green : .orange,
                title: "Reminders Access",
                subtitle: "Allow access to your reminders so we can display your tasks on the X4.",
                buttonTitle: calendarManager.remindersAuthorized ? "Continue" : "Allow Reminders Access",
                buttonAction: {
                    if calendarManager.remindersAuthorized {
                        withAnimation { currentPage = 3 }
                    } else {
                        calendarManager.requestRemindersPermission()
                    }
                },
                secondaryButtonTitle: calendarManager.remindersAuthorized ? nil : "Skip for Now",
                secondaryButtonAction: { withAnimation { currentPage = 3 } }
            )
            .tag(2)
            
            // Bluetooth Info
            OnboardingPage(
                icon: "antenna.radiowaves.left.and.right",
                iconColor: .purple,
                title: "Bluetooth Connection",
                subtitle: "Make sure your Xteink X4 is powered on and in range. You'll be prompted to allow Bluetooth when you scan for devices.",
                buttonTitle: "Start Using Glance Companion",
                buttonAction: onComplete
            )
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

// MARK: - Reusable Onboarding Page

private struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonAction: () -> Void
    var secondaryButtonTitle: String? = nil
    var secondaryButtonAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(iconColor)
            }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(iconColor)
                
                if let secondaryTitle = secondaryButtonTitle,
                   let secondaryAction = secondaryButtonAction {
                    Button(action: secondaryAction) {
                        Text(secondaryTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
}
