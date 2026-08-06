//
//  SettingsViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

@Observable
@MainActor
final class SettingsViewModel {
    var isSigningOut = false
    var isDeletingAccount = false
    var isUpdatingAvatar = false
    var showSignOutConfirmation = false
    var showDeleteConfirmation = false
    var errorMessage: String?
    var avatarImage: UIImage?

    private let authService: AuthServicing
    private let settingsService: SettingsServicing
    private let trackDataService: TrackDataServicing

    var username: String {
        authService.currentUser?.username ?? "Player"
    }

    var animationsEnabled: Bool {
        settingsService.settings.animationsEnabled
    }

    var tipsEnabled: Bool {
        settingsService.settings.tipsEnabled
    }

    init(
        authService: AuthServicing,
        settingsService: SettingsServicing,
        trackDataService: TrackDataServicing
    ) {
        self.authService = authService
        self.settingsService = settingsService
        self.trackDataService = trackDataService
        reloadAvatar()
    }

    func reloadAvatar() {
        avatarImage = ProfileAvatarStore.loadImage(
            fileName: authService.currentUser?.avatarFileName
        )
    }

    func updateAvatar(from item: PhotosPickerItem?) async {
        guard let item else { return }

        isUpdatingAvatar = true
        errorMessage = nil
        defer { isUpdatingAvatar = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Couldn't read that photo. Try another."
                return
            }
            _ = try await authService.updateAvatar(imageData: data)
            reloadAvatar()
        } catch {
            errorMessage = "Couldn't update profile photo. Try again."
        }
    }

    func setAnimationsEnabled(_ enabled: Bool) {
        settingsService.updateAnimationsEnabled(enabled)
    }

    func setTipsEnabled(_ enabled: Bool) {
        settingsService.updateTipsEnabled(enabled)
    }

    func makeEditProfileViewModel() -> EditProfileViewModel {
        EditProfileViewModel(authService: authService)
    }

    func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        await authService.signOut()
        trackDataService.clear()
        avatarImage = nil
    }

    func deleteAccount() async {
        isDeletingAccount = true
        errorMessage = nil
        defer { isDeletingAccount = false }

        do {
            try await authService.deleteAccount()
            trackDataService.clear()
            avatarImage = nil
        } catch {
            errorMessage = "Couldn't delete account. Try again."
        }
    }
}
