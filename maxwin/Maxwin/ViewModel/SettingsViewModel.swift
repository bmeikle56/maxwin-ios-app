//
//  SettingsViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var isSigningOut = false
    var isDeletingAccount = false
    var showSignOutConfirmation = false
    var showDeleteConfirmation = false
    var errorMessage: String?

    private let authService: AuthServicing
    private let settingsService: SettingsServicing
    private let trackDataService: TrackDataServicing

    var username: String {
        authService.currentUser?.username ?? "Player"
    }

    var animationsEnabled: Bool {
        settingsService.settings.animationsEnabled
    }

    init(
        authService: AuthServicing,
        settingsService: SettingsServicing,
        trackDataService: TrackDataServicing
    ) {
        self.authService = authService
        self.settingsService = settingsService
        self.trackDataService = trackDataService
    }

    func setAnimationsEnabled(_ enabled: Bool) {
        settingsService.updateAnimationsEnabled(enabled)
    }

    func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        await authService.signOut()
        trackDataService.clear()
    }

    func deleteAccount() async {
        isDeletingAccount = true
        errorMessage = nil
        defer { isDeletingAccount = false }

        do {
            try await authService.deleteAccount()
            trackDataService.clear()
        } catch {
            errorMessage = "Couldn't delete account. Try again."
        }
    }
}
