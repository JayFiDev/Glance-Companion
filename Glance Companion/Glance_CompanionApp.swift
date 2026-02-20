//
//  Glance_CompanionApp.swift
//  Glance Companion
//


import SwiftUI

@main
struct Glance_CompanionApp: App {
    @State private var appState = AppState()
    @State private var bleManager = BLEManager()
    @State private var calendarManager = CalendarManager()

    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                MainView(
                    bleManager: bleManager,
                    calendarManager: calendarManager,
                    appState: $appState
                )
            } else {
                OnboardingView(
                    calendarManager: calendarManager,
                    onComplete: {
                        appState.completeOnboarding()
                    }
                )
            }
        }
    }
}
