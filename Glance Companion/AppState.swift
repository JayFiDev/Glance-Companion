//
//  AppState.swift
//  ReminderSync
//
//  Manages application-wide state including onboarding.
//

import SwiftUI

@Observable
final class AppState {
    // MARK: - Onboarding
    
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    // MARK: - Sync Settings
    
    var useDemoData: Bool = false
    
    // MARK: - Methods
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
