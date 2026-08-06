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
    var avatarImage: UIImage?
    var isSaving = false
    var isUpdatingAvatar = false
    var errorMessage: String?

    private let authService: AuthServicing
    private let originalUsername: String

    var canSave: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != originalUsername && !isSaving
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
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await authService.updateUsername(username)
            return true
        } catch AuthError.emptyFields {
            errorMessage = "Enter a username to continue."
            return false
        } catch {
            errorMessage = "Couldn't update profile. Try again."
            return false
        }
    }
}
