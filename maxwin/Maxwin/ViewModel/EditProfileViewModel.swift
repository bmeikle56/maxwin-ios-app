//
//  EditProfileViewModel.swift
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
final class EditProfileViewModel {
    var username: String
    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""
    var avatarImage: UIImage?
    var isSaving = false
    var isUpdatingAvatar = false
    var errorMessage: String?

    private let authService: AuthServicing
    private let originalUsername: String

    var hasEnteredCurrentPassword: Bool {
        !currentPassword.isEmpty
    }

    var hasEnteredNewPassword: Bool {
        !newPassword.isEmpty
    }

    var isChangingPassword: Bool {
        !currentPassword.isEmpty || !newPassword.isEmpty || !confirmPassword.isEmpty
    }

    var isPasswordChangeValid: Bool {
        !currentPassword.isEmpty
            && !newPassword.isEmpty
            && newPassword == confirmPassword
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasUsernameChange: Bool {
        !trimmedUsername.isEmpty && trimmedUsername != originalUsername
    }

    var canSave: Bool {
        guard !isSaving, !trimmedUsername.isEmpty else { return false }

        if isChangingPassword {
            return isPasswordChangeValid
        }

        return hasUsernameChange
    }

    init(authService: AuthServicing) {
        self.authService = authService
        let current = authService.currentUser?.username ?? ""
        self.originalUsername = current
        self.username = current
        self.avatarImage = ProfileAvatarStore.loadImage(
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
            avatarImage = ProfileAvatarStore.loadImage(
                fileName: authService.currentUser?.avatarFileName
            )
        } catch {
            errorMessage = "Couldn't update profile photo. Try again."
        }
    }

    /// Returns `true` when the profile was saved successfully.
    @discardableResult
    func save() async -> Bool {
        guard canSave else { return false }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            if hasUsernameChange {
                _ = try await authService.updateUsername(username)
            }

            if isChangingPassword {
                guard newPassword == confirmPassword else {
                    errorMessage = "New passwords don’t match."
                    return false
                }
                try await authService.updatePassword(current: currentPassword, new: newPassword)
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            }

            return true
        } catch AuthError.emptyFields {
            errorMessage = "Fill in all required fields to continue."
            return false
        } catch AuthError.incorrectPassword {
            errorMessage = AuthError.incorrectPassword.localizedDescription
            return false
        } catch {
            errorMessage = "Couldn't update profile. Try again."
            return false
        }
    }
}
