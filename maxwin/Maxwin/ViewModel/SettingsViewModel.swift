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
    var showDeleteConfirmation = false
    var errorMessage: String?

    private let authService: AuthServicing
    private let settingsService: SettingsServicing

    var username: String {
        authService.currentUser?.username ?? "Player"
    }

    var animationsEnabled: Bool {
        settingsService.settings.animationsEnabled
    }

    init(authService: AuthServicing, settingsService: SettingsServicing) {
        self.authService = authService
        self.settingsService = settingsService
    }

    func setAnimationsEnabled(_ enabled: Bool) {
        settingsService.updateAnimationsEnabled(enabled)
    }

    func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        await authService.signOut()
    }

    func deleteAccount() async {
        isDeletingAccount = true
        errorMessage = nil
        defer { isDeletingAccount = false }

        do {
            try await authService.deleteAccount()
        } catch {
            errorMessage = "Couldn't delete account. Try again."
        }
    }
}
